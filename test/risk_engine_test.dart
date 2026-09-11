import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_simulator/data/models/methodology.dart';
import 'package:project_management_simulator/data/models/project_state.dart';
import 'package:project_management_simulator/data/models/risk_item.dart';
import 'package:project_management_simulator/data/repositories/project_repository.dart';
import 'package:project_management_simulator/data/services/project_generator.dart';
import 'package:project_management_simulator/data/services/risk_engine.dart';

void main() {
  const RiskEngine engine = RiskEngine();

  ProjectState estado({int seed = 77}) => const ProjectGenerator().generate(
        caseId: 'matricula',
        seed: seed,
        methodology: Methodology.agile,
        priority: ConstraintPriority.time,
      );

  group('registro inicial', () {
    test('el acta solo revela dos riesgos', () {
      final ProjectState s = estado();
      expect(s.identifiedRisks.length, 2);
      expect(s.risks.length, greaterThan(2),
          reason: 'Debe haber riesgos fuera del registro desde el inicio.');
    });

    test('los riesgos no identificados existen igual', () {
      final ProjectState s = estado();
      final int ocultos =
          s.risks.where((RiskItem r) => !r.identified).length;
      expect(ocultos, greaterThan(0));
    });
  });

  group('respuestas', () {
    test('evitar elimina la probabilidad', () {
      final RiskItem r = RiskItem.fromCatalog('key_person');
      r.response = RiskResponse.avoid;
      expect(r.effectiveProbability, 0);
      expect(r.effectiveImpactHours, 0);
      expect(r.exposure(60), 0);
    });

    test('mitigar reduce la probabilidad y algo del impacto', () {
      final RiskItem base = RiskItem.fromCatalog('integration');
      final RiskItem mitigado = RiskItem.fromCatalog('integration');
      mitigado.response = RiskResponse.mitigate;
      expect(mitigado.effectiveProbability,
          lessThan(base.effectiveProbability));
      expect(mitigado.exposure(60), lessThan(base.exposure(60)));
      expect(mitigado.responseCost, base.mitigationCost);
    });

    test('transferir no cambia la probabilidad pero si quien paga', () {
      final RiskItem base = RiskItem.fromCatalog('vendor_delay');
      final RiskItem transferido = RiskItem.fromCatalog('vendor_delay');
      transferido.response = RiskResponse.transfer;
      expect(transferido.effectiveProbability,
          closeTo(base.effectiveProbability, 1e-9));
      expect(transferido.effectiveImpactCost,
          lessThan(base.effectiveImpactCost));
    });

    test('aceptar es una decision valida y no cuesta por adelantado', () {
      final RiskItem r = RiskItem.fromCatalog('infra_outage');
      r.response = RiskResponse.accept;
      expect(r.responseCost, 0);
      expect(r.effectiveProbability, r.baseProbability);
    });
  });

  group('materializacion', () {
    test('un riesgo evitado nunca ocurre', () {
      final ProjectState s = estado();
      for (final RiskItem r in s.risks) {
        r.identified = true;
        r.response = RiskResponse.avoid;
      }
      for (int period = 1; period <= 12; period++) {
        engine.evaluate(state: s, period: period, seed: 99);
      }
      expect(s.risks.every((RiskItem r) => !r.occurred), isTrue);
    });

    test('un riesgo fuera de su ventana no puede ocurrir', () {
      final ProjectState s = estado();
      for (final RiskItem r in s.risks) {
        r.identified = true;
      }
      engine.evaluate(state: s, period: 1, seed: 5);
      for (final RiskItem r in s.risks) {
        if (r.occurred) {
          expect(r.window, contains(1));
        }
      }
    });

    test('el riesgo no identificado castiga mas la relacion con el patrocinador',
        () {
      double caida({required bool identificado}) {
        final ProjectState s = estado(seed: 31);
        for (final RiskItem r in s.risks) {
          r.identified = identificado;
          r.response = RiskResponse.none;
        }
        final double antes = s.sponsorSatisfaction;
        for (int period = 1; period <= 12; period++) {
          engine.evaluate(state: s, period: period, seed: 31);
        }
        return antes - s.sponsorSatisfaction;
      }

      expect(caida(identificado: false), greaterThan(caida(identificado: true)));
    });
  });

  group('taller de identificacion', () {
    test('revela riesgos ocultos y deja registro del taller', () {
      final ProjectState s = estado();
      final int antes = s.identifiedRisks.length;
      final List<RiskItem> revelados =
          engine.runIdentificationWorkshop(state: s, seed: 12);
      expect(revelados, isNotEmpty);
      expect(s.identifiedRisks.length, greaterThan(antes));
      expect(s.riskWorkshops, 1);
    });

    test('no revela nada cuando ya no queda nada oculto', () {
      final ProjectState s = estado();
      for (final RiskItem r in s.risks) {
        r.identified = true;
      }
      expect(engine.runIdentificationWorkshop(state: s, seed: 12), isEmpty);
    });

    test('cuesta dinero al proyecto', () {
      final ProjectRepository repo = ProjectRepository();
      final ProjectState s = estado();
      repo.hire(s, 'senior');
      final double antes = s.actualCost;
      repo.runWorkshop(s, 4);
      expect(s.actualCost, greaterThan(antes));
    });
  });

  group('exposicion', () {
    test('se ordena por exposicion y no por impacto bruto', () {
      final RiskItem probable = RiskItem.fromCatalog('scope_pressure');
      final RiskItem grave = RiskItem.fromCatalog('infra_outage');
      // scope_pressure es mas probable; infra_outage pega menos y menos veces.
      expect(probable.exposure(60), greaterThan(grave.exposure(60)));
    });

    test('la exposicion total ignora los riesgos ya ocurridos', () {
      final ProjectState s = estado();
      for (final RiskItem r in s.risks) {
        r.identified = true;
      }
      final double total = s.riskExposure(60);
      s.risks.first.occurred = true;
      expect(s.riskExposure(60), lessThan(total));
    });
  });
}
