# Contrato de la API de Gachia

Estado: contrato de diseño listo para revisión, con las decisiones de las rondas Q41–Q50 incorporadas. No describe una API implementada.

## Alcance

La API recibe instrucciones estructuradas. El agente interpreta el lenguaje natural, resuelve ambigüedades con el usuario y utiliza la API para consultar o guardar datos.

La primera implementación cubre registrar un gasto, consultar ese registro, listar gastos y obtener un resumen por período. El contrato completo debe contemplar también categorías, devoluciones, correcciones, recuperación y clasificación por lotes para no contradecir los acuerdos existentes.

El [documento OpenAPI](openapi.yaml) formaliza ese primer recorrido, incluyendo consultas de categorías y operaciones. Contiene cinco rutas y seis operaciones. El dominio `.invalid` es un ejemplo reservado, no un servicio desplegado.

## Recursos previstos

- Gastos: `/v1/expenses` y `/v1/expenses/{expense_id}`.
- Categorías: `/v1/categories` y `/v1/categories/{category_id}`.
- Devoluciones de un gasto: `/v1/expenses/{expense_id}/refunds`.
- Resúmenes: `/v1/reports/summary`.
- Ejecuciones de clasificación: `/v1/classification-runs` y sus lotes.
- Operaciones identificables: `/v1/operations/{operation_id}`.

Las rutas de registro y consulta ya tienen métodos, esquemas, errores y permisos en OpenAPI. Las mutaciones de corrección y recuperación, devoluciones, gestión de categorías y clasificación son ampliaciones de contrato posteriores; su comportamiento debe conservar las reglas descritas aquí. El modelo SQL contempla sus entidades, pero no acredita que esas operaciones estén implementadas.

## Representación de un gasto

Los campos previstos son un identificador estable, importe, moneda, fecha del gasto, descripción, categoría opcional, versión y fechas de registro y modificación. El estado de eliminación se conserva para permitir recuperación.

La moneda pertenece a `PEN` o `USD`. La fecha del gasto se expresa como `YYYY-MM-DD`; la fecha de registro es un instante en UTC. Un nombre de categoría no sustituye a su identificador al registrar una asignación.

Los importes se transmiten como cadenas decimales exactas de dos posiciones, por ejemplo `"20.00"`, y se convierten a unidades menores enteras al guardar. Esta forma evita que los clientes deban representar importes grandes mediante números JSON de precisión limitada.

El rango por gasto o devolución es de `0.01` a `92233720368547758.07`, en PEN o USD, correspondiente al rango positivo int64 de unidades menores, guardadas como TEXT canónico en D1. Se rechazan cero, negativos, números JSON, precisión adicional, comas y separadores de miles. No se redondea. Los totales pueden superar el importe máximo individual y se serializan también como cadenas exactas; el neto puede ser negativo.

Cuando una solicitud de registro omite moneda o fecha, la API aplica PEN y la fecha actual en la hora de Lima. La respuesta devuelve los valores completos utilizados. La API no interpreta expresiones de lenguaje natural como "ayer"; esa resolución corresponde al agente. Un reintento conserva la fecha resuelta para la operación original.

Un registro puede solicitarse con esta representación mínima:

```json
{
	"amount": "20.00",
	"description": "Almuerzo"
}
```

La respuesta incorpora identificador, moneda, fecha del gasto, categoría opcional y datos de registro. La solicitud completa incluye `Authorization: Bearer ...` e `Idempotency-Key`. El ejemplo representa datos financieros y no contiene una credencial real.

## Categorías

La comparación de nombres ignora diferencias de mayúsculas y espacios sobrantes. Los nombres distintos no se fusionan automáticamente. Las asignaciones utilizan el identificador estable de la categoría, no su nombre.

La regla se aplica al conjunto de categorías del usuario, incluidas las desactivadas. Crear un nombre equivalente al de una categoría inactiva produce conflicto e identifica la existente. Hace falta una reactivación explícita antes de nuevas asignaciones; la clasificación automática no puede reactivarla ni crear una copia para eludir su estado.

## Devoluciones

La API permite corregir, eliminar y recuperar devoluciones individuales, conservando el historial. Toda modificación vuelve a comprobar la consistencia con el gasto original, su moneda y el importe pendiente de devolución.

Recuperar una compra no recupera una devolución que ya se había eliminado individualmente.

## Reintentos y conflictos

Cada escritura exige una clave estable de operación, enviada mediante `Idempotency-Key`. La solicitud y su resultado se conservan sin vencimiento automático en la primera versión. El cambio financiero, su historial y el resultado confirmado se guardan juntos.

Una compra nueva recibe una clave nueva aunque coincida con otra en fecha, importe y descripción. Una respuesta perdida se resuelve recuperando o reintentando la operación original.

La misma clave y contenido devuelven el resultado original. Reutilizar una clave con contenido distinto produce un conflicto. La consulta posterior del registro muestra su estado vigente, que puede ser distinto del resultado original si hubo correcciones.

Los valores predeterminados forman parte de la resolución inicial: repetir la solicitud con fecha omitida no vuelve a calcular "hoy". El acceso autenticado se comprueba también al repetir una operación; conservar su resultado no permite utilizar una credencial revocada.

Modificar, eliminar o recuperar un registro exige la versión que el agente consultó. Se transporta mediante la etiqueta fuerte devuelta en `ETag`, enviada completa en `If-Match`. La falta de precondición produce `428`; una versión antigua produce `412` y exige consultar el estado actualizado. No se aceptan comodines, etiquetas débiles ni listas como sustituto de una versión concreta. Las rutas de esas mutaciones se formalizarán en la ampliación correspondiente.

Si una operación ya fue confirmada y se perdió su respuesta, el reintento devuelve el resultado original antes de volver a evaluar la versión de esa misma modificación. Esto distingue una respuesta perdida de una solicitud nueva sobre una versión antigua.

El [protocolo del esquema](schema/README.md) distingue una reserva pendiente, un resultado confirmado y un rechazo de negocio. La reserva mantiene la fecha resuelta incluso tras un fallo técnico. Los errores de autenticación o de forma anteriores a la reserva no asocian una clave a una operación. Los rechazos de negocio posteriores sí conservan su respuesta: corregir la instrucción requiere una clave nueva.

## Filtros y paginación

Las fechas `from` y `to` son inclusivas y deben enviarse juntas; `from` no puede ser posterior a `to`. Si se omiten ambas se utiliza el mes calendario actual en Lima. Se admiten filtros de moneda y categoría; `uncategorized=true` selecciona gastos sin categoría y no puede combinarse con `category_id`.

Los listados utilizan `limit=50` por defecto, con mínimo 1 y máximo 200. La continuación se envía como `cursor` opaco. En gastos, el orden es fecha descendente e identificador descendente. En categorías, es nombre normalizado e identificador ascendentes.

El cursor queda ligado al propietario, filtros, orden y período ya resuelto. Cambiar esos parámetros invalida su uso; se permite cambiar el tamaño de página dentro del límite. Si pasa el tiempo, continuar una consulta con período omitido conserva el período de la primera página. Las páginas consultan datos vigentes: no garantizan una instantánea común frente a ediciones concurrentes.

El listado habitual excluye gastos eliminados. La consulta por identificador permite recuperarlos como datos de solo lectura para preparar una futura restauración. Las consultas de categorías admiten activas, inactivas o todas, sin que ello habilite nuevas asignaciones a las inactivas.

## Resúmenes

Los resúmenes de cualquier período utilizan los datos vigentes. Corregir hoy el importe de un gasto de octubre modifica el resumen de octubre en la siguiente consulta; el historial conserva la corrección.

Cada respuesta indica período y fecha de generación. No se conserva una instantánea permanente de cada resumen consultado. Los gastos y las devoluciones se agregan por separado, conforme a sus propias fechas, antes de calcular el neto por moneda; unirlos sin esa separación podría multiplicar el importe de una compra con varias devoluciones.

Los totales y la distribución cubren todo el período y los filtros, no una página. Las devoluciones se filtran por su fecha de recepción, aunque la compra original quede fuera del período, y utilizan la categoría vigente de esa compra. Los datos de una respuesta deben obtenerse de una lectura consistente.

`period.is_complete` indica si el último día del período ya terminó en Lima. No significa que el período esté cerrado a correcciones. Para comparar períodos, el agente consulta ambos intervalos y conserva sus fechas, fecha de generación e indicador de período completo; este primer recorrido no necesita un endpoint separado de comparación.

Sin filtro de moneda se devuelven PEN y USD, incluidos sus totales cero. Con filtro se devuelve solo la moneda solicitada. La agrupación sin categoría tiene identificador y nombre nulos. El límite de paginación del listado no se admite como filtro del resumen.

## Errores y fechas

Los errores de la aplicación utilizan `application/problem+json`. Se distinguen `400` para JSON o cabeceras mal formados y cursores inválidos; `401` y `403` para acceso; `404` para recursos no encontrados en el ámbito del propietario; `409` para conflictos; `413` para cuerpos mayores de 65536 bytes; `422` para el esquema o reglas financieras; y `503` para fallos transitorios. Los mensajes para personas no sustituyen a `type` y `code` estables.

La validación del cuerpo es estricta: no convierte tipos, no elimina propiedades desconocidas y no inyecta valores predeterminados antes de identificar la solicitud. El contrato OpenAPI es la referencia de diseño para los esquemas de la implementación; los tipos de TypeScript no sustituyen esa validación en ejecución.

Los códigos iniciales incluyen `invalid_request`, `validation_error`, `authentication_required`, `permission_denied`, `not_found`, `idempotency_conflict`, `category_inactive`, `operation_pending`, `payload_too_large` y `transient_failure`. La identidad de tipo sigue `urn:gachia:problem:<code>`. `operation_pending` es un conflicto transitorio, no un resultado financiero terminal, y no reemplaza la reserva existente.

El contrato distinguirá una fecha de calendario de un instante de registro. Los formatos de OpenAPI deberán acompañarse de validación real; una anotación de formato no acredita por sí sola que el servidor rechace una fecha inválida.

Fuentes: [JSON y precisión numérica](https://www.rfc-editor.org/rfc/rfc8259.html#section-6), [Problem Details](https://www.rfc-editor.org/rfc/rfc9457.html), [If-Match](https://www.rfc-editor.org/rfc/rfc9110.html#section-13.1.1) y [OpenAPI 3.1.1](https://spec.openapis.org/oas/v3.1.1.html).

## Decisiones cerradas de la ronda inicial

- Importes como cadenas decimales en la API y unidades menores enteras al guardar.
- Aplicación de moneda y fecha predeterminadas en la API, resueltas una vez por operación.
- Corrección, eliminación y recuperación de devoluciones individuales.
- Comparación de nombres de categorías sin distinguir mayúsculas ni espacios sobrantes.

## Decisiones cerradas de reintentos y consultas

- Clave de operación para todas las escrituras, resultado original repetible e idempotencia sin vencimiento automático.
- Versión esperada para impedir sobrescribir cambios simultáneos.
- Recálculo de períodos históricos con datos vigentes, sin instantáneas permanentes de informes.

## Decisiones cerradas de validación y consultas

- Rechazo de importes cero, negativos o con precisión excesiva, sin redondeo automático.
- Páginas de 50 registros por defecto, con máximo de 200.
- Resúmenes sobre todo el período y filtros, independientes de la paginación.
- Reactivación explícita de categorías desactivadas, sin duplicados ni reactivación autónoma por la IA.

## Verificación y alcance posterior

El [validador local](../scripts/validate-contract.py) comprueba el documento OpenAPI, referencias, ejemplos, importes y el ejecución local del SQL en SQLite. No prueba un servidor, una base D1, la autenticación efectiva ni carreras concurrentes.

Las mutaciones de la versión completa ampliarán OpenAPI conservando este modelo. Las instrucciones para reproducir la validación y las comprobaciones pendientes están en la [guía del esquema](schema/README.md).

## Ejecución y cuotas gratuitas

La API se diseña con Hono en Workers Free, D1 Free y despliegue Void. El presupuesto es US$0. El agotamiento de cuotas o la terminación del Worker puede producir un error del proveedor fuera del contrato JSON. No confirma la escritura: el agente conserva `Idempotency-Key` y consulta o reintenta cuando se recupere el servicio, sin bucles agresivos. El [procedimiento de uso](AVISOS_DE_GASTOS.md) describe cortes y reinicio de cuotas.
