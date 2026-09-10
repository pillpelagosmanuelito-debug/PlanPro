import 'package:project_management_simulator/data/models/methodology.dart';
import 'package:project_management_simulator/data/models/period_result.dart';
import 'package:project_management_simulator/data/models/project_config.dart';
import 'package:project_management_simulator/data/models/project_state.dart';
import 'package:project_management_simulator/data/models/risk_item.dart';
import 'package:project_management_simulator/data/models/work_package.dart';
import 'package:project_management_simulator/data/repositories/project_repository.dart';
import 'package:project_management_simulator/data/services/project_generator.dart';

/// Estrategia que un "estudiante sintetico" aplica para jugar una partida
/// completa sin interfaz.
///
/// Sirve para verificar la calibracion: si una estrategia trivial ganara
/// siempre, el simulador no ensenaria a decidir sino a repetir una receta.
class Strategy {
  const Strategy({
    required this.roles,
    this.methodology = Methodology.agile,
    this.priority = ConstraintPriority.time,
    this.qaLevel = 0.5,
    this.committedPeriods = 10,
    this.contingencyRate = 0.10,
    this.dropOptionalScope = false,
    this.treatTopRisks = 0,
    this.runWorkshop = false,
    this.overtimePeriods = const <int>{},
  });

  final List<String> roles;
  final Methodology methodology;
  final ConstraintPriority priority;
  final double qaLevel;
  final int committedPeriods;
  final double contingencyRate;
  final bool dropOptionalScope;

  /// Cuantos riesgos identificados se mitigan al empezar la ejecucion.
  final int treatTopRisks;
  final bool runWorkshop;
  final Set<int> overtimePeriods;
}

class PlayResult {
  const PlayResult({
    required this.state,
    required this.history,
    required this.delivered,
    required this.periodsUsed,
  });

  final ProjectState state;
  final List<PeriodResult> history;
  final bool delivered;
  final int periodsUsed;

  double get cost => state.actualCost;
  double get escapedDefects => state.escapedDefects;
  double get wastedHours {
    double total = 0;
    for (final PeriodResult r in history) {
      total += r.wastedHours;
    }
    return total;
  }
}

/// Juega una partida completa de forma determinista.
PlayResult play({
  required String caseId,
  required int seed,
  required Strategy strategy,
  ProjectConfig config = const ProjectConfig(),
}) {
  final ProjectRepository repo = ProjectRepository(config: config);
  final ProjectState state = ProjectGenerator(config: config).generate(
    caseId: caseId,
    seed: seed,
    methodology: strategy.methodology,
    priority: strategy.priority,
  );

  for (final String role in strategy.roles) {
    repo.hire(state, role);
  }
  repo.setQaLevel(state, strategy.qaLevel);

  if (strategy.dropOptionalScope) {
    for (final WorkPackage p in state.packages) {
      if (p.optional) p.included = false;
    }
  }

  repo.commitBaseline(
    state: state,
    committedPeriods: strategy.committedPeriods,
    contingencyRate: strategy.contingencyRate,
  );

  if (strategy.runWorkshop) repo.runWorkshop(state, seed);

  if (strategy.treatTopRisks > 0) {
    final double hourValue = state.hourValue(config);
    final List<RiskItem> ranked = state.identifiedRisks
        .where((RiskItem r) => !r.occurred)
        .toList()
      ..sort((RiskItem a, RiskItem b) =>
          b.exposure(hourValue).compareTo(a.exposure(hourValue)));
    for (int i = 0; i < strategy.treatTopRisks && i < ranked.length; i++) {
      repo.respondToRisk(state, ranked[i].id, RiskResponse.mitigate);
    }
  }

  final List<PeriodResult> history = <PeriodResult>[];
  while (!state.outcome.isFinished && state.period <= config.totalPeriods) {
    repo.autoAssign(state);
    final PeriodResult r = repo.runPeriodOn(
      state: state,
      seed: seed,
      overtime: strategy.overtimePeriods.contains(state.period),
    );
    history.add(r);
  }

  return PlayResult(
    state: state,
    history: history,
    delivered: state.outcome == ProjectOutcome.delivered ||
        state.outcome == ProjectOutcome.deliveredLate,
    periodsUsed: history.length,
  );
}

