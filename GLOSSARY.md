# Finanzas personales de Gachia

Este glosario reúne los términos acordados durante la definición de Gachia.

## Lenguaje

**Usuario**:
Persona cuyas finanzas personales se gestionan en Gachia. El creador del proyecto es el primer usuario.

**Gasto**:
Consumo de dinero del usuario, atribuido por su importe total a la fecha de compra aunque se pague con tarjeta de crédito o en cuotas. El pago de la tarjeta y las transferencias entre cuentas propias no constituyen gastos.

**Categoría de gasto**:
Clasificación que agrupa gastos según su finalidad. Las categorías no tienen subcategorías en la primera versión.

**Moneda del gasto**:
Moneda en la que se expresa el importe de un gasto. Gachia contempla gastos en soles y en dólares desde la primera versión.

**Fecha del gasto**:
Fecha en la que ocurrió el gasto, que determina a qué período corresponde.

**Fecha de registro**:
Fecha en la que se incorpora un gasto a Gachia. Puede ser distinta de la fecha del gasto.

**Gasto sin categoría**:
Gasto registrado que todavía no tiene una clasificación asignada.

**Clasificación automática**:
Acción solicitada por el usuario para que la IA clasifique gastos sin categoría, reutilizando categorías existentes antes de crear nuevas. Guarda las asignaciones e informa del resultado, incluidos los gastos que siguen pendientes por ambigüedad.

**Reclasificación**:
Cambio de la categoría de un gasto ya clasificado, solicitado explícitamente por el usuario.

**Devolución**:
Restitución total o parcial del dinero de una compra, vinculada al gasto original y atribuida a la fecha en que se recibe. La compra y la devolución conservan sus respectivos registros.

**Corrección**:
Cambio que subsana un error en los datos registrados de un gasto o una devolución. No representa por sí mismo un nuevo movimiento de dinero.

**Gasto neto**:
Total de gastos de un período menos el total de devoluciones recibidas en ese período, calculado por separado para cada moneda. Puede ser negativo cuando las devoluciones superan los gastos.

**Gasto eliminado**:
Gasto que queda fuera de las consultas habituales y los totales, cuyo registro se conserva y puede recuperarse.

**Devolución eliminada**:
Devolución que queda fuera de los totales, cuyo registro e historial se conservan para permitir su recuperación. Recuperar la compra original no recupera automáticamente una devolución eliminada individualmente.

**Devolución efectiva**:
Devolución no eliminada individualmente cuya compra tampoco está eliminada. Se incluye en los totales del período en que se recibió.

**Categoría desactivada**:
Categoría que conserva sus gastos históricos pero no admite nuevas asignaciones. Requiere una reactivación explícita antes de recibir nuevos gastos.

**Ejecución de clasificación**:
Realización identificable de la acción de clasificación automática. Su historial permite revisar los cambios que produjo.

**Lote de clasificación**:
Conjunto de categorías nuevas y asignaciones que se guardan juntas durante la clasificación automática. Si falla su validación o guardado, el lote no se aplica parcialmente.
