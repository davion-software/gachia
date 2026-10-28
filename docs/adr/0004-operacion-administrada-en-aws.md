# Priorizar operación administrada en AWS

Estado: Reemplazado por ADR-0009. Véase [Usar Cloudflare Workers, D1 y Void en el plan gratis](0009-cloudflare-workers-d1-y-void.md). El contenido siguiente conserva la decisión histórica.

El usuario ha elegido AWS para alojar Gachia y prefiere delegar el mantenimiento del servidor mediante servicios administrados para la API y la base de datos. El diseño debe comparar el costo conjunto de ejecución, persistencia y respaldos con un presupuesto inicial de hasta US$10 mensuales, aparte de Grok Bot. Esta elección reduce el trabajo operativo frente a mantener un servidor propio; los servicios y la región se concretan en el [ADR 0005](0005-lambda-aurora-dsql-y-backup.md).
