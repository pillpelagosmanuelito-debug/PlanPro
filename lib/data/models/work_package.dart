import 'project_case.dart';

/// Paquete de trabajo en ejecucion.
///
/// El estudiante ve [estimatedHours]; [realHours] es la duracion verdadera y
/// permanece oculta: se descubre trabajando, igual que en un proyecto real.
class WorkPackage {
  WorkPackage({
    required this.id,
    required this.name,
    required this.phase,
    required this.estimatedHours,
    required this.realHours,
    required this.complexity,
    required this.optional,
    required this.detail,
    this.workedHours = 0,
    this.included = true,
    this.defects = 0,
    this.reworkHours = 0,
  });

  final String id;
  final String name;
  final ProjectPhase phase;

  /// Horas que el equipo estimo al planificar.
  final double estimatedHours;

  /// Horas reales necesarias (oculta durante la partida).
  double realHours;

  final double complexity;
  final bool optional;
  final String detail;

  /// Horas efectivamente trabajadas.
  double workedHours;

  /// Si forma parte del alcance comprometido.
  bool included;

  /// Defectos generados al terminar el paquete.
  double defects;

  /// Horas de retrabajo que se le agregaron por defectos detectados.
  double reworkHours;

  bool get isDone => workedHours >= realHours - 1e-6;

  /// Avance fisico real (0-1).
  double get progress =>
      realHours <= 0 ? 1.0 : (workedHours / realHours).clamp(0.0, 1.0).toDouble();

  /// Horas que faltan segun la duracion real.
  double get remainingHours =>
      (realHours - workedHours) < 0 ? 0.0 : realHours - workedHours;

  /// Avance que el equipo reporta, expresado sobre la estimacion original.
  ///
  /// Es el numero con el que se calcula el valor ganado: por eso un paquete
  /// puede estar "al 100% de lo estimado" y aun asi no estar terminado.
  double get earnedHours => progress * estimatedHours;

  factory WorkPackage.fromSpec(PackageSpec spec, double realHours) =>
      WorkPackage(
        id: spec.id,
        name: spec.name,
        phase: spec.phase,
        estimatedHours: spec.estimatedHours,
        realHours: realHours,
        complexity: spec.complexity,
        optional: spec.optional,
        detail: spec.detail,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'phase': phase.name,
        'estimatedHours': estimatedHours,
        'realHours': realHours,
        'complexity': complexity,
        'optional': optional,
        'detail': detail,
        'workedHours': workedHours,
        'included': included,
        'defects': defects,
        'reworkHours': reworkHours,
      };

  static double _num(Map<String, dynamic> j, String k, double d) {
    final Object? v = j[k];
    return v is num ? v.toDouble() : d;
  }

  factory WorkPackage.fromJson(Map<String, dynamic> json) => WorkPackage(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        phase: ProjectPhase.fromName(json['phase'] as String?),
        estimatedHours: _num(json, 'estimatedHours', 100),
        realHours: _num(json, 'realHours', 110),
        complexity: _num(json, 'complexity', 1),
        optional: json['optional'] == true,
        detail: json['detail'] as String? ?? '',
        workedHours: _num(json, 'workedHours', 0),
        included: json['included'] != false,
        defects: _num(json, 'defects', 0),
        reworkHours: _num(json, 'reworkHours', 0),
      );
}
