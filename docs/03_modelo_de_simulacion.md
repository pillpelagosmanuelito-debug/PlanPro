# Modelo de simulación

Este documento describe **toda** la matemática del simulador y, sobre todo,
por qué cada regla está donde está. Un simulador educativo cuyo motor no se
puede auditar no enseña: adoctrina.

Todos los parámetros viven en `lib/data/models/project_config.dart`, de modo
que un docente puede ajustar la dificultad sin tocar la lógica.

---

## 1. Duración real oculta

El estudiante ve la **estimación del equipo**. La duración real permanece
oculta y se descubre trabajando.

```
factor  = lognormal(mediana = 1.10, σ = 0.20)
ajuste  = 1 + (factor − 1) × complejidad
real    = estimado × ajuste × (1 + retrabajo × 0.60)
```

**Por qué lognormal.** La distribución de duraciones de tareas está acotada
por abajo (una tarea no puede tomar menos de cero) y tiene cola larga por
arriba (siempre puede aparecer algo). La lognormal captura esa asimetría, que
es la razón por la que los proyectos se atrasan mucho más a menudo de lo que
se adelantan.

**Por qué mediana 1.10 y no 1.0.** El sesgo de optimismo en estimación está
extensamente documentado. Ponerlo en 1.0 enseñaría que estimar bien es
cuestión de suerte; ponerlo en 1.10 enseña que hay que planificar contando con
él.

**Por qué la complejidad amplifica la desviación y no el trabajo base.** Un
paquete complejo no es necesariamente más largo: es *menos predecible*. Esa
distinción es exactamente la que separa "estimación" de "riesgo".

---

## 2. Capacidad del equipo

```
capacidad = Σ(horas_i × productividad_i × curva_i)
          × eficiencia(n)
          × mentoría
          × gobernanza
          × (1 − qa × 0.14)
          × (1 − fatiga)
          × (1 + 0.25 si hay horas extra)
```

### 2.1 Eficiencia por comunicación

```
eficiencia(n) = 1 / (1 + 0.040·k + 0.010·k²)      con k = n − 1
```

| Personas | Eficiencia | Capacidad total relativa |
|---|---|---|
| 1 | 1.00 | 1.00 |
| 3 | 0.90 | 2.69 |
| 5 | 0.78 | 3.92 |
| 7 | 0.63 | 4.38 |
| 9 | 0.51 | 4.58 |
| 12 | 0.38 | 4.50 |

**Por qué el término cuadrático.** Con *n* personas hay *n(n−1)/2* canales de
comunicación. El costo de coordinación crece con el cuadrado del equipo, no en
línea recta. La consecuencia se ve en la tabla: **más allá de nueve personas,
sumar gente ya no suma capacidad, solo planilla.** Ese es el contenido
operativo de la ley de Brooks, y con un factor lineal simplemente no aparece.

### 2.2 Curva de aprendizaje

```
curva = 0.45 + 0.55 × (periodos_en_equipo / periodos_de_rampa)   [tope 1.0]
```

Quien se incorpora rinde al 45% y sube hasta el 100% en 1, 2 o 3 periodos
según el perfil. Un junior barato tarda tres periodos —medio proyecto— en
rendir de verdad.

### 2.3 Mentoría

```
mentoría = 1 − 0.14 × min(nuevos, 3)
```

Cada persona en curva de aprendizaje consume tiempo de quienes ya producían.
Es el segundo tramo de la ley de Brooks, y el que la mayoría olvida: el costo
no lo paga solo quien llega, lo paga **todo el equipo**.

El efecto combinado es fuerte y deliberado: incorporar a la quinta persona en
un equipo de cuatro durante la ejecución **reduce** la capacidad efectiva del
periodo. "Agregar personas a un proyecto atrasado lo atrasa más" deja de ser
una cita y pasa a ser algo que el estudiante ve en el tablero.

### 2.4 Gobernanza

| Enfoque | No regulado | Regulado |
|---|---|---|
| Predictivo | 2% | 2% |
| Ágil | 3% | **10%** |
| Híbrido | 5% | 5% |

El ágil en entorno regulado paga caro: produce poca evidencia formal y aun
así alguien tiene que producirla.

---

## 3. Dependencias entre fases

Una fase se habilita cuando las anteriores alcanzan un umbral de avance
**acumulado**:

| Fase | Umbral |
|---|---|
| Análisis | 0% |
| Diseño | 55% |
| Construcción | 50% |
| Pruebas | 70% |
| Implantación | 80% |

**Por qué no 100%.** Las fases de un proyecto real se traslapan
(*fast tracking*). Exigir el 100% enseñaría un modelo en cascada estricto que
nadie usa. Los umbrales parciales enseñan lo correcto: se puede adelantar, con
límites.

Las horas asignadas a una fase bloqueada **se pierden**. Es la penalización
por planificar sin mirar dependencias.

---

## 4. Aplicación del trabajo y capacidad ociosa

Cada periodo, cada integrante aporta sus horas al paquete que tenga asignado.
Se distinguen dos situaciones que parecen iguales:

- **Asignación inválida** (nadie asignado, paquete fuera de alcance, fase
  bloqueada, o un paquete que ya estaba terminado al empezar el periodo): las
  horas se pierden. La aplicación avisa antes de cerrar el periodo, y aun así
  se cerró.
- **El paquete lo terminó otro durante este mismo periodo**: la persona se
  reasigna sola a otro paquete habilitado, empezando por los de su fase. Eso
  no es un error de dirección, es el curso normal del trabajo en paralelo.

Esta distinción importa: sin ella, el trabajo en paralelo generaría ociosidad
artificial y el simulador castigaría al estudiante por algo que no decidió.

---

## 5. Economía de la calidad

Al terminarse un paquete:

```
creados  = estimado × complejidad × 0.030 × (1 − 0.70 × qa)
directos = creados × 0.30 × (1 − qa)        → escapan al cliente
latentes = creados − directos               → detectables en pruebas
```

Durante la fase de pruebas, y **antes** de aplicar el trabajo del periodo:

```
detectados = latentes × min(0.95, avance_pruebas × 1.6)
retrabajo  = detectados × 8 horas
```

Si quedan menos de 0.5 defectos latentes, el resto se considera escapado.

### Por qué así

**Por qué el aseguramiento no llega a cero defectos.** El factor `0.70` deja
un 30% irreducible. Si la calidad máxima eliminara todos los defectos, sería
una estrategia dominante: siempre convendría el máximo y la decisión
desaparecería. Además sería falso.

**Por qué el multiplicador 8.** Es la regla 1-10-100: un defecto corregido
donde se produjo cuesta 1; en pruebas, cerca de 10; en producción, 100. El
simulador usa 8 para el tramo de pruebas.

**Por qué la detección ocurre antes de aplicar el trabajo.** Si el retrabajo
apareciera al cerrar el periodo, reabriría el paquete de corrección ya
terminado y el equipo tendría que esperar al periodo siguiente. Detectar
primero permite que la capacidad del periodo lo absorba, que es lo que pasa
en un proyecto real donde pruebas y corrección conviven en la misma iteración.

**El resultado pedagógico.** Recortar calidad **no** impide entregar: acelera
un poco y multiplica por diez los defectos que llegan al cliente. La
evaluación de cierre los cuenta. Es la tensión real: el atajo funciona a
corto plazo y se cobra después.

---

## 6. Riesgos

Cada riesgo tiene probabilidad declarada **para toda su ventana**, y el motor
la reparte por periodo para que la exposición total coincida con lo que el
estudiante ve en el registro:

```
p_periodo = 1 − (1 − p_efectiva)^(1 / longitud_ventana)
```

| Respuesta | Probabilidad | Impacto en horas | Impacto en costo | Costo por adelantado |
|---|---|---|---|---|
| Sin respuesta | ×1.00 | ×1.00 | ×1.00 | 0 |
| Mitigar | **×0.40** | ×0.75 | ×0.75 | mitigación |
| Transferir | ×1.00 | **×0.35** | **×0.25** | transferencia |
| Aceptar | ×1.00 | ×1.00 | ×1.00 | 0 |
| Evitar | **×0.00** | ×0.00 | ×0.00 | se cede alcance |

**Riesgos no identificados.** Ocurren igual, con **×1.25 en horas**, **×1.20 en
costo** y **−7 de satisfacción** del patrocinador en lugar de −3. La diferencia
no es arbitraria: sin plan de respuesta, la reacción llega tarde y desordenada.

El acta revela solo **dos** riesgos. El resto existe desde el primer periodo y
solo aparece si el estudiante invierte en un taller de identificación. Esa
asimetría es la lección central del módulo: *los riesgos que no identificas no
desaparecen*.

**Exposición.** El registro se ordena por `probabilidad × (costo + horas ×
valor_hora)`, no por impacto bruto. Priorizar por miedo en lugar de por
exposición es el error que este orden hace visible.

---

## 7. Solicitudes de cambio

Aparecen en periodos guionados (4 y 7 en casos volátiles, 6 en estables) y
**el acta ya las anunciaba**: cada caso lista los temas abiertos. Un director
atento reserva contingencia para ellas.

```
horas = horas_base × factor_de_la_metodología
```

| Enfoque | Factor |
|---|---|
| Predictivo | 2.4 |
| Híbrido | 1.5 |
| Ágil | 1.0 |

| Decisión | Efecto en el trabajo | Línea base | Satisfacción |
|---|---|---|---|
| Aceptar sin ajustar línea base | Entra completo | Sin cambios | **+4** |
| Aceptar renegociando | Entra completo | Se ajusta, queda revisión | +1 |
| Intercambiar alcance | Entra, sale alcance opcional | Sin cambios | −2 |
| Rechazar formalmente | No entra | Sin cambios | −8 |

**La trampa está diseñada a propósito.** La opción que más contenta al
patrocinador es la que peor termina: el trabajo entra al proyecto y la promesa
no se mueve, así que el atraso aparecerá después y será del director. La
evaluación de cierre penaliza explícitamente esa decisión. Dejar una solicitud
sin responder cuesta −2 por periodo: el silencio también es una decisión.

---

## 8. Horas extra

```
capacidad × 1.25    costo × 1.60    fatiga += 0.12  (tope 0.35)
```

La fatiga se recupera a 0.06 por periodo normal. Las horas extra sirven para
un empujón corto de dos o tres periodos; como régimen permanente son la forma
más rápida de superar el techo presupuestal y que el proyecto se cancele.

---

## 9. Valor ganado

```
PV  = BAC × (periodo / periodos_comprometidos)
EV  = BAC × avance_reportado
AC  = costo real acumulado

SPI = EV / PV        CPI = EV / AC
EAC = BAC / CPI      ETC = EAC − AC      VAC = BAC − EAC
TCPI = (BAC − EV) / (BAC − AC)
```

El avance reportado usa las **horas estimadas**, no las reales. Por eso un
paquete puede estar "al 100% de lo estimado" y todavía faltarle trabajo: esa
brecha entre lo que el equipo reporta y lo que realmente falta es el corazón
del ejercicio, y se revela recién en el informe de cierre.

---

## 10. Desenlace

| Condición | Resultado |
|---|---|
| Alcance comprometido terminado dentro del plazo | Entregado |
| Alcance terminado fuera del plazo comprometido | Entregado fuera de plazo |
| Costo real > techo × 1.15, o satisfacción ≤ 8 | Cancelado |
| Se agotan los 12 periodos sin terminar | Cerrado sin completar |

---

## 11. Cómo se verificó la calibración

`test/calibration_test.dart` juega **cientos de partidas completas** con
semillas fijas y un estudiante sintético, y verifica las propiedades que
hacen educativo al simulador:

- Un equipo razonable entrega entre el 35% y el 95% de las veces. Ni imposible
  ni automático.
- Un equipo demasiado pequeño no alcanza.
- Duplicar el equipo no reduce el plazo a la mitad, y sí encarece el proyecto.
- Recortar calidad multiplica los defectos que llegan al cliente.
- El aseguramiento máximo **no** elimina todos los defectos.
- Recortar alcance opcional y tratar los riesgos mejoran la entrega.
- Las horas extra permanentes cuestan más de lo que rinden.
- En requisitos volátiles, el ágil supera al predictivo.
- En alcance estable y regulado, el predictivo supera al ágil.
- La misma semilla produce exactamente el mismo proyecto.

**Si alguna de esas pruebas falla después de tocar un parámetro, el simulador
dejó de enseñar a decidir.** Ese es el propósito de tenerlas.

---

## 12. Limitaciones conocidas

Se declaran porque un modelo que oculta sus supuestos es propaganda:

- **El equipo es intercambiable dentro de su perfil.** No hay especialización
  por dominio: cualquier analista puede trabajar cualquier paquete. Un modelo
  con habilidades por área sería más realista y bastante más complejo de
  operar en una interfaz móvil.
- **Las solicitudes de cambio están guionadas**, no emergen del estado. Se
  eligió así para que sean comparables entre estudiantes con la misma semilla.
- **La calidad es un solo número.** En la práctica hay revisión de código,
  pruebas unitarias, integración y aceptación, con economías distintas.
- **No hay negociación real con el patrocinador.** La satisfacción es un
  marcador, no un interlocutor. Un modo multijugador cubriría ese vacío.
- **Los costos están en soles con valores plausibles de 2025**, no
  auditados contra una encuesta salarial. Sirven para razonar sobre órdenes
  de magnitud, no para cotizar.
