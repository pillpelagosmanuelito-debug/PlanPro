import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_simulator/data/models/methodology.dart';
import 'package:project_management_simulator/data/models/project_config.dart';
import 'package:project_management_simulator/data/models/project_state.dart';
import 'package:project_management_simulator/data/models/team_member.dart';
import 'package:project_management_simulator/data/repositories/project_repository.dart';
import 'package:project_management_simulator/data/services/project_generator.dart';

void main() {
  const ProjectConfig config = ProjectConfig();

  group('curva de comunicacion', () {
    test('la eficiencia cae de forma acelerada con el tamanio', () {
      final List<double> eficiencias = <double>[
        for (int n = 1; n <= 12; n++) config.teamEfficiency(n),
      ];
      for (int i = 1; i < eficiencias.length; i++) {
        expect(eficiencias[i], lessThan(eficiencias[i - 1]));
      }
      // La caida entre 8 y 9 debe ser mayor que entre 2 y 3: los canales de
      // comunicacion crecen con el cuadrado del equipo, no en linea recta.
      final double caidaTemprana = eficiencias[1] - eficiencias[2];
      final double caidaTardia = eficiencias[7] - eficiencias[8];
      expect(caidaTardia, greaterThan(caidaTemprana));
    });

    test('una persona sola conserva toda su capacidad', () {
      expect(config.teamEfficiency(1), 1.0);
    });

    test('la capacidad total crece pero cada vez menos por persona', () {
      double capacidadPorPersona(int n) {
        final ProjectState s = _estado();
        final ProjectRepository repo = ProjectRepository(config: config);
        for (int i = 0; i < n; i++) {
          repo.hire(s, 'analista');
        }
        return s.effectiveCapacity(config) / n;
      }

      expect(capacidadPorPersona(9), lessThan(capacidadPorPersona(3)));
    });
  });

  group('curva de aprendizaje', () {
    test('quien se incorpora durante la ejecucion rinde parcialmente', () {
      final TeamMember nuevo = TeamMember(
        id: 'm1',
        roleId: 'junior',
        name: 'Junior 1',
        joinedPeriod: 5,
      );
      expect(nuevo.rampFactor, closeTo(0.45, 1e-9));
      expect(nuevo.isNewcomer, isTrue);

      nuevo.periodsOnTeam = 3;
      expect(nuevo.rampFactor, 1.0);
      expect(nuevo.isNewcomer, isFalse);
    });

    test('el equipo inicial arranca rodado', () {
      final ProjectState s = _estado();
      final ProjectRepository repo = ProjectRepository(config: config);
      final TeamMember m = repo.hire(s, 'junior');
      expect(m.isNewcomer, isFalse,
          reason: 'Contratar antes de ejecutar no deberia costar curva.');
    });

    test('incorporar en ejecucion penaliza a todo el equipo', () {
      final ProjectRepository repo = ProjectRepository(config: config);
      final ProjectState s = _estado();
      for (int i = 0; i < 4; i++) {
        repo.hire(s, 'analista');
      }
      repo.commitBaseline(state: s, committedPeriods: 10, contingencyRate: 0.1);

      final double antes = s.effectiveCapacity(config);
      repo.hire(s, 'analista');
      final double despues = s.effectiveCapacity(config);

      // Suma capacidad bruta, pero la mentoria y la coordinacion se la comen
      // casi entera: ese es exactamente el efecto que la ley de Brooks
      // describe.
      expect(despues - antes, lessThan(config.hoursPerPerson * 0.6),
          reason: 'La quinta persona aporta su capacidad completa.');
    });
  });

  group('gobernanza y calidad', () {
    test('un enfoque agil en entorno regulado consume mas gobernanza', () {
      expect(
        Methodology.agile.governanceOverhead(regulated: true),
        greaterThan(Methodology.agile.governanceOverhead(regulated: false)),
      );
      expect(
        Methodology.agile.governanceOverhead(regulated: true),
        greaterThan(Methodology.predictive.governanceOverhead(regulated: true)),
      );
    });

    test('subir el aseguramiento reduce la capacidad disponible', () {
      final ProjectRepository repo = ProjectRepository(config: config);
      final ProjectState s = _estado();
      for (int i = 0; i < 4; i++) {
        repo.hire(s, 'analista');
      }
      repo.setQaLevel(s, 0.0);
      final double sinQa = s.effectiveCapacity(config);
      repo.setQaLevel(s, 1.0);
      expect(s.effectiveCapacity(config), lessThan(sinQa));
    });
  });

  group('costo del equipo', () {
    test('el costo por periodo es la suma de los perfiles', () {
      final ProjectRepository repo = ProjectRepository(config: config);
      final ProjectState s = _estado();
      repo.hire(s, 'senior');
      repo.hire(s, 'junior');
      expect(
        s.teamCostPerPeriod(),
        TeamRole.byId('senior').costPerPeriod +
            TeamRole.byId('junior').costPerPeriod,
      );
    });

    test('retirar a alguien libera su costo', () {
      final ProjectRepository repo = ProjectRepository(config: config);
      final ProjectState s = _estado();
      final TeamMember a = repo.hire(s, 'especialista');
      repo.hire(s, 'analista');
      final double antes = s.teamCostPerPeriod();
      repo.release(s, a.id);
      expect(s.teamCostPerPeriod(), lessThan(antes));
      expect(s.team.length, 1);
    });
  });
}

ProjectState _estado() => const ProjectGenerator().generate(
      caseId: 'matricula',
      seed: 11,
      methodology: Methodology.hybrid,
      priority: ConstraintPriority.time,
    );
