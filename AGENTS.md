# AGENTS.md — Gachia

## Propósito
Servicio personal para registrar y consultar gastos en soles (PEN) y dólares (USD). Grok Bot interpreta y clasifica; Gachia valida, persiste y calcula totales. Hoy el repo es **solo documentación y contrato**: no hay código de aplicación ni recursos desplegados.

## Stack objetivo
- Cloudflare Workers (plan **Free**) + TypeScript + **Hono** (no Fastify).
- **D1** (SQLite) como base de datos; recuperación con D1 Time Travel (7 días).
- **Void** (Vite) para build, despliegue y migraciones D1.
- Presupuesto de infraestructura: **US$0/mes**. No introducir servicios facturables (R2 export desactivado por defecto).
- AWS (ADR 0004/0005, `docs/AWS.md`) está **sustituido** por el ADR 0009; consérvalo solo como histórico.

## Estructura
- `README.md` — visión general y enlaces.
- `GLOSSARY.md` — términos del dominio; úsalos tal cual.
- `docs/PRODUCT.md`, `docs/ACCEPTANCE_CRITERIA.md` — acuerdos funcionales.
- `docs/TECHNICAL_DESIGN.md`, `docs/CLOUDFLARE.md` — diseño técnico y límites del plan Free.
- `docs/API.md`, `docs/openapi.yaml` — contrato HTTPS.
- `docs/DATA_MODEL.md`, `docs/PHYSICAL_MODEL.md`, `docs/schema/` — modelo y SQL para D1.
- `docs/EXPENSE_NOTIFICATIONS.md` — vigilancia de cuotas del plan gratis.
- `docs/adr/NNNN_TITLE.md` — decisiones (0001–0009).
- `infra/budget.json`, `scripts/validate-contract.py` — presupuesto y validación del contrato.

## Convenciones
- Documentación en **español**; nombres de archivo en **inglés UPPER_SNAKE_CASE** (`README.md`, `AGENTS.md`, `GLOSSARY.md` se mantienen).
- Nueva decisión → nuevo ADR numerado; no reescribas ADRs aceptados, márcalos como sustituidos.
- Importes como decimales en string en la API (ADR 0007); operaciones idempotentes (ADR 0008); gastos por fecha de compra (ADR 0001).
- La IA vive en el agente, no en el servicio (ADR 0002).
- Al renombrar o mover docs, actualiza todos los enlaces y verifica que no queden rotos.
- Nunca incluyas secretos ni tokens en el repo.

## Comandos
```bash
pip install -r scripts/contract-requirements.txt
python3 scripts/validate-contract.py   # valida OpenAPI, ejemplos y límites
```
