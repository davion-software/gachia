# Conservar las operaciones y repetir su resultado original

Todas las escrituras utilizan una clave de operación en el ámbito del propietario. La solicitud y su resultado confirmado se conservan sin vencimiento automático, y un reintento devuelve ese resultado original aunque el registro haya cambiado después. Frente a una caché temporal o a devolver el estado vigente, esta decisión permite reconocer reintentos tardíos y distinguir el resultado de una instrucción del estado actual del gasto, a cambio de conservar datos de operación a largo plazo.

Una reserva pendiente conserva los valores predeterminados ya resueltos, sin crear todavía el gasto. La transacción que confirma el cambio financiero guarda también historial y resultado; el protocolo completo está en la [guía del esquema](../schema/README.md).

## Adaptación a D1

Revisión del 28 de octubre de 2026 por el [ADR 0009](0009_CLOUDFLARE_WORKERS_D1_Y_VOID.md). La reserva `pending` sigue siendo una escritura independiente que conserva fecha, UUID y valores resueltos. El batch financiero guarda datos, historial y respuesta terminal juntos. No se utiliza `BEGIN` seguido de consultas desde JavaScript ni se supone que varias llamadas `run()` forman una transacción.

`D1Database.batch()` ejecuta sentencias preparadas secuenciales y revierte la secuencia si una falla. Todas las dependencias leídas previamente se vuelven a comprobar mediante condiciones SQL: estado pendiente, versión, propietario, categoría activa, moneda y capacidad de devolución. La base serializa el batch, pero no protege lecturas anteriores hechas fuera de él.

Un `UPDATE ... WHERE version = ?` con cero filas no lanza error. El diseño exige una aserción SQL inmediatamente después de cada cambio esperado: por ejemplo, insertar en el historial obligatorio mediante un `INSERT ... SELECT` de una sola fila sin FROM, usando `CASE WHEN changes() = 1 THEN ? ELSE NULL END` para su `id NOT NULL`. Debe ser la sentencia inmediatamente siguiente, sin otra escritura intermedia. Si la condición falla, NOT NULL aborta todo el batch. Cada cambio esperado necesita esta protección; comprobar resultados JavaScript después del commit llega tarde. La implementación debe probar este patrón en D1 antes de adoptarlo y no usar `OR IGNORE` para ocultar fallos.

La comprobación final del estado `pending` se hace con un UPDATE condicional y una aserción SQL equivalente antes de finalizar el batch. Una carrera que ya encuentra estado terminal revierte sus cambios y recupera la respuesta confirmada. Ante fallo de precondición, revertir primero todo el batch financiero. Un segundo batch puede guardar `rejected` si la operación sigue pendiente, con la misma protección; si otro ejecutor ya la completó, recuperar ese resultado. Un fallo técnico deja `pending` y permite retomar la operación con la misma clave.

Las devoluciones actualizan también importe acumulado y versión de la compra. Validar capacidad mediante resta antes de sumar para evitar overflow de int64; guardar el acumulado como TEXT. Las categorías nuevas y asignaciones de un lote usan el mismo protocolo atómico. El tamaño del lote se limita por parámetros por sentencia, CPU, tiempo y filas consumidas, contando historial y operaciones. Un batch cuenta como una llamada D1 según sus límites actuales; esto no elimina las cuotas de filas ni los límites individuales de sentencias.

Fuentes consultadas el 28 de octubre de 2026: [batch](https://developers.cloudflare.com/d1/worker-api/d1-database/), [sentencias SQL de D1](https://developers.cloudflare.com/d1/sql-api/sql-statements/) y [límites](https://developers.cloudflare.com/d1/platform/limits/). La comprobación de concurrencia y rollback remotos sigue pendiente.
