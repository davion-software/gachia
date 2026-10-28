# Evaluación de AWS para Gachia

Estado: histórico. Reemplazado por el [ADR 0009](adr/0009-cloudflare-workers-d1-y-void.md) y la [evaluación de Cloudflare](cloudflare.md). Los costos, región y servicios siguientes ya no describen el diseño vigente. La antigua [plantilla de AWS Budgets](../infra/budget.json) se conserva solo como referencia y no se despliega.

Estado: combinación de servicios, región y retención confirmadas por el usuario. La evaluación de costos sigue pendiente de comprobar con una carga representativa. No se han creado recursos ni medido cargas.

## Restricciones

AWS, TypeScript con Node.js y Fastify, operación administrada y presupuesto inicial de hasta US$10 al mes para API, base de datos y respaldos. La suscripción a Grok Bot queda aparte.

## Combinación elegida

- API Gateway HTTP API recibe las solicitudes HTTPS.
- Lambda ejecuta la aplicación Fastify con el adaptador `@fastify/aws-lambda`.
- Aurora DSQL conserva los datos, permite consultas SQL y transacciones para cambios, historial e idempotencia.
- AWS Backup programa las copias diarias del clúster.

La propuesta es una aplicación con almacenamiento persistente externo, aunque Lambda ejecute distintas solicitudes en instancias diferentes. La autenticación del agente pertenece a Gachia; los permisos del servicio para acceder a AWS son una responsabilidad distinta.

Fastify documenta la adaptación a Lambda y API Gateway en su [guía serverless](https://fastify.dev/docs/latest/Guides/Serverless/). La región elegida es `us-east-1`, incluida en las [regiones admitidas por DSQL](https://docs.aws.amazon.com/aurora-dsql/latest/userguide/what-is-aurora-dsql.html#region-availability).

## Motivo de la recomendación

Aurora DSQL ofrece SQL, compatibilidad con PostgreSQL y transacciones ACID, con detección optimista de conflictos. No es idéntico a PostgreSQL convencional: la implementación debe respetar sus límites y reintentar transacciones que aborten por conflicto. Los lotes deben limitarse contando todos los cambios, incluido el historial. Fuentes: [concurrencia](https://docs.aws.amazon.com/aurora-dsql/latest/userguide/working-with-concurrency-control.html) y [límites](https://docs.aws.amazon.com/aurora-dsql/latest/userguide/CHAP_quotas.html).

DSQL permite evaluar una base administrada sin reservar una instancia por hora. Mantener SQL simplifica las consultas por períodos y categorías frente a diseñarlas mediante claves e índices de DynamoDB. Esa simplificación es un criterio de diseño, no una medición de rendimiento o costo.

Las copias DSQL mediante AWS Backup son completas y se restauran a un clúster nuevo. El usuario ha confirmado la retención de 30 copias diarias, eliminando automáticamente las más antiguas. La copia portátil de datos financieros seguirá siendo una exportación lógica con formato propio; no se presupone que `pg_dump` sea compatible. Fuentes: [respaldo DSQL](https://docs.aws.amazon.com/aurora-dsql/latest/userguide/backup-aurora-dsql.html) y [restauración](https://docs.aws.amazon.com/aws-backup/latest/devguide/restore-auroradsql.html).

## Escenario de costos para evaluar

Este escenario es una hipótesis de planificación, no una previsión del uso personal ni una factura estimada completa. Utiliza precios publicados en USD y no descuenta franquicias gratuitas o créditos:

- 100.000 DPUs al mes, a US$8 por millón: US$0,80.
- 1 GB-mes de base, a US$0,33: US$0,33.
- 30 copias completas de 1 GB retenidas de forma estable, a US$0,10 por GB-mes: aproximadamente US$3 al mes en almacenamiento de respaldos.

El subtotal de estos conceptos es US$4,13. Falta añadir solicitudes y duración de Lambda, HTTP API, registros, transferencia, restauraciones y cualquier otro recurso utilizado. Los tamaños y DPUs reales dependen de los datos, consultas, índices y reintentos. La retención de copias completas hace crecer el costo con el tamaño de la base.

Fuentes: [precios de DSQL](https://aws.amazon.com/rds/aurora/dsql/pricing/), [AWS Backup](https://aws.amazon.com/backup/pricing/), [tarifas oficiales de Backup por región](https://b0.p.awsstatic.com/pricing/2.0/meteredUnitMaps/backup/USD/current/backup.json), [Lambda](https://aws.amazon.com/lambda/pricing/) y [API Gateway](https://aws.amazon.com/api-gateway/pricing/).

Antes de considerar viable el presupuesto se debe calcular el costo completo y comprobar con una carga representativa los DPUs, las duraciones, los tamaños de copia y el volumen de registros. Elegir esta propuesta no convierte US$10 en un tope automático de facturación.

## Alternativas consideradas

DynamoDB bajo demanda también ofrece transacciones administradas. Requeriría definir los accesos por claves y los agregados de los informes, además de aplicar sus límites de transacción a lotes, historial y resultados de operación. Sigue siendo una alternativa si la evaluación de DSQL no cumple el presupuesto. Fuentes: [precios](https://aws.amazon.com/dynamodb/pricing/) y [transacciones](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/transaction-apis.html).

Una base administrada de Lightsail parte de US$15 mensuales y supera por sí sola el presupuesto. Una máquina virtual con base propia cambia la decisión de operación administrada porque exige mantener el servidor. Fuente: [precios de Lightsail](https://aws.amazon.com/lightsail/pricing/).

## Verificación pendiente

- Comprobar consumo, costo completo, generación de respaldos y restauración.
- Completar el contrato, los permisos y la estrategia de exportación y recuperación conforme al diseño técnico.

## Avisos acordados

Se han confirmado avisos de gasto acumulado a US$5, US$8 y US$10 y de previsión de superar US$10, manteniendo el servicio operativo hasta que el propietario decida un ajuste. El usuario configurará estos avisos más adelante; actualmente no están activos ni tienen destinatario definido. La plantilla conservada es histórica. La [guía vigente](avisos-gastos.md) la sustituye por vigilancia de cuotas gratuitas.
