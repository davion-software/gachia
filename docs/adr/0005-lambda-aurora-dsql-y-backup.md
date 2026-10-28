# Utilizar Lambda, HTTP API, Aurora DSQL y AWS Backup en us-east-1

Estado: Reemplazado por ADR-0009. Véase [Usar Cloudflare Workers, D1 y Void en el plan gratis](0009-cloudflare-workers-d1-y-void.md). El contenido siguiente conserva la decisión histórica.

El usuario elige Lambda con API Gateway HTTP API para ejecutar Fastify, Aurora DSQL para conservar SQL y transacciones con operación administrada, y AWS Backup para los respaldos. Frente a DynamoDB se conserva el modelo SQL para los informes; frente a una base con instancia reservada se utiliza facturación por consumo. Los componentes se alojan en `us-east-1` y se retienen 30 copias diarias, eliminando las más antiguas.

DSQL requiere respetar sus límites y su control optimista de concurrencia. El presupuesto de US$10 mensuales sigue sujeto a comprobar el costo conjunto con una carga representativa; la elección no garantiza ese importe ni crea un tope de facturación. La [evaluación de AWS](../aws.md) conserva las fuentes y el escenario de costos.
