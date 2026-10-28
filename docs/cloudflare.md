# Evaluación de Cloudflare y Void

Estado: decisión de diseño confirmada, sin recursos desplegados. Consulta de todas las fuentes: 28 de octubre de 2026. Presupuesto: US$0 al mes para alojamiento, datos y recuperación, aparte de Grok Bot.

## Elección y alcance

Una API TypeScript con Hono se ejecuta en Workers Free y accede a una base D1 Free mediante el binding `DB`. Void construye con Vite y despliega directamente a la cuenta del propietario. Sus handlers utilizan Hono internamente; no hace falta adaptar Fastify ni mantener un servidor Node.js. La IA continúa en el agente. No se habilitan AI, KV, Queues, Durable Objects ni una Void Platform propia.

Void permite generar migraciones con `void db generate` y aplicarlas durante `void deploy --platform cloudflare`. Se versionan y revisan antes del despliegue; no se presupone que el DDL de diseño se aplique automáticamente sin integrarlo en el proyecto. `void project rollback` revierte código, pero no migraciones. `void db restore` requiere un punto de restauración dentro de la ventana de Time Travel. Fijar versiones del CLI y SDK y probar el despliegue completo será parte de la implementación.

Fuentes: [Void](https://void.cloud/), [Hono](https://void.cloud/integrations/hono) y [Cloudflare, migraciones y rollback](https://void.cloud/integrations/cloudflare).

## Cuotas de Workers Free

- 100.000 solicitudes diarias por cuenta, reinicio a medianoche UTC.
- 10 ms de CPU por invocación HTTP o Cron y 128 MB de memoria. Esperar I/O no consume CPU.
- 50 subsolicitudes por invocación; los servicios internos tienen reglas propias. Para D1 se aplica su límite específico de 50 llamadas por invocación.
- Cinco Cron Triggers por cuenta. Una tarea diaria de respaldo también consume recursos del plan.

Al agotar solicitudes se devuelve el error Cloudflare 1027. Una ruta de API financiera debe fallar cerrada: nunca omitir autenticación al fallar el Worker. CPU o memoria excesivas terminan la ejecución. No se cobran excesos de Workers Free ni se amplía el plan automáticamente.

Fuentes: [límites de Workers](https://developers.cloudflare.com/workers/platform/limits/) y [precios de Workers](https://developers.cloudflare.com/workers/platform/pricing/).

## Cuotas de D1 Free

- Diez bases por cuenta, 500 MB por base y 5 GB en total. Los 5 GB no permiten una sola base de ese tamaño.
- 5 millones de filas leídas y 100.000 filas escritas por día, compartidas por cuenta. Los índices también consumen escrituras; historial y operaciones añaden filas por cada acción financiera.
- 50 llamadas a D1 por invocación de Worker. Un `batch()` cuenta como una llamada, no una por sentencia, según los límites actuales.
- Cada sentencia del batch conserva sus límites: 100 parámetros, 100 KB de SQL, fila o valor de hasta 2 MB y consulta de hasta 30 segundos.

D1 ejecuta consultas de una base de forma serial. `batch()` agrupa sentencias preparadas secuenciales en una transacción y revierte todo si alguna falla. No ofrece un callback transaccional con decisiones JavaScript entre sentencias. Un `UPDATE` que afecta cero filas no es un error: la implementación debe comprobar precondiciones dentro del SQL y provocar rollback si esperaba un cambio. Las reglas del [ADR 0008](adr/0008-operaciones-duraderas-e-idempotencia.md) concretan el protocolo.

Las cuotas diarias agotadas hacen fallar consultas hasta medianoche UTC, sin borrar los datos ni cobrar excesos en Free. El almacenamiento lleno impide nuevas inserciones y cambios de esquema; no se resuelve esperando al día siguiente. Optimizar consultas e índices reduce lecturas, pero no elimina el crecimiento del historial.

Fuentes: [límites y batch](https://developers.cloudflare.com/d1/platform/limits/), [precios y cómputo de filas](https://developers.cloudflare.com/d1/platform/pricing/), [API batch](https://developers.cloudflare.com/d1/worker-api/d1-database/) y [FAQ sobre límites](https://developers.cloudflare.com/d1/reference/faq/).

## Recuperación y export diario opcional

Time Travel mantiene una ventana continua de siete días en Free, sin cargo adicional. No equivale a siete archivos ni a las antiguas 30 copias diarias. Permite hasta diez restauraciones por diez minutos y base. Una restauración modifica la base existente; Time Travel no permite clonarla directamente. Registrar el bookmark anterior y detener escrituras antes de restaurar. Para ensayar en otra base, importar un export y comparar registros, historial y totales por moneda.

El export SQL diario a R2 Standard cabe en su franquicia solo si el consumo total de la cuenta permanece por debajo de 10 GB-mes, un millón de operaciones clase A y diez millones clase B al mes. La salida a Internet es gratuita. Infrequent Access no tiene esa franquicia. R2 factura los excesos: no es un servicio con corte gratuito como D1 Free.

Por eso R2 queda desactivado en el diseño de US$0. Como ampliación opcional, retener siete exports diarios, privados, con ciclo de vida de siete días. Antes de habilitarlo, medir el archivo real: siete archivos de 500 MB ocuparían 3,5 GB, pero un dump SQL puede ser mayor que la base. Contar también el nuevo archivo antes de expirar el anterior, multipart, listados, restauraciones y otros buckets. Usar un máximo operativo de 8 GB y márgenes en operaciones, sin presentarlos como un tope contractual de cobro. Detener nuevos exports si no hay margen; no ampliar el plan.

La implementación opcional utilizaría un Cron diario y la API de export asíncrono de D1, con sondeo acotado y transferencia en streaming a R2. No debe cargar el dump completo en 128 MB ni asumir que el trabajo cabe en 10 ms de CPU. Primero probar export, importación y precisión monetaria. Un export en curso bloquea otras solicitudes a la base; programarlo fuera del uso habitual. Si la tarea no cabe en Free, mantener Time Travel y export manual local, sin prometer una copia diaria externa.

La copia completa contiene secretos verificadores de credenciales: acceso exclusivo del propietario. La exportación financiera portátil excluye esos verificadores. Tras una restauración completa, revisar revocaciones y rotar credenciales restauradas. Time Travel y R2 en la misma cuenta no protegen de perder el acceso a ella; conservar exports locales privados cuando sea posible.

Fuentes: [Time Travel](https://developers.cloudflare.com/d1/reference/time-travel/), [import y export](https://developers.cloudflare.com/d1/best-practices/import-export-data/) y [R2 Standard y franquicia gratuita](https://developers.cloudflare.com/r2/pricing/).

## Riesgos y alternativas

Los 10 ms de CPU exigen medir autenticación, validación JSON y cálculo de totales. Los informes completos pueden agotar lecturas aunque devuelvan pocas filas. Limitar clasificación por tamaño, parámetros y trabajo medido, y paginar los listados. No truncar silenciosamente un resumen para ahorrar cuota.

La retención de operaciones sin vencimiento puede llenar los 500 MB. Vigilar crecimiento, reservar espacio para administración y preparar export antes de llegar al límite. Cualquier política de archivo que retire claves de idempotencia necesita una decisión nueva: no se borran automáticamente para ahorrar espacio.

Workers no implica residencia en `us-east-1`. No se promete una región fija ni residencia peruana de los datos. Revisar ubicación de D1 y requisitos de privacidad antes de producción.

Wrangler con Hono y migraciones SQL es la alternativa si Void deja de encajar; mantiene los mismos límites. SQLite local elimina cuotas de proveedor pero requiere un equipo encendido y respaldos propios. Workers Paid o R2 por encima de la franquicia quedan fuera de US$0 y necesitan una nueva decisión. AWS queda como [evaluación histórica](aws.md).
