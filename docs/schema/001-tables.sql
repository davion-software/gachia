-- Contrato de diseño, no migración aplicada.
-- D1/SQLite: ejecutar como migraciones revisadas de Void.
-- Identificadores UUID e instantes UTC se proporcionan desde la aplicación.

CREATE TABLE owners (
	id TEXT PRIMARY KEY NOT NULL,
	default_currency TEXT NOT NULL CHECK (default_currency IN ('PEN', 'USD')),
	timezone TEXT NOT NULL CHECK (timezone = 'America/Lima'),
	created_at TEXT NOT NULL,
	CHECK (id IS NULL OR (length(id) = 36 AND substr(id, 9, 1) = '-' AND substr(id, 14, 1) = '-' AND substr(id, 19, 1) = '-' AND substr(id, 24, 1) = '-' AND length(replace(id, '-', '')) = 32 AND replace(id, '-', '') NOT GLOB '*[^0-9a-f]*')),
	CHECK (created_at IS NULL OR (length(created_at) = 24 AND created_at GLOB '????-??-??T??:??:??.???Z' AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at, '+0 days') IS NOT NULL AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at, '+0 days') = created_at))
) STRICT;

CREATE TABLE principals (
	id TEXT PRIMARY KEY NOT NULL,
	owner_id TEXT NOT NULL REFERENCES owners (id),
	kind TEXT NOT NULL CHECK (kind IN ('owner', 'agent')),
	label TEXT NOT NULL CHECK (length(label) BETWEEN 1 AND 80),
	created_at TEXT NOT NULL,
	UNIQUE (owner_id, id),
	CHECK (id IS NULL OR (length(id) = 36 AND substr(id, 9, 1) = '-' AND substr(id, 14, 1) = '-' AND substr(id, 19, 1) = '-' AND substr(id, 24, 1) = '-' AND length(replace(id, '-', '')) = 32 AND replace(id, '-', '') NOT GLOB '*[^0-9a-f]*')),
	CHECK (owner_id IS NULL OR (length(owner_id) = 36 AND substr(owner_id, 9, 1) = '-' AND substr(owner_id, 14, 1) = '-' AND substr(owner_id, 19, 1) = '-' AND substr(owner_id, 24, 1) = '-' AND length(replace(owner_id, '-', '')) = 32 AND replace(owner_id, '-', '') NOT GLOB '*[^0-9a-f]*')),
	CHECK (created_at IS NULL OR (length(created_at) = 24 AND created_at GLOB '????-??-??T??:??:??.???Z' AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at, '+0 days') IS NOT NULL AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at, '+0 days') = created_at))
) STRICT;

CREATE TABLE agent_credentials (
	id TEXT PRIMARY KEY NOT NULL,
	owner_id TEXT NOT NULL REFERENCES owners (id),
	principal_id TEXT NOT NULL,
	secret_verifier TEXT NOT NULL,
	permission TEXT NOT NULL CHECK (permission IN ('read', 'write')),
	created_at TEXT NOT NULL,
	revoked_at TEXT,
	FOREIGN KEY (owner_id, principal_id) REFERENCES principals (owner_id, id),
	CHECK (revoked_at IS NULL OR revoked_at >= created_at),
	CHECK (id IS NULL OR (length(id) = 36 AND substr(id, 9, 1) = '-' AND substr(id, 14, 1) = '-' AND substr(id, 19, 1) = '-' AND substr(id, 24, 1) = '-' AND length(replace(id, '-', '')) = 32 AND replace(id, '-', '') NOT GLOB '*[^0-9a-f]*')),
	CHECK (owner_id IS NULL OR (length(owner_id) = 36 AND substr(owner_id, 9, 1) = '-' AND substr(owner_id, 14, 1) = '-' AND substr(owner_id, 19, 1) = '-' AND substr(owner_id, 24, 1) = '-' AND length(replace(owner_id, '-', '')) = 32 AND replace(owner_id, '-', '') NOT GLOB '*[^0-9a-f]*')),
	CHECK (principal_id IS NULL OR (length(principal_id) = 36 AND substr(principal_id, 9, 1) = '-' AND substr(principal_id, 14, 1) = '-' AND substr(principal_id, 19, 1) = '-' AND substr(principal_id, 24, 1) = '-' AND length(replace(principal_id, '-', '')) = 32 AND replace(principal_id, '-', '') NOT GLOB '*[^0-9a-f]*')),
	CHECK (created_at IS NULL OR (length(created_at) = 24 AND created_at GLOB '????-??-??T??:??:??.???Z' AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at, '+0 days') IS NOT NULL AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at, '+0 days') = created_at)),
	CHECK (revoked_at IS NULL OR (length(revoked_at) = 24 AND revoked_at GLOB '????-??-??T??:??:??.???Z' AND strftime('%Y-%m-%dT%H:%M:%fZ', revoked_at, '+0 days') IS NOT NULL AND strftime('%Y-%m-%dT%H:%M:%fZ', revoked_at, '+0 days') = revoked_at))
) STRICT;

CREATE TABLE categories (
	id TEXT PRIMARY KEY NOT NULL,
	owner_id TEXT NOT NULL REFERENCES owners (id),
	name TEXT NOT NULL CHECK (length(name) BETWEEN 1 AND 80),
	name_key TEXT NOT NULL CHECK (length(name_key) BETWEEN 1 AND 320),
	active INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0, 1)),
	version INTEGER NOT NULL DEFAULT 1 CHECK (version BETWEEN 1 AND 9007199254740991),
	created_at TEXT NOT NULL,
	updated_at TEXT NOT NULL,
	UNIQUE (owner_id, id),
	UNIQUE (owner_id, name_key),
	CHECK (updated_at >= created_at),
	CHECK (id IS NULL OR (length(id) = 36 AND substr(id, 9, 1) = '-' AND substr(id, 14, 1) = '-' AND substr(id, 19, 1) = '-' AND substr(id, 24, 1) = '-' AND length(replace(id, '-', '')) = 32 AND replace(id, '-', '') NOT GLOB '*[^0-9a-f]*')),
	CHECK (owner_id IS NULL OR (length(owner_id) = 36 AND substr(owner_id, 9, 1) = '-' AND substr(owner_id, 14, 1) = '-' AND substr(owner_id, 19, 1) = '-' AND substr(owner_id, 24, 1) = '-' AND length(replace(owner_id, '-', '')) = 32 AND replace(owner_id, '-', '') NOT GLOB '*[^0-9a-f]*')),
	CHECK (created_at IS NULL OR (length(created_at) = 24 AND created_at GLOB '????-??-??T??:??:??.???Z' AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at, '+0 days') IS NOT NULL AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at, '+0 days') = created_at)),
	CHECK (updated_at IS NULL OR (length(updated_at) = 24 AND updated_at GLOB '????-??-??T??:??:??.???Z' AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at, '+0 days') IS NOT NULL AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at, '+0 days') = updated_at))
) STRICT;

CREATE TABLE expenses (
	id TEXT PRIMARY KEY NOT NULL,
	owner_id TEXT NOT NULL REFERENCES owners (id),
	amount_minor TEXT NOT NULL CHECK (CAST(amount_minor AS INTEGER) > 0 AND amount_minor = CAST(CAST(amount_minor AS INTEGER) AS TEXT)),
	currency TEXT NOT NULL CHECK (currency IN ('PEN', 'USD')),
	occurred_on TEXT NOT NULL,
	description TEXT NOT NULL CHECK (length(description) BETWEEN 1 AND 1000),
	category_id TEXT,
	refunded_minor TEXT NOT NULL DEFAULT '0' CHECK (CAST(refunded_minor AS INTEGER) >= 0 AND refunded_minor = CAST(CAST(refunded_minor AS INTEGER) AS TEXT)),
	version INTEGER NOT NULL DEFAULT 1 CHECK (version BETWEEN 1 AND 9007199254740991),
	created_at TEXT NOT NULL,
	updated_at TEXT NOT NULL,
	deleted_at TEXT,
	UNIQUE (owner_id, id),
	FOREIGN KEY (owner_id, category_id) REFERENCES categories (owner_id, id),
	CHECK (CAST(refunded_minor AS INTEGER) <= CAST(amount_minor AS INTEGER)),
	CHECK (updated_at >= created_at),
	CHECK (deleted_at IS NULL OR deleted_at >= created_at),
	CHECK (id IS NULL OR (length(id) = 36 AND substr(id, 9, 1) = '-' AND substr(id, 14, 1) = '-' AND substr(id, 19, 1) = '-' AND substr(id, 24, 1) = '-' AND length(replace(id, '-', '')) = 32 AND replace(id, '-', '') NOT GLOB '*[^0-9a-f]*')),
	CHECK (owner_id IS NULL OR (length(owner_id) = 36 AND substr(owner_id, 9, 1) = '-' AND substr(owner_id, 14, 1) = '-' AND substr(owner_id, 19, 1) = '-' AND substr(owner_id, 24, 1) = '-' AND length(replace(owner_id, '-', '')) = 32 AND replace(owner_id, '-', '') NOT GLOB '*[^0-9a-f]*')),
	CHECK (length(occurred_on) = 10 AND occurred_on GLOB '????-??-??' AND date(occurred_on, '+0 days') IS NOT NULL AND date(occurred_on, '+0 days') = occurred_on),
	CHECK (category_id IS NULL OR (length(category_id) = 36 AND substr(category_id, 9, 1) = '-' AND substr(category_id, 14, 1) = '-' AND substr(category_id, 19, 1) = '-' AND substr(category_id, 24, 1) = '-' AND length(replace(category_id, '-', '')) = 32 AND replace(category_id, '-', '') NOT GLOB '*[^0-9a-f]*')),
	CHECK (created_at IS NULL OR (length(created_at) = 24 AND created_at GLOB '????-??-??T??:??:??.???Z' AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at, '+0 days') IS NOT NULL AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at, '+0 days') = created_at)),
	CHECK (updated_at IS NULL OR (length(updated_at) = 24 AND updated_at GLOB '????-??-??T??:??:??.???Z' AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at, '+0 days') IS NOT NULL AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at, '+0 days') = updated_at)),
	CHECK (deleted_at IS NULL OR (length(deleted_at) = 24 AND deleted_at GLOB '????-??-??T??:??:??.???Z' AND strftime('%Y-%m-%dT%H:%M:%fZ', deleted_at, '+0 days') IS NOT NULL AND strftime('%Y-%m-%dT%H:%M:%fZ', deleted_at, '+0 days') = deleted_at))
) STRICT;

CREATE TABLE refunds (
	id TEXT PRIMARY KEY NOT NULL,
	owner_id TEXT NOT NULL REFERENCES owners (id),
	expense_id TEXT NOT NULL,
	amount_minor TEXT NOT NULL CHECK (CAST(amount_minor AS INTEGER) > 0 AND amount_minor = CAST(CAST(amount_minor AS INTEGER) AS TEXT)),
	currency TEXT NOT NULL CHECK (currency IN ('PEN', 'USD')),
	received_on TEXT NOT NULL,
	description TEXT NOT NULL CHECK (length(description) BETWEEN 1 AND 1000),
	version INTEGER NOT NULL DEFAULT 1 CHECK (version BETWEEN 1 AND 9007199254740991),
	created_at TEXT NOT NULL,
	updated_at TEXT NOT NULL,
	deleted_at TEXT,
	UNIQUE (owner_id, id),
	FOREIGN KEY (owner_id, expense_id) REFERENCES expenses (owner_id, id),
	CHECK (updated_at >= created_at),
	CHECK (deleted_at IS NULL OR deleted_at >= created_at),
	CHECK (id IS NULL OR (length(id) = 36 AND substr(id, 9, 1) = '-' AND substr(id, 14, 1) = '-' AND substr(id, 19, 1) = '-' AND substr(id, 24, 1) = '-' AND length(replace(id, '-', '')) = 32 AND replace(id, '-', '') NOT GLOB '*[^0-9a-f]*')),
	CHECK (owner_id IS NULL OR (length(owner_id) = 36 AND substr(owner_id, 9, 1) = '-' AND substr(owner_id, 14, 1) = '-' AND substr(owner_id, 19, 1) = '-' AND substr(owner_id, 24, 1) = '-' AND length(replace(owner_id, '-', '')) = 32 AND replace(owner_id, '-', '') NOT GLOB '*[^0-9a-f]*')),
	CHECK (expense_id IS NULL OR (length(expense_id) = 36 AND substr(expense_id, 9, 1) = '-' AND substr(expense_id, 14, 1) = '-' AND substr(expense_id, 19, 1) = '-' AND substr(expense_id, 24, 1) = '-' AND length(replace(expense_id, '-', '')) = 32 AND replace(expense_id, '-', '') NOT GLOB '*[^0-9a-f]*')),
	CHECK (length(received_on) = 10 AND received_on GLOB '????-??-??' AND date(received_on, '+0 days') IS NOT NULL AND date(received_on, '+0 days') = received_on),
	CHECK (created_at IS NULL OR (length(created_at) = 24 AND created_at GLOB '????-??-??T??:??:??.???Z' AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at, '+0 days') IS NOT NULL AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at, '+0 days') = created_at)),
	CHECK (updated_at IS NULL OR (length(updated_at) = 24 AND updated_at GLOB '????-??-??T??:??:??.???Z' AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at, '+0 days') IS NOT NULL AND strftime('%Y-%m-%dT%H:%M:%fZ', updated_at, '+0 days') = updated_at)),
	CHECK (deleted_at IS NULL OR (length(deleted_at) = 24 AND deleted_at GLOB '????-??-??T??:??:??.???Z' AND strftime('%Y-%m-%dT%H:%M:%fZ', deleted_at, '+0 days') IS NOT NULL AND strftime('%Y-%m-%dT%H:%M:%fZ', deleted_at, '+0 days') = deleted_at))
) STRICT;

CREATE TABLE operations (
	id TEXT PRIMARY KEY NOT NULL,
	owner_id TEXT NOT NULL REFERENCES owners (id),
	idempotency_key TEXT NOT NULL CHECK (length(idempotency_key) BETWEEN 1 AND 128),
	request_fingerprint TEXT NOT NULL CHECK (length(request_fingerprint) = 64),
	method TEXT NOT NULL CHECK (method IN ('POST', 'PATCH', 'DELETE')),
	path TEXT NOT NULL,
	resolved_input TEXT NOT NULL,
	actor_id TEXT NOT NULL,
	state TEXT NOT NULL CHECK (state IN ('pending', 'succeeded', 'rejected')),
	response_status INTEGER,
	response_headers TEXT,
	response_body TEXT,
	created_at TEXT NOT NULL,
	completed_at TEXT,
	UNIQUE (owner_id, id),
	UNIQUE (owner_id, idempotency_key),
	FOREIGN KEY (owner_id, actor_id) REFERENCES principals (owner_id, id),
	CHECK (
		(state = 'pending' AND response_status IS NULL AND completed_at IS NULL
			AND response_headers IS NULL AND response_body IS NULL)
		OR (state = 'succeeded' AND response_status IS NOT NULL AND response_status BETWEEN 200 AND 299
			AND completed_at IS NOT NULL AND response_headers IS NOT NULL)
		OR (state = 'rejected' AND response_status IS NOT NULL AND response_status BETWEEN 400 AND 499
			AND completed_at IS NOT NULL AND response_headers IS NOT NULL
			AND response_body IS NOT NULL)
	),
	CHECK (completed_at IS NULL OR completed_at >= created_at),
	CHECK (id IS NULL OR (length(id) = 36 AND substr(id, 9, 1) = '-' AND substr(id, 14, 1) = '-' AND substr(id, 19, 1) = '-' AND substr(id, 24, 1) = '-' AND length(replace(id, '-', '')) = 32 AND replace(id, '-', '') NOT GLOB '*[^0-9a-f]*')),
	CHECK (owner_id IS NULL OR (length(owner_id) = 36 AND substr(owner_id, 9, 1) = '-' AND substr(owner_id, 14, 1) = '-' AND substr(owner_id, 19, 1) = '-' AND substr(owner_id, 24, 1) = '-' AND length(replace(owner_id, '-', '')) = 32 AND replace(owner_id, '-', '') NOT GLOB '*[^0-9a-f]*')),
	CHECK (resolved_input IS NULL OR json_valid(resolved_input)),
	CHECK (actor_id IS NULL OR (length(actor_id) = 36 AND substr(actor_id, 9, 1) = '-' AND substr(actor_id, 14, 1) = '-' AND substr(actor_id, 19, 1) = '-' AND substr(actor_id, 24, 1) = '-' AND length(replace(actor_id, '-', '')) = 32 AND replace(actor_id, '-', '') NOT GLOB '*[^0-9a-f]*')),
	CHECK (response_headers IS NULL OR json_valid(response_headers)),
	CHECK (response_body IS NULL OR json_valid(response_body)),
	CHECK (created_at IS NULL OR (length(created_at) = 24 AND created_at GLOB '????-??-??T??:??:??.???Z' AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at, '+0 days') IS NOT NULL AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at, '+0 days') = created_at)),
	CHECK (completed_at IS NULL OR (length(completed_at) = 24 AND completed_at GLOB '????-??-??T??:??:??.???Z' AND strftime('%Y-%m-%dT%H:%M:%fZ', completed_at, '+0 days') IS NOT NULL AND strftime('%Y-%m-%dT%H:%M:%fZ', completed_at, '+0 days') = completed_at))
) STRICT;

CREATE TABLE audit_entries (
	id TEXT PRIMARY KEY NOT NULL,
	owner_id TEXT NOT NULL REFERENCES owners (id),
	operation_id TEXT NOT NULL,
	actor_id TEXT NOT NULL,
	entity_type TEXT NOT NULL CHECK (entity_type IN ('expense', 'refund', 'category', 'classification_run', 'classification_batch')),
	entity_id TEXT NOT NULL,
	entity_version INTEGER NOT NULL CHECK (entity_version BETWEEN 1 AND 9007199254740991),
	action TEXT NOT NULL CHECK (length(action) BETWEEN 1 AND 80),
	before_data TEXT,
	after_data TEXT,
	recorded_at TEXT NOT NULL,
	FOREIGN KEY (owner_id, operation_id) REFERENCES operations (owner_id, id),
	FOREIGN KEY (owner_id, actor_id) REFERENCES principals (owner_id, id),
	UNIQUE (owner_id, entity_type, entity_id, entity_version),
	CHECK (before_data IS NOT NULL OR after_data IS NOT NULL),
	CHECK (id IS NULL OR (length(id) = 36 AND substr(id, 9, 1) = '-' AND substr(id, 14, 1) = '-' AND substr(id, 19, 1) = '-' AND substr(id, 24, 1) = '-' AND length(replace(id, '-', '')) = 32 AND replace(id, '-', '') NOT GLOB '*[^0-9a-f]*')),
	CHECK (owner_id IS NULL OR (length(owner_id) = 36 AND substr(owner_id, 9, 1) = '-' AND substr(owner_id, 14, 1) = '-' AND substr(owner_id, 19, 1) = '-' AND substr(owner_id, 24, 1) = '-' AND length(replace(owner_id, '-', '')) = 32 AND replace(owner_id, '-', '') NOT GLOB '*[^0-9a-f]*')),
	CHECK (operation_id IS NULL OR (length(operation_id) = 36 AND substr(operation_id, 9, 1) = '-' AND substr(operation_id, 14, 1) = '-' AND substr(operation_id, 19, 1) = '-' AND substr(operation_id, 24, 1) = '-' AND length(replace(operation_id, '-', '')) = 32 AND replace(operation_id, '-', '') NOT GLOB '*[^0-9a-f]*')),
	CHECK (actor_id IS NULL OR (length(actor_id) = 36 AND substr(actor_id, 9, 1) = '-' AND substr(actor_id, 14, 1) = '-' AND substr(actor_id, 19, 1) = '-' AND substr(actor_id, 24, 1) = '-' AND length(replace(actor_id, '-', '')) = 32 AND replace(actor_id, '-', '') NOT GLOB '*[^0-9a-f]*')),
	CHECK (entity_id IS NULL OR (length(entity_id) = 36 AND substr(entity_id, 9, 1) = '-' AND substr(entity_id, 14, 1) = '-' AND substr(entity_id, 19, 1) = '-' AND substr(entity_id, 24, 1) = '-' AND length(replace(entity_id, '-', '')) = 32 AND replace(entity_id, '-', '') NOT GLOB '*[^0-9a-f]*')),
	CHECK (before_data IS NULL OR json_valid(before_data)),
	CHECK (after_data IS NULL OR json_valid(after_data)),
	CHECK (recorded_at IS NULL OR (length(recorded_at) = 24 AND recorded_at GLOB '????-??-??T??:??:??.???Z' AND strftime('%Y-%m-%dT%H:%M:%fZ', recorded_at, '+0 days') IS NOT NULL AND strftime('%Y-%m-%dT%H:%M:%fZ', recorded_at, '+0 days') = recorded_at))
) STRICT;

CREATE TABLE classification_runs (
	id TEXT PRIMARY KEY NOT NULL,
	owner_id TEXT NOT NULL REFERENCES owners (id),
	actor_id TEXT NOT NULL,
	state TEXT NOT NULL CHECK (state IN ('open', 'completed', 'cancelled')),
	version INTEGER NOT NULL DEFAULT 1 CHECK (version BETWEEN 1 AND 9007199254740991),
	result TEXT,
	created_at TEXT NOT NULL,
	completed_at TEXT,
	UNIQUE (owner_id, id),
	FOREIGN KEY (owner_id, actor_id) REFERENCES principals (owner_id, id),
	CHECK (
		(state = 'open' AND completed_at IS NULL)
		OR (state IN ('completed', 'cancelled') AND completed_at IS NOT NULL)
	),
	CHECK (completed_at IS NULL OR completed_at >= created_at),
	CHECK (id IS NULL OR (length(id) = 36 AND substr(id, 9, 1) = '-' AND substr(id, 14, 1) = '-' AND substr(id, 19, 1) = '-' AND substr(id, 24, 1) = '-' AND length(replace(id, '-', '')) = 32 AND replace(id, '-', '') NOT GLOB '*[^0-9a-f]*')),
	CHECK (owner_id IS NULL OR (length(owner_id) = 36 AND substr(owner_id, 9, 1) = '-' AND substr(owner_id, 14, 1) = '-' AND substr(owner_id, 19, 1) = '-' AND substr(owner_id, 24, 1) = '-' AND length(replace(owner_id, '-', '')) = 32 AND replace(owner_id, '-', '') NOT GLOB '*[^0-9a-f]*')),
	CHECK (actor_id IS NULL OR (length(actor_id) = 36 AND substr(actor_id, 9, 1) = '-' AND substr(actor_id, 14, 1) = '-' AND substr(actor_id, 19, 1) = '-' AND substr(actor_id, 24, 1) = '-' AND length(replace(actor_id, '-', '')) = 32 AND replace(actor_id, '-', '') NOT GLOB '*[^0-9a-f]*')),
	CHECK (result IS NULL OR json_valid(result)),
	CHECK (created_at IS NULL OR (length(created_at) = 24 AND created_at GLOB '????-??-??T??:??:??.???Z' AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at, '+0 days') IS NOT NULL AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at, '+0 days') = created_at)),
	CHECK (completed_at IS NULL OR (length(completed_at) = 24 AND completed_at GLOB '????-??-??T??:??:??.???Z' AND strftime('%Y-%m-%dT%H:%M:%fZ', completed_at, '+0 days') IS NOT NULL AND strftime('%Y-%m-%dT%H:%M:%fZ', completed_at, '+0 days') = completed_at))
) STRICT;

CREATE TABLE classification_batches (
	id TEXT PRIMARY KEY NOT NULL,
	owner_id TEXT NOT NULL REFERENCES owners (id),
	run_id TEXT NOT NULL,
	operation_id TEXT NOT NULL,
	result TEXT NOT NULL,
	created_at TEXT NOT NULL,
	UNIQUE (owner_id, operation_id),
	FOREIGN KEY (owner_id, run_id) REFERENCES classification_runs (owner_id, id),
	FOREIGN KEY (owner_id, operation_id) REFERENCES operations (owner_id, id),
	CHECK (id IS NULL OR (length(id) = 36 AND substr(id, 9, 1) = '-' AND substr(id, 14, 1) = '-' AND substr(id, 19, 1) = '-' AND substr(id, 24, 1) = '-' AND length(replace(id, '-', '')) = 32 AND replace(id, '-', '') NOT GLOB '*[^0-9a-f]*')),
	CHECK (owner_id IS NULL OR (length(owner_id) = 36 AND substr(owner_id, 9, 1) = '-' AND substr(owner_id, 14, 1) = '-' AND substr(owner_id, 19, 1) = '-' AND substr(owner_id, 24, 1) = '-' AND length(replace(owner_id, '-', '')) = 32 AND replace(owner_id, '-', '') NOT GLOB '*[^0-9a-f]*')),
	CHECK (run_id IS NULL OR (length(run_id) = 36 AND substr(run_id, 9, 1) = '-' AND substr(run_id, 14, 1) = '-' AND substr(run_id, 19, 1) = '-' AND substr(run_id, 24, 1) = '-' AND length(replace(run_id, '-', '')) = 32 AND replace(run_id, '-', '') NOT GLOB '*[^0-9a-f]*')),
	CHECK (operation_id IS NULL OR (length(operation_id) = 36 AND substr(operation_id, 9, 1) = '-' AND substr(operation_id, 14, 1) = '-' AND substr(operation_id, 19, 1) = '-' AND substr(operation_id, 24, 1) = '-' AND length(replace(operation_id, '-', '')) = 32 AND replace(operation_id, '-', '') NOT GLOB '*[^0-9a-f]*')),
	CHECK (result IS NULL OR json_valid(result)),
	CHECK (created_at IS NULL OR (length(created_at) = 24 AND created_at GLOB '????-??-??T??:??:??.???Z' AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at, '+0 days') IS NOT NULL AND strftime('%Y-%m-%dT%H:%M:%fZ', created_at, '+0 days') = created_at))
) STRICT;
