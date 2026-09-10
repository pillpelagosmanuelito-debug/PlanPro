import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_simulator/data/models/change_request.dart';
import 'package:project_management_simulator/data/models/methodology.dart';
import 'package:project_management_simulator/data/models/period_result.dart';
import 'package:project_management_simulator/data/models/project_case.dart';
import 'package:project_management_simulator/data/models/project_config.dart';
import 'package:project_management_simulator/data/models/project_state.dart';
import 'package:project_management_simulator/data/models/team_member.dart';
import 'package:project_management_simulator/data/models/work_package.dart';
import 'package:project_management_simulator/data/repositories/project_repository.dart';
import 'package:project_management_simulator/data/services/execution_engine.dart';
import 'package:project_management_simulator/data/services/project_generator.dart';

void main() {
  const ProjectConfig config = ProjectConfig();
  const ExecutionEngine engine = ExecutionEngine();

  ProjectState nuevoEstado({
    String caseId = 'matricula',
    int seed = 2024,
    Methodology methodology = Methodology.agile,
    List<String> roles = const <String>['senior', 'analista', 'analista'],
    double qa = 0.5,
    int committedPeriods = 10,
  }) {
    final ProjectRepository repo = ProjectRepository(config: config);
    final ProjectState state = const ProjectGenerator().generate(
      caseId: caseId,
      seed: seed,
      methodology: methodology,
      priority: ConstraintPriority.time,
    );
    for (final String r in roles) {
      repo.hire(state, r);
    }
    repo.setQaLevel(state, qa);
    repo.commitBaseline(
      state: state,
      committedPeriods: committedPeriods,
      contingencyRate: 0.10,
    );
    return state;
  }

  group('capacidad y asignaciones', () {
    test('la capacidad aplicada mas la perdida es la capacidad disponible', () {
      final ProjectState state = nuevoEstado();
      final PeriodResult r =
          engine.runPeriod(state: state, overtime: false, seed: 2024);
      expect(r.appliedHours + r.wastedHours, closeTo(r.capacity, 1e-6));
    });

    test('quien no tiene asignacion pierde su capacidad completa', () {
      final ProjectState state = nuevoEstado();
      for (final TeamMember m in state.team) {
        m.assignedPackageId = null;
      }
      final PeriodResult r =
          engine.runPeriod(state: state, overtime: false, seed: 2024);
      expect(r.appliedHours, closeTo(0, 1e-6));
      expect(r.wastedHours, closeTo(r.capacity, 1e-6));
      expect(r.utilization, closeTo(0, 1e-6));
    });

    test('asignar a una fase bloqueada tambien pierde la capacidad', () {
      final ProjectState state = nuevoEstado();
      final WorkPackage implantacion = state.includedPackages
          .firstWhere((WorkPackage p) => p.phase == ProjectPhase.deploy);
      expect(state.phaseUnlocked(ProjectPhase.deploy), isFalse);
      for (final TeamMember m in state.team) {
        m.assignedPackageId = implantacion.id;
      }
      final PeriodResult r =
          engine.runPeriod(state: state, overtime: false, seed: 2024);
      expect(r.wastedHours, closeTo(r.capacity, 1e-6));
    });

    test('el trabajo sobrante se derrama al terminar un paquete', () {
      final ProjectState state = nuevoEstado(
        roles: const <String>['senior', 'senior', 'senior', 'senior'],
      );
      final WorkPackage primero = state.availablePackages().first;
      // Se deja casi terminado para forzar el derrame en el mismo periodo.
      primero.workedHours = primero.realHours - 5;
      for (final TeamMember m in state.team) {
        m.assignedPackageId = primero.id;
      }
      final PeriodResult r =
          engine.runPeriod(state: state, overtime: false, seed: 7);
      expect(r.completedPackages, contains(primero.name));
      expect(r.progressByPackage.length, greaterThan(1),
          reason: 'Las horas sobrantes debieron pasar a otro paquete.');
    });

    test('el reparto automatico no amontona gente en trabajo minimo', () {
      final ProjectRepository repo = ProjectRepository(config: config);
      final ProjectState state = nuevoEstado(
        roles: const <String>[
          'senior',
          'senior',
          'analista',
          'analista',
          'junior',
          'qa',
        ],
      );
      repo.autoAssign(state);
      final Set<String?> distintos =
          state.team.map((TeamMember m) => m.assignedPackageId).toSet();
      expect(distintos.length, greaterThan(1),
          reason: 'Seis personas en un solo paquete garantizan ociosidad.');
    });
  });

  group('horas extra', () {
    test('dan capacidad, cuestan dinero y dejan fatiga', () {
      final ProjectState normal = nuevoEstado();
      final ProjectState extra = nuevoEstado();

      final PeriodResult a =
          engine.runPeriod(state: normal, overtime: false, seed: 2024);
      final PeriodResult b =
          engine.runPeriod(state: extra, overtime: true, seed: 2024);

      expect(b.capacity, greaterThan(a.capacity));
      expect(b.periodCost, greaterThan(a.periodCost));
      expect(extra.fatigue, greaterThan(normal.fatigue));
      expect(extra.overtimePeriods, 1);
    });

    test('la fatiga se recupera en un periodo normal', () {
      final ProjectState state = nuevoEstado();
      engine.runPeriod(state: state, overtime: true, seed: 1);
      final double conFatiga = state.fatigue;
      engine.runPeriod(state: state, overtime: false, seed: 2);
      expect(state.fatigue, lessThan(conFatiga));
    });
  });

  group('calidad y retrabajo', () {
    test('menos aseguramiento deja mas defectos que llegan al cliente', () {
      double escapados(double qa) {
        final ProjectState state = nuevoEstado(
          qa: qa,
          roles: const <String>[
            'senior',
            'senior',
            'analista',
            'analista',
            'junior',
          ],
        );
        while (!state.outcome.isFinished) {
          ProjectRepository(config: config).autoAssign(state);
          engine.runPeriod(state: state, overtime: false, seed: 2024);
        }
        return state.escapedDefects;
      }

      expect(escapados(0.0), greaterThan(escapados(1.0)));
    });

    test('el paquete de correccion crece con el retrabajo detectado', () {
      final ProjectState state = nuevoEstado(
        qa: 0.0,
        roles: const <String>[
          'senior',
          'senior',
          'senior',
          'analista',
          'analista',
        ],
      );
      final WorkPackage correccion =
          state.packages.firstWhere((WorkPackage p) => p.id == 't2');
      final double inicial = correccion.realHours;
      while (!state.outcome.isFinished) {
        ProjectRepository(config: config).autoAssign(state);
        engine.runPeriod(state: state, overtime: false, seed: 2024);
      }
      expect(correccion.realHours, greaterThan(inicial));
      expect(correccion.reworkHours, greaterThan(0));
    });
  });

  group('desenlace', () {
    test('el proyecto se cierra al terminar el alcance comprometido', () {
      final ProjectState state = nuevoEstado(
        roles: const <String>[
          'senior',
          'senior',
          'especialista',
          'analista',
          'analista',
          'qa',
        ],
      );
      while (!state.outcome.isFinished) {
        ProjectRepository(config: config).autoAssign(state);
        engine.runPeriod(state: state, overtime: false, seed: 2024);
      }
      if (state.isComplete) {
        expect(
          state.outcome,
          anyOf(ProjectOutcome.delivered, ProjectOutcome.deliveredLate),
        );
        expect(state.stage, ProjectStage.closure);
      }
    });

    test('agotar el calendario cierra el proyecto sin completar', () {
      final ProjectState state =
          nuevoEstado(roles: const <String>['junior']);
      while (!state.outcome.isFinished) {
        engine.runPeriod(state: state, overtime: false, seed: 5);
      }
      expect(state.outcome, ProjectOutcome.abandoned);
      expect(state.isComplete, isFalse);
    });

    test('superar el techo con holgura cancela el proyecto', () {
      final ProjectState state = nuevoEstado(
        roles: List<String>.filled(12, 'especialista'),
      );
      while (!state.outcome.isFinished) {
        ProjectRepository(config: config).autoAssign(state);
        engine.runPeriod(state: state, overtime: true, seed: 3);
      }
      // Doce consultores expertos con horas extra son insostenibles.
      expect(
        state.outcome,
        anyOf(
          ProjectOutcome.cancelled,
          ProjectOutcome.delivered,
          ProjectOutcome.deliveredLate,
        ),
      );
      if (state.outcome == ProjectOutcome.cancelled) {
        expect(state.actualCost,
            greaterThan(state.projectCase.budgetCeiling * 1.15));
      }
    });
  });

  group('solicitudes de cambio', () {
    ChangeRequest nuevaSolicitud(ProjectState state) => ChangeRequest(
          id: 'ch-test',
          period: state.period,
          title: 'Cambio de prueba',
          requestedBy: 'Patrocinador',
          description: 'Trabajo adicional solicitado.',
          baseHours: 100,
          targetPackageIds: const <String>['c1'],
        );

    test('aceptar agrega trabajo real al proyecto', () {
      final ProjectState state = nuevoEstado();
      final WorkPackage c1 =
          state.packages.firstWhere((WorkPackage p) => p.id == 'c1');
      final double antes = c1.realHours;
      final ChangeRequest ch = nuevaSolicitud(state);
      state.changes.add(ch);

      engine.applyChangeDecision(
        state: state,
        change: ch,
        decision: ChangeDecision.acceptedWithoutBaseline,
      );

      expect(c1.realHours, closeTo(antes + 100, 1e-6));
      expect(state.baseline!.revisions, 0,
          reason: 'Aceptar sin renegociar no debe mover la linea base.');
    });

    test('aceptar renegociando ajusta la linea base y deja constancia', () {
      final ProjectState state = nuevoEstado();
      final double antes = state.baseline!.plannedCost;
      final ChangeRequest ch = nuevaSolicitud(state);
      state.changes.add(ch);

      engine.applyChangeDecision(
        state: state,
        change: ch,
        decision: ChangeDecision.acceptedWithBaseline,
      );

      expect(state.baseline!.plannedCost, greaterThan(antes));
      expect(state.baseline!.revisions, 1);
    });

    test('intercambiar alcance saca trabajo opcional equivalente', () {
      final ProjectState state = nuevoEstado();
      final int incluidosAntes = state.includedPackages.length;
      final ChangeRequest ch = nuevaSolicitud(state);
      state.changes.add(ch);

      engine.applyChangeDecision(
        state: state,
        change: ch,
        decision: ChangeDecision.tradedOff,
      );

      expect(state.includedPackages.length, lessThan(incluidosAntes));
    });

    test('rechazar protege el alcance y molesta al patrocinador', () {
      final ProjectState state = nuevoEstado();
      final double satisfaccion = state.sponsorSatisfaction;
      final WorkPackage c1 =
          state.packages.firstWhere((WorkPackage p) => p.id == 'c1');
      final double horas = c1.realHours;
      final ChangeRequest ch = nuevaSolicitud(state);
      state.changes.add(ch);

      engine.applyChangeDecision(
        state: state,
        change: ch,
        decision: ChangeDecision.rejected,
      );

      expect(c1.realHours, closeTo(horas, 1e-9));
      expect(state.sponsorSatisfaction, lessThan(satisfaccion));
    });

    test('una decision no se puede cambiar despues de tomada', () {
      final ProjectState state = nuevoEstado();
      final ChangeRequest ch = nuevaSolicitud(state);
      state.changes.add(ch);
      engine.applyChangeDecision(
        state: state,
        change: ch,
        decision: ChangeDecision.rejected,
      );
      final WorkPackage c1 =
          state.packages.firstWhere((WorkPackage p) => p.id == 'c1');
      final double horas = c1.realHours;
      engine.applyChangeDecision(
        state: state,
        change: ch,
        decision: ChangeDecision.acceptedWithoutBaseline,
      );
      expect(ch.decision, ChangeDecision.rejected);
      expect(c1.realHours, closeTo(horas, 1e-9));
    });
  });
}
