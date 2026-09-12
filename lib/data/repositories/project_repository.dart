import 'dart:math' as math;

import '../models/advisor_message.dart';
import '../models/baseline.dart';
import '../models/change_request.dart';
import '../models/evaluation_report.dart';
import '../models/methodology.dart';
import '../models/period_result.dart';
import '../models/project_config.dart';
import '../models/project_session.dart';
import '../models/project_state.dart';
import '../models/risk_item.dart';
import '../models/team_member.dart';
import '../models/work_package.dart';
import '../services/evaluation_service.dart';
import '../services/evm_calculator.dart';
import '../services/execution_engine.dart';
import '../services/local_storage_service.dart';
import '../services/pm_advisor.dart';
import '../services/project_generator.dart';
import '../services/risk_engine.dart';

/// Punto único de acceso al dominio.
///
/// Los ViewModels no conocen los motores ni la persistencia: hablan con este
/// repositorio. Sustituir el almacenamiento local o afinar la simulación no
/// obliga a tocar una sola pantalla.
class ProjectRepository {
  ProjectRepository({
    LocalStorageService? storage,
    this.config = const ProjectConfig(),
  }) : _storage = storage ?? LocalStorageService();

  final LocalStorageService _storage;
  final ProjectConfig config;

  late final ProjectGenerator _generator = ProjectGenerator(config: config);
  late final ExecutionEngine _engine = ExecutionEngine(config: config);
  late final RiskEngine _risk = RiskEngine(config: config);
  late final PmAdvisor _advisor = PmAdvisor(config: config);
  late final EvaluationService _evaluator = EvaluationService(config: config);
  final EvmCalculator evm = const EvmCalculator();

  PmAdvisor get advisor => _advisor;

  // ------------------------------------------------------------------
  // Ciclo de vida de la partida
  // ------------------------------------------------------------------

  ProjectSession createSession({
    required String caseId,
    required Methodology methodology,
    required ConstraintPriority priority,
    int? seed,
    String playerName = '',
  }) {
    final int usedSeed = seed ?? ProjectGenerator.randomSeed();
    final ProjectState state = _generator.generate(
      caseId: caseId,
      seed: usedSeed,
      methodology: methodology,
      priority: priority,
    );
    return ProjectSession(
      id: 'pms-${DateTime.now().millisecondsSinceEpoch}',
      seed: usedSeed,
      startedAt: DateTime.now(),
      state: state,
      history: <PeriodResult>[],
      playerName: playerName,
    );
  }

  Future<ProjectSession?> loadSession() async {
    final Map<String, dynamic>? raw = await _storage.loadSession();
    if (raw == null) return null;
    try {
      return ProjectSession.fromJson(raw);
    } catch (_) {
      await _storage.clearSession();
      return null;
    }
  }

  Future<void> saveSession(ProjectSession session) =>
      _storage.saveSession(session.toJson());

  Future<void> clearSession() => _storage.clearSession();

  Future<List<Map<String, dynamic>>> finishedSessions() =>
      _storage.loadFinished();

  Future<void> archive(ProjectSession session, EvaluationReport report) =>
      _storage.addFinished(<String, dynamic>{
        'id': session.id,
        'seed': session.seed,
        'caseId': session.state.caseId,
        'caseName': session.state.projectCase.name,
        'methodology': session.state.methodology.shortLabel,
        'outcome': session.state.outcome.label,
        'score': report.overallScore,
        'periods': report.periodsUsed,
        'cost': report.finalCost,
        'finishedAt': DateTime.now().toIso8601String(),
      });

  Future<void> clearFinished() => _storage.clearFinished();

  Future<bool> hasSeenIntro() => _storage.hasSeenIntro();
  Future<void> markIntroSeen() => _storage.markIntroSeen();

  // ------------------------------------------------------------------
  // Equipo
  // ------------------------------------------------------------------

  /// Incorpora a alguien al equipo.
  ///
  /// Antes de que empiece la ejecución, el equipo arranca rodado; después, la
  /// persona entra en curva de aprendizaje, que es exactamente el costo que la
  /// ley de Brooks describe.
  TeamMember hire(ProjectState state, String roleId) {
    final TeamRole role = TeamRole.byId(roleId);
    final int index = state.nextMemberIndex++;
    final bool preExecution = state.stage != ProjectStage.execution;
    final TeamMember member = TeamMember(
      id: 'm$index',
      roleId: roleId,
      name: '${role.label} $index',
      joinedPeriod: state.period,
      periodsOnTeam: preExecution ? role.rampPeriods : 0,
    );
    state.team.add(member);
    return member;
  }

  void release(ProjectState state, String memberId) {
    state.team.removeWhere((TeamMember m) => m.id == memberId);
  }

  void assign(ProjectState state, String memberId, String? packageId) {
    for (final TeamMember m in state.team) {
      if (m.id == memberId) m.assignedPackageId = packageId;
    }
  }

  /// Asignación automática del equipo sobre los paquetes habilitados.
  ///
  /// No reparte por turnos: calcula cuántas personas necesita cada paquete
  /// según el trabajo que le queda y las coloca en orden de fase. Poner cinco
  /// personas en un paquete al que le faltan diez horas no lo termina antes,
  /// solo deja cuatro sin nada que hacer. Es la versión automática de la
  /// pregunta que el estudiante debería hacerse cada periodo: cuánta gente
  /// cabe realmente en este trabajo.
  void autoAssign(ProjectState state) {
    final List<WorkPackage> available = state.availablePackages();
    if (available.isEmpty) {
      for (final TeamMember m in state.team) {
        m.assignedPackageId = null;
      }
      return;
    }
    available.sort((WorkPackage a, WorkPackage b) {
      final int phase = a.phase.order.compareTo(b.phase.order);
      if (phase != 0) return phase;
      return b.estimatedHours.compareTo(a.estimatedHours);
    });

    if (state.team.isEmpty) return;
    final double capacity = state.effectiveCapacity(config);
    final double share =
        capacity <= 0 ? 1 : math.max(1.0, capacity / state.team.length);

    final List<String> slots = <String>[];
    for (final WorkPackage p in available) {
      final double pending = p.estimatedHours * (1 - p.progress);
      final int needed = math.max(1, (pending / share).ceil());
      for (int i = 0; i < needed; i++) {
        slots.add(p.id);
      }
    }

    for (int i = 0; i < state.team.length; i++) {
      state.team[i].assignedPackageId =
          i < slots.length ? slots[i] : available[i % available.length].id;
    }
  }

  // ------------------------------------------------------------------
  // Alcance y línea base
  // ------------------------------------------------------------------

  void toggleScope(ProjectState state, String packageId) {
    final WorkPackage? p = state.packageById(packageId);
    if (p == null || !p.optional) return;
    if (p.workedHours > 0) return;
    p.included = !p.included;
  }

  void setQaLevel(ProjectState state, double level) {
    state.qaLevel = level.clamp(0.0, 1.0).toDouble();
  }

  void setMethodology(ProjectState state, Methodology methodology) {
    if (state.stage == ProjectStage.execution) return;
    state.methodology = methodology;
  }

  void setPriority(ProjectState state, ConstraintPriority priority) {
    if (state.stage == ProjectStage.execution) return;
    state.priority = priority;
  }

  /// Compromete la línea base y abre la ejecución.
  void commitBaseline({
    required ProjectState state,
    required int committedPeriods,
    required double contingencyRate,
  }) {
    final double plannedCost = state.teamCostPerPeriod() * committedPeriods;
    state.baseline = Baseline(
      committedPeriods: committedPeriods,
      plannedCost: plannedCost,
      contingencyReserve: plannedCost * contingencyRate,
      scopeHours: state.scopeEstimatedHours,
      qaLevel: state.qaLevel,
      teamSize: state.team.length,
      committedAtPeriod: state.period,
    );
    state.stage = ProjectStage.execution;
    autoAssign(state);
  }

  // ------------------------------------------------------------------
  // Riesgos
  // ------------------------------------------------------------------

  /// Costo en dinero de un taller de identificación.
  double workshopCost(ProjectState state) =>
      state.hourValue(config) * 40 + 3000;

  List<RiskItem> runWorkshop(ProjectState state, int seed) {
    state.actualCost += workshopCost(state);
    return _risk.runIdentificationWorkshop(state: state, seed: seed);
  }

  /// Aplica una respuesta a un riesgo y cobra su costo por adelantado.
  void respondToRisk(ProjectState state, String riskId, RiskResponse response) {
    for (final RiskItem r in state.risks) {
      if (r.id != riskId || !r.identified || r.occurred) continue;
      final double before = r.responseCost;
      r.response = response;
      final double delta = r.responseCost - before;
      if (delta > 0) {
        state.actualCost += delta;
        state.reserveUsed += delta;
      }
      if (response == RiskResponse.avoid) {
        // Evitar significa cambiar el plan: se cede alcance opcional.
        for (final WorkPackage p in state.packages) {
          if (p.optional && p.included && p.workedHours <= 0) {
            p.included = false;
            break;
          }
        }
      }
    }
  }

  // ------------------------------------------------------------------
  // Cambios
  // ------------------------------------------------------------------

  void decideChange(
    ProjectState state,
    String changeId,
    ChangeDecision decision,
  ) {
    for (final ChangeRequest c in state.changes) {
      if (c.id == changeId) {
        _engine.applyChangeDecision(
          state: state,
          change: c,
          decision: decision,
        );
      }
    }
  }

  // ------------------------------------------------------------------
  // Ejecución
  // ------------------------------------------------------------------

  PeriodResult runPeriod({
    required ProjectSession session,
    required bool overtime,
  }) {
    final PeriodResult result = runPeriodOn(
      state: session.state,
      seed: session.seed,
      overtime: overtime,
    );
    session.history.add(result);
    return result;
  }

  /// Ejecuta un periodo sobre un estado suelto, sin partida asociada.
  ///
  /// Es la puerta que usan las pruebas para jugar simulaciones completas sin
  /// interfaz ni almacenamiento, y con ella se verifica que la calibración
  /// siga siendo la que se documentó.
  PeriodResult runPeriodOn({
    required ProjectState state,
    required int seed,
    required bool overtime,
  }) =>
      _engine.runPeriod(state: state, overtime: overtime, seed: seed);

  List<AdvisorMessage> advise(ProjectSession session) => _advisor.execute(
        state: session.state,
        last: session.history.isEmpty ? null : session.history.last,
      );

  List<AdvisorMessage> planningAdvice({
    required ProjectState state,
    required int committedPeriods,
    required double contingencyRate,
  }) =>
      _advisor.planningAdvice(
        state: state,
        committedPeriods: committedPeriods,
        contingencyRate: contingencyRate,
      );

  EvaluationReport evaluate(ProjectSession session) => _evaluator.build(
        state: session.state,
        history: session.history,
      );

  /// Cierre anticipado decidido por el estudiante.
  void closeEarly(ProjectSession session) {
    final ProjectState state = session.state;
    if (state.outcome.isFinished) return;
    state.escapedDefects += state.latentDefects;
    state.latentDefects = 0;
    state.outcome = state.isComplete
        ? ProjectOutcome.delivered
        : ProjectOutcome.abandoned;
    state.stage = ProjectStage.closure;
  }
}
