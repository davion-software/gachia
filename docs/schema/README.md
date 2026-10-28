# Esquema SQL de diseño

Estado: esquema ejecutable en SQLite localmente, no aplicado en D1. Las tablas contemplan la versión financiera completa; OpenAPI formaliza primero el recorrido de registro y consulta.

## Archivos

- [001-tables.sql](001-tables.sql) define diez tablas, tipos, claves y restricciones.
- [002-indexes.sql](002-indexes.sql) define nueve índices SQLite sincrónicos propuestos para las consultas y referencias.

`principals` conserva la identidad estable del actor, separada de sus credenciales revocables. Permite atribuir cambios a un agente aunque rote su credencial, y distinguir al propietario administrativo.

En D1 se guardan unidades menores como `TEXT` canónico sin signo ni ceros iniciales (salvo `"0"` para el acumulado). El rango individual sigue siendo `0.01` a `92233720368547758.07` en la API. Los CHECK verifican el viaje de ida y vuelta a INTEGER de 64 bits. La aplicación convierte cadenas con BigInt, nunca con Number. Esto evita pérdida de precisión en bindings y exports de D1.

Para comparaciones individuales se usa `CAST(... AS INTEGER)`. Una suma solo se hace después de comprobar que no desborda: una devolución debe ser menor o igual que importe menos acumulado. Guardar el resultado de nuevo como TEXT. No usar `SUM()` de enteros de 64 bits ni `REAL` para informes: leer importes como cadenas por páginas y sumar con BigInt. No usar `ORDER BY` textual para ordenar importes. Los totales pueden superar el rango de un registro. Las versiones INTEGER se limitan a `9007199254740991` para transportarlas exactamente; al llegar al máximo se rechaza el cambio, sin reiniciarlas.

Los UUID se guardan como TEXT canónico en minúsculas, con guiones, generado y validado por la aplicación. Las fechas financieras son TEXT `YYYY-MM-DD`; los instantes UTC son TEXT de longitud fija `YYYY-MM-DDTHH:mm:ss.sssZ`. Los booleanos son INTEGER 0 o 1; el JSON es TEXT con `json_valid`. Las tablas STRICT, NOT NULL, CHECK, claves únicas y referencias compuestas conservan las restricciones. D1 mantiene las claves foráneas activas; SQLite local debe usar `PRAGMA foreign_keys = ON`. La aplicación valida también calendario, UUID y límites de cuerpos.

## Reglas de la aplicación y la transacción

Las restricciones SQL no sustituyen estas comprobaciones:

- Normalizar nombres con Unicode NFC, quitar espacios exteriores, reducir secuencias de espacios a uno y convertir mayúsculas a minúsculas antes de construir `name_key`. Conservar tildes y el nombre de presentación. La unicidad incluye categorías inactivas; la reactivación debe ser explícita.
- Validar fechas de calendario, cadenas no vacías y la representación decimal exacta. La API no redondea, no acepta coma decimal ni signo en los importes de gastos o devoluciones.
- Comprobar que una categoría de destino está activa al crear o cambiar una asignación. Usar una condición SQL sobre la categoría dentro del batch para detectar una desactivación simultánea; una FK acredita existencia, no el estado activo.
- Registrar la moneda de la devolución desde la compra, como dato de solo lectura. Toda devolución efectiva debe coincidir con la moneda vigente del gasto. No modificar retrospectivamente la moneda guardada de una devolución eliminada.
- Actualizar `expenses.refunded_minor` y la versión de la compra junto con cada alta, corrección, eliminación o recuperación individual de devolución. El importe acumulado incluye devoluciones no eliminadas individualmente, aunque la compra esté eliminada. Cambiar el importe o la moneda del gasto exige comprobar también sus devoluciones.
- Obtener el historial y el resultado de la operación en la misma transacción que confirma el cambio financiero. Las claves de operación e historial no tienen borrado automático en la primera versión.
- No entregar credenciales de base de datos al agente ni tratar una credencial financiera como autorización administrativa. Los comandos de acceso y restauración requieren la identidad del propietario.

## Protocolo de una escritura identificable

1. Autenticar y comprobar permisos, tamaño, cabeceras y esquema de entrada. Una solicitud que no alcanza esta fase no reserva una operación.
2. Buscar la clave en el ámbito del propietario. Comparar la huella de método, ruta, cuerpo JSON canónico y precondiciones. La huella se calcula antes de aplicar valores predeterminados y excluye secretos.
3. Si existe una respuesta terminal y coincide la huella, devolverla. Si cambia la huella, devolver conflicto. Una nueva instrucción utiliza una clave nueva.
4. Para una clave nueva, reservar una operación `pending`, conservando los valores resueltos, la fecha y el identificador del registro previsto. La reserva no crea un gasto ni se presenta como éxito financiero.
5. Retomar una operación pendiente utilizando esos datos. Dentro de una transacción, comprobar la operación, el acceso y las dependencias vigentes; aplicar las reglas y precondiciones; guardar datos, historial y respuesta; y confirmar `succeeded`.
6. Un rechazo de negocio posterior a la reserva conserva una respuesta `rejected`, sin cambios financieros. Un fallo técnico no se guarda como respuesta terminal: se reintenta la transacción completa con la misma clave y los datos ya resueltos.

Dos solicitudes simultáneas con la misma clave compiten por la restricción única de operación. Solo una reserva gana; la otra recupera la fila y compara la huella. La ejecución financiera utiliza el protocolo de [batch del ADR 0008](../adr/0008_OPERACIONES_DURADERAS_E_IDEMPOTENCIA.md), sin depender de una lectura previa ni de `BEGIN` interactivo.

La reserva permite mantener la fecha original incluso si un fallo retrasa el reintento hasta el día siguiente. No existe un borrado de pendientes ni se considera una fila pendiente una compra confirmada.

## Verificación local y prueba pendiente

Desde la raíz del repositorio, prepara un entorno de herramientas y ejecuta:

```bash
python3 -m venv /tmp/gachia-contract-venv
/tmp/gachia-contract-venv/bin/pip install -r scripts/contract-requirements.txt
/tmp/gachia-contract-venv/bin/python scripts/validate-contract.py
```

El validador comprueba OpenAPI, referencias, ejemplos, formatos, límites monetarios y paginación. Ejecuta ambos DDL en SQLite local en memoria con claves foráneas activas, verifica diez tablas y nueve índices y prueba restricciones, precisión monetaria y rollback de una secuencia fallida. No conecta con Cloudflare ni aplica migraciones remotas.

La prueba pendiente con Void y D1 debe comprobar migraciones, binding, `batch()`, autenticación y aislamiento por propietario; devoluciones concurrentes; dos claves iguales simultáneas; cero filas en una precondición; fallo a mitad de lote; y respuesta perdida. Probar también export e import con el importe máximo y medir CPU, lecturas, escrituras y tamaño. SQLite local no acredita esos resultados de D1.

Validación del 28 de octubre de 2026: SQLite 3.45.1 ejecutó diez tablas y nueve índices. OpenAPI validó cinco rutas, seis operaciones, diecinueve esquemas y once ejemplos. Pasaron las comprobaciones de restricciones, ida y vuelta del importe máximo, rollback y enlaces locales. No se ejecutaron pruebas remotas.
