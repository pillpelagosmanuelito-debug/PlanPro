import 'dart:math' as math;

import '../models/baseline.dart';
import '../models/change_request.dart';
import '../models/evm_snapshot.dart';
import '../models/period_result.dart';
import '../models/project_case.dart';
import '../models/project_config.dart';
import '../models/project_state.dart';
import '../models/team_member.dart';
import '../models/work_package.dart';
import 'evm_calculator.dart';
import 'risk_engine.dart';

/// Motor de ejecucion: convierte las decisiones del periodo en resultados.
///
/// Toda la fisica del simulador vive aqui y en [RiskEngine]. La regla que
/// gobierna el diseno es que ninguna decision sea gratis: sumar gente cuesta
/// comunicacion y curva de aprendizaje, recortar calidad cuesta retrabajo,
/// autorizar horas extra cuesta dinero y fatiga, y no asignar a alguien cuesta
/// la capacidad completa de esa persona.
class ExecutionEngine {
  const ExecutionEngine({
    this.config = const ProjectConfig(),
    this.evm = const EvmCalculator(),
  });

  final ProjectConfig config;
  final EvmCalculator evm;

  RiskEngine get _risk => RiskEngine(config: config);

  /// Ejecuta un periodo completo y devuelve lo que ocurrio.
  ///
  /// Muta [state]: al terminar, [ProjectState.period] apunta al siguiente
  /// periodo y [ProjectState.outcome] refleja si el proyecto termino.
  PeriodResult runPeriod({
    required ProjectState state,
    required bool overtime,
    required int seed,
  }) {
    final int period = state.period;

    // 1. Capacidad -------------------------------------------------------
    final double capacity = state.effectiveCapacity(config, overtime: overtime);
    double rawSum = 0;
    for (final TeamMember m in state.team) {
      rawSum += m.effectiveHours(config.hoursPerPerson);
    }
    final double teamMultiplier = rawSum <= 0 ? 0.0 : capacity / rawSum;

    // 2. Deteccion de defectos -------------------------------------------
    //
    // Se resuelve ANTES de aplicar el trabajo del periodo, y no despues: si el
    // retrabajo apareciera al final, reabriria el paquete de correccion ya
    // terminado y el equipo tendria que esperar al periodo siguiente para
    // atacarlo. Detectar primero permite que la capacidad del periodo lo
    // absorba, que es lo que ocurre en un proyecto real cuando pruebas y
    // correccion conviven en la misma iteracion.
    double defectsFound = 0;
    double reworkHours = 0;
    final double testProgress = state.phaseProgress(ProjectPhase.test);
    if (testProgress > 0.10 && state.latentDefects > 1e-6) {
      final double share =
          math.min(config.detectionCap, testProgress * config.detectionSlope);
      defectsFound = state.latentDefects * share;
      state.latentDefects -= defectsFound;
      reworkHours = defectsFound * config.lateFixMultiplier;
      final WorkPackage? corrective = _correctivePackage(state);
      if (corrective != null) {
        corrective.realHours += reworkHours;
        corrective.reworkHours += reworkHours;
      }
    }
    if (state.latentDefects > 0 && state.latentDefects < config.escapeFloor) {
      // Lo que queda es demasiado poco para que una campania de pruebas lo
      // encuentre: llega al cliente.
      state.escapedDefects += state.latentDefects;
      state.latentDefects = 0;
    }

    // 3. Aplicacion del trabajo ------------------------------------------
    final Set<String> preDone = <String>{
      for (final WorkPackage p in state.packages)
        if (p.isDone) p.id,
    };
    final Map<String, double> applied = <String, double>{};
    final List<String> completed = <String>[];
    double appliedHours = 0;
    double wastedHours = 0;

    for (final TeamMember m in state.team) {
      final double hours = m.effectiveHours(config.hoursPerPerson) * teamMultiplier;
      if (hours <= 0) continue;
      final double lost = _applyHours(
        state: state,
        packageId: m.assignedPackageId,
        hours: hours,
        applied: applied,
        completed: completed,
        preDone: preDone,
      );
      wastedHours += lost;
      appliedHours += hours - lost;
    }

    // 4. Costo del periodo ------------------------------------------------
    final double periodCost = state.teamCostPerPeriod() *
        (overtime ? config.overtimeCostFactor : 1.0);
    state.actualCost += periodCost;

    // 5. Fatiga ------------------------------------------------------------
    if (overtime) {
      state.overtimePeriods++;
      state.fatigue = math.min(0.35, state.fatigue + config.overtimeFatigue);
    } else {
      state.fatigue = math.max(0, state.fatigue - config.fatigueRecovery);
    }

    // 6. Riesgos -----------------------------------------------------------
    final List<RiskEvent> events =
        _risk.evaluate(state: state, period: period, seed: seed);

    // 7. Solicitudes de cambio --------------------------------------------
    final List<ChangeRequest> nuevos = _spawnChanges(state, period);
    state.changes.addAll(nuevos);

    // Dejar una solicitud sin responder desgasta la relacion: el silencio
    // tambien es una decision, y la peor de todas.
    final int stillPending = state.pendingChanges
        .where((ChangeRequest c) => c.period < period)
        .length;
    state.sponsorSatisfaction -= 2.0 * stillPending;

    // 8. Antiguedad del equipo --------------------------------------------
    for (final TeamMember m in state.team) {
      m.periodsOnTeam++;
    }

    // 9. Indicadores -------------------------------------------------------
    state.sponsorSatisfaction = state.sponsorSatisfaction.clamp(0.0, 100.0);
    final EvmSnapshot snapshot = evm.snapshot(state: state, period: period);
    state.snapshots.add(snapshot);

    final List<PackageProgress> progressList = <PackageProgress>[];
    applied.forEach((String id, double hours) {
      final WorkPackage? p = state.packageById(id);
      if (p == null) return;
      progressList.add(PackageProgress(
        packageId: p.id,
        packageName: p.name,
        hoursApplied: hours,
        progressAfter: p.progress,
        completed: p.isDone,
      ));
    });
    progressList.sort((PackageProgress a, PackageProgress b) =>
        b.hoursApplied.compareTo(a.hoursApplied));

    // 10. Avance del reloj y desenlace -------------------------------------
    state.period = period + 1;
    _resolveOutcome(state, period);

    return PeriodResult(
      period: period,
      capacity: capacity,
      appliedHours: appliedHours,
      wastedHours: wastedHours,
      periodCost: periodCost,
      overtime: overtime,
      progressByPackage: progressList,
      completedPackages: completed,
      risksTriggered: events.map((RiskEvent e) => e.narrative).toList(),
      defectsFound: defectsFound,
      reworkHours: reworkHours,
      newChanges: nuevos.map((ChangeRequest c) => c.title).toList(),
      evm: snapshot,
    );
  }

  // --------------------------------------------------------------------
  // Aplicacion de horas
  // --------------------------------------------------------------------

  /// Aplica [hours] al paquete indicado y devuelve las horas perdidas.
  ///
  /// Se distinguen dos situaciones que parecen iguales y no lo son:
  ///
  /// - La asignacion es invalida por decision del estudiante (nadie asignado,
  ///   paquete fuera del alcance, fase todavia bloqueada, o un paquete que ya
  ///   estaba terminado al empezar el periodo). Ahi las horas se pierden: la
  ///   aplicacion avisa antes de cerrar y aun asi se cerro.
  /// - El paquete lo termino otro integrante durante este mismo periodo. Eso
  ///   no es un error de direccion sino el curso normal del trabajo en
  ///   paralelo, asi que la persona se reasigna sola a otro paquete
  ///   habilitado, empezando por los de su propia fase.
  double _applyHours({
    required ProjectState state,
    required String? packageId,
    required double hours,
    required Map<String, double> applied,
    required List<String> completed,
    required Set<String> preDone,
  }) {
    double remaining = hours;
    WorkPackage? target = _validTarget(state, packageId, preDone);
    if (target == null) return remaining;

    if (target.isDone) {
      target = _spillTarget(state, target);
      if (target == null) return remaining;
    }

    int hops = 0;
    while (remaining > 1e-6 && target != null && hops < 12) {
      final double take = math.min(remaining, target.remainingHours);
      if (take <= 1e-9) break;
      target.workedHours += take;
      remaining -= take;
      applied.update(target.id, (double v) => v + take, ifAbsent: () => take);

      if (target.isDone) {
        completed.add(target.name);
        _generateDefects(state, target);
        target = _spillTarget(state, target);
        hops++;
      }
    }
    return remaining;
  }

  WorkPackage? _validTarget(
    ProjectState state,
    String? packageId,
    Set<String> preDone,
  ) {
    final WorkPackage? p = state.packageById(packageId);
    if (p == null) return null;
    if (!p.included) return null;
    if (preDone.contains(p.id)) return null;
    if (!state.phaseUnlocked(p.phase)) return null;
    return p;
  }

  /// Siguiente paquete donde derramar horas sobrantes.
  WorkPackage? _spillTarget(ProjectState state, WorkPackage finished) {
    final List<WorkPackage> options = state
        .availablePackages()
        .where((WorkPackage p) => p.id != finished.id)
        .toList();
    if (options.isEmpty) return null;
    options.sort((WorkPackage a, WorkPackage b) {
      final int samePhase = (b.phase == finished.phase ? 1 : 0)
          .compareTo(a.phase == finished.phase ? 1 : 0);
      if (samePhase != 0) return samePhase;
      return a.phase.order.compareTo(b.phase.order);
    });
    return options.first;
  }

  /// Defectos que deja un paquete al terminarse.
  ///
  /// Es la regla del 1-10-100 en dos tramos. El aseguramiento reduce cuantos
  /// defectos se generan, pero nunca hasta cero: al maximo nivel sigue
  /// quedando un 30%. Y de los que se generan, una parte escapa directamente
  /// al cliente sin pasar por pruebas, tanto mayor cuanto menor sea el
  /// control. Por eso recortar calidad no ahorra trabajo: cambia trabajo
  /// barato de hoy por retrabajo caro en pruebas y por defectos que nadie
  /// vera hasta que el sistema este en produccion.
  void _generateDefects(ProjectState state, WorkPackage pkg) {
    if (pkg.phase == ProjectPhase.test) return;
    final double created = pkg.estimatedHours *
        pkg.complexity *
        config.defectRatePerHour *
        (1 - config.qaDefectReduction * state.qaLevel);
    final double direct =
        created * config.directEscapeShare * (1 - state.qaLevel);
    pkg.defects = created;
    state.escapedDefects += direct;
    state.latentDefects += created - direct;
  }

  /// Paquete que absorbe el retrabajo por defectos.
  WorkPackage? _correctivePackage(ProjectState state) {
    for (final WorkPackage p in state.includedPackages) {
      if (p.phase == ProjectPhase.test && p.id == 't2') return p;
    }
    for (final WorkPackage p in state.includedPackages) {
      if (p.phase == ProjectPhase.test && !p.isDone) return p;
    }
    return null;
  }

  // --------------------------------------------------------------------
  // Solicitudes de cambio
  // --------------------------------------------------------------------

  /// Genera las solicitudes de cambio del periodo.
  ///
  /// No son aleatorias: el acta de constitucion ya avisaba que estos temas
  /// estaban abiertos. Un director atento reserva contingencia para ellas.
  List<ChangeRequest> _spawnChanges(ProjectState state, int period) {
    if (state.stage != ProjectStage.execution) return <ChangeRequest>[];
    final ProjectCase c = state.projectCase;
    final List<int> schedule =
        c.volatileRequirements ? <int>[4, 7] : <int>[6];
    if (!schedule.contains(period)) return <ChangeRequest>[];

    final int index = schedule.indexOf(period);
    final List<_ChangeTemplate> templates = _templatesFor(c.id);
    if (index >= templates.length) return <ChangeRequest>[];
    final _ChangeTemplate t = templates[index];

    final double hours = t.baseHours * state.methodology.changeCostFactor;
    return <ChangeRequest>[
      ChangeRequest(
        id: 'ch$period',
        period: period,
        title: t.title,
        requestedBy: t.requestedBy,
        description: t.description,
        baseHours: hours,
        targetPackageIds: t.targets,
      ),
    ];
  }

  List<_ChangeTemplate> _templatesFor(String caseId) {
    switch (caseId) {
      case 'planta':
        return const <_ChangeTemplate>[
          _ChangeTemplate(
            title: 'Tablero de control adicional en la sala de bombas',
            requestedBy: 'Area usuaria de operaciones',
            description:
                'Operaciones pide un tablero de control adicional para la '
                'sala de bombas. No estaba en el expediente tecnico, pero el '
                'area sostiene que sin el no podra operar la ampliacion.',
            baseHours: 90,
            targets: <String>['c2', 'c4'],
          ),
        ];
      case 'cobranzas':
        return const <_ChangeTemplate>[
          _ChangeTemplate(
            title: 'Nueva segmentacion de clientes',
            requestedBy: 'Gerencia comercial',
            description:
                'Comercial cerro su estrategia de contacto y ahora pide seis '
                'segmentos en lugar de dos, con reglas distintas de '
                'asignacion de cartera para cada uno.',
            baseHours: 90,
            targets: <String>['c1'],
          ),
          _ChangeTemplate(
            title: 'Registro reforzado de consentimiento',
            requestedBy: 'Oficialia de cumplimiento',
            description:
                'Cumplimiento precisa que cada gestion debe guardar evidencia '
                'del consentimiento del cliente y permitir su revocacion en '
                'linea. Es exigible por el regulador.',
            baseHours: 95,
            targets: <String>['c4'],
          ),
        ];
      default:
        return const <_ChangeTemplate>[
          _ChangeTemplate(
            title: 'Flujo de convalidaciones por escuela',
            requestedBy: 'Consejo de escuelas profesionales',
            description:
                'Las escuelas acordaron el proceso de convalidaciones y cada '
                'una quiere sus propias reglas de equivalencia, con '
                'aprobacion del director de escuela.',
            baseHours: 90,
            targets: <String>['c1'],
          ),
          _ChangeTemplate(
            title: 'Conciliacion de pagos en linea',
            requestedBy: 'Tesoreria',
            description:
                'Tesoreria pide que la conciliacion bancaria sea en linea y '
                'no nocturna, para liberar la matricula del estudiante en el '
                'momento del pago.',
            baseHours: 95,
            targets: <String>['c2'],
          ),
        ];
    }
  }

  /// Aplica la decision del director sobre una solicitud de cambio.
  ///
  /// Cada camino tiene un costo distinto y ninguno es gratis: aceptar sin
  /// mover la linea base es lo que mas gusta al patrocinador y lo que peor
  /// termina, porque el trabajo entra igual pero la promesa no cambia.
  void applyChangeDecision({
    required ProjectState state,
    required ChangeRequest change,
    required ChangeDecision decision,
  }) {
    if (!change.isPending) return;
    change.decision = decision;

    switch (decision) {
      case ChangeDecision.pending:
        return;
      case ChangeDecision.rejected:
        change.appliedHours = 0;
        break;
      case ChangeDecision.acceptedWithoutBaseline:
      case ChangeDecision.acceptedWithBaseline:
        change.appliedHours = _injectWork(state, change);
        break;
      case ChangeDecision.tradedOff:
        change.appliedHours = _injectWork(state, change);
        _dropOptionalScope(state, change.baseHours);
        break;
    }

    if (decision == ChangeDecision.acceptedWithBaseline) {
      final Baseline? current = state.baseline;
      if (current != null) {
        // Renegociar es un acto formal: se reconoce el trabajo nuevo en el
        // presupuesto y se registra la revision.
        state.baseline = current.copyWith(
          plannedCost: current.plannedCost +
              change.baseHours * state.hourValue(config),
          revisions: current.revisions + 1,
        );
      }
    }

    state.sponsorSatisfaction =
        (state.sponsorSatisfaction + change.satisfactionDelta())
            .clamp(0.0, 100.0);
  }

  double _injectWork(ProjectState state, ChangeRequest change) {
    final List<WorkPackage> targets = <WorkPackage>[];
    for (final String id in change.targetPackageIds) {
      final WorkPackage? p = state.packageById(id);
      if (p != null && p.included) targets.add(p);
    }
    if (targets.isEmpty) {
      final List<WorkPackage> fallback = state.includedPackages
          .where((WorkPackage p) => !p.isDone)
          .toList();
      if (fallback.isEmpty) return 0;
      targets.add(fallback.first);
    }
    final double each = change.baseHours / targets.length;
    for (final WorkPackage p in targets) {
      p.realHours += each;
    }
    return change.baseHours;
  }

  /// Saca alcance opcional equivalente para que el proyecto no crezca.
  void _dropOptionalScope(ProjectState state, double hours) {
    double removed = 0;
    for (final WorkPackage p in state.packages) {
      if (removed >= hours) break;
      if (!p.included || !p.optional || p.workedHours > 0) continue;
      p.included = false;
      removed += p.estimatedHours;
    }
  }

  // --------------------------------------------------------------------
  // Desenlace
  // --------------------------------------------------------------------

  void _resolveOutcome(ProjectState state, int finishedPeriod) {
    if (state.outcome.isFinished) return;
    final ProjectCase c = state.projectCase;

    if (state.isComplete) {
      final int committed =
          state.baseline?.committedPeriods ?? c.targetPeriods;
      state.outcome = finishedPeriod <= committed
          ? ProjectOutcome.delivered
          : ProjectOutcome.deliveredLate;
      state.escapedDefects += state.latentDefects;
      state.latentDefects = 0;
      state.stage = ProjectStage.closure;
      return;
    }

    if (state.actualCost > c.budgetCeiling * 1.15 ||
        state.sponsorSatisfaction <= 8) {
      state.outcome = ProjectOutcome.cancelled;
      state.escapedDefects += state.latentDefects;
      state.latentDefects = 0;
      state.stage = ProjectStage.closure;
      return;
    }

    if (finishedPeriod >= config.totalPeriods) {
      state.outcome = ProjectOutcome.abandoned;
      state.escapedDefects += state.latentDefects;
      state.latentDefects = 0;
      state.stage = ProjectStage.closure;
    }
  }
}

class _ChangeTemplate {
  const _ChangeTemplate({
    required this.title,
    required this.requestedBy,
    required this.description,
    required this.baseHours,
    required this.targets,
  });

  final String title;
  final String requestedBy;
  final String description;
  final double baseHours;
  final List<String> targets;
}
