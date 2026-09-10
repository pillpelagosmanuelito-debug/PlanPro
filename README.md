# Project Management Simulator

Simulador móvil de dirección de proyectos para estudiantes universitarios de
**Administración, Ingeniería y Gestión empresarial**.

El estudiante no responde preguntas sobre PMBOK, Scrum o Agile: **dirige un
proyecto real durante 24 semanas** y descubre en carne propia por qué las
metodologías dicen lo que dicen.

---

## El problema educativo que resuelve

Los estudiantes conocen las metodologías. Pueden recitar los grupos de
procesos, dibujar un tablero Scrum y definir qué es el valor ganado. Lo que no
tienen es **experiencia decidiendo bajo restricciones**, que es lo único que
un empleador les va a pedir.

La distancia entre las dos cosas es enorme y no se cruza con más teoría. Se
cruza tomando decisiones malas en un entorno donde equivocarse no cuesta
dinero real, y viendo la consecuencia dos semanas después.

Este simulador construye exactamente ese entorno:

| Lo que el estudiante decide | Lo que descubre |
|---|---|
| Cuánta gente contratar | Que el equipo grande no es el equipo rápido |
| Qué plazo comprometer | Que una fecha imposible no se vuelve posible por prometerla |
| Cuánto aseguramiento de calidad | Que recortar calidad no ahorra trabajo: lo aplaza y lo multiplica |
| Qué hacer con cada riesgo | Que el riesgo que no identificas ocurre igual, y peor |
| Cómo responder a un cambio de alcance | Que aceptar en silencio es la decisión que más gusta y peor termina |
| Qué metodología usar | Que ninguna es mejor en abstracto |

---

## Los cinco módulos

1. **Inicio del proyecto** — Acta de constitución, restricciones del
   patrocinador, registro inicial de riesgos y estructura de desglose del
   trabajo. Se practica leer un acta buscando supuestos y señales, no solo el
   objetivo.
2. **Planificación** — Equipo, alcance comprometido, nivel de calidad, plazo y
   reserva de contingencia. La pantalla muestra en todo momento la única
   aritmética que importa: alcance ÷ capacidad.
3. **Ejecución** — Doce periodos de dos semanas. Cada periodo: asignar al
   equipo, decidir horas extra, cerrar y leer los indicadores.
4. **Riesgos** — Registro, exposición monetizada, talleres de identificación y
   las cuatro respuestas (mitigar, transferir, aceptar, evitar).
5. **Cierre** — Informe con evaluación por competencias, curva del valor
   ganado y —por fin— la duración real que cada paquete tenía oculta.

---

## Competencias que desarrolla

| Competencia | Cómo se evalúa |
|---|---|
| **Planificación** | Realismo de la línea base comprometida, reserva de contingencia declarada y gestión formal de los cambios |
| **Gestión de recursos** | Utilización de la capacidad pagada, tamaño de equipo, momento de las incorporaciones y uso de horas extra |
| **Gestión de riesgos** | Cobertura del registro, respuestas explícitas y riesgos que golpearon sin haber sido identificados |
| **Gestión del tiempo** | SPI final, cumplimiento del plazo comprometido y capacidad de reaccionar cuando el índice cayó |

---

## Los tres casos

| Caso | Sector | Naturaleza | Enfoque que suele ganar |
|---|---|---|---|
| Sistema de Matrícula Universitaria | Educación superior | Requisitos abiertos, sin supervisión formal | **Ágil** |
| Planta de Tratamiento de Agua | Infraestructura sanitaria | Expediente aprobado, entorno regulado | **Predictivo** |
| Transformación Digital de Cobranzas | Servicios financieros | Requisitos abiertos **y** entorno regulado | **Híbrido** |

Los tres tienen presupuesto, plazo y estructura de trabajo comparables. La
diferencia está en la naturaleza del problema, y esa diferencia es lo que
decide qué metodología conviene. Esto no es una afirmación de diseño: está
verificado con pruebas automatizadas que juegan cientos de partidas
(`test/calibration_test.dart`).

---

## El asistente de dirección de proyectos

La aplicación incluye un asistente que analiza el estado y recomienda
acciones. Es un **sistema experto basado en reglas**, no un modelo
generativo, y la decisión es deliberada:

1. **Auditabilidad.** Cada consejo se rastrea hasta una regla con nombre,
   umbral y fundamento. Un estudiante puede discutir la regla; no puede
   discutir una caja negra.
2. **Honestidad epistémica.** El asistente lee *exactamente* lo que lee el
   estudiante: estimaciones, avance reportado e indicadores. **Nunca** consulta
   la duración real oculta ni los riesgos no identificados. Si supiera el
   futuro, el simulador dejaría de entrenar la competencia que quiere
   entrenar: decidir con información incompleta. Hay una prueba automatizada
   que verifica esta propiedad.
3. **Disponibilidad.** Funciona sin conexión, sin costo por consulta y con
   latencia cero — condiciones necesarias para un aula peruana promedio.

---

## Instalación y ejecución

Requisitos: **Flutter 3.24+** (Dart 3.3+).

```bash
flutter pub get
flutter test          # 8 suites de pruebas
flutter analyze
flutter run
```

### Construir el APK

```bash
python3 -m pip install Pillow      # solo para generar el ícono
python3 tool/generate_icon.py
bash tool/prepare_android.sh       # genera android/ y aplica ícono y nombre
flutter build apk --release
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`.

> La carpeta `android/` **no está versionada**: son cientos de archivos que
> Flutter regenera de forma determinista. `tool/prepare_android.sh` la
> reconstruye y vuelve a aplicar lo único que sí es del proyecto:
> `applicationId`, nombre visible e ícono.

### Integración continua

`.github/workflows/ci.yml` define tres etapas:

| Etapa | Qué hace |
|---|---|
| `quality` | `flutter analyze` + `flutter test` |
| `android` | Genera el ícono, prepara la plataforma y construye el APK como artefacto |
| `release` | Con una etiqueta `v*`, publica el APK en un release de GitHub |

Para publicar una versión:

```bash
git tag v1.0.0 && git push origin v1.0.0
```

---

## Arquitectura

Patrón **MVVM**, con una sola dependencia externa (`shared_preferences`).

```
lib/
├── core/                  Tema y formateo
├── data/
│   ├── models/            Dominio puro, sin Flutter
│   ├── services/          Motores de simulación
│   └── repositories/      Punto único de acceso al dominio
├── viewmodels/            ChangeNotifier que traduce intenciones
└── views/                 Pantallas, pestañas y widgets
```

El flujo es estrictamente unidireccional:

```
View → ViewModel → Repository → Services → Models
  ↑                                            │
  └──────────── notifyListeners() ─────────────┘
```

Los motores de simulación son **funciones del estado**: reciben el estado y lo
transforman, sin conocer Flutter ni el almacenamiento. Por eso se pueden
probar jugando partidas completas sin interfaz.

Documentación detallada en [`docs/`](docs/):

- [`01_diseno_educativo.md`](docs/01_diseno_educativo.md) — Qué enseña y por qué
- [`02_arquitectura.md`](docs/02_arquitectura.md) — Estructura técnica y decisiones
- [`03_modelo_de_simulacion.md`](docs/03_modelo_de_simulacion.md) — Toda la matemática, con su fundamento
- [`04_guia_docente.md`](docs/04_guia_docente.md) — Cómo usarlo en clase

---

## Semillas: el mismo proyecto para toda la clase

Cada partida se genera a partir de una semilla. **Con la misma semilla, las
duraciones reales ocultas y los riesgos son idénticos para todos.** Las
diferencias de resultado se explican entonces por cómo se dirigió, no por
cómo fue la suerte — que es la condición para poder comparar y discutir en
clase.

---

## Estado del proyecto

Aplicación **completa y funcional**: 5 módulos, 3 casos, 3 metodologías,
motor de simulación calibrado, asistente de 24 reglas, evaluación por
competencias, persistencia local e integración continua.

Lo que **no** está incluido y sería el siguiente paso natural:

- Panel docente para comparar resultados de un aula
- Casos adicionales por carrera (minería, ambiental, electrónica)
- Exportación del informe de cierre a PDF
- Modo multijugador para negociar entre roles (director, patrocinador, cliente)

---

## Licencia

MIT. Ver [`LICENSE`](LICENSE).
