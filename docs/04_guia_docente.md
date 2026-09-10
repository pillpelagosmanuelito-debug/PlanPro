# Guía docente

## 1. Para qué sirve y para qué no

Este simulador entrena **juicio bajo restricciones**. No reemplaza la clase de
metodologías: la aprovecha. Funciona mejor cuando los estudiantes ya vieron
PMBOK, Scrum y valor ganado, y les falta haberlo usado para decidir algo.

Una partida completa toma entre 25 y 40 minutos. Cabe en una sesión de 90
minutos con espacio para discutir, que es donde ocurre la mitad del
aprendizaje.

## 2. Sesión de 90 minutos

| Tiempo | Actividad |
|---|---|
| 0–10 | Presentación del simulador y de las reglas. Todos anotan la **misma semilla**. |
| 10–20 | Módulo 1 (acta) y módulo 2 (planificación). **Se comprometen individualmente antes de conversar.** |
| 20–25 | Pausa de comparación: ¿qué plazo comprometió cada uno? ¿por qué? |
| 25–55 | Ejecución de los 12 periodos. |
| 55–70 | Cierre y lectura del informe individual. |
| 70–90 | Discusión guiada (sección 5). |

**El punto crítico está en el minuto 20.** Si dejan comprometer la línea base
después de conversar, todos convergen al mismo plan y se pierde la variedad
que hace rica la discusión final. Que se comprometan a ciegas y **después**
comparen.

## 3. La semilla

En la pantalla de nuevo proyecto hay un campo de semilla. Si el docente dicta
`2024`, toda la clase enfrenta:

- Las mismas duraciones reales ocultas de cada paquete.
- Los mismos riesgos, en las mismas ventanas.
- Las mismas solicitudes de cambio.

Cualquier diferencia de resultado se explica **solo** por las decisiones. Eso
elimina la explicación más cómoda —"me fue mal por mala suerte"— y obliga a
mirar el propio plan.

Semillas sugeridas para empezar:

| Semilla | Caso recomendado | Para qué sirve |
|---|---|---|
| `2024` | Matrícula | Primera partida; el caso más intuitivo |
| `1990` | Planta | Contraste: alcance cerrado, entorno regulado |
| `3001` | Cobranzas | El caso mixto; el más difícil de leer |

## 4. Secuencia de tres sesiones

**Sesión 1 — El costo de una promesa.**
Caso Matrícula, semilla común, enfoque libre. Casi todos comprometen un plazo
optimista. El objetivo es que lo vean en el informe.

**Sesión 2 — La metodología no es una preferencia.**
Se divide la clase en tres grupos. Todos juegan el caso **Planta** con la
misma semilla, pero cada grupo con un enfoque distinto: predictivo, ágil,
híbrido. El predictivo gana con claridad, y la discusión escribe sola: *¿por
qué aquí sí y en Matrícula no?*

**Sesión 3 — El riesgo que no viste.**
Caso Cobranzas. Mitad de la clase con instrucción de hacer taller de riesgos
en los dos primeros periodos; la otra mitad sin instrucción. Se comparan los
riesgos que golpearon sin estar identificados.

## 5. Preguntas para la discusión

Ordenadas de más concreta a más incómoda:

1. ¿Cuántos periodos comprometiste y cuántos usaste? ¿Qué te hizo pensar que
   ese plazo era alcanzable?
2. Divide tu alcance entre tu capacidad por periodo. ¿Ese número te habría
   cambiado la decisión si lo hubieras mirado antes de firmar?
3. ¿Cuántas horas de equipo perdiste por asignaciones inválidas? ¿Cuánto
   costaron?
4. ¿En qué periodo cayó tu SPI por debajo de 0.95? ¿Cuántos periodos después
   hiciste algo?
5. ¿Qué decidiste con la solicitud de cambio? ¿Cuál fue la decisión más fácil
   de tomar y cuál habrías defendido mejor ante un comité?
6. ¿Cuántos riesgos te golpearon sin estar en tu registro? ¿Qué te costó no
   haber hecho el taller?
7. ¿Cuántos defectos llegaron al cliente? ¿Qué nivel de calidad elegiste y qué
   creías que estabas comprando con esa decisión?
8. Mira la tabla de estimación contra realidad. ¿Qué paquete se desvió más?
   ¿Había alguna señal de eso en el acta?

La pregunta 8 suele ser la más productiva: en los tres casos, el paquete que
más se desvía tiene la complejidad más alta, y el acta lo anunciaba con
frases como *"sistema antiguo, sin documentación y con soporte externo"*.

## 6. Cómo leer el informe de cierre

El informe califica cuatro competencias de 0 a 100 con evidencia de la propia
partida. Vale la pena advertir a los estudiantes de dos cosas:

- **Entregar no garantiza buena nota.** Un proyecto entregado a fuerza de
  horas extra, con la reserva quemada, capacidad ociosa y el patrocinador
  molesto puntúa peor que uno entregado con holgura.
- **No entregar no garantiza mala nota en todo.** Un estudiante que planificó
  bien y fue golpeado por riesgos que sí había identificado y tratado puede
  sacar buen puntaje en planificación y riesgos.

Esa disociación entre *resultado* y *calidad de la dirección* es
intencional, y es probablemente la lección más difícil de transmitir en una
clase teórica.

## 7. Ajustar la dificultad

Todos los parámetros están en `lib/data/models/project_config.dart` con
comentarios que explican qué modela cada uno. Ajustes útiles:

| Objetivo | Qué cambiar |
|---|---|
| Partida más corta | `totalPeriods` de 12 a 9 |
| Más margen para principiantes | Bajar `estimationBias` de 1.10 a 1.05 |
| Hacer más visible la ley de Brooks | Subir `communicationOverheadSquared` |
| Hacer la calidad más decisiva | Subir `lateFixMultiplier` |
| Menos aleatoriedad | Bajar `estimationSpread` de 0.20 a 0.12 |

**Después de cualquier cambio, ejecutar `flutter test`.**
`test/calibration_test.dart` verifica que ninguna estrategia trivial gane y
que cada metodología siga ganando en su caso. Si esas pruebas fallan, el
simulador dejó de enseñar lo que dice enseñar.

## 8. Evaluación con nota

Si se quiere calificar, se sugiere no usar el puntaje del simulador
directamente:

| Peso | Criterio |
|---|---|
| 40% | Justificación escrita de la línea base comprometida, **entregada antes de ejecutar** |
| 30% | Análisis del informe de cierre: qué salió mal y qué decisión lo causó |
| 20% | Puntaje de competencias del simulador |
| 10% | Participación en la discusión |

El 40% inicial es lo importante: obliga a razonar el plan antes de conocer el
resultado, que es la única forma de evaluar planificación sin contaminarla
con el sesgo retrospectivo.

## 9. Preguntas frecuentes

**¿Necesita internet?** No. Todo corre en el dispositivo y la partida se
guarda localmente.

**¿Se puede pausar?** Sí. La partida se guarda después de cada decisión.
Cerrar la aplicación no pierde nada.

**¿Puedo ver los resultados de mis estudiantes?** No en esta versión. Cada
partida vive en el dispositivo. El estudiante puede mostrar el informe de
cierre. Un panel docente es la mejora más pedida y la más obvia siguiente.

**¿Los montos son reales?** Están en soles, con valores plausibles del
mercado peruano, pero no auditados contra una encuesta salarial. Sirven para
razonar sobre órdenes de magnitud, no para cotizar un proyecto.

**¿Se puede agregar un caso de mi carrera?** Sí. Un caso es una entrada en
`ProjectCase.catalog` con su acta, 11 paquetes de trabajo y una lista de
riesgos del catálogo. No requiere tocar el motor.
