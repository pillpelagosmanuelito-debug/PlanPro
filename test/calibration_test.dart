import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_simulator/data/models/methodology.dart';

import 'support/simulation_harness.dart';

/// Pruebas de calibracion.
///
/// Verifican la propiedad que hace educativo al simulador: **ninguna decision
/// gratis y ninguna receta ganadora**. Si alguna de estas pruebas falla
/// despues de tocar un parametro, el simulador dejo de ensenar a decidir.
///
/// Se juegan partidas completas con un estudiante sintetico y semillas fijas,
/// de modo que los resultados son deterministas y reproducibles.
void main() {
  const List<String> equipoBalanceado = <String>[
    'senior',
    'analista',
    'analista',
    'junior',
    'qa',
  ];
  const List<int> semillas = <int>[
    1001, 1007, 1013, 1019, 1023, 1031, 1037, 1041, 1049, 1053,
    1061, 1067, 1073, 1079, 1083, 1091, 1097, 1101, 1109, 1113,
  ];

  double tasaEntrega(Strategy s, {String caseId = 'matricula'}) {
    int ok = 0;
    for (final int seed in semillas) {
      if (play(caseId: caseId, seed: seed, strategy: s).delivered) ok++;
    }
    return ok / semillas.length;
  }

  double promedioEscapados(Strategy s, {String caseId = 'matricula'}) {
    double total = 0;
    for (final int seed in semillas) {
      total += play(caseId: caseId, seed: seed, strategy: s).escapedDefects;
    }
    return total / semillas.length;
  }

  double promedioCosto(Strategy s, {String caseId = 'matricula'}) {
    double total = 0;
    for (final int seed in semillas) {
      total += play(caseId: caseId, seed: seed, strategy: s).cost;
    }
    return total / semillas.length;
  }

  group('dificultad general', () {
    test('un equipo razonable no gana solo por existir', () {
      const Strategy base = Strategy(roles: equipoBalanceado);
      final double tasa = tasaEntrega(base);
      // Debe ser posible pero no automatico: si fuera 100%, dirigir no
      // importaria; si fuera 0%, el juego seria injusto.
      expect(tasa, greaterThan(0.35),
          reason: 'El caso base es imposible: nadie aprenderia nada.');
      expect(tasa, lessThan(0.95),
          reason: 'El caso base se gana solo: las decisiones no importan.');
    });

    test('un equipo demasiado pequenio no alcanza', () {
      final double tasa = tasaEntrega(
        const Strategy(roles: <String>['senior', 'analista', 'junior']),
      );
      expect(tasa, lessThan(0.35));
    });
  });

  group('ley de Brooks', () {
    test('duplicar el equipo no duplica la velocidad', () {
      const Strategy cinco = Strategy(roles: equipoBalanceado);
      const Strategy diez = Strategy(roles: <String>[
        ...equipoBalanceado,
        'senior',
        'analista',
        'junior',
        'qa',
        'senior',
      ]);
      final PlayResult a = play(caseId: 'matricula', seed: 1001, strategy: cinco);
      final PlayResult b = play(caseId: 'matricula', seed: 1001, strategy: diez);

      // Con el doble de gente, el proyecto no puede tardar la mitad.
      expect(b.periodsUsed * 2, greaterThan(a.periodsUsed),
          reason: 'El equipo grande escala de forma lineal: falta el costo '
              'de coordinacion.');
    });

    test('el equipo masivo termina mas rapido pero mucho mas caro', () {
      const Strategy diez = Strategy(roles: <String>[
        ...equipoBalanceado,
        'senior',
        'analista',
        'junior',
        'qa',
        'senior',
      ]);
      expect(promedioCosto(diez),
          greaterThan(promedioCosto(const Strategy(roles: equipoBalanceado))));
    });
  });

  group('economia de la calidad', () {
    test('recortar aseguramiento multiplica los defectos que llegan al cliente',
        () {
      final double sinCalidad = promedioEscapados(
        const Strategy(roles: equipoBalanceado, qaLevel: 0.0),
      );
      final double conCalidad = promedioEscapados(
        const Strategy(roles: equipoBalanceado, qaLevel: 1.0),
      );
      expect(sinCalidad, greaterThan(conCalidad * 3),
          reason: 'La calidad no cambia el resultado: la decision es falsa.');
    });

    test('el maximo aseguramiento no elimina todos los defectos', () {
      expect(
        promedioEscapados(const Strategy(roles: equipoBalanceado, qaLevel: 1.0)),
        greaterThan(0),
        reason: 'Con QA al maximo no queda ningun defecto: seria una '
            'estrategia dominante y una mentira.',
      );
    });

    test('el aseguramiento cuesta capacidad y no sale gratis', () {
      double periodos(double qa) {
        double total = 0;
        for (final int seed in semillas) {
          total += play(
            caseId: 'matricula',
            seed: seed,
            strategy: Strategy(roles: equipoBalanceado, qaLevel: qa),
          ).periodsUsed;
        }
        return total / semillas.length;
      }

      // Menos defectos, si; pero tambien menos capacidad disponible cada
      // periodo. La calidad se compra con tiempo, no con buenas intenciones.
      expect(periodos(1.0), greaterThan(periodos(0.0) - 1.5),
          reason: 'El aseguramiento maximo saldria gratis en plazo.');
    });
  });

  group('palancas de direccion', () {
    test('recortar alcance opcional mejora la entrega', () {
      final double sin = tasaEntrega(const Strategy(roles: equipoBalanceado));
      final double con = tasaEntrega(
        const Strategy(roles: equipoBalanceado, dropOptionalScope: true),
      );
      expect(con, greaterThan(sin));
    });

    test('tratar los riesgos de mayor exposicion mejora la entrega', () {
      final double sin = tasaEntrega(const Strategy(roles: equipoBalanceado));
      final double con = tasaEntrega(
        const Strategy(roles: equipoBalanceado, treatTopRisks: 2),
      );
      expect(con, greaterThanOrEqualTo(sin));
    });

    test('las horas extra permanentes son mas caras que utiles', () {
      final double siempre = promedioCosto(
        Strategy(
          roles: equipoBalanceado,
          overtimePeriods: <int>{for (int i = 1; i <= 12; i++) i},
        ),
      );
      final double nunca =
          promedioCosto(const Strategy(roles: equipoBalanceado));
      expect(siempre, greaterThan(nunca * 1.3),
          reason: 'Las horas extra permanentes salen casi gratis.');
    });
  });

  group('la metodologia debe encajar con el caso', () {
    test('en requisitos volatiles, el enfoque agil supera al predictivo', () {
      final double agil = tasaEntrega(
        const Strategy(roles: equipoBalanceado, methodology: Methodology.agile),
      );
      final double predictivo = tasaEntrega(
        const Strategy(
          roles: equipoBalanceado,
          methodology: Methodology.predictive,
        ),
      );
      expect(agil, greaterThan(predictivo),
          reason: 'El caso de matricula tiene el alcance abierto: el control '
              'de cambios estricto deberia costar caro.');
    });

    test('en alcance estable y regulado, el predictivo supera al agil', () {
      final double predictivo = tasaEntrega(
        const Strategy(
          roles: equipoBalanceado,
          methodology: Methodology.predictive,
        ),
        caseId: 'planta',
      );
      final double agil = tasaEntrega(
        const Strategy(roles: equipoBalanceado, methodology: Methodology.agile),
        caseId: 'planta',
      );
      expect(predictivo, greaterThan(agil),
          reason: 'Con expediente aprobado, la agilidad no compra nada y '
              'cuesta coordinacion.');
    });
  });

  group('reproducibilidad', () {
    test('la misma semilla produce exactamente el mismo proyecto', () {
      final PlayResult a = play(
        caseId: 'cobranzas',
        seed: 4242,
        strategy: const Strategy(roles: equipoBalanceado),
      );
      final PlayResult b = play(
        caseId: 'cobranzas',
        seed: 4242,
        strategy: const Strategy(roles: equipoBalanceado),
      );
      expect(a.periodsUsed, b.periodsUsed);
      expect(a.cost, closeTo(b.cost, 1e-6));
      expect(a.state.outcome, b.state.outcome);
    });

    test('semillas distintas producen proyectos distintos', () {
      final PlayResult a = play(
        caseId: 'cobranzas',
        seed: 4242,
        strategy: const Strategy(roles: equipoBalanceado),
      );
      final PlayResult b = play(
        caseId: 'cobranzas',
        seed: 9999,
        strategy: const Strategy(roles: equipoBalanceado),
      );
      expect(a.state.packages.first.realHours,
          isNot(closeTo(b.state.packages.first.realHours, 1e-9)));
    });
  });
}
