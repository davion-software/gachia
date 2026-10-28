# Criterios de aceptación de la primera versión

Estos escenarios reflejan los acuerdos de producto. Todos están pendientes de implementación y verificación.

1. **Integración real.** Desde el Grok Bot del usuario se registra un gasto mediante la API autenticada y se consulta ese mismo registro. Una prueba directa de la API no sustituye este recorrido.

2. **Registro y aclaraciones.** "Gasté 20 en almuerzo" registra un gasto de S/ 20 con una descripción y la fecha actual en la hora de Lima. Si falta el importe o no se entiende el consumo, el agente pregunta antes de registrar.

3. **Monedas y fechas.** Un gasto de S/ 20 y otro de US$ 10 producen totales separados. Un gasto ocurrido ayer y registrado hoy pertenece al período de ayer y conserva una fecha de registro distinta.

4. **Consumo y cuotas.** Una compra de S/ 1.200 en doce cuotas cuenta como S/ 1.200 en la fecha de compra. Pagar la tarjeta o transferir dinero entre cuentas propias no añade gastos.

5. **Devoluciones.** Una compra de S/ 100 en octubre y una devolución de S/ 30 recibida en noviembre conservan ambos registros. Octubre muestra el gasto de S/ 100 y noviembre la devolución de S/ 30. Cada período presenta gastos, devoluciones y neto por moneda, incluido un neto negativo cuando corresponde.

6. **Consistencia.** Una devolución en otra moneda o que eleve lo devuelto por encima del importe original no se registra. Una corrección incompatible con las devoluciones existentes requiere resolver esa inconsistencia.

7. **Clasificación habitual.** El agente utiliza una categoría existente cuando la descripción es clara. En caso contrario, registra el gasto sin categoría. No crea categorías nuevas durante el registro habitual.

8. **Clasificación automática.** A petición del usuario, el agente analiza únicamente gastos sin categoría, reutiliza categorías existentes y crea nuevas cuando hacen falta. Informa de las asignaciones y de los gastos que siguen pendientes. No cambia gastos ya clasificados sin una solicitud explícita.

9. **Guardado por lote.** Las categorías nuevas y las asignaciones de un lote se guardan juntas. Un fallo de validación o guardado no deja el lote parcialmente aplicado. Cada ejecución aparece identificada en el historial con sus cambios.

10. **Categorías editables.** Renombrar una categoría conserva sus asignaciones. Desactivarla impide nuevas asignaciones y mantiene sus gastos históricos consultables. Nombres equivalentes por mayúsculas o espacios no crean duplicados, incluso si la categoría está inactiva; su reactivación exige una solicitud explícita.

11. **Corrección y recuperación.** Una corrección queda en el historial. Eliminar una compra la excluye de las consultas habituales y los totales, junto con sus devoluciones. Recuperarla vuelve a incluir la compra y sus devoluciones.

12. **Reintentos y versiones.** Repetir la misma clave y contenido devuelve el resultado original, sin vencimiento automático ni duplicados. Cambiar el contenido con la misma clave produce conflicto. Dos compras reales con la misma fecha, importe y descripción pueden conservarse como gastos distintos; una instrucción ambigua requiere aclaración. Una modificación nueva con versión antigua no sobrescribe el estado vigente.

13. **Consultas comprobables.** Se listan gastos por período, categoría y moneda, se consultan gastos sin categoría y se obtienen distribuciones y comparaciones. Los listados tienen 50 registros por defecto y máximo 200 por página; los resúmenes abarcan todo el período y filtros. Los resúmenes permiten consultar los registros que explican sus cifras. Sin período explícito se utiliza el mes calendario actual en la hora de Lima; las comparaciones indican fechas y períodos incompletos. Una corrección posterior modifica el siguiente resumen del período afectado y queda en el historial.

14. **Exportación y restauración.** Se exportan gastos a CSV y se obtiene una copia restaurable con gastos, categorías, devoluciones e historial. Una restauración de prueba recupera esos datos. Se comprueba Time Travel dentro de siete días y la importación de un export en una base de prueba. El export diario externo con siete copias solo se exige si se habilita R2 tras verificar su franquicia; permanece desactivado en la configuración US$0.

15. **Disponibilidad y acceso.** El servicio puede utilizarse con la computadora del usuario apagada. Solo el usuario y los agentes autorizados acceden a sus datos; no hay registro público de usuarios.

16. **Cuotas y presupuesto.** El despliegue mediante Void usa Hono, Workers Free y D1 Free, sin planes de pago. Se miden CPU, filas y tamaño. Agotar una cuota produce un fallo reconocible, no éxito financiero ni duplicado al reintentar. Se comprueba la vigilancia del dashboard y los correos de límite de D1 disponibles. El presupuesto es US$0; no se presupone continuidad después del límite ni un tope de cobro en R2.

17. **Precisión y atomicidad en D1.** El importe máximo conserva todos sus céntimos al guardar, consultar, exportar e importar. Dos devoluciones concurrentes no exceden la compra. Un fallo de precondición con cero filas o una sentencia fallida revierte todo el batch, incluido historial y resultado. Dos solicitudes de la misma clave solo producen un cambio financiero.
