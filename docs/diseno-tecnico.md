# Propuesta de diseño técnico

Estado: decisiones funcionales, de arquitectura y de operación confirmadas. Los detalles de implementación descritos aquí orientan la construcción del servicio; todavía no hay funcionalidades implementadas.

## Restricciones confirmadas

- API TypeScript con Hono en Cloudflare Workers Free, desplegada con Void y Vite.
- D1 Free como base SQL administrada, sin servidor Node.js de producción.
- Presupuesto US$0 mensuales para alojamiento, base y recuperación, aparte de Grok Bot.
- Time Travel de siete días. Export diario a R2 Standard opcional, desactivado por defecto por riesgo de cargos.
- Sin región AWS fija. Workers usa la red de Cloudflare y D1 gestiona su ubicación.

El [ADR 0009](adr/0009-cloudflare-workers-d1-y-void.md) reemplaza las decisiones AWS. La [evaluación de Cloudflare](cloudflare.md) registra límites, fuentes consultadas el 28 de octubre de 2026 y alternativas. El servicio acepta indisponibilidad al agotar cuotas gratuitas.

## Carga de trabajo

Gachia recibe solicitudes HTTPS de un usuario y sus agentes autorizados. Las operaciones son registros, consultas y modificaciones de datos financieros. La IA se ejecuta en el agente y entrega instrucciones estructuradas a Gachia.

La clasificación no requiere mantener una llamada de IA abierta en el servidor. El agente consulta los gastos pendientes y las categorías, prepara sus decisiones y envía los cambios para su validación y guardado.

El servicio también necesita exportaciones y recuperación con Time Travel. El respaldo externo diario es opcional, sujeto a las condiciones de R2. No se ha definido una necesidad de conexiones permanentes, colas o servicios separados.

## Estructura del servicio

Se propone una única aplicación desplegable con estos módulos:

- Entrada HTTP: autenticación, validación de solicitudes y respuestas, y contrato de la API.
- Gastos y devoluciones: registro, corrección, eliminación, recuperación y reglas de consistencia.
- Categorías y clasificación: categorías activas, planes del agente y guardado de lotes.
- Consultas: filtros, totales por moneda, distribución y comparaciones de períodos.
- Persistencia e historial: transacciones, control de cambios simultáneos y resultados de operaciones.
- Exportación y respaldos: CSV, copia completa, verificación y restauración.

Son módulos de la misma aplicación, no servicios independientes. Las reglas financieras se concentran en Gachia para que otro agente o la futura app obtengan el mismo resultado.

## Opciones de tecnología

Void construye con Vite, aplica migraciones revisadas y despliega en la cuenta Cloudflare del propietario. Sus handlers ya utilizan Hono. Se elige Hono con TypeScript para utilizar el modelo Fetch, el contexto HTTP y los bindings de Workers. Fastify requiere adaptar un servidor Node.js y no aporta una ventaja para esta ejecución.

D1 ofrece SQLite administrado. Se accede con `c.env.DB` y sentencias preparadas; `batch()` permite guardar cambios, historial y resultado en una transacción. No se utiliza un driver PostgreSQL ni una transacción interactiva con consultas intercaladas con JavaScript. La validación externa y la comprobación de tipos siguen siendo tareas distintas.

Fuentes consultadas el 28 de octubre de 2026: [Hono en Void](https://void.cloud/integrations/hono), [Cloudflare en Void](https://void.cloud/integrations/cloudflare) y [API de D1](https://developers.cloudflare.com/d1/worker-api/d1-database/).

## Dinero y fechas

Se propone representar los importes como enteros de unidades menores, asociados siempre a PEN o USD. Por ejemplo, S/ 20 se representaría como 2000 unidades menores de PEN. Los cálculos no utilizarían números decimales de coma flotante.

La fecha del gasto y la fecha de recepción de una devolución serían fechas de calendario. La hora de Lima determinaría valores como "hoy". La creación y las modificaciones conservarían además su instante de registro en UTC.

Las fechas y monedas predeterminadas se resolverían una vez al iniciar la operación. Un reintento no volvería a interpretar "hoy" si ya cambió el día.

## Guardado y cambios simultáneos

Cada modificación se propone guardar en una transacción junto con su historial y el resultado identificable de la operación. Así, un fallo no dejaría el gasto modificado sin el historial correspondiente.

Un identificador de operación distinguiría un reintento de una compra nueva. Repetir el identificador con el mismo contenido devolvería el resultado existente; reutilizarlo con otro contenido produciría un conflicto.

Una versión del registro permitiría detectar que otro agente lo cambió después de su lectura. Ante ese conflicto, el agente consultaría el estado vigente antes de preparar un cambio nuevo.

Para una devolución, la comprobación del importe pendiente y el guardado tendrían que coordinarse para impedir que dos solicitudes concurrentes superen conjuntamente el importe de la compra.

Con D1 cada devolución actualiza también el total devuelto y la versión de la compra dentro del mismo `batch()`. Las condiciones SQL comprueban versión, moneda, importe disponible y estado. Una lectura previa no autoriza por sí sola la escritura. El [ADR 0008](adr/0008-operaciones-duraderas-e-idempotencia.md) exige rollback si una condición deja cero filas cuando se esperaba una. Reintentar un fallo técnico conserva la misma clave y los valores ya resueltos.

## Clasificación por lotes

El agente propondría categorías nuevas y asignaciones usando referencias claras a los gastos y categorías existentes. Gachia validaría que los gastos siguen sin categoría, que las categorías de destino admiten asignaciones y que los registros no cambiaron desde la lectura del agente.

Cada lote guardaría conjuntamente las categorías nuevas, las asignaciones, el historial y su resultado. Una respuesta perdida se resolvería consultando o reintentando la misma operación, sin volver a aplicar los cambios. Los gastos ambiguos seguirían pendientes y aparecerían en el informe.

## Acceso y contrato para agentes

Cada agente tendrá una credencial revocable, asociada al propietario de la instancia. El servicio guardará una representación verificable de la credencial y evitará incluir secretos en respuestas, historial y registros de diagnóstico.

Las credenciales pueden permitir solo lectura o lectura y escritura. El usuario ha confirmado que los agentes deben poder gestionar sus gastos con permiso de escritura. Ambos tipos de credencial quedan limitados a las operaciones autorizadas por el propietario. Emitir o revocar credenciales y restaurar una copia sobre la instancia de uso real son operaciones administrativas del propietario, fuera de los permisos habituales del agente.

La API tendría una versión explícita y respuestas estructuradas con identificadores de registro, operación y versión. La skill describiría las reglas de moneda y fecha, aclaraciones, reintentos, clasificación y comprobación de resultados.

La API será la interfaz compartida por los agentes y la futura app. La administración inicial se realizará mediante comandos documentados con una identidad administrativa separada, sin añadir una interfaz web de gestión.

## Respaldos y recuperación

Time Travel cubre los últimos siete días en D1 Free. Antes de restaurar, detener escrituras y registrar el bookmark actual para poder deshacer la restauración dentro de su ventana. Time Travel restaura la base existente, no crea una copia separada.

La copia portátil versionada conserva datos financieros, historial y operaciones, excluyendo verificadores de credenciales. Un export completo SQL es administrativo y sensible. Se ensaya su importación en otra base y se comparan registros y totales. R2 Standard queda opcional y desactivado: siete exports diarios solo si tamaño, operaciones y ejecución caben en la franquicia. El [procedimiento y sus riesgos](cloudflare.md) sustituyen la retención anterior.

## Control del presupuesto

El presupuesto es US$0. Workers Free y D1 Free fallan al agotar cuotas y no cobran excesos. Se vigilan solicitudes, CPU, errores, filas y almacenamiento en el dashboard. D1 documenta correo al alcanzar cuotas diarias; no se presupone un aviso anticipado configurable en Free. No hay AWS Budgets ni avisos monetarios a US$5, US$8 o US$10. El [procedimiento de vigilancia](avisos-gastos.md) describe comprobaciones y respuesta al límite.

## Trabajo de implementación y verificación

El [contrato HTTP](api.md), el [OpenAPI del primer recorrido](openapi.yaml), el [modelo de datos](modelo-datos.md) y el [DDL de diseño](schema/001-tables.sql) están preparados para revisión. Los artefactos tienen validación local, pero no se han ejecutado en un Worker o una base D1 real. El alcance y las comprobaciones pendientes están en la [guía del esquema](schema/README.md).

Los comandos administrativos y la infraestructura como código se elaborarán conforme a las decisiones cerradas. El consumo de cuotas y la restauración se comprobarán durante la implementación y verificación.

La secuencia prevista es construir primero un recorrido de registro y consulta con autenticación e historial; después incorporar correcciones, devoluciones, categorías y clasificación por lotes. La exportación, la recuperación y las comprobaciones de concurrencia y cuotas completan los criterios de aceptación de la versión.

La siguiente verificación de compatibilidad sigue siendo registrar y consultar un gasto desde el Grok Bot real del usuario, una vez implementado y alojado el servicio.
