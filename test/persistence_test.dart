import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_simulator/data/models/methodology.dart';
import 'package:project_management_simulator/data/models/project_session.dart';
import 'package:project_management_simulator/data/models/project_state.dart';
import 'package:project_management_simulator/data/models/risk_item.dart';
import 'package:project_management_simulator/data/models/work_package.dart';
import 'package:project_management_simulator/data/repositories/project_repository.dart';

import 'support/simulation_harness.dart';

/// Una partida se juega en varias sesiones de clase: si el guardado perdiera
/// estado, el simulador seria inutilizable en un curso real.
void main() {
  const List<String> equipo = <String>[
    'senior',
    'analista',
    'analista',
    'junior',
  ];

  test('una partida a medias sobrevive al ida y vuelta por JSON', () {
    final ProjectRepository repo = ProjectRepository();
    final ProjectSession original = repo.createSession(
      caseId: 'cobranzas',
      methodology: Methodology.hybrid,
      priority: ConstraintPriority.cost,
      seed: 5150,
    );
    for (final String r in equipo) {
      repo.hire(original.state, r);
    }
    repo.commitBaseline(
      state: original.state,
      committedPeriods: 9,
      contingencyRate: 0.12,
    );
    for (int i = 0; i < 4; i++) {
      repo.autoAssign(original.state);
      repo.runPeriod(session: original, overtime: i == 3);
    }

    final ProjectSession copia = ProjectSession.fromJson(
      jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
    );

    expect(copia.seed, original.seed);
    expect(copia.history.length, original.history.length);
    expect(copia.state.period, original.state.period);
    expect(copia.state.caseId, original.state.caseId);
    expect(copia.state.methodology, original.state.methodology);
    expect(copia.state.priority, original.state.priority);
    expect(copia.state.actualCost, closeTo(original.state.actualCost, 1e-6));
    expect(copia.state.team.length, original.state.team.length);
    expect(copia.state.snapshots.length, original.state.snapshots.length);
    expect(copia.state.baseline!.committedPeriods, 9);
  });

  test('la duracion real oculta de cada paquete se conserva', () {
    final PlayResult r = play(
      caseId: 'matricula',
      seed: 8080,
      strategy: const Strategy(roles: equipo),
    );
    final ProjectState copia = ProjectState.fromJson(
      jsonDecode(jsonEncode(r.state.toJson())) as Map<String, dynamic>,
    );
    for (int i = 0; i < r.state.packages.length; i++) {
      expect(copia.packages[i].realHours,
          closeTo(r.state.packages[i].realHours, 1e-6));
      expect(copia.packages[i].workedHours,
          closeTo(r.state.packages[i].workedHours, 1e-6));
      expect(copia.packages[i].included, r.state.packages[i].included);
    }
  });

  test('el estado de los riesgos se conserva', () {
    final PlayResult r = play(
      caseId: 'matricula',
      seed: 8080,
      strategy: const Strategy(roles: equipo, runWorkshop: true),
    );
    final ProjectState copia = ProjectState.fromJson(
      jsonDecode(jsonEncode(r.state.toJson())) as Map<String, dynamic>,
    );
    expect(copia.risks.length, r.state.risks.length);
    for (int i = 0; i < r.state.risks.length; i++) {
      final RiskItem a = r.state.risks[i];
      final RiskItem b = copia.risks[i];
      expect(b.id, a.id);
      expect(b.identified, a.identified);
      expect(b.response, a.response);
      expect(b.occurred, a.occurred);
    }
    expect(copia.riskWorkshops, r.state.riskWorkshops);
  });

  test('un guardado corrupto no deja el estado inconsistente', () {
    final ProjectState s = ProjectState.fromJson(<String, dynamic>{});
    expect(s.caseId, isNotEmpty);
    expect(s.outcome, ProjectOutcome.running);
    expect(s.stage, ProjectStage.initiation);
    expect(s.packages, isEmpty);
  });

  test('el alcance excluido se guarda como tal', () {
    final ProjectRepository repo = ProjectRepository();
    final ProjectSession sesion = repo.createSession(
      caseId: 'matricula',
      methodology: Methodology.agile,
      priority: ConstraintPriority.time,
      seed: 3030,
    );
    final WorkPackage opcional = sesion.state.packages
        .firstWhere((WorkPackage p) => p.optional);
    repo.toggleScope(sesion.state, opcional.id);
    expect(opcional.included, isFalse);

    final ProjectSession copia = ProjectSession.fromJson(
      jsonDecode(jsonEncode(sesion.toJson())) as Map<String, dynamic>,
    );
    expect(
      copia.state.packages.firstWhere((WorkPackage p) => p.id == opcional.id)
          .included,
      isFalse,
    );
  });

  test('el alcance ya empezado no se puede excluir', () {
    final ProjectRepository repo = ProjectRepository();
    final ProjectSession sesion = repo.createSession(
      caseId: 'matricula',
      methodology: Methodology.agile,
      priority: ConstraintPriority.time,
      seed: 3030,
    );
    final WorkPackage opcional = sesion.state.packages
        .firstWhere((WorkPackage p) => p.optional);
    opcional.workedHours = 10;
    repo.toggleScope(sesion.state, opcional.id);
    expect(opcional.included, isTrue,
        reason: 'Sacar del alcance algo ya pagado seria gratis.');
  });
}
