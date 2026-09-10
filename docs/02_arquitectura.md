# Arquitectura

## 1. Estructura

```
lib/
├── main.dart                      Arranque y enrutado por etapa
├── core/
│   ├── app_theme.dart             Paleta y tema
│   └── formatters.dart            Formato de moneda, horas, porcentajes
├── data/
│   ├── models/                    Dominio puro — no importa Flutter
│   │   ├── project_config.dart    Todos los parámetros del simulador
│   │   ├── project_case.dart      Los tres casos y su EDT
│   │   ├── methodology.dart       PMBOK / Scrum / Híbrido y sus efectos
│   │   ├── work_package.dart      Paquete con duración real oculta
│   │   ├── team_member.dart       Perfiles y curva de aprendizaje
│   │   ├── risk_item.dart         Catálogo de riesgos y respuestas
│   │   ├── change_request.dart    Solicitudes y decisiones posibles
│   │   ├── baseline.dart          Línea base comprometida
│   │   ├── evm_snapshot.dart      Valor ganado de un periodo
│   │   ├── period_result.dart     Resultado de cerrar un periodo
│   │   ├── evaluation_report.dart Informe por competencias
│   │   ├── project_state.dart     Estado completo del proyecto
│   │   ├── project_session.dart   Partida = estado + historia + semilla
│   │   └── advisor_message.dart   Mensaje del asistente
│   ├── services/                  Motores — funciones del estado
│   │   ├── project_generator.dart Genera el proyecto desde una semilla
│   │   ├── execution_engine.dart  Ejecuta un periodo
│   │   ├── risk_engine.dart       Dispara riesgos y talleres
│   │   ├── evm_calculator.dart    Instrumental de medición
│   │   ├── pm_advisor.dart        Sistema experto de 24 reglas
│   │   ├── evaluation_service.dart Informe de cierre
│   │   └── local_storage_service.dart Persistencia JSON
│   └── repositories/
│       └── project_repository.dart Punto único de acceso al dominio
├── viewmodels/
│   └── project_viewmodel.dart     ChangeNotifier: traduce intenciones
└── views/
    ├── app_scope.dart             Inyección con InheritedNotifier
    ├── screens/                   Inicio, caso, acta, planificación,
    │                              ejecución, cierre, guía, historial
    ├── tabs/                      Tablero, equipo, alcance, riesgos, asistente
    └── widgets/                   Tarjetas, indicadores, curva S, hojas
```

## 2. MVVM y flujo de datos

```
   View  ──intención──►  ViewModel  ──llamada──►  Repository
     ▲                                                │
     │                                                ▼
     └────────── notifyListeners() ──────────  Services → Models
```

Reglas que se respetan sin excepción:

1. **Las vistas no conocen los motores ni el almacenamiento.** Solo hablan con
   el ViewModel.
2. **El ViewModel no contiene reglas del negocio.** Traduce "el usuario tocó
   cerrar periodo" en una llamada al repositorio y notifica.
3. **Los modelos no importan Flutter.** Se pueden probar sin binding gráfico.
4. **Los motores son funciones del estado.** Reciben el estado, lo
   transforman, devuelven el resultado. No conocen persistencia ni interfaz.

La consecuencia práctica: `test/calibration_test.dart` juega cientos de
partidas completas **sin instanciar un solo widget**. Si la lógica viviera en
las pantallas, esa verificación sería imposible.

## 3. Por qué `InheritedNotifier` y no un paquete de estado

El MVP tiene **una sola dependencia externa**: `shared_preferences`.

`InheritedNotifier<ProjectViewModel>` da exactamente lo necesario —inyección
en el árbol y reconstrucción al notificar— en 25 líneas. Agregar Provider,
Riverpod o BLoC habría sumado una dependencia, una curva de aprendizaje para
quien mantenga el código y ninguna capacidad que este proyecto use.

Cuando la aplicación crezca a varios ViewModels con dependencias entre sí, el
cambio a Provider es mecánico: `AppScope.of(context)` pasa a ser
`context.watch<ProjectViewModel>()` y nada más se toca.

## 4. Persistencia

`LocalStorageService` guarda tres cosas en `shared_preferences`:

| Clave | Contenido |
|---|---|
| `pms_current_session` | La partida en curso, completa, como JSON |
| `pms_finished_sessions` | Hasta 20 resúmenes de partidas cerradas |
| `pms_seen_intro` | Si ya se mostró la introducción |

Se guarda **después de cada decisión**, no solo al cerrar periodo: cerrar la
aplicación a mitad de una asignación no pierde nada.

Un guardado corrupto se descarta en silencio y la aplicación arranca limpia.
Es preferible perder una partida a dejar la aplicación en un estado que no
arranca.

**Por qué JSON y no SQLite.** El estado completo de una partida ocupa unos
30 KB. Una base de datos relacional agregaría una dependencia, migraciones y
esquema para resolver un problema que no existe. El aislamiento tras
`LocalStorageService` hace que migrar más adelante sea local.

## 5. La carpeta `android/` no está versionada

Flutter genera cientos de archivos deterministas. Versionarlos produce diffs
ilegibles y conflictos de merge sin contenido.

`tool/prepare_android.sh` regenera la plataforma y vuelve a aplicar lo único
que sí es del proyecto:

- `applicationId` y `namespace`: `pe.edu.simulador.project_management_simulator`
- Nombre visible: `PM Simulator`
- Ícono, desde `android_icons/`

El script respalda `lib/`, `test/`, `pubspec.yaml` y `analysis_options.yaml`
antes de invocar `flutter create --overwrite`, y los restaura después,
incluso si algo falla a mitad de camino (`trap`).

## 6. El ícono se genera por código

`tool/generate_icon.py` dibuja el ícono con Pillow y exporta las cinco
densidades de Android.

**Por qué no un PNG en el repositorio.** Un binario no se puede revisar en un
diff. Un script sí: quien lo lea entiende por qué el ícono es un diagrama de
Gantt con la barra crítica en ámbar, y puede cambiarlo sin abrir un editor
gráfico. El centrado se calcula sobre el *bounding box* real del contenido,
así que ajustar las coordenadas no descuadra la composición.

## 7. Compatibilidad de versiones

El código evita deliberadamente las API que cambiaron de tipo entre versiones
del canal estable de Flutter:

- Se usa `Color.withOpacity` y no `withValues` (esta última no existe en 3.19).
- Se usa `DropdownButtonFormField(value:)` y no `initialValue:` (esta última
  se agregó en 3.35).
- No se usa `CardTheme`, cuyo tipo cambió.

`analysis_options.yaml` silencia `deprecated_member_use` por esta razón, y
degrada los avisos de código no usado a informativos para que no rompan la
integración continua durante el desarrollo.

Un detalle de Dart que se cuidó en todo el código: **`num.clamp()` devuelve
`num`, no `double`**. Cada uso en un contexto que exige `double` —como
`Positioned(left:)` o un ancho— lleva `.toDouble()` explícito. Es el tipo de
error que solo aparece al compilar y que cuesta un ciclo entero de CI.

## 8. Pruebas

| Archivo | Qué verifica |
|---|---|
| `calibration_test.dart` | Que ninguna estrategia trivial gane y que cada metodología gane en su caso |
| `execution_engine_test.dart` | Conservación de capacidad, derrame, horas extra, retrabajo, desenlaces, cambios |
| `risk_engine_test.dart` | Respuestas, ventanas, talleres, exposición |
| `evm_calculator_test.dart` | Toda la matemática del valor ganado |
| `evaluation_service_test.dart` | Rangos, evidencia y penalizaciones del informe |
| `team_capacity_test.dart` | Ley de Brooks, curva de aprendizaje, gobernanza |
| `pm_advisor_test.dart` | Que las reglas disparen y que el asistente no vea datos ocultos |
| `persistence_test.dart` | Ida y vuelta por JSON sin pérdida |
| `widget_test.dart` | Arranque, navegación y widgets con datos límite |

`test/support/simulation_harness.dart` provee un "estudiante sintético" que
juega partidas completas con una estrategia declarativa. Es lo que hace
posible verificar la calibración de forma automática y no a ojo.

## 9. Decisiones que se tomaron y su alternativa descartada

| Decisión | Alternativa descartada | Razón |
|---|---|---|
| Sistema experto de reglas | Modelo de lenguaje | Auditabilidad, offline, costo cero, y no puede ver datos ocultos |
| Motor determinista por semilla | Aleatoriedad libre | Sin comparabilidad no hay discusión de aula |
| JSON en `shared_preferences` | SQLite | 30 KB no justifican esquema ni migraciones |
| `InheritedNotifier` | Provider / BLoC | Una dependencia menos, misma capacidad |
| `android/` regenerada | Versionada | Diffs legibles |
| Ícono por código | PNG binario | Revisable en un diff |
| 12 periodos de 2 semanas | 24 periodos semanales | Una partida debe caber en una sesión de clase |
