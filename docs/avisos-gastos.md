# Vigilar el uso del plan gratis

Estado: procedimiento de diseño, sin cuenta desplegada ni notificaciones comprobadas. Presupuesto: US$0 mensuales. Consulta de fuentes: 28 de octubre de 2026.

## Mantener la cuenta en Free

Usa Workers Free y D1 Free en la cuenta del propietario. No actives Workers Paid ni servicios adicionales para resolver cuotas. R2 permanece desactivado: su franquicia gratuita permite cargos por exceso. La [evaluación](cloudflare.md) recoge límites y respaldo opcional.

AWS Budgets y los avisos a US$5, US$8 y US$10 quedan retirados. La plantilla de AWS es histórica. En Workers Free y D1 Free agotar cuotas produce errores, no un cargo por sobreconsumo.

## Revisar el consumo

1. En el dashboard de Cloudflare, abre **Workers & Pages**, el Worker y sus métricas. Revisa solicitudes diarias, CPU y errores.
2. Abre **D1**, la base, **Metrics > Row Metrics**. Revisa filas leídas y escritas, tamaño y crecimiento. Consulta también **Billing > Billable Usage** para el conjunto de la cuenta.
3. Comprueba recursos compartidos: las cuotas diarias corresponden a la cuenta, no solo a Gachia.
4. Durante la implementación, registra `meta.rows_read`, `meta.rows_written` y tamaño de D1 sin cuerpos financieros ni secretos. GraphQL Analytics permite consultar métricas sin escanear tablas financieras.
5. Revisa cada día durante las pruebas y después de despliegues o clasificaciones grandes. Usa 80% de cuota y 400 MB por base como umbrales operativos para investigar; no son avisos configurados ni límites del proveedor.

Fuentes: [D1 pricing y métricas](https://developers.cloudflare.com/d1/platform/pricing/), [D1 billing](https://developers.cloudflare.com/d1/observability/billing/) y [Workers limits](https://developers.cloudflare.com/workers/platform/limits/).

## Notificaciones disponibles

D1 documenta correos automáticos al alcanzar el límite diario gratuito de lecturas o escrituras desde el 1 de septiembre de 2026. Verifica el correo de la cuenta y su recepción durante la prueba; no son avisos anticipados personalizables al 80%.

Las notificaciones generales de uso facturable por producto requieren Professional o superior según Billing. No se presuponen disponibles en Free aunque la página de D1 mencione notificaciones de facturación. Las notificaciones de mantenimiento e incidentes de Cloudflare están disponibles en todos los planes y pueden configurarse en **Notifications**; avisan del estado de la plataforma, no del consumo de Gachia. No hay garantía documentada aquí de un correo anticipado por cuota de Workers Free: el dashboard es la comprobación principal.

Fuentes: [correo y corte de D1 Free](https://developers.cloudflare.com/changelog/post/2026-09-01-d1-free-tier-limit-enforcement/), [requisitos de avisos de uso](https://developers.cloudflare.com/billing/understand/usage-based-billing/) y [notificaciones de plataforma](https://developers.cloudflare.com/notifications/notification-available/).

## Actuar al alcanzar un límite

- Workers: al agotar 100.000 solicitudes diarias, error 1027 hasta medianoche UTC. Mantener cierre de acceso ante fallo. Exceso de CPU o memoria termina la invocación.
- D1: al agotar cinco millones de lecturas o 100.000 escrituras diarias, las consultas fallan hasta medianoche UTC. No reintentar en bucle; conservar la clave de operación y retomarla después.
- Al llenar 500 MB por base o 5 GB por cuenta, esperar no libera espacio. Exportar y revisar capacidad antes de llegar ahí. No borrar historial ni claves duraderas automáticamente.
- Un error del proveedor puede impedir que Gachia construya su respuesta JSON habitual. El agente no interpreta el fallo como éxito ni cambia la clave al reintentar. Consulta el estado al recuperar acceso.

No se garantiza continuidad al agotar las cuotas. Cualquier activación de un plan de pago requiere cambiar la decisión de presupuesto.
