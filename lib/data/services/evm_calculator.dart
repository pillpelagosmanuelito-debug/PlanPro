import 'dart:math' as math;

import '../models/baseline.dart';
import '../models/project_case.dart';
import '../models/evm_snapshot.dart';
import '../models/project_state.dart';
import '../models/work_package.dart';

/// Calcula el valor ganado del proyecto.
///
/// Se mantiene aparte del motor de ejecución porque es el instrumental de
/// medición, no de simulación: recibe el estado y devuelve indicadores, sin
/// modificar nada.
class EvmCalculator {
  const EvmCalculator();

  /// Valor planificado a la fecha, con distribución lineal sobre la línea base.
  double plannedValue({
    required Baseline baseline,
    required int period,
  }) {
    if (baseline.committedPeriods <= 0) return baseline.budgetAtCompletion;
    final double fraction =
        (period / baseline.committedPeriods).clamp(0.0, 1.0).toDouble();
    return baseline.budgetAtCompletion * fraction;
  }

  /// Valor ganado: la fracción del alcance realmente terminada, valorizada.
  double earnedValue({
    required ProjectState state,
    required Baseline baseline,
  }) {
    return baseline.budgetAtCompletion * state.progress;
  }

  /// Fotografía completa del periodo.
  EvmSnapshot snapshot({
    required ProjectState state,
    required int period,
  }) {
    final Baseline? baseline = state.baseline;
    if (baseline == null) {
      return EvmSnapshot(
        period: period,
        plannedValue: 0,
        earnedValue: 0,
        actualCost: state.actualCost,
        budgetAtCompletion: 1,
      );
    }
    return EvmSnapshot(
      period: period,
      plannedValue: plannedValue(baseline: baseline, period: period),
      earnedValue: earnedValue(state: state, baseline: baseline),
      actualCost: state.actualCost,
      budgetAtCompletion: baseline.budgetAtCompletion,
    );
  }

  /// Periodos estimados hasta terminar, con el ritmo observado.
  ///
  /// Es la traducción práctica del SPI: si vienes rindiendo al 80% de lo
  /// planificado, lo que falta tomará más periodos de los que quedan.
  double estimatedPeriodsToFinish({
    required ProjectState state,
    required int currentPeriod,
  }) {
    final double progress = state.progress;
    if (progress >= 0.999) return 0;
    if (currentPeriod <= 1 || progress <= 0.001) {
      return double.infinity;
    }
    final double ratePerPeriod = progress / (currentPeriod - 1);
    if (ratePerPeriod <= 0) return double.infinity;
    return (1 - progress) / ratePerPeriod;
  }

  /// Fecha estimada de término en periodos absolutos.
  double estimatedFinishPeriod({
    required ProjectState state,
    required int currentPeriod,
  }) {
    final double remaining =
        estimatedPeriodsToFinish(state: state, currentPeriod: currentPeriod);
    if (!remaining.isFinite) return double.infinity;
    return currentPeriod - 1 + remaining;
  }

  /// Holgura de un paquete respecto de la fase más cargada.
  ///
  /// La fase con más trabajo pendiente marca el ritmo del proyecto: los
  /// paquetes que están fuera de ella tienen holgura y pueden esperar.
  double slackFor({
    required ProjectState state,
    required String packageId,
  }) {
    final WorkPackage? pkg = state.packageById(packageId);
    if (pkg == null) return 0;
    final double own = _remainingOfPhase(state, pkg.phase);
    double worst = 0;
    for (final ProjectPhase phase in ProjectPhase.values) {
      final double remaining = _remainingOfPhase(state, phase);
      worst = math.max(worst, remaining);
    }
    if (worst <= 0) return 0;
    return ((worst - own) / worst).clamp(0.0, 1.0).toDouble();
  }

  /// Fase con más trabajo pendiente: la que define el camino crítico.
  ProjectPhase criticalPhase(ProjectState state) {
    ProjectPhase worst = ProjectPhase.analysis;
    double most = -1;
    for (final ProjectPhase phase in ProjectPhase.values) {
      final double remaining = _remainingOfPhase(state, phase);
      if (remaining > most) {
        most = remaining;
        worst = phase;
      }
    }
    return worst;
  }

  double _remainingOfPhase(ProjectState state, ProjectPhase phase) {
    double total = 0;
    for (final WorkPackage p in state.includedPackages) {
      if (p.phase == phase) {
        total += p.estimatedHours * (1 - p.progress);
      }
    }
    return total;
  }
}
