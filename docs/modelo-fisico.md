# Esquema físico propuesto

Estado: esquema de diseño listo para revisión. El [DDL de tablas](schema/001-tables.sql) y los [índices](schema/002-indexes.sql) están escritos y se analizan localmente, pero no se han ejecutado en una base D1 real.

## Convenciones

Los identificadores son UUID aleatorios generados por la aplicación. Las tablas financieras incluyen `owner_id`; las referencias compuestas deben pertenecer al mismo propietario. La autenticación resuelve el propietario y no permite elegir otro desde el cuerpo de una solicitud.

En D1 se guardan unidades menores como `TEXT` canónico sin signo ni ceros iniciales (salvo `"0"` para el acumulado). El rango individual sigue siendo `0.01` a `92233720368547758.07` en la API. Los CHECK verifican el viaje de ida y vuelta a INTEGER de 64 bits. La aplicación convierte cadenas con BigInt, nunca con Number. Esto evita pérdida de precisión en bindings y exports de D1.

Para comparaciones individuales se usa `CAST(... AS INTEGER)`. Una suma solo se hace después de comprobar que no desborda: una devolución debe ser menor o igual que importe menos acumulado. Guardar el resultado de nuevo como TEXT. No usar `SUM()` de enteros de 64 bits ni `REAL` para informes: leer importes como cadenas por páginas y sumar con BigInt. No usar `ORDER BY` textual para ordenar importes. Los totales pueden superar el rango de un registro. Las versiones INTEGER se limitan a `9007199254740991` para transportarlas exactamente; al llegar al máximo se rechaza el cambio, sin reiniciarlas.

Los UUID se guardan como TEXT canónico en minúsculas, con guiones, generado y validado por la aplicación. Las fechas financieras son TEXT `YYYY-MM-DD`; los instantes UTC son TEXT de longitud fija `YYYY-MM-DDTHH:mm:ss.sssZ`. Los booleanos son INTEGER 0 o 1; el JSON es TEXT con `json_valid`. Las tablas STRICT, NOT NULL, CHECK, claves únicas y referencias compuestas conservan las restricciones. D1 mantiene las claves foráneas activas; SQLite local debe usar `PRAGMA foreign_keys = ON`. La aplicación valida también calendario, UUID y límites de cuerpos.

En la API, `amount_minor` se convierte a `amount`, `refunded_minor` a `refunded_amount` y `created_at` a `recorded_at`. Las versiones se serializan como cadenas de dígitos para no depender de la precisión numérica de JSON. El cliente devuelve el `ETag` completo, no calcula por su cuenta la siguiente versión.

## Tablas del primer recorrido

`owners` conserva `id`, `default_currency`, `timezone` y `created_at`. La instancia inicial tiene un propietario, con PEN y `America/Lima` como preferencias.

`principals` conserva `id`, `owner_id`, `kind`, `label` y `created_at`. Identifica al actor estable, ya sea propietario o agente; cambiar una credencial no cambia la autoría histórica.

`agent_credentials` conserva `id`, `owner_id`, `principal_id`, `secret_verifier`, `permission`, `created_at` y `revoked_at`. Los permisos distinguen lectura de lectura y escritura. La identidad administrativa no se deriva de una credencial financiera de agente. Los verificadores de secretos no forman parte de la exportación portátil de datos financieros.

`categories` conserva `id`, `owner_id`, `name`, `name_key`, `active`, `version`, `created_at` y `updated_at`. La pareja `owner_id` y `name_key` es única, incluidas las categorías desactivadas. `name` conserva la presentación; `name_key` aplica la comparación acordada.

`expenses` conserva `id`, `owner_id`, `amount_minor`, `currency`, `occurred_on`, `description`, `category_id`, `refunded_minor`, `version`, `created_at`, `updated_at` y `deleted_at`. La categoría es opcional. `refunded_minor` representa la suma de devoluciones no eliminadas individualmente, aunque la compra esté eliminada; sirve para validar el límite al recuperarla o modificarla.

`operations` conserva `id`, `owner_id`, `idempotency_key`, `request_fingerprint`, `method`, `path`, `resolved_input`, `actor_id`, `state`, `response_status`, `response_headers`, `response_body`, `created_at` y `completed_at`. La pareja `owner_id` y `idempotency_key` es única. La huella identifica método, destino, cuerpo y precondiciones; no incluye credenciales ni depende del orden de las claves JSON. El resultado confirmado no vence automáticamente.

Una reserva `pending` conserva la fecha y los datos resueltos sin crear todavía un gasto. El resultado `succeeded` confirma cambios e historial en la misma transacción; `rejected` conserva un rechazo de negocio sin cambios financieros. Los rechazos anteriores a la reserva y los fallos técnicos transitorios no se presentan como resultados financieros confirmados.

`audit_entries` conserva `id`, `owner_id`, `operation_id`, `actor_id`, `entity_type`, `entity_id`, `entity_version`, `action`, `before_data`, `after_data` y `recorded_at`. Las representaciones anteriores y posteriores contienen datos financieros y metadatos del cambio, nunca secretos de autenticación.

## Tablas para completar la versión

`refunds` conserva `id`, `owner_id`, `expense_id`, `amount_minor`, `currency`, `received_on`, `description`, `version`, `created_at`, `updated_at` y `deleted_at`. La moneda se captura desde la compra al registrar la devolución y es de solo lectura. No se reinterpreta una devolución eliminada si después se corrige la moneda de la compra. Crear, modificar o recuperar una devolución efectiva comprueba su coincidencia con la moneda vigente del gasto; corregir el gasto comprueba a su vez las devoluciones no eliminadas.

`classification_runs` conserva identidad, propietario, actor, fechas, estado y resultado del trabajo de clasificación solicitado. `classification_batches` conserva la ejecución a la que pertenece cada lote, su operación identificable y su resultado. Los límites por lote se concretarán contando también historial y nuevas categorías.

## Restricciones e índices

Las restricciones comprobables dentro de una fila incluyen moneda admitida, versiones positivas, límites del importe y que `refunded_minor` permanezca entre cero y el importe de la compra. Las referencias a categorías, compras, credenciales y operaciones no deben cruzar propietarios.

La suma de devoluciones requiere una transacción: se modifica también la compra para que las operaciones concurrentes detecten el conflicto. Las precondiciones SQL y su comprobación forman parte del mismo batch; véase ADR 0008.

Se prevén índices para listar gastos activos por `owner_id`, `occurred_on` e `id`, y por categoría cuando corresponda; consultar devoluciones por compra y fecha; y recuperar historial por entidad y operación. La lectura por fechas usa un orden total, con el identificador como desempate.

El diseño no exige indexar JSON de auditoría ni almacenar totales permanentes de informes. Los resúmenes agregan gastos y devoluciones vigentes por separado y calculan el neto por moneda.

Las claves primarias y restricciones están definidas en el DDL. Los índices adicionales se crean sincrónicamente mediante migraciones D1. Su utilidad y el costo de escritura se comprobarán con las consultas reales, sin asumir mejoras de rendimiento no medidas.

La [guía del esquema](schema/README.md) explica qué invariantes dependen de la transacción y cómo reproducir la validación. Las restricciones SQL no comprueban por sí solas permisos, normalización, suma entre varias devoluciones o estado activo de una categoría.

## Casos que debe comprobar la implementación

- Dos devoluciones simultáneas no superan juntas el importe de la compra.
- Dos creaciones de categorías equivalentes no producen nombres duplicados.
- Un reintento tras perder la respuesta devuelve el resultado original, incluso si el registro cambió después.
- Una recuperación no revive una devolución eliminada individualmente ni elude el límite del gasto corregido.
- Un resumen no multiplica gastos al incluir varias devoluciones de una misma compra.

Fuentes consultadas el 28 de octubre de 2026: [tipos y conversión en D1](https://developers.cloudflare.com/d1/worker-api/), [export y precisión numérica](https://developers.cloudflare.com/d1/best-practices/import-export-data/) y [batch](https://developers.cloudflare.com/d1/worker-api/d1-database/).
