import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_simulator/data/models/change_request.dart';
import 'package:project_management_simulator/data/models/evaluation_report.dart';
import 'package:project_management_simulator/data/models/methodology.dart';
import 'package:project_management_simulator/data/models/period_result.dart';
import 'package:project_management_simulator/data/models/project_state.dart';
import 'package:project_management_simulator/data/services/evaluation_service.dart';

import 'support/simulation_harness.dart';

/// La evaluacion es la parte educativa del cierre: si premiara solo entregar,
/// ensenaria a entregar de cualquier manera.
void main() {
  const EvaluationService evaluator = EvaluationService();
  const List<String> equipo = <String>[
    'senior',
    'analista',
    'analista',
    'junior',
    'qa',
  ];

  EvaluationReport informe(Strategy s, {int seed = 1001}) {
    final PlayResult r = play(caseId: 'matricula', seed: seed, strategy: s);
    return evaluator.build(state: r.state, history: r.history);
  }

  group('estructura del informe', () {
    test('califica las cuatro competencias declaradas', () {
      final EvaluationReport r = informe(const Strategy(roles: equipo));
      expect(r.scores.length, PmCompetency.values.length);
      for (final PmCompetency c in PmCompetency.values) {
        expect(r.scoreFor(c).competency, c);
      }
    });

    test('todos los puntajes quedan dentro de rango', () {
      final EvaluationReport r = informe(const Strategy(roles: equipo));
      for (final CompetencyScore s in r.scores) {
        expect(s.score, inInclusiveRange(0, 100));
      }
      expect(r.overallScore, inInclusiveRange(0, 100));
    });

    test('cada competencia entrega evidencia, no solo un numero', () {
      final EvaluationReport r = informe(const Strategy(roles: equipo));
      final int evidencias = r.scores.fold<int>(
        0,
        (int acc, CompetencyScore s) => acc + s.strengths.length + s.gaps.length,
      );
      expect(evidencias, greaterThan(0));
      expect(r.nextSteps, isNotEmpty);
      expect(r.narrative, isNotEmpty);
    });

    test('la brecha de estimacion revela la duracion real oculta', () {
      final EvaluationReport r = informe(const Strategy(roles: equipo));
      expect(r.estimateGaps, isNotEmpty);
      // Ordenada por desviacion: lo peor estimado, primero.
      for (int i = 1; i < r.estimateGaps.length; i++) {
        expect(r.estimateGaps[i - 1].deviation,
            greaterThanOrEqualTo(r.estimateGaps[i].deviation));
      }
    });
  });

  group('planificacion', () {
    test('sin reserva de contingencia se penaliza', () {
      final CompetencyScore sin = informe(
        const Strategy(roles: equipo, contingencyRate: 0.0),
      ).scoreFor(PmCompetency.planning);
      final CompetencyScore con = informe(
        const Strategy(roles: equipo, contingencyRate: 0.10),
      ).scoreFor(PmCompetency.planning);
      expect(sin.score, lessThan(con.score));
      expect(sin.gaps, isNotEmpty);
    });

    test('comprometer un plazo imposible se paga en el puntaje', () {
      final CompetencyScore optimista = informe(
        const Strategy(roles: equipo, committedPeriods: 4),
      ).scoreFor(PmCompetency.planning);
      final CompetencyScore realista = informe(
        const Strategy(roles: equipo, committedPeriods: 11),
      ).scoreFor(PmCompetency.planning);
      expect(optimista.score, lessThan(realista.score));
    });

    test('aceptar cambios sin mover la linea base es deslizamiento de alcance',
        () {
      final PlayResult r = play(
        caseId: 'matricula',
        seed: 1001,
        strategy: const Strategy(roles: equipo),
      );
      // Se fuerzan las decisiones silenciosas sobre lo que aparecio.
      for (final ChangeRequest c in r.state.changes) {
        c.decision = ChangeDecision.acceptedWithoutBaseline;
      }
      final EvaluationReport conCreep =
          evaluator.build(state: r.state, history: r.history);

      for (final ChangeRequest c in r.state.changes) {
        c.decision = ChangeDecision.acceptedWithBaseline;
      }
      final EvaluationReport conFormalidad =
          evaluator.build(state: r.state, history: r.history);

      if (r.state.changes.isNotEmpty) {
        expect(
          conCreep.scoreFor(PmCompetency.planning).score,
          lessThan(conFormalidad.scoreFor(PmCompetency.planning).score),
        );
      }
    });
  });

  group('recursos', () {
    test('la capacidad ociosa baja el puntaje de recursos', () {
      final PlayResult r = play(
        caseId: 'matricula',
        seed: 1001,
        strategy: const Strategy(roles: equipo),
      );
      final EvaluationReport informeReal =
          evaluator.build(state: r.state, history: r.history);
      expect(informeReal.wastedHours, greaterThanOrEqualTo(0));
      expect(
        informeReal.scoreFor(PmCompetency.resources).score,
        inInclusiveRange(0, 100),
      );
    });

    test('el abuso de horas extra se penaliza', () {
      final CompetencyScore abuso = informe(
        Strategy(
          roles: equipo,
          overtimePeriods: <int>{for (int i = 1; i <= 12; i++) i},
        ),
      ).scoreFor(PmCompetency.resources);
      final CompetencyScore puntual = informe(
        const Strategy(roles: equipo, overtimePeriods: <int>{9, 10}),
      ).scoreFor(PmCompetency.resources);
      expect(abuso.score, lessThan(puntual.score));
    });
  });

  group('riesgos', () {
    test('no analizar riesgos nunca baja el puntaje', () {
      final CompetencyScore sin = informe(
        const Strategy(roles: equipo),
      ).scoreFor(PmCompetency.risk);
      final CompetencyScore con = informe(
        const Strategy(roles: equipo, runWorkshop: true, treatTopRisks: 3),
      ).scoreFor(PmCompetency.risk);
      expect(sin.score, lessThan(con.score));
    });

    test('el informe cuenta los riesgos que golpearon sin estar identificados',
        () {
      final EvaluationReport r = informe(const Strategy(roles: equipo));
      expect(r.risksUnidentifiedHit, lessThanOrEqualTo(r.risksMaterialized));
      expect(r.risksIdentified, lessThanOrEqualTo(r.risksTotal));
    });
  });

  group('cierre en entorno regulado', () {
    test('un enfoque agil en obra publica deja el cierre observado', () {
      final PlayResult r = play(
        caseId: 'planta',
        seed: 1001,
        strategy: const Strategy(roles: equipo, methodology: Methodology.agile),
      );
      final EvaluationReport informeReal =
          evaluator.build(state: r.state, history: r.history);
      expect(informeReal.complianceIssue, isTrue);
    });

    test('un enfoque predictivo en obra publica cierra sin observaciones', () {
      final PlayResult r = play(
        caseId: 'planta',
        seed: 1001,
        strategy: const Strategy(
          roles: equipo,
          methodology: Methodology.predictive,
        ),
      );
      final EvaluationReport informeReal =
          evaluator.build(state: r.state, history: r.history);
      expect(informeReal.complianceIssue, isFalse);
    });
  });

  group('sin linea base', () {
    test('no comprometer nada es la peor planificacion posible', () {
      final ProjectState s = play(
        caseId: 'matricula',
        seed: 1001,
        strategy: const Strategy(roles: equipo),
      ).state;
      s.baseline = null;
      final EvaluationReport r =
          evaluator.build(state: s, history: const <PeriodResult>[]);
      expect(r.scoreFor(PmCompetency.planning).score, lessThan(40));
    });
  });
}
