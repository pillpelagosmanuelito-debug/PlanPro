import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_simulator/data/models/advisor_message.dart';
import 'package:project_management_simulator/data/models/change_request.dart';
import 'package:project_management_simulator/data/models/methodology.dart';
import 'package:project_management_simulator/data/models/project_config.dart';
import 'package:project_management_simulator/data/models/project_state.dart';
import 'package:project_management_simulator/data/models/risk_item.dart';
import 'package:project_management_simulator/data/models/team_member.dart';
import 'package:project_management_simulator/data/repositories/project_repository.dart';
import 'package:project_management_simulator/data/services/pm_advisor.dart';
import 'package:project_management_simulator/data/services/project_generator.dart';

import 'support/simulation_harness.dart';

/// El asistente es un sistema experto, no un oraculo. Estas pruebas fijan las
/// dos propiedades que lo hacen educativo: que dispare cuando corresponde y,
/// sobre todo, que **no vea mas de lo que ve el estudiante**.
void main() {
  const PmAdvisor advisor = PmAdvisor();
  const ProjectConfig config = ProjectConfig();
  const List<String> equipo = <String>[
    'senior',
    'analista',
    'analista',
    'junior',
    'qa',
  ];

  bool tieneRegla(List<AdvisorMessage> ms, String ruleId) =>
      ms.any((AdvisorMessage m) => m.ruleId == ruleId);

  ProjectState planificando({List<String> roles = equipo}) {
    final ProjectRepository repo = ProjectRepository(config: config);
    final ProjectState s = const ProjectGenerator().generate(
      caseId: 'matricula',
      seed: 606,
      methodology: Methodology.agile,
      priority: ConstraintPriority.time,
    );
    for (final String r in roles) {
      repo.hire(s, r);
    }
    s.stage = ProjectStage.planning;
    return s;
  }

  group('honestidad epistemica', () {
    test('cada mensaje explica que observa y que hacer', () {
      final PlayResult r = play(
        caseId: 'matricula',
        seed: 1001,
        strategy: const Strategy(roles: equipo),
      );
      final List<AdvisorMessage> ms =
          advisor.execute(state: r.state, last: r.history.last);
      for (final AdvisorMessage m in ms) {
        expect(m.title, isNotEmpty);
        expect(m.diagnosis, isNotEmpty);
        expect(m.recommendation, isNotEmpty);
        expect(m.ruleId, isNotEmpty);
      }
    });

    test('nunca menciona un riesgo que el estudiante no identifico', () {
      final PlayResult r = play(
        caseId: 'matricula',
        seed: 1013,
        strategy: const Strategy(roles: equipo),
      );
      final List<RiskItem> ocultos = r.state.risks
          .where((RiskItem x) => !x.identified)
          .toList();
      final String texto = advisor
          .execute(state: r.state, last: r.history.last)
          .map((AdvisorMessage m) =>
              '${m.title} ${m.diagnosis} ${m.recommendation} ${m.evidence}')
          .join(' ');
      for (final RiskItem oculto in ocultos) {
        expect(texto.contains(oculto.name), isFalse,
            reason: 'El asistente delato el riesgo oculto "${oculto.name}": '
                'si conociera el futuro, el ejercicio dejaria de entrenar la '
                'decision con informacion incompleta.');
      }
    });

    test('los mensajes se ordenan por urgencia', () {
      final PlayResult r = play(
        caseId: 'matricula',
        seed: 1019,
        strategy: const Strategy(roles: equipo, qaLevel: 0.0),
      );
      final List<AdvisorMessage> ms =
          advisor.execute(state: r.state, last: r.history.last);
      for (int i = 1; i < ms.length; i++) {
        expect(ms[i].severity.order,
            greaterThanOrEqualTo(ms[i - 1].severity.order));
      }
    });
  });

  group('reglas de planificacion', () {
    test('avisa cuando el plazo comprometido no alcanza', () {
      final ProjectState s = planificando();
      final List<AdvisorMessage> ms = advisor.planningAdvice(
        state: s,
        committedPeriods: 4,
        contingencyRate: 0.10,
      );
      expect(tieneRegla(ms, 'plan_overcommit'), isTrue);
    });

    test('avisa cuando no hay reserva de contingencia', () {
      final ProjectState s = planificando();
      final List<AdvisorMessage> ms = advisor.planningAdvice(
        state: s,
        committedPeriods: 10,
        contingencyRate: 0.0,
      );
      expect(tieneRegla(ms, 'plan_no_reserve'), isTrue);
    });

    test('sin equipo, lo unico que importa es el equipo', () {
      final ProjectState s = planificando(roles: const <String>[]);
      final List<AdvisorMessage> ms = advisor.planningAdvice(
        state: s,
        committedPeriods: 10,
        contingencyRate: 0.10,
      );
      expect(ms.length, 1);
      expect(ms.single.ruleId, 'plan_no_team');
      expect(ms.single.severity, AdvisorSeverity.critical);
    });

    test('senala el desajuste entre metodologia y caso', () {
      final ProjectRepository repo = ProjectRepository(config: config);
      final ProjectState s = const ProjectGenerator().generate(
        caseId: 'planta',
        seed: 606,
        methodology: Methodology.agile,
        priority: ConstraintPriority.scope,
      );
      repo.hire(s, 'senior');
      final List<AdvisorMessage> ms = advisor.planningAdvice(
        state: s,
        committedPeriods: 10,
        contingencyRate: 0.10,
      );
      expect(tieneRegla(ms, 'fit_agile_regulated'), isTrue);
      expect(tieneRegla(ms, 'fit_agile_stable'), isTrue);
    });
  });

  group('reglas de ejecucion', () {
    test('detecta gente sin trabajo valido', () {
      final PlayResult r = play(
        caseId: 'matricula',
        seed: 1001,
        strategy: const Strategy(roles: equipo),
      );
      for (final TeamMember m in r.state.team) {
        m.assignedPackageId = null;
      }
      expect(
        tieneRegla(
          advisor.execute(state: r.state, last: r.history.last),
          'unassigned',
        ),
        isTrue,
      );
    });

    test('detecta una solicitud de cambio sin responder', () {
      final PlayResult r = play(
        caseId: 'matricula',
        seed: 1001,
        strategy: const Strategy(roles: equipo),
      );
      r.state.changes.add(ChangeRequest(
        id: 'ch-x',
        period: 1,
        title: 'Pendiente de prueba',
        requestedBy: 'Patrocinador',
        description: 'Trabajo adicional.',
        baseHours: 90,
        targetPackageIds: const <String>['c1'],
      ));
      expect(
        tieneRegla(
          advisor.execute(state: r.state, last: r.history.last),
          'change_pending',
        ),
        isTrue,
      );
    });

    test('detecta el deslizamiento de alcance', () {
      final PlayResult r = play(
        caseId: 'matricula',
        seed: 1001,
        strategy: const Strategy(roles: equipo),
      );
      r.state.changes.add(ChangeRequest(
        id: 'ch-y',
        period: 1,
        title: 'Aceptada en silencio',
        requestedBy: 'Patrocinador',
        description: 'Trabajo adicional.',
        baseHours: 90,
        targetPackageIds: const <String>['c1'],
        decision: ChangeDecision.acceptedWithoutBaseline,
      ));
      expect(
        tieneRegla(
          advisor.execute(state: r.state, last: r.history.last),
          'scope_creep',
        ),
        isTrue,
      );
    });

    test('reclama el analisis de riesgos si nunca se hizo', () {
      final PlayResult r = play(
        caseId: 'matricula',
        seed: 1001,
        strategy: const Strategy(roles: equipo),
      );
      expect(
        tieneRegla(
          advisor.execute(state: r.state, last: r.history.last),
          'risk_no_workshop',
        ),
        isTrue,
      );
    });

    test('avisa cuando el aseguramiento quedo demasiado bajo', () {
      final PlayResult r = play(
        caseId: 'matricula',
        seed: 1001,
        strategy: const Strategy(roles: equipo, qaLevel: 0.0),
      );
      expect(
        tieneRegla(
          advisor.execute(state: r.state, last: r.history.last),
          'qa_low',
        ),
        isTrue,
      );
    });

    test('la cabecera resume el estado en una linea', () {
      final PlayResult r = play(
        caseId: 'matricula',
        seed: 1001,
        strategy: const Strategy(roles: equipo),
      );
      final String linea = advisor.headline(r.state);
      expect(linea, contains('SPI'));
      expect(linea, contains('CPI'));
    });
  });
}
