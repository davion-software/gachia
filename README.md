# Gachia

Gachia ayuda a ordenar las finanzas personales y a comprender los gastos.

La primera versión es un servicio personal para registrar y consultar gastos en soles y dólares. Grok Bot aporta la interpretación y la clasificación inteligente; Gachia valida las operaciones, conserva los datos y calcula los totales.

La integración inicial utiliza una API HTTPS autenticada y una skill para el agente. La implementación y la prueba con el bot real están pendientes.

El servicio se alojará en Cloudflare Workers Free con TypeScript y Hono. Void construye con Vite y despliega la API y las migraciones de D1 Free. El presupuesto de alojamiento, datos y recuperación es US$0 mensuales, aparte de Grok Bot.

D1 Time Travel permite recuperar los últimos siete días. El export diario a R2 es opcional y permanece desactivado porque sus excesos son facturables. La [evaluación de Cloudflare](docs/cloudflare.md) recoge cuotas, riesgos y fuentes oficiales; el [ADR 0009](docs/adr/0009-cloudflare-workers-d1-y-void.md) sustituye la arquitectura AWS.

La definición funcional y las decisiones del diseño técnico están confirmadas. Consulta los [acuerdos de producto](docs/producto.md), el [glosario](GLOSSARY.md), los [criterios de aceptación](docs/criterios-aceptacion.md), las [decisiones registradas](docs/adr/) y el [diseño técnico](docs/diseno-tecnico.md).

La [vigilancia del plan gratis](docs/avisos-gastos.md) sustituye AWS Budgets. Agotar cuotas puede interrumpir el servicio. Todavía no hay recursos desplegados ni notificaciones comprobadas.

El contrato y el modelo tienen artefactos de diseño revisables: [API](docs/api.md), [OpenAPI del primer recorrido](docs/openapi.yaml), [modelo de datos](docs/modelo-datos.md) y [esquema SQL](docs/schema/README.md). La [validación local](scripts/validate-contract.py) comprueba su estructura, ejemplos y límites; la ejecución real en D1 sigue pendiente.
