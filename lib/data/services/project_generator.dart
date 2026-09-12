import 'dart:math' as math;

import '../models/change_request.dart';
import '../models/evm_snapshot.dart';
import '../models/methodology.dart';
import '../models/project_case.dart';
import '../models/project_config.dart';
import '../models/project_state.dart';
import '../models/risk_item.dart';
import '../models/team_member.dart';
import '../models/work_package.dart';

/// Construye el proyecto real a partir de una semilla.
///
/// La duración real de cada paquete queda oculta: el estudiante solo ve la
/// estimación del equipo, que es sistemáticamente optimista. Dos estudiantes
/// con la misma semilla enfrentan el mismo proyecto, de modo que las
/// diferencias de resultado se explican por sus decisiones.
class ProjectGenerator {
  const ProjectGenerator({this.config = const ProjectConfig()});

  final ProjectConfig config;

  ProjectState generate({
    required String caseId,
    required int seed,
    required Methodology methodology,
    required ConstraintPriority priority,
  }) {
    final ProjectCase projectCase = ProjectCase.byId(caseId);
    final math.Random random = math.Random(seed);

    final double rework = methodology.reworkFactor(
      volatileRequirements: projectCase.volatileRequirements,
    );

    final List<WorkPackage> packages = <WorkPackage>[];
    for (final PackageSpec spec in projectCase.packages) {
      final double factor = _lognormal(
        random,
        config.estimationBias,
        config.estimationSpread,
      );
      // La complejidad amplifica la desviación, no el trabajo base.
      final double adjusted = 1 + (factor - 1) * spec.complexity;
      final double real = spec.estimatedHours *
          adjusted *
          (1 + rework * config.reworkCoefficient);
      packages.add(WorkPackage.fromSpec(spec, real));
    }

    // Riesgos: dos visibles desde el acta, el resto solo con análisis.
    final List<RiskItem> risks = projectCase.riskIds
        .map((String id) => RiskItem.fromCatalog(id))
        .toList();
    final List<int> order = List<int>.generate(risks.length, (int i) => i);
    order.shuffle(random);
    for (int i = 0; i < order.length && i < 2; i++) {
      risks[order[i]].identified = true;
    }

    return ProjectState(
      caseId: caseId,
      stage: ProjectStage.initiation,
      period: 1,
      methodology: methodology,
      priority: priority,
      qaLevel: 0.5,
      packages: packages,
      team: <TeamMember>[],
      risks: risks,
      changes: <ChangeRequest>[],
      snapshots: <EvmSnapshot>[],
    );
  }

  /// Muestra lognormal: modela que las tareas casi nunca terminan antes y a
  /// veces terminan mucho después.
  double _lognormal(math.Random random, double median, double sigma) {
    final double u1 = math.max(1e-9, random.nextDouble());
    final double u2 = random.nextDouble();
    final double z =
        math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
    return math.exp(math.log(median) + sigma * z);
  }

  static int randomSeed() =>
      DateTime.now().millisecondsSinceEpoch.remainder(900000) + 1000;
}
