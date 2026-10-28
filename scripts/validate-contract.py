"""Validate design artifacts locally; executes SQLite locally, never connects to Cloudflare."""

from decimal import Decimal
from pathlib import Path
import random
import re

from jsonschema import Draft202012Validator, FormatChecker
from openapi_spec_validator import validate
import sqlite3
import yaml


ROOT = Path(__file__).resolve().parent.parent
api = yaml.safe_load((ROOT / "docs/openapi.yaml").read_text())
validate(api)


def resolve(value):
    while isinstance(value, dict) and "$ref" in value:
        pointer = value["$ref"]
        if not pointer.startswith("#/"):
            raise AssertionError(f"External reference not supported: {pointer}")
        value = api
        for part in pointer[2:].split("/"):
            value = value[part.replace("~1", "/").replace("~0", "~")]
    return value


def walk(value):
    if isinstance(value, dict):
        if "$ref" in value:
            resolve(value)
        for child in value.values():
            walk(child)
    elif isinstance(value, list):
        for child in value:
            walk(child)


walk(api)
checker = FormatChecker()


def validator(schema):
    return Draft202012Validator(
        {**schema, "components": api["components"]}, format_checker=checker
    )


def named(name):
    return validator({"$ref": f"#/components/schemas/{name}"})


examples = 0
for path_item in api["paths"].values():
    for method, operation in path_item.items():
        if method not in {"get", "post", "patch", "delete"}:
            continue
        assert api["security"] == [{"BearerAuth": []}]
        assert operation["x-gachia-permission"] == ("read" if method == "get" else "write")
        if method != "get":
            parameters = [resolve(p) for p in operation.get("parameters", [])]
            assert any(p["name"] == "Idempotency-Key" and p["required"] for p in parameters)
        messages = list(operation["responses"].values())
        if "requestBody" in operation:
            messages.append(operation["requestBody"])
        for message in messages:
            for media in resolve(message).get("content", {}).values():
                values = [media["example"]] if "example" in media else []
                values += [item["value"] for item in media.get("examples", {}).values()]
                for example in values:
                    validator(media["schema"]).validate(example)
                    examples += 1

money = named("PositiveMoney")
for value in ["0.01", "1.00", "20.00", "9999999999999999.99", "92233720368547758.07"]:
    money.validate(value)
for value in ["0.00", "-1.00", "20", "20.0", "20.005", "01.00", " 20.00", "20.00\n", "1e2", "1,000.00", "92233720368547758.08", "92233720368547759.00", "99999999999999999.99", 20, 20.0, None]:
    assert not money.is_valid(value), f"Invalid money accepted: {value!r}"

rng = random.Random(4150)
ceiling = 2**63 - 1
for units in [1, 99, 100, ceiling - 1, ceiling, ceiling + 1, 10**19] + [rng.randrange(1, 10**19) for _ in range(250)]:
    value = f"{units // 100}.{units % 100:02d}"
    assert money.is_valid(value) == (units <= ceiling), value
    if money.is_valid(value):
        assert Decimal(value) * 100 == units

create = named("ExpenseCreate")
create.validate({"amount": "20.00", "description": "Almuerzo"})
for body in [
    {"amount": "20.00"},
    {"amount": 20, "description": "Almuerzo"},
    {"amount": "20.00", "description": 20},
    {"amount": "20.00", "description": "   "},
    {"amount": "20.00", "description": "Almuerzo", "currency": "EUR"},
    {"amount": "20.00", "description": "Almuerzo", "occurred_on": "ayer"},
    {"amount": "20.00", "description": "Almuerzo", "occurred_on": "2026-02-29"},
    {"amount": "20.00", "description": "Almuerzo", "owner_id": "other-owner"},
]:
    assert not create.is_valid(body), f"Invalid expense accepted: {body!r}"

named("SignedTotal").validate("-30.00")
named("UnsignedTotal").validate("0.00")
named("UnsignedTotal").validate("184467440737095516.14")
assert not named("SignedTotal").is_valid("-0.00")
assert not named("SignedTotal").is_valid("30.00\n")
summary_example = api["paths"]["/v1/reports/summary"]["get"]["responses"]["200"]["content"]["application/json"]["example"]
for totals in summary_example["currencies"]:
    assert Decimal(totals["expense_amount"]) - Decimal(totals["refund_amount"]) == Decimal(totals["net_amount"])
    for field in ["expense_amount", "refund_amount", "net_amount"]:
        assert sum(Decimal(category[field]) for category in totals["categories"]) == Decimal(totals[field])
    for field in ["expense_count", "refund_count"]:
        assert sum(category[field] for category in totals["categories"]) == totals[field]
limit = api["components"]["parameters"]["Limit"]["schema"]
assert (limit["default"], limit["minimum"], limit["maximum"]) == (50, 1, 200)
summary_parameters = [resolve(p)["name"] for p in api["paths"]["/v1/reports/summary"]["get"]["parameters"]]
assert set(summary_parameters) == {"from", "to", "currency", "category_id", "uncategorized"}

ddl = (ROOT / "docs/schema/001-tables.sql").read_text()
indexes = (ROOT / "docs/schema/002-indexes.sql").read_text()
db = sqlite3.connect(":memory:")
db.execute("PRAGMA foreign_keys = ON")
db.executescript(ddl)
db.executescript(indexes)
tables = {
    name: {col[1]: col for col in db.execute(f"PRAGMA table_info({name})")}
    for (name,) in db.execute("SELECT name FROM sqlite_schema WHERE type = 'table'").fetchall()
}
assert set(tables) == {"owners", "principals", "agent_credentials", "categories", "expenses", "refunds", "operations", "audit_entries", "classification_runs", "classification_batches"}
for name, columns in tables.items():
    assert "id" in columns
    if name != "owners":
        assert "owner_id" in columns, name
for name in ["expenses", "refunds"]:
    assert {"amount_minor", "currency", "version", "deleted_at"} <= set(tables[name])
    assert tables[name]["amount_minor"][2] == "TEXT"
assert {"idempotency_key", "resolved_input", "response_body", "request_fingerprint"} <= set(tables["operations"])
index_statements = db.execute("SELECT name FROM sqlite_schema WHERE type = 'index' AND sql IS NOT NULL").fetchall()
assert len(index_statements) == 9
assert not db.execute("PRAGMA foreign_key_check").fetchall()

owner = "10000000-0000-4000-8000-000000000001"
expense = "10000000-0000-4000-8000-000000000002"
now = "2026-10-28T12:00:00.000Z"
db.execute("INSERT INTO owners VALUES (?, 'PEN', 'America/Lima', ?)", (owner, now))
insert_expense = """INSERT INTO expenses
    (id, owner_id, amount_minor, currency, occurred_on, description, created_at, updated_at)
    VALUES (?, ?, ?, 'PEN', ?, 'Almuerzo', ?, ?)"""
db.execute(insert_expense, (expense, owner, str(2**63 - 1), "2026-10-28", now, now))
assert db.execute("SELECT amount_minor, typeof(amount_minor) FROM expenses").fetchone() == (str(2**63 - 1), "text")
assert db.execute("SELECT CAST(amount_minor AS INTEGER) FROM expenses").fetchone()[0] == 2**63 - 1
# El dump conserva los int64 como cadenas, sin depender de números JavaScript.
restored = sqlite3.connect(":memory:")
restored.executescript("\n".join(db.iterdump()))
assert restored.execute("SELECT amount_minor FROM expenses").fetchone()[0] == str(2**63 - 1)


def must_fail(sql, args=()):
    try:
        db.execute(sql, args)
    except sqlite3.IntegrityError:
        return
    raise AssertionError(f"Constraint did not reject: {sql}")


for bad in ["0", "-1", "01", "1.0", "1e2", str(2**63), "abc"]:
    must_fail("UPDATE expenses SET amount_minor = ? WHERE id = ?", (bad, expense))
must_fail("UPDATE expenses SET occurred_on = '2026-02-29'")
must_fail("UPDATE expenses SET updated_at = '2026-10-28T12:00:00+00:00'")
must_fail("UPDATE expenses SET owner_id = '20000000-0000-4000-8000-000000000001'")
must_fail("UPDATE expenses SET id = 'not-a-uuid'")
must_fail("UPDATE expenses SET version = 9007199254740992")
must_fail("UPDATE expenses SET amount_minor = '1', refunded_minor = '2'")
category = "10000000-0000-4000-8000-000000000003"
db.execute("INSERT INTO categories VALUES (?, ?, 'Comida', 'comida', 1, 1, ?, ?)", (category, owner, now, now))
must_fail("UPDATE categories SET active = 2")
must_fail("INSERT INTO categories VALUES (?, ?, 'COMIDA', 'comida', 1, 1, ?, ?)", (expense, owner, now, now))
actor = "10000000-0000-4000-8000-000000000004"
op = "10000000-0000-4000-8000-000000000005"
db.execute("INSERT INTO principals VALUES (?, ?, 'agent', 'Bot', ?)", (actor, owner, now))
insert_op = """INSERT INTO operations
    (id, owner_id, idempotency_key, request_fingerprint, method, path, resolved_input, actor_id, state, created_at)
    VALUES (?, ?, 'key', ?, 'POST', '/v1/expenses', ?, ?, 'pending', ?)"""
must_fail(insert_op, (op, owner, "a" * 64, "not-json", actor, now))
db.execute(insert_op, (op, owner, "a" * 64, "{}", actor, now))
must_fail(insert_op, (category, owner, "a" * 64, "{}", actor, now))
must_fail("UPDATE operations SET state = 'succeeded'")
db.commit()
# Probar la aserción changes() descrita en ADR 0008: cero filas revierte
# incluso una modificación financiera anterior de la misma secuencia.
try:
    with db:
        db.execute("UPDATE expenses SET description = 'No debe persistir'")
        db.execute("UPDATE expenses SET version = version + 1 WHERE version = 99")
        db.execute("""INSERT INTO audit_entries
            (id, owner_id, operation_id, actor_id, entity_type, entity_id,
             entity_version, action, after_data, recorded_at)
            VALUES (CASE WHEN changes() = 1 THEN ? ELSE NULL END,
                    ?, ?, ?, 'expense', ?, 1, 'created', '{}', ?)""",
            (category, owner, op, actor, expense, now))
except sqlite3.IntegrityError:
    pass
else:
    raise AssertionError("Zero-row precondition did not abort the transaction")
assert db.execute("SELECT description, version FROM expenses").fetchone() == ("Almuerzo", 1)
assert db.execute("SELECT count(*) FROM audit_entries").fetchone()[0] == 0
assert not db.execute("PRAGMA foreign_key_check").fetchall()

for path in ROOT.rglob("*.md"):
    if any(part.startswith(".") for part in path.relative_to(ROOT).parts):
        continue
    for target in re.findall(r"\]\(([^)]+)\)", path.read_text()):
        if "://" not in target and not target.startswith("#"):
            assert (path.parent / target.split("#", 1)[0]).exists(), (path, target)

operations = sum(len(item) for item in api["paths"].values())
print(f"OpenAPI válido: {len(api['paths'])} rutas, {operations} operaciones, {len(api['components']['schemas'])} esquemas y {examples} ejemplos.")
print(f"DDL ejecutado en SQLite {sqlite3.sqlite_version}: {len(tables)} tablas y {len(index_statements)} índices; D1 remoto pendiente.")
print("Importes, fechas, campos de entrada, permisos declarados, paginación, referencias y enlaces comprobados.")
