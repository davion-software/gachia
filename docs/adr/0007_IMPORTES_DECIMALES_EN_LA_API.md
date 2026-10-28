# Representar los importes de la API como cadenas decimales exactas

El contrato público expresa los importes con cadenas decimales de dos posiciones, como `"20.00"`, y una moneda explícita o resuelta mediante el valor predeterminado. El almacenamiento utiliza unidades menores enteras y la conversión se realiza de forma exacta. Esta separación conserva una representación legible para agentes y clientes sin depender de que los números JSON cubran el rango numérico de la base de datos.

Referencia: [precisión numérica en JSON](https://www.rfc-editor.org/rfc/rfc8259.html#section-6).

La adaptación a D1 conserva este contrato y su rango. Las unidades menores se almacenan como TEXT canónico para evitar que los bindings y exports JavaScript conviertan int64 a coma flotante. El [modelo físico](../MODELO_FISICO.md) define conversiones exactas, límites y sumas con BigInt.
