import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_simulator/data/models/baseline.dart';
import 'package:project_management_simulator/data/models/evm_snapshot.dart';

/// La gestion del valor ganado es el instrumental que el estudiante debe
/// aprender a leer. Si estas cuentas estuvieran mal, el simulador ensenaria a
/// leer mal un tablero, que es peor que no tener tablero.
void main() {
  group('EvmSnapshot', () {
    const EvmSnapshot atrasadoYSobrecostado = EvmSnapshot(
      period: 6,
      plannedValue: 200000,
      earnedValue: 160000,
      actualCost: 200000,
      budgetAtCompletion: 400000,
    );

    test('SPI y CPI se calculan con la definicion estandar', () {
      expect(atrasadoYSobrecostado.spi, closeTo(0.80, 1e-9));
      expect(atrasadoYSobrecostado.cpi, closeTo(0.80, 1e-9));
    });

    test('las variaciones son consistentes con los indices', () {
      expect(atrasadoYSobrecostado.scheduleVariance, closeTo(-40000, 1e-9));
      expect(atrasadoYSobrecostado.costVariance, closeTo(-40000, 1e-9));
    });

    test('la estimacion a la conclusion proyecta el desempenio observado', () {
      expect(atrasadoYSobrecostado.estimateAtCompletion, closeTo(500000, 1e-9));
      expect(atrasadoYSobrecostado.estimateToComplete, closeTo(300000, 1e-9));
      expect(atrasadoYSobrecostado.varianceAtCompletion, closeTo(-100000, 1e-9));
    });

    test('el TCPI expresa la eficiencia que falta para cerrar en presupuesto',
        () {
      // Falta ganar 240,000 con 200,000 disponibles: hay que rendir 1.20.
      expect(atrasadoYSobrecostado.tcpi, closeTo(1.20, 1e-9));
    });

    test('la lectura traduce los indices a lenguaje de direccion', () {
      expect(atrasadoYSobrecostado.reading, 'Atrasado y sobrecostado');
      expect(
        const EvmSnapshot(
          period: 3,
          plannedValue: 100000,
          earnedValue: 100000,
          actualCost: 100000,
          budgetAtCompletion: 400000,
        ).reading,
        'Dentro de lo planificado',
      );
      expect(
        const EvmSnapshot(
          period: 3,
          plannedValue: 100000,
          earnedValue: 80000,
          actualCost: 80000,
          budgetAtCompletion: 400000,
        ).reading,
        'Atrasado, dentro de costo',
      );
    });

    test('sin costo real todavia, los indices no se disparan', () {
      const EvmSnapshot inicio = EvmSnapshot(
        period: 1,
        plannedValue: 0,
        earnedValue: 0,
        actualCost: 0,
        budgetAtCompletion: 400000,
      );
      expect(inicio.spi, 1.0);
      expect(inicio.cpi, 1.0);
      expect(inicio.progress, 0.0);
    });

    test('sobrevive a un presupuesto agotado sin producir NaN', () {
      const EvmSnapshot agotado = EvmSnapshot(
        period: 10,
        plannedValue: 400000,
        earnedValue: 300000,
        actualCost: 400000,
        budgetAtCompletion: 400000,
      );
      expect(agotado.tcpi, double.infinity);
      expect(agotado.estimateAtCompletion.isFinite, isTrue);
    });
  });

  group('Baseline', () {
    const Baseline linea = Baseline(
      committedPeriods: 10,
      plannedCost: 300000,
      contingencyReserve: 30000,
      scopeHours: 2000,
      qaLevel: 0.5,
      teamSize: 5,
      committedAtPeriod: 1,
    );

    test('el presupuesto hasta la conclusion incluye la reserva', () {
      expect(linea.budgetAtCompletion, 330000);
    });

    test('renegociar deja constancia de la revision', () {
      final Baseline revisada = linea.copyWith(
        plannedCost: 320000,
        revisions: linea.revisions + 1,
      );
      expect(revisada.revisions, 1);
      expect(revisada.budgetAtCompletion, 350000);
      expect(revisada.scopeHours, linea.scopeHours);
    });

    test('sobrevive a un ida y vuelta por JSON', () {
      final Baseline copia = Baseline.fromJson(linea.toJson());
      expect(copia.committedPeriods, linea.committedPeriods);
      expect(copia.budgetAtCompletion, linea.budgetAtCompletion);
    });
  });
}
