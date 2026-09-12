/// Parámetros del simulador de proyectos.
///
/// Centralizados para que el docente ajuste dificultad (plazo, presupuesto,
/// costos del equipo, penalizaciones) sin tocar la lógica del motor.
class ProjectConfig {
  const ProjectConfig({
    this.totalPeriods = 12,
    this.weeksPerPeriod = 2,
    this.hoursPerPerson = 80,
    this.communicationOverhead = 0.007,
    this.communicationOverheadSquared = 0.018,
    this.mentoringPenaltyPerNewcomer = 0.14,
    this.maxMentoringNewcomers = 3,
    this.qaCapacityCost = 0.14,
    this.defectRatePerHour = 0.030,
    this.qaDefectReduction = 0.70,
    this.directEscapeShare = 0.30,
    this.detectionSlope = 1.6,
    this.detectionCap = 0.95,
    this.escapeFloor = 0.5,
    this.reworkCoefficient = 0.60,
    this.lateFixMultiplier = 8.0,
    this.overtimeCapacityGain = 0.25,
    this.overtimeCostFactor = 1.6,
    this.overtimeFatigue = 0.12,
    this.fatigueRecovery = 0.06,
    this.estimationBias = 1.11,
    this.estimationSpread = 0.20,
    this.contingencyMax = 0.20,
    this.escalationSatisfactionCost = 12.0,
  });

  /// Periodos del proyecto (quincenas).
  final int totalPeriods;
  final int weeksPerPeriod;

  /// Horas disponibles por persona y periodo.
  final double hoursPerPerson;

  /// Penalización de comunicación por cada integrante adicional.
  ///
  /// Con n personas hay n(n-1)/2 canales de comunicación, así que el costo de
  /// coordinación no crece de forma lineal sino cuadrática. El simulador usa
  /// las dos componentes para reproducir esa curva: la lineal domina en
  /// equipos pequeños y la cuadrática hace que a partir de siete u ocho
  /// personas cada incorporación aporte cada vez menos.
  final double communicationOverhead;
  final double communicationOverheadSquared;

  /// Caída de productividad del equipo por cada persona en curva de aprendizaje.
  final double mentoringPenaltyPerNewcomer;
  final int maxMentoringNewcomers;

  /// Capacidad que consume el aseguramiento de calidad, al máximo nivel.
  final double qaCapacityCost;

  /// Defectos generados por hora estimada cuando no hay aseguramiento.
  final double defectRatePerHour;

  /// Cuanto reduce los defectos el aseguramiento al máximo nivel.
  ///
  /// No llega a 1: ninguna cantidad de control elimina todos los defectos, y
  /// modelarlo así evitaría la decisión (siempre convendría el máximo).
  final double qaDefectReduction;

  /// Fracción de defectos que escapa directamente al cliente sin pasar por
  /// pruebas, cuando no hay aseguramiento.
  ///
  /// Es la diferencia práctica entre un defecto caro y un defecto invisible:
  /// sin control, una parte no se detecta nunca dentro del proyecto.
  final double directEscapeShare;

  /// Curva de detección durante pruebas: cuanto más avanzada está la fase,
  /// mayor la fracción de defectos latentes que aparece.
  final double detectionSlope;
  final double detectionCap;

  /// Por debajo de este número de defectos latentes, el resto se considera
  /// escapado al cliente y deja de generar retrabajo.
  final double escapeFloor;

  /// Cuanto del factor de retrabajo de la metodología se traduce en trabajo
  /// real adicional.
  final double reworkCoefficient;

  /// Horas de retrabajo por defecto corregido tarde (regla del 1-10-100).
  final double lateFixMultiplier;

  /// Efecto de las horas extra.
  final double overtimeCapacityGain;
  final double overtimeCostFactor;
  final double overtimeFatigue;
  final double fatigueRecovery;

  /// Sesgo y dispersión de la estimación frente a la duración real.
  final double estimationBias;
  final double estimationSpread;

  /// Reserva de contingencia máxima admitida sobre la línea base.
  final double contingencyMax;

  /// Puntos de satisfacción que cuesta escalar al patrocinador.
  final double escalationSatisfactionCost;

  int get totalWeeks => totalPeriods * weeksPerPeriod;

  /// Eficiencia del equipo según su tamaño.
  ///
  /// Un equipo de cinco conserva cerca del 76% de su capacidad nominal; uno de
  /// nueve, apenas el 45%. La caída se acelera con el tamaño porque los
  /// canales de comunicación crecen con el cuadrado del equipo, no en línea
  /// recta. Por eso duplicar el equipo no duplica la velocidad, y a partir de
  /// cierto punto solo duplica la planilla.
  double teamEfficiency(int size) {
    final int k = (size - 1).clamp(0, 99);
    return 1 /
        (1 + communicationOverhead * k + communicationOverheadSquared * k * k);
  }
}

/// Textos del encuadre inicial.
class ProjectBriefing {
  const ProjectBriefing._();

  static const String mandate =
      'Te nombran gerente del proyecto. El patrocinador fija un plazo, un '
      'presupuesto y un alcance mínimo; lo demás lo decides tú. Nadie te '
      'pedirá que recites una metodología: te pedirán resultados dentro de '
      'las restricciones.';

  static const List<String> rules = <String>[
    'El proyecto dura 12 periodos de 2 semanas: 24 semanas de calendario.',
    'Las estimaciones del equipo son optimistas: la duración real se descubre trabajando.',
    'Cada periodo asignas a cada persona un paquete de trabajo; lo no asignado no avanza.',
    'Las fases tienen dependencias: no puedes construir sin diseño suficiente.',
    'Sumar gente a mitad del proyecto cuesta curva de aprendizaje y comunicación.',
    'Recortar aseguramiento acelera hoy y multiplica el retrabajo después.',
    'Los riesgos que no identificas no desaparecen: ocurren sin aviso.',
    'Al cerrar se comparan tus resultados contra la línea base que tú comprometiste.',
  ];
}
