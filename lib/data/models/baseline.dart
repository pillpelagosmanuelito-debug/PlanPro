/// Línea base comprometida al terminar la planificación.
///
/// Es la promesa contra la que se mide todo lo demás: el valor planificado,
/// los índices de desempeño y la evaluación final. Cambiarla después exige
/// una solicitud de cambio aprobada, igual que en la práctica.
class Baseline {
  const Baseline({
    required this.committedPeriods,
    required this.plannedCost,
    required this.contingencyReserve,
    required this.scopeHours,
    required this.qaLevel,
    required this.teamSize,
    required this.committedAtPeriod,
    this.revisions = 0,
  });

  /// Periodos comprometidos ante el patrocinador.
  final int committedPeriods;

  /// Costo planificado del equipo durante esos periodos (sin reserva).
  final double plannedCost;

  /// Reserva de contingencia declarada (S/).
  final double contingencyReserve;

  /// Horas estimadas del alcance comprometido.
  final double scopeHours;

  /// Nivel de aseguramiento comprometido (0-1).
  final double qaLevel;

  final int teamSize;

  /// Periodo en que se comprometió.
  final int committedAtPeriod;

  /// Veces que la línea base fue renegociada formalmente.
  final int revisions;

  /// Presupuesto hasta la conclusión.
  double get budgetAtCompletion => plannedCost + contingencyReserve;

  Baseline copyWith({
    int? committedPeriods,
    double? plannedCost,
    double? contingencyReserve,
    int? revisions,
  }) =>
      Baseline(
        committedPeriods: committedPeriods ?? this.committedPeriods,
        plannedCost: plannedCost ?? this.plannedCost,
        contingencyReserve: contingencyReserve ?? this.contingencyReserve,
        scopeHours: scopeHours,
        qaLevel: qaLevel,
        teamSize: teamSize,
        committedAtPeriod: committedAtPeriod,
        revisions: revisions ?? this.revisions,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'committedPeriods': committedPeriods,
        'plannedCost': plannedCost,
        'contingencyReserve': contingencyReserve,
        'scopeHours': scopeHours,
        'qaLevel': qaLevel,
        'teamSize': teamSize,
        'committedAtPeriod': committedAtPeriod,
        'revisions': revisions,
      };

  factory Baseline.fromJson(Map<String, dynamic> json) => Baseline(
        committedPeriods: (json['committedPeriods'] as num?)?.toInt() ?? 12,
        plannedCost: (json['plannedCost'] as num?)?.toDouble() ?? 0,
        contingencyReserve:
            (json['contingencyReserve'] as num?)?.toDouble() ?? 0,
        scopeHours: (json['scopeHours'] as num?)?.toDouble() ?? 0,
        qaLevel: (json['qaLevel'] as num?)?.toDouble() ?? 0.5,
        teamSize: (json['teamSize'] as num?)?.toInt() ?? 0,
        committedAtPeriod: (json['committedAtPeriod'] as num?)?.toInt() ?? 1,
        revisions: (json['revisions'] as num?)?.toInt() ?? 0,
      );
}
