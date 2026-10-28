# Definición de Gachia

Estado: definición funcional confirmada por el usuario el 28 de octubre de 2026. El diseño técnico está en curso.

## Propósito y primer usuario

Gachia ayuda a las personas a ordenar sus finanzas personales, comprender sus hábitos de gasto y tomar decisiones para ahorrar.

El creador del proyecto es el primer usuario y utilizará Gachia para sus propias finanzas.

## Objetivo inicial

La primera prioridad es obtener una visión fiable de los gastos registrados. Cada resumen debe permitir consultar los gastos que explican sus cifras. La cobertura depende de los gastos que el usuario comunica al agente.

## Alcance de la primera versión

La primera versión permite registrar y consultar gastos. Los ingresos, saldos de cuentas, deudas e inversiones quedan para después.

El usuario comunica los gastos al agente. La importación de extractos y las conexiones bancarias quedan para después.

Los gastos pueden estar expresados en soles o en dólares. Cada gasto conserva su moneda original y las consultas muestran un total por moneda. La conversión entre monedas queda para después.

La primera entrega se considera completa cuando el usuario puede registrar, corregir, eliminar y recuperar gastos, gestionar categorías, registrar devoluciones y realizar las consultas acordadas mediante el agente.

Los dashboards visuales, la detección de patrones y las recomendaciones de ahorro quedan para siguientes versiones.

## Criterio de gasto

El gasto se atribuye a la fecha de la compra, incluso cuando se paga con tarjeta de crédito. Pagar la tarjeta no genera otro gasto. Las transferencias entre cuentas propias tampoco son gastos.

Una compra en cuotas cuenta por su importe total en la fecha de compra. El calendario de pagos queda para cuando se aborden las deudas.

## Datos del gasto

Cada gasto tiene importe, moneda, fecha y descripción. La categoría es opcional.

Cuando el usuario no menciona una moneda, se utilizan soles. El agente puede deducir una descripción de la instrucción del usuario. Si falta el importe o no se entiende en qué gastó, pregunta antes de registrar.

## Devoluciones y correcciones

Gachia contempla devoluciones totales o parciales vinculadas al gasto original. Conserva el registro de la compra y el de la devolución.

Una devolución real y la corrección de un importe registrado por error son operaciones distintas.

Cada devolución se atribuye al período en que el usuario recibe el dinero. La compra conserva su fecha original. Los resúmenes muestran gastos, devoluciones y gasto neto, por separado para cada moneda. Un período puede tener un gasto neto negativo si sus devoluciones superan sus gastos.

Las devoluciones tienen la misma moneda del gasto y su suma no puede superar el importe original. Las devoluciones en otra moneda quedan fuera de la primera versión. Una corrección que contradiga las devoluciones existentes requiere resolver la inconsistencia antes de aplicarse.

Las devoluciones individuales también pueden corregirse, eliminarse y recuperarse con historial. Recuperar la compra no recupera una devolución que ya se había eliminado individualmente.

Al eliminar una compra, sus devoluciones también quedan fuera de los totales. Al recuperar la compra, sus devoluciones vuelven a incluirse.

## Fechas

Gachia utiliza la hora de Lima. Cuando el usuario no indica una fecha, el gasto corresponde al día actual en esa zona horaria.

Una fecha explícita o una referencia como "ayer" determina cuándo ocurrió el gasto. La fecha del gasto y la fecha de registro se conservan por separado.

## Categorías

El usuario dispone de categorías sin subcategorías y puede modificar su lista. Las categorías iniciales son Alimentación, Transporte, Vivienda, Servicios, Salud, Educación, Ocio, Compras personales y Viajes.

El usuario puede renombrar categorías sin perder sus asignaciones y desactivarlas para impedir nuevas asignaciones. Las categorías desactivadas siguen apareciendo en los gastos históricos. Cambiar la clasificación histórica requiere una reclasificación explícita.

Los nombres que solo difieren en mayúsculas o espacios sobrantes identifican la misma categoría. Los nombres distintos no se fusionan automáticamente.

Durante el registro habitual, el agente elige una categoría existente cuando la descripción permite clasificar el gasto con claridad. Si no puede clasificarlo, el gasto queda sin categoría. El agente no crea categorías nuevas por iniciativa propia durante este registro.

El usuario también puede solicitar una acción de clasificación automática. La IA analiza gastos sin categoría, crea categorías nuevas para el usuario cuando sea necesario, asigna las categorías y guarda los cambios. Al terminar, informa al usuario del resultado.

La clasificación automática trabaja únicamente sobre gastos sin categoría. Reutiliza categorías existentes antes de crear nuevas. Si un gasto sigue siendo ambiguo, lo deja pendiente y lo incluye en el informe del resultado.

Los gastos ya clasificados solo cambian mediante una solicitud explícita de reclasificación.

En la clasificación automática, las categorías nuevas y las asignaciones de cada lote se guardan juntas. Si falla la validación o el guardado del lote, no se aplica parcialmente. Los gastos ambiguos quedan pendientes y no se consideran un fallo del lote.

Cada ejecución se identifica en el historial para que el usuario pueda revisar qué cambió.

## Acciones del agente

El agente puede registrar directamente un gasto cuando la instrucción del usuario es explícita y contiene los datos necesarios. Pregunta cuando falta información o hay ambigüedad.

Para modificar o eliminar un gasto existente, deben estar claros el registro afectado y el cambio solicitado.

## Responsabilidades del agente y de Gachia

El agente interpreta los mensajes del usuario y realiza la clasificación inteligente. Gachia guarda los datos, valida las operaciones y calcula los totales.

La clasificación automática es una secuencia que ejecuta el agente con las herramientas de Gachia. La primera versión no requiere que Gachia contrate o ejecute otro modelo de IA.

## Disponibilidad y acceso

Gachia funciona como un servicio disponible aunque la computadora del usuario esté apagada, mientras no se agoten las cuotas gratuitas. David ha elegido Cloudflare Workers Free, D1 Free y Void, con TypeScript y Hono. El presupuesto de alojamiento, datos y recuperación es US$0 mensuales, aparte de Grok Bot.

No se exige una región AWS. La [evaluación de Cloudflare](CLOUDFLARE.md) detalla límites y alternativas.

La primera entrega es una instancia personal, accesible únicamente por el usuario y los agentes que autorice. No incluye registro público de usuarios.

Los agentes pueden recibir credenciales revocables de lectura y escritura para gestionar los gastos. El propietario conserva la gestión de credenciales y las restauraciones completas mediante una identidad administrativa separada.

La operación vigila el consumo en el dashboard de Cloudflare. Las cuotas de Workers Free y D1 Free producen fallos al agotarse, sin cargos por exceso. D1 documenta correo al alcanzar sus límites diarios. No se garantiza continuidad ni avisos anticipados. El [procedimiento](EXPENSE_NOTIFICATIONS.md) está pendiente de comprobar en la cuenta real.

## Reintentos y gastos similares

Un reintento de la misma operación devuelve el registro existente, sin crear otro gasto.

Todas las escrituras llevan una clave de operación. Repetirla con el mismo contenido devuelve el resultado original, que se conserva sin vencimiento automático en la primera versión; reutilizarla con contenido distinto produce un conflicto. Las modificaciones, eliminaciones y recuperaciones exigen la versión consultada para no sobrescribir cambios simultáneos.

Dos gastos distintos pueden coincidir en importe, descripción y fecha. Esa coincidencia no basta para eliminar o rechazar uno. Si el agente no sabe si el usuario repite una instrucción o comunica una compra nueva, pregunta.

## Historial de cambios

Gachia conserva un historial de cambios. Los gastos eliminados dejan de aparecer en las consultas habituales y de sumar en los totales, pero pueden recuperarse.

## Exportación y respaldos

La primera versión permite exportar gastos a CSV y obtener una copia completa restaurable. Esta copia incluye gastos, categorías, devoluciones e historial.

D1 Time Travel cubre una ventana continua de siete días en Free. Un export diario a R2 Standard con siete copias queda opcional y desactivado por defecto: sus excesos pueden generar cargos. La recuperación y la exportación local se probarán durante la implementación; no se promete una copia externa diaria en US$0.

## Consultas iniciales

La primera versión permite estas consultas:

- Listar gastos por período, categoría y moneda.
- Obtener totales por moneda y su distribución por categorías.
- Comparar períodos.
- Consultar los gastos sin categoría.

Cada resumen permite consultar los gastos y las devoluciones que explican sus cifras.

Se utilizan meses calendario. Una consulta sin período explícito corresponde al mes actual en la hora de Lima. El usuario también puede solicitar intervalos de fechas concretos.

Las comparaciones indican las fechas exactas e informan si alguno de los períodos todavía está incompleto.

Los resúmenes históricos se recalculan con los datos vigentes, incluidas las correcciones posteriores. Cada respuesta indica su período y fecha de generación, sin conservar una copia permanente de cada resumen consultado.

## Formas de uso

El usuario contempla tres formas de usar Gachia:

- Un agente de IA utiliza las herramientas de Gachia. Esta es la primera forma de uso, con Grok Bot como agente inicial.
- Una persona registra o consulta gastos por WhatsApp o Telegram con ayuda de una IA. Esta experiencia queda para después.
- Una persona utiliza una aplicación directamente. Esta experiencia queda para después.

La elección de [Grok Bot](https://x.ai/bot) como primer agente responde al uso habitual que hace de él el primer usuario. El usuario confirmó este producto como el agente concreto que utiliza.

La primera integración utiliza una API HTTPS autenticada y una skill que enseña a Grok Bot a invocarla desde su terminal. La API también sirve como interfaz para otros agentes y la futura app. MCP queda para después.

La compatibilidad se considera comprobada cuando se logra registrar y consultar un gasto desde el Grok Bot real del usuario. Esta prueba está pendiente.

La documentación oficial consultada el 27 de octubre de 2026 describe un ordenador persistente en la nube con terminal y archivos, además de skills reutilizables. Esto permite considerar una integración mediante comandos, aunque todavía no se ha probado Gachia con la cuenta del usuario. Fuentes: [ordenador y aplicaciones](https://docs.x.ai/grok-bot/computer-and-apps) y [skills y rutinas](https://docs.x.ai/grok-bot/skills-routines-and-automations).

La documentación de Team Bots también describe servidores MCP personalizados por HTTPS remoto o por comando. Esa documentación no demuestra por sí sola que todas esas opciones estén disponibles en el bot personal del usuario. Esta alternativa queda fuera de la primera integración elegida. Fuente: [Team Bots](https://docs.x.ai/grok-bot/team-bots#plugins).

## Capacidades propuestas

La idea de producto incluye estas capacidades. La primera entrega cubre el registro, la clasificación y la consulta de gastos; el alcance y orden de las capacidades posteriores siguen pendientes:

- Registrar gastos y clasificarlos por categorías.
- Visualizar gastos, tendencias y distribución del dinero mediante gráficos.
- Identificar patrones de consumo a partir de los movimientos registrados.
- Ofrecer recomendaciones de ahorro personalizadas.
- Comprender la evolución de las finanzas personales a lo largo del tiempo.

## Criterios de aceptación

Los [criterios de aceptación](ACCEPTANCE_CRITERIA.md) describen cómo comprobar la primera versión. Son requisitos pendientes de implementación y verificación, no resultados de pruebas ya realizadas.

## Diseño técnico

El [diseño técnico](TECHNICAL_DESIGN.md) recoge las decisiones confirmadas. Durante la implementación se concretarán:

- Estructura detallada y despliegue de TypeScript y Hono en Workers Free, con D1 Free y despliegue mediante Void.
- Contrato de la API y formato de la skill para el agente.
- Autenticación, autorización de agentes y gestión de credenciales.
- Implementación de reintentos, cambios simultáneos e historial.
- Formato de la copia completa y procedimiento de restauración con la retención ya confirmada.

Los detalles técnicos pendientes se resolverán en el diseño. La integración real con Grok Bot todavía no está comprobada.
