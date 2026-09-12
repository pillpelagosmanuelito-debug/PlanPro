import 'dart:math' as math;

import 'baseline.dart';
import 'change_request.dart';
import 'evm_snapshot.dart';
import 'methodology.dart';
import 'project_case.dart';
import 'project_config.dart';
import 'risk_item.dart';
import 'team_member.dart';
import 'work_package.dart';

/// Etapa del simulador en que se encuentra el estudiante.
enum ProjectStage {
  initiation,
  planning,
  execution,
  closure;

  String get label {
    switch (this) {
      case ProjectStage.initiation:
        return 'Inicio';
      case ProjectStage.planning:
        return 'Planificación';
      case ProjectStage.execution:
        return 'Ejecución';
      case ProjectStage.closure:
        return 'Cierre';
    }
  }

  static ProjectStage fromName(String? name) => ProjectStage.values.firstWhere(
        (ProjectStage s) => s.name == name,
        orElse: () => ProjectStage.initiation,
      );
}

/// Desenlace del proyecto.
enum ProjectOutcome {
  running,
  delivered,
  deliveredLate,
  cancelled,
  abandoned;

  String get label {
    switch (this) {
      case ProjectOutcome.running:
        return 'En ejecución';
      case ProjectOutcome.delivered:
        return 'Entregado';
      case ProjectOutcome.deliveredLate:
        return 'Entregado fuera de plazo';
      case ProjectOutcome.cancelled:
        return 'Cancelado por el patrocinador';
      case ProjectOutcome.abandoned:
        return 'Cerrado sin completar';
    }
  }

  bool get isFinished => this != ProjectOutcome.running;

  static ProjectOutcome fromName(String? name) =>
      ProjectOutcome.values.firstWhere(
        (ProjectOutcome o) => o.name == name,
        orElse: () => ProjectOutcome.running,
      );
}

/// Estado completo del proyecto dirigido por el estudiante.
class ProjectState {
  ProjectState({
    required this.caseId,
    required this.stage,
    required this.period,
    required this.methodology,
    required this.priority,
    required this.qaLevel,
    required this.packages,
    required this.team,
    required this.risks,
    required this.changes,
    required this.snapshots,
    this.baseline,
    this.actualCost = 0,
    this.sponsorSatisfaction = 70,
    this.fatigue = 0,
    this.latentDefects = 0,
    this.escapedDefects = 0,
    this.reserveUsed = 0,
    this.riskWorkshops = 0,
    this.outcome = ProjectOutcome.running,
    this.overtimePeriods = 0,
    this.nextMemberIndex = 1,
  });

  final String caseId;

  ProjectStage stage;

  /// Periodo en curso (1 = primera quincena de ejecución).
  int period;

  Methodology methodology;
  ConstraintPriority priority;

  /// Nivel de aseguramiento de calidad (0-1).
  double qaLevel;

  final List<WorkPackage> packages;
  final List<TeamMember> team;
  final List<RiskItem> risks;
  final List<ChangeRequest> changes;

  /// Historial de indicadores por periodo.
  final List<EvmSnapshot> snapshots;

  Baseline? baseline;

  /// Costo real acumulado.
  double actualCost;

  /// Satisfacción del patrocinador (0-100).
  double sponsorSatisfaction;

  /// Fatiga acumulada por horas extra (0-1).
  double fatigue;

  /// Defectos aún no detectados.
  double latentDefects;

  /// Defectos que llegaron al cliente.
  double escapedDefects;

  /// Reserva de contingencia consumida.
  double reserveUsed;

  /// Talleres de identificación de riesgos realizados.
  int riskWorkshops;

  ProjectOutcome outcome;

  /// Periodos con horas extra autorizadas.
  int overtimePeriods;

  int nextMemberIndex;

  ProjectCase get projectCase => ProjectCase.byId(caseId);

  List<WorkPackage> get includedPackages =>
      packages.where((WorkPackage p) => p.included).toList();

  double get scopeEstimatedHours {
    double total = 0;
    for (final WorkPackage p in includedPackages) {
      total += p.estimatedHours;
    }
    return total;
  }

  double get earnedHours {
    double total = 0;
    for (final WorkPackage p in includedPackages) {
      total += p.earnedHours;
    }
    return total;
  }

  /// Avance físico del alcance comprometido (0-1).
  double get progress {
    final double scope = scopeEstimatedHours;
    return scope <= 0 ? 0.0 : (earnedHours / scope).clamp(0.0, 1.0).toDouble();
  }

  bool get isComplete =>
      includedPackages.every((WorkPackage p) => p.isDone);

  /// Costo del equipo por periodo, con la plantilla actual.
  double teamCostPerPeriod() {
    double total = 0;
    for (final TeamMember m in team) {
      total += m.role.costPerPeriod;
    }
    return total;
  }

  /// Capacidad efectiva del equipo en horas para el periodo en curso.
  double effectiveCapacity(ProjectConfig config, {bool overtime = false}) {
    if (team.isEmpty) return 0;
    double raw = 0;
    int newcomers = 0;
    for (final TeamMember m in team) {
      raw += m.effectiveHours(config.hoursPerPerson);
      if (m.isNewcomer) newcomers++;
    }
    final double mentoring = 1 -
        config.mentoringPenaltyPerNewcomer *
            math.min(newcomers, config.maxMentoringNewcomers);
    final double governance =
        1 - methodology.governanceOverhead(regulated: projectCase.regulated);
    double capacity = raw *
        config.teamEfficiency(team.length) *
        mentoring *
        governance *
        (1 - qaLevel * config.qaCapacityCost) *
        (1 - fatigue);
    if (overtime) capacity *= 1 + config.overtimeCapacityGain;
    return math.max(0, capacity);
  }

  /// Paquetes habilitados para trabajar según las dependencias de fase.
  List<WorkPackage> availablePackages() {
    final List<WorkPackage> out = <WorkPackage>[];
    for (final ProjectPhase phase in ProjectPhase.values) {
      if (!phaseUnlocked(phase)) continue;
      out.addAll(includedPackages.where(
          (WorkPackage p) => p.phase == phase && !p.isDone));
    }
    return out;
  }

  /// Si una fase está habilitada por el avance de las anteriores.
  bool phaseUnlocked(ProjectPhase phase) {
    final List<WorkPackage> previous = includedPackages
        .where((WorkPackage p) => p.phase.order < phase.order)
        .toList();
    if (previous.isEmpty) return true;
    double estimated = 0;
    double earned = 0;
    for (final WorkPackage p in previous) {
      estimated += p.estimatedHours;
      earned += p.earnedHours;
    }
    if (estimated <= 0) return true;
    return earned / estimated >= phase.gate - 1e-9;
  }

  /// Avance de una fase (0-1).
  double phaseProgress(ProjectPhase phase) {
    final List<WorkPackage> list = includedPackages
        .where((WorkPackage p) => p.phase == phase)
        .toList();
    if (list.isEmpty) return 1.0;
    double estimated = 0;
    double earned = 0;
    for (final WorkPackage p in list) {
      estimated += p.estimatedHours;
      earned += p.earnedHours;
    }
    return estimated <= 0 ? 1.0 : earned / estimated;
  }

  /// Riesgos identificados por el estudiante.
  List<RiskItem> get identifiedRisks =>
      risks.where((RiskItem r) => r.identified).toList();

  /// Exposición total al riesgo, monetizada.
  double riskExposure(double hourValue) {
    double total = 0;
    for (final RiskItem r in identifiedRisks) {
      if (r.occurred) continue;
      total += r.exposure(hourValue);
    }
    return total;
  }

  /// Valor monetario aproximado de una hora de equipo.
  double hourValue(ProjectConfig config) {
    if (team.isEmpty) return 60;
    final double capacity = team.length * config.hoursPerPerson;
    return capacity <= 0 ? 60 : teamCostPerPeriod() / capacity;
  }

  List<ChangeRequest> get pendingChanges =>
      changes.where((ChangeRequest c) => c.isPending).toList();

  WorkPackage? packageById(String? id) {
    if (id == null) return null;
    for (final WorkPackage p in packages) {
      if (p.id == id) return p;
    }
    return null;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'caseId': caseId,
        'stage': stage.name,
        'period': period,
        'methodology': methodology.name,
        'priority': priority.name,
        'qaLevel': qaLevel,
        'packages': packages.map((WorkPackage p) => p.toJson()).toList(),
        'team': team.map((TeamMember m) => m.toJson()).toList(),
        'risks': risks.map((RiskItem r) => r.toJson()).toList(),
        'changes': changes.map((ChangeRequest c) => c.toJson()).toList(),
        'snapshots': snapshots.map((EvmSnapshot s) => s.toJson()).toList(),
        'baseline': baseline?.toJson(),
        'actualCost': actualCost,
        'sponsorSatisfaction': sponsorSatisfaction,
        'fatigue': fatigue,
        'latentDefects': latentDefects,
        'escapedDefects': escapedDefects,
        'reserveUsed': reserveUsed,
        'riskWorkshops': riskWorkshops,
        'outcome': outcome.name,
        'overtimePeriods': overtimePeriods,
        'nextMemberIndex': nextMemberIndex,
      };

  static double _num(Map<String, dynamic> j, String k, double d) {
    final Object? v = j[k];
    return v is num ? v.toDouble() : d;
  }

  factory ProjectState.fromJson(Map<String, dynamic> json) {
    final Object? rawBaseline = json['baseline'];
    return ProjectState(
      caseId: json['caseId'] as String? ?? 'matricula',
      stage: ProjectStage.fromName(json['stage'] as String?),
      period: (json['period'] as num?)?.toInt() ?? 1,
      methodology: Methodology.fromName(json['methodology'] as String?),
      priority: ConstraintPriority.fromName(json['priority'] as String?),
      qaLevel: _num(json, 'qaLevel', 0.5),
      packages: ((json['packages'] as List<dynamic>?) ?? <dynamic>[])
          .map((dynamic e) =>
              WorkPackage.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      team: ((json['team'] as List<dynamic>?) ?? <dynamic>[])
          .map((dynamic e) =>
              TeamMember.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      risks: ((json['risks'] as List<dynamic>?) ?? <dynamic>[])
          .map((dynamic e) =>
              RiskItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      changes: ((json['changes'] as List<dynamic>?) ?? <dynamic>[])
          .map((dynamic e) =>
              ChangeRequest.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      snapshots: ((json['snapshots'] as List<dynamic>?) ?? <dynamic>[])
          .map((dynamic e) =>
              EvmSnapshot.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      baseline: rawBaseline is Map
          ? Baseline.fromJson(Map<String, dynamic>.from(rawBaseline))
          : null,
      actualCost: _num(json, 'actualCost', 0),
      sponsorSatisfaction: _num(json, 'sponsorSatisfaction', 70),
      fatigue: _num(json, 'fatigue', 0),
      latentDefects: _num(json, 'latentDefects', 0),
      escapedDefects: _num(json, 'escapedDefects', 0),
      reserveUsed: _num(json, 'reserveUsed', 0),
      riskWorkshops: (json['riskWorkshops'] as num?)?.toInt() ?? 0,
      outcome: ProjectOutcome.fromName(json['outcome'] as String?),
      overtimePeriods: (json['overtimePeriods'] as num?)?.toInt() ?? 0,
      nextMemberIndex: (json['nextMemberIndex'] as num?)?.toInt() ?? 1,
    );
  }
}
