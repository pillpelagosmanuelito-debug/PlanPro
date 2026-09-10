# Diseño educativo

## 1. El problema real

Un estudiante de Administración o Ingeniería termina el curso de gestión de
proyectos sabiendo:

- Los cinco grupos de procesos del PMBOK.
- Qué son los eventos y artefactos de Scrum.
- La definición de SPI, CPI y EAC.
- Que existe una estructura de desglose del trabajo.

Y sin haber tomado **una sola decisión** de las que se toman todos los días en
un proyecto: a quién contratar, qué fecha comprometer, qué hacer cuando el
patrocinador pide algo que no estaba, cuándo dejar de mejorar y entregar.

Esa brecha no se cierra con más contenido. Los conceptos ya están; falta el
juicio. Y el juicio solo se construye decidiendo y viendo consecuencias.

La razón por la que no se practica en la universidad es logística: un proyecto
real dura meses, y equivocarse cuesta dinero de alguien. Un simulador
comprime 24 semanas en una sesión de clase y hace que equivocarse sea gratis
—en dinero— y caro —en aprendizaje—, que es exactamente la relación que se
busca.

## 2. Qué se evaluó antes de construir

| Criterio | Evaluación |
|---|---|
| **Valor educativo** | Alto. Entrena juicio bajo restricciones, no memoria. La transferencia al trabajo real es directa. |
| **Problema real** | Documentado y transversal: se repite en Administración, Ingeniería y Gestión. |
| **Usuario objetivo** | Estudiantes de 5.º a 10.º ciclo con el marco teórico ya visto. |
| **Competencia profesional** | Planificación, gestión de recursos, gestión de riesgos y gestión del tiempo. |
| **Experiencia de aprendizaje** | Simulación con consecuencia diferida. El error se paga dos periodos después, que es como se paga en la práctica. |
| **Viabilidad técnica** | Alta. Motor determinista, sin backend, sin costo por uso, funciona sin conexión. |
| **Diferenciación** | Los simuladores existentes son de escritorio, caros y en inglés. No hay uno móvil, gratuito y con casos peruanos. |
| **Potencial de uso real** | Alto. Encaja en una sesión de 90 minutos y produce material de discusión inmediato. |

## 3. Los principios de diseño

### 3.1 Ninguna decisión es gratis

Cada palanca tiene un costo real:

| Decisión | Beneficio | Costo |
|---|---|---|
| Contratar más gente | Más capacidad bruta | Coordinación cuadrática y curva de aprendizaje |
| Subir la calidad | Menos defectos y menos retrabajo | Menos capacidad cada periodo |
| Horas extra | +25% de capacidad | +60% de costo y fatiga acumulada |
| Taller de riesgos | Riesgos identificados se pueden tratar | Horas y dinero por adelantado |
| Aceptar un cambio | Patrocinador contento | Trabajo que nadie planificó |
| Rechazar un cambio | Alcance protegido | Patrocinador molesto |

Si alguna decisión fuera gratis, el simulador enseñaría una receta en lugar
de un criterio. Hay pruebas automatizadas que verifican que ninguna lo sea.

### 3.2 La información es incompleta a propósito

El estudiante ve la estimación del equipo, no la duración real. Ve dos
riesgos, no los cinco. Ve el avance reportado, no lo que falta.

Esto no es una limitación del simulador: **es el contenido**. Dirigir un
proyecto es decidir sin saber, y la competencia consiste en decidir bien de
todos modos. Un simulador con información perfecta entrenaría optimización,
que es otra cosa y bastante menos útil.

### 3.3 El asistente no sabe más que el estudiante

El asistente de dirección analiza el proyecto y recomienda acciones, pero lee
**exactamente los mismos datos** que el estudiante: estimaciones, avance
reportado, indicadores y riesgos identificados. Nunca consulta la duración
real oculta ni los riesgos que el estudiante no encontró.

Hay una prueba automatizada que verifica esta propiedad, y la aplicación se lo
dice al usuario en la propia pantalla del asistente. Es honestidad, y también
es contenido: **una herramienta de apoyo a la decisión vale lo que valen los
datos que le das.**

### 3.4 La retroalimentación llega tarde, como en la vida

Un error de planificación en el periodo 2 se manifiesta en el periodo 8. El
simulador no avisa "esa decisión fue mala": deja que el SPI baje y espera a
que el estudiante lo note.

Es lo contrario de la gamificación que premia cada acierto al instante. Aquí
lo que se entrena es **leer indicadores antes de que la crisis sea evidente**,
y para eso la consecuencia tiene que ser diferida.

### 3.5 Comparabilidad por semilla

Con la misma semilla, todos los estudiantes enfrentan exactamente el mismo
proyecto: mismas duraciones ocultas, mismos riesgos, mismos cambios. Las
diferencias de resultado se explican **solo** por cómo se dirigió.

Esto convierte la discusión de aula en algo productivo: "a mí me fue mal por
mala suerte" deja de ser una explicación disponible.

## 4. Por qué un sistema experto y no un modelo de lenguaje

La decisión fue de diseño, no de presupuesto:

| Criterio | Sistema de reglas | Modelo generativo |
|---|---|---|
| Auditabilidad | Cada consejo tiene regla, umbral y fundamento | Caja negra |
| Consistencia | La misma situación da el mismo consejo | Varía entre ejecuciones |
| Honestidad | Imposible que use datos ocultos | Depende del prompt |
| Conexión | Funciona sin internet | Requiere red |
| Costo | Cero | Por consulta |
| Latencia | Inmediata | Segundos |

Para un aula peruana con conectividad irregular y sin presupuesto por alumno,
la comparación no está reñida. Y para el propósito educativo, la
auditabilidad es una ventaja, no un consuelo: un estudiante puede discutir la
regla `spi_critical` y su umbral de 0.90. No puede discutir una alucinación.

**Dónde sí aportaría un modelo generativo**, y sería la evolución natural:

- Redactar el acta de constitución de casos nuevos a partir de un contexto.
- Interpretar en lenguaje natural las preguntas del estudiante sobre su
  propio tablero.
- Actuar como patrocinador en una negociación de cambio de alcance.

Ninguna de esas tres es necesaria para el MVP, y las tres se pueden agregar
después sin tocar el motor.

## 5. Alineación con el currículo

| Tema del curso | Dónde se practica |
|---|---|
| Acta de constitución | Módulo 1: leer restricciones, supuestos y señales |
| EDT / WBS | Módulo 1: estructura de paquetes por fase |
| Estimación | Módulos 2 y 5: comprometer y después ver el error |
| Línea base | Módulo 2: firmar y después ser medido contra ella |
| Gestión del cronograma | Módulo 3: dependencias, traslape, ruta crítica |
| Gestión de recursos | Módulo 3: asignación periodo a periodo |
| Gestión de riesgos | Módulo 4: identificación, análisis, respuesta |
| Control de cambios | Módulo 3: las cuatro decisiones posibles |
| Valor ganado | Módulo 3: SPI, CPI, EAC, TCPI en el tablero |
| Cierre | Módulo 5: informe, lecciones y trazabilidad |
| PMBOK / Scrum / Agile | Transversal: cada enfoque gana en su caso |

## 6. Lo que este simulador NO enseña

Se declara para que nadie lo use esperando lo que no da:

- **No enseña a usar herramientas.** No hay MS Project ni Jira.
- **No enseña habilidades blandas.** No hay conversaciones difíciles ni
  gestión de personas; la satisfacción del patrocinador es un marcador, no un
  interlocutor.
- **No enseña estimación técnica.** Las estimaciones vienen dadas; se practica
  qué hacer con ellas, no cómo producirlas.
- **No certifica nada.** No prepara para el examen PMP.

Un curso completo necesita las cuatro cosas. Este simulador cubre una: el
juicio para decidir bajo restricciones, que es la que peor se cubre con
lectura.
