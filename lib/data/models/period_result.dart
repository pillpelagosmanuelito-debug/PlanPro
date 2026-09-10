import 'evm_snapshot.dart';

/// Trabajo aplicado a un paquete durante el periodo.
class PackageProgress {
  const PackageProgress({
    required this.packageId,
    required this.packageName,
    required this.hoursApplied,
    required this.progressAfter,
    required this.completed,
  });

  final String packageId;
  final String packageName;
  final double hoursApplied;
  final double progressAfter;
  final bool completed;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'packageId': packageId,
        'packageName': packageName,
        'hoursApplied': hoursApplied,
        'progressAfter': progressAfter,
        'completed': completed,
      };

  factory PackageProgress.fromJson(Map<String, dynamic> json) =>
      PackageProgress(
        packageId: json['packageId'] as String? ?? '',
        packageName: json['packageName'] as String? ?? '',
        hoursApplied: (json['hoursApplied'] as num?)?.toDouble() ?? 0,
        progressAfter: (json['progressAfter'] as num?)?.toDouble() ?? 0,
        completed: json['completed'] == true,
      );
}

/// Resultado de cerrar un periodo de ejecucion.
class PeriodResult {
  const PeriodResult({
    required this.period,
    required this.capacity,
    required this.appliedHours,
    required this.wastedHours,
    required this.periodCost,
    required this.overtime,
    required this.progressByPackage,
    required this.completedPackages,
    required this.risksTriggered,
    required this.defectsFound,
    required this.reworkHours,
    required this.newChanges,
    required this.evm,
  });

  final int period;

  /// Capacidad disponible del equipo en horas.
  final double capacity;

  /// Horas efectivamente aplicadas a paquetes habilitados.
  final double appliedHours;

  /// Horas perdidas por asignaciones invalidas o falta de trabajo disponible.
  final double wastedHours;

  final double periodCost;
  final bool overtime;

  final List<PackageProgress> progressByPackage;
  final List<String> completedPackages;

  /// Riesgos que se materializaron en el periodo.
  final List<String> risksTriggered;

  /// Defectos detectados durante pruebas.
  final double defectsFound;

  /// Horas de retrabajo agregadas por esos defectos.
  final double reworkHours;

  /// Solicitudes de cambio aparecidas en el periodo.
  final List<String> newChanges;

  final EvmSnapshot evm;

  double get utilization => capacity <= 0 ? 0.0 : appliedHours / capacity;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'period': period,
        'capacity': capacity,
        'appliedHours': appliedHours,
        'wastedHours': wastedHours,
        'periodCost': periodCost,
        'overtime': overtime,
        'progressByPackage':
            progressByPackage.map((PackageProgress p) => p.toJson()).toList(),
        'completedPackages': completedPackages,
        'risksTriggered': risksTriggered,
        'defectsFound': defectsFound,
        'reworkHours': reworkHours,
        'newChanges': newChanges,
        'evm': evm.toJson(),
      };

  factory PeriodResult.fromJson(Map<String, dynamic> json) => PeriodResult(
        period: (json['period'] as num?)?.toInt() ?? 1,
        capacity: (json['capacity'] as num?)?.toDouble() ?? 0,
        appliedHours: (json['appliedHours'] as num?)?.toDouble() ?? 0,
        wastedHours: (json['wastedHours'] as num?)?.toDouble() ?? 0,
        periodCost: (json['periodCost'] as num?)?.toDouble() ?? 0,
        overtime: json['overtime'] == true,
        progressByPackage:
            ((json['progressByPackage'] as List<dynamic>?) ?? <dynamic>[])
                .map((dynamic e) =>
                    PackageProgress.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList(),
        completedPackages:
            ((json['completedPackages'] as List<dynamic>?) ?? <dynamic>[])
                .map((dynamic e) => e.toString())
                .toList(),
        risksTriggered: ((json['risksTriggered'] as List<dynamic>?) ?? <dynamic>[])
            .map((dynamic e) => e.toString())
            .toList(),
        defectsFound: (json['defectsFound'] as num?)?.toDouble() ?? 0,
        reworkHours: (json['reworkHours'] as num?)?.toDouble() ?? 0,
        newChanges: ((json['newChanges'] as List<dynamic>?) ?? <dynamic>[])
            .map((dynamic e) => e.toString())
            .toList(),
        evm: EvmSnapshot.fromJson(
          Map<String, dynamic>.from(json['evm'] as Map),
        ),
      );
}
