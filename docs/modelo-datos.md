# Modelo de datos de Gachia

Estado: modelo de diseño listo para revisión. Las entidades y reglas están expresadas en un [esquema físico](modelo-fisico.md) y un [DDL](schema/001-tables.sql) que todavía no se han ejecutado en D1.

## Entidades financieras

Un gasto tiene identificador estable, importe, moneda, fecha del gasto, descripción y una categoría opcional. Conserva su fecha de registro, modificaciones, versión y eliminación recuperable. Un gasto pertenece al usuario de la instancia.

Una categoría tiene identificador estable, nombre y estado activo o desactivado. Renombrarla conserva su identidad y asignaciones. Desactivarla impide nuevas asignaciones y conserva las anteriores.

Se conserva un nombre de presentación y una clave de comparación que ignora diferencias de mayúsculas y espacios sobrantes. La unicidad debe comprobarse para el usuario, incluidas las escrituras concurrentes.

Una devolución pertenece a una compra existente, tiene importe y fecha de recepción, y utiliza la moneda del gasto original. La suma de devoluciones efectivas no supera el importe de esa compra. Puede corregirse, eliminarse y recuperarse individualmente, manteniendo su historial.

Su moneda se captura de la compra al crearla y no se modifica indirectamente al corregir la compra. Cualquier devolución efectiva debe coincidir con la moneda vigente de su gasto, también al recuperarla.

Los totales por período son resultados de consulta: suman gastos y devoluciones efectivas por sus respectivas fechas y monedas. No son un nuevo hecho financiero que el usuario tenga que registrar.

Las consultas históricas utilizan el estado vigente, incluidas las correcciones posteriores. Se conservan los hechos y sus cambios, pero no una instantánea permanente de cada resumen consultado.

## Identidad y preferencias

La instancia tiene un propietario. Sus preferencias iniciales son PEN y la hora de Lima; esto no implica abrir registro público de usuarios.

Cada credencial de agente tiene identidad, propietario, permisos y estado de revocación. Su representación verificable se mantiene fuera de las respuestas y el historial financiero. El servidor deriva el propietario del acceso autenticado, no de una instrucción del cliente para acceder a otro usuario.

La identidad del actor es estable e independiente de la credencial utilizada. El historial sigue identificando al agente o propietario que inició una operación aunque cambie su forma de acceso.

## Operaciones e historial

Una operación identificable permite reconocer un reintento y recuperar su resultado. Una entrada del historial identifica quién produjo un cambio, cuándo ocurrió y a qué operación y registro pertenece.

Las operaciones conservan su clave, la identidad de la solicitud y el resultado original sin vencimiento automático. La comparación debe distinguir la solicitud original con valores omitidos de los valores predeterminados resueltos al registrarla. La misma clave no puede representar una compra nueva ni un cambio de instrucción.

Las ejecuciones de clasificación agrupan el trabajo solicitado al agente. Cada lote guarda conjuntamente las categorías nuevas, las asignaciones, sus cambios de historial y el resultado de la operación.

Estas entidades de seguimiento no sustituyen a los gastos y devoluciones. La propuesta guarda el estado vigente y su historial dentro de la misma transacción, sin exigir reconstruir todas las consultas desde una secuencia de eventos.

## Representación física propuesta

En D1 se guardan unidades menores como `TEXT` canónico sin signo ni ceros iniciales (salvo `"0"` para el acumulado). El rango individual sigue siendo `0.01` a `92233720368547758.07` en la API. Los CHECK verifican el viaje de ida y vuelta a INTEGER de 64 bits. La aplicación convierte cadenas con BigInt, nunca con Number. Esto evita pérdida de precisión en bindings y exports de D1.

Para comparaciones individuales se usa `CAST(... AS INTEGER)`. Una suma solo se hace después de comprobar que no desborda: una devolución debe ser menor o igual que importe menos acumulado. Guardar el resultado de nuevo como TEXT. No usar `SUM()` de enteros de 64 bits ni `REAL` para informes: leer importes como cadenas por páginas y sumar con BigInt. No usar `ORDER BY` textual para ordenar importes. Los totales pueden superar el rango de un registro. Las versiones INTEGER se limitan a `9007199254740991` para transportarlas exactamente; al llegar al máximo se rechaza el cambio, sin reiniciarlas.

Los UUID se guardan como TEXT canónico en minúsculas, con guiones, generado y validado por la aplicación. Las fechas financieras son TEXT `YYYY-MM-DD`; los instantes UTC son TEXT de longitud fija `YYYY-MM-DDTHH:mm:ss.sssZ`. Los booleanos son INTEGER 0 o 1; el JSON es TEXT con `json_valid`. Las tablas STRICT, NOT NULL, CHECK, claves únicas y referencias compuestas conservan las restricciones. D1 mantiene las claves foráneas activas; SQLite local debe usar `PRAGMA foreign_keys = ON`. La aplicación valida también calendario, UUID y límites de cuerpos.

La API mantiene las cadenas decimales de dos posiciones del [ADR 0007](adr/0007-importes-decimales-en-la-api.md).

La versión del registro permite detectar cambios simultáneos. Para las devoluciones, el diseño técnico propone actualizar también la compra y su total devuelto en la misma transacción, de modo que dos devoluciones concurrentes no validen ambas contra el mismo importe pendiente sin detectar el conflicto.

## Eliminación y recuperación

Eliminar una compra la excluye de las consultas habituales y los totales, junto con sus devoluciones. Recuperarla vuelve a incluir el conjunto correspondiente. La eliminación no borra su identidad ni su historial.

Cada devolución conserva su propio estado de eliminación. Su inclusión en los totales requiere que tanto ella como su compra estén activas. Eliminar o recuperar la compra no sobrescribe el estado individual de sus devoluciones.

Recuperar o corregir una devolución comprueba de nuevo el límite de la compra: una operación que superaría el importe original no puede aplicarse aunque el registro hubiera sido válido antes de eliminarlo.

## Reglas que deben conservarse

- El gasto tiene una sola moneda y una categoría opcional.
- Las devoluciones conservan referencia al gasto y no cambian su moneda.
- El gasto en cuotas conserva el importe completo en la fecha de compra.
- Los reintentos no se detectan comparando únicamente los datos financieros.
- Cambios, historial y resultado de una escritura se guardan juntos.
- La clasificación automática no modifica gastos ya clasificados sin una solicitud explícita.
- Los secretos de acceso no forman parte del historial financiero ni de la exportación portátil de gastos.

Fuentes oficiales consultadas el 28 de octubre de 2026: [API de D1](https://developers.cloudflare.com/d1/worker-api/), [batch](https://developers.cloudflare.com/d1/worker-api/d1-database/) y [export y precisión](https://developers.cloudflare.com/d1/best-practices/import-export-data/).

## Especificación y comprobaciones pendientes

El [esquema físico](modelo-fisico.md) y el [contrato OpenAPI del primer recorrido](openapi.yaml) concretan las entidades y su representación pública. Los datos financieros usan fechas y unidades menores exactas como TEXT en D1; la API devuelve fechas de calendario, instantes UTC e importes decimales exactos como cadenas.

El DDL contempla también devoluciones y clasificación para la versión completa. Sus rutas de modificación se formalizarán en ampliaciones posteriores de OpenAPI. La implementación debe ejecutar y comprobar el esquema con D1, además de probar las invariantes que dependen de varias filas.
