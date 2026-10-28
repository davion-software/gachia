# Usar Cloudflare Workers, D1 y Void en el plan gratis

Estado: aceptado por David el 28 de octubre de 2026. Reemplaza [ADR 0004](0004_MANAGED_OPERATION_ON_AWS.md) y [ADR 0005](0005_LAMBDA_AURORA_DSQL_AND_BACKUP.md).

Gachia utiliza Workers Free para la API HTTPS, D1 Free para SQL y Void para construir con Vite, gestionar migraciones y desplegar directamente en la cuenta Cloudflare del propietario. El presupuesto de alojamiento, persistencia y recuperación es US$0 al mes, aparte de Grok Bot. No se activa Workers Paid ni se contratan servicios adicionales para ampliar cuotas.

La API utiliza TypeScript y Hono. Los handlers de Void ya se ejecutan sobre Hono y permiten utilizar su contexto y middleware. Fastify presupone un servidor Node.js y añade una adaptación innecesaria al modelo Fetch de Workers. Node.js queda como herramienta local de construcción, no como servidor de producción.

D1 sustituye los tipos PostgreSQL por SQLite y la transacción interactiva por `D1Database.batch()`. El [ADR 0008](0008_DURABLE_OPERATIONS_AND_IDEMPOTENCY.md) conserva idempotencia, historial y resultado atómicos con precondiciones SQL. El [ADR 0007](0007_DECIMAL_AMOUNTS_IN_THE_API.md) mantiene el contrato decimal exacto.

Time Travel proporciona recuperación durante siete días. El export diario a R2 Standard es opcional y queda desactivado por defecto: su franquicia gratuita admite excesos facturables. Se reduce la retención opcional a siete copias diarias y se comprueba su tamaño real antes de habilitarla. No se promete un tope de facturación de R2.

Se acepta indisponibilidad al agotar las cuotas gratuitas. Las operaciones e historial sin vencimiento aumentan el almacenamiento; los 500 MB por base son un límite real. No se conserva la región AWS: Workers ejecuta en la red de Cloudflare y D1 gestiona la ubicación. La evaluación, alternativas y fuentes oficiales consultadas el 28 de octubre de 2026 están en [Cloudflare](../CLOUDFLARE.md).

Fuentes: [Hono en Void](https://void.cloud/integrations/hono), [despliegue Cloudflare de Void](https://void.cloud/integrations/cloudflare), [límites de D1](https://developers.cloudflare.com/d1/platform/limits/) y [precios de R2](https://developers.cloudflare.com/r2/pricing/).
