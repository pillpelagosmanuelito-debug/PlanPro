import 'dart:math' as math;

import '../models/project_config.dart';
import '../models/project_state.dart';
import '../models/risk_item.dart';
import '../models/work_package.dart';

/// Riesgo materializado durante un periodo.
class RiskEvent {
  const RiskEvent({
    required this.risk,
    required this.addedHours,
    required this.addedCost,
    required this.wasIdentified,
    required this.affectedPackage,
  });

  final RiskItem risk;
  final double addedHours;
  final double addedCost;

  /// Si el estudiante lo tenia en el registro antes de que ocurriera.
  final bool wasIdentified;

  final String affectedPackage;

  String get narrative => wasIdentified
      ? 'Ocurrio un riesgo que tenias identificado: ${risk.name}.'
      : 'Ocurrio un riesgo que nunca registraste: ${risk.name}.';
}

/// Dispara riesgos y aplica sus consecuencias.
///
/// La probabilidad declarada corresponde a toda la ventana del riesgo, no a
/// un periodo: el motor la reparte para que la exposicion total coincida con
/// lo que el estudiante ve en el registro.
class RiskEngine {
  const RiskEngine({this.config = const ProjectConfig()});

  final ProjectConfig config;

  List<RiskEvent> evaluate({
    required ProjectState state,
    required int period,
    required int seed,
  }) {
    final math.Random random = math.Random(seed * 7919 + period * 104729);
    final List<RiskEvent> events = <RiskEvent>[];

    for (final RiskItem risk in state.risks) {
      if (risk.occurred) continue;
      if (!risk.window.contains(period)) continue;

      // Evitar un riesgo significa eliminar su causa: no queda probabilidad
      // residual que sortear.
      if (risk.effectiveProbability <= 0) continue;

      final int windowLength = math.max(1, risk.window.length);
      final double perPeriod =
          1 - math.pow(1 - risk.effectiveProbability, 1 / windowLength);
      if (perPeriod <= 0) continue;
      if (random.nextDouble() > perPeriod) continue;

      risk.occurred = true;
      risk.occurredPeriod = period;

      final WorkPackage? target = _targetPackage(state, random);
      final double hours = risk.effectiveImpactHours *
          (risk.identified ? 1.0 : 1.25); // sin plan, se responde tarde
      final double cost = risk.effectiveImpactCost *
          (risk.identified ? 1.0 : 1.20);

      if (target != null) {
        target.realHours += hours;
      }
      state.actualCost += cost;
      state.sponsorSatisfaction -= risk.identified ? 3 : 7;

      events.add(RiskEvent(
        risk: risk,
        addedHours: hours,
        addedCost: cost,
        wasIdentified: risk.identified,
        affectedPackage: target?.name ?? 'el proyecto',
      ));
    }
    return events;
  }

  /// Elige el paquete que absorbe el impacto: uno pendiente de la fase mas
  /// cargada, porque ahi es donde un problema duele de verdad.
  WorkPackage? _targetPackage(ProjectState state, math.Random random) {
    final List<WorkPackage> pending = state.includedPackages
        .where((WorkPackage p) => !p.isDone)
        .toList();
    if (pending.isEmpty) return null;
    pending.sort((WorkPackage a, WorkPackage b) =>
        b.remainingHours.compareTo(a.remainingHours));
    final int index = random.nextInt(math.min(3, pending.length));
    return pending[index];
  }

  /// Taller de identificacion de riesgos.
  ///
  /// Cuesta horas del equipo y dinero, y revela riesgos que estaban fuera del
  /// registro. Es la version practica de "los riesgos que no identificas no
  /// desaparecen".
  List<RiskItem> runIdentificationWorkshop({
    required ProjectState state,
    required int seed,
  }) {
    final List<RiskItem> hidden =
        state.risks.where((RiskItem r) => !r.identified).toList();
    if (hidden.isEmpty) return <RiskItem>[];

    final math.Random random =
        math.Random(seed * 31 + state.riskWorkshops * 977 + state.period);
    hidden.shuffle(random);
    final int reveal = math.min(2, hidden.length);
    final List<RiskItem> revealed = <RiskItem>[];
    for (int i = 0; i < reveal; i++) {
      hidden[i].identified = true;
      revealed.add(hidden[i]);
    }
    state.riskWorkshops++;
    return revealed;
  }
}
