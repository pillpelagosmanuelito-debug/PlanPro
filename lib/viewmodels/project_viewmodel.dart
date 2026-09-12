import 'package:flutter/foundation.dart';

import '../data/models/advisor_message.dart';
import '../data/models/change_request.dart';
import '../data/models/evaluation_report.dart';
import '../data/models/methodology.dart';
import '../data/models/period_result.dart';
import '../data/models/project_config.dart';
import '../data/models/project_session.dart';
import '../data/models/project_state.dart';
import '../data/models/risk_item.dart';
import '../data/models/team_member.dart';
import '../data/models/work_package.dart';
import '../data/repositories/project_repository.dart';

/// Estado de carga de la aplicación.
enum ViewStatus { loading, ready, error }

/// Coordina la partida entre las vistas y el dominio.
///
/// Aplica el patrón MVVM: la vista observa este objeto y no conoce motores ni
/// almacenamiento; el ViewModel traduce intenciones ("contratar", "cerrar
/// periodo") en llamadas al repositorio y notifica el nuevo estado.
class ProjectViewModel extends ChangeNotifier {
  ProjectViewModel({ProjectRepository? repository})
      : _repository = repository ?? ProjectRepository();

  final ProjectRepository _repository;

  ViewStatus _status = ViewStatus.loading;
  ViewStatus get status => _status;

  String? _error;
  String? get error => _error;

  ProjectSession? _session;
  ProjectSession? get session => _session;

  ProjectState? get state => _session?.state;

  ProjectConfig get config => _repository.config;

  bool _seenIntro = false;
  bool get seenIntro => _seenIntro;

  List<Map<String, dynamic>> _finished = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> get finished => _finished;

  // Último periodo cerrado, para el resumen que ve el estudiante.
  PeriodResult? _lastResult;
  PeriodResult? get lastResult => _lastResult;

  // Riesgos revelados por el último taller.
  List<RiskItem> _lastRevealed = <RiskItem>[];
  List<RiskItem> get lastRevealed => _lastRevealed;

  EvaluationReport? _report;
  EvaluationReport? get report => _report;

  // Parámetros de la pantalla de planificación.
  int _plannedPeriods = 10;
  int get plannedPeriods => _plannedPeriods;

  double _contingencyRate = 0.10;
  double get contingencyRate => _contingencyRate;

  bool _overtimeNextPeriod = false;
  bool get overtimeNextPeriod => _overtimeNextPeriod;

  // ------------------------------------------------------------------
  // Carga
  // ------------------------------------------------------------------

  Future<void> init() async {
    _status = ViewStatus.loading;
    notifyListeners();
    try {
      _seenIntro = await _repository.hasSeenIntro();
      _session = await _repository.loadSession();
      _finished = await _repository.finishedSessions();
      if (_session != null && _session!.state.outcome.isFinished) {
        _report = _repository.evaluate(_session!);
      }
      _status = ViewStatus.ready;
    } catch (_) {
      _error = 'No se pudo cargar la partida guardada.';
      _status = ViewStatus.error;
    }
    notifyListeners();
  }

  Future<void> markIntroSeen() async {
    _seenIntro = true;
    await _repository.markIntroSeen();
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Partida
  // ------------------------------------------------------------------

  Future<void> startSession({
    required String caseId,
    required Methodology methodology,
    required ConstraintPriority priority,
    int? seed,
    String playerName = '',
  }) async {
    _session = _repository.createSession(
      caseId: caseId,
      methodology: methodology,
      priority: priority,
      seed: seed,
      playerName: playerName,
    );
    _lastResult = null;
    _lastRevealed = <RiskItem>[];
    _report = null;
    _plannedPeriods = _session!.state.projectCase.targetPeriods;
    _contingencyRate = 0.10;
    _overtimeNextPeriod = false;
    await _persist();
    notifyListeners();
  }

  Future<void> abandonSession() async {
    _session = null;
    _report = null;
    _lastResult = null;
    await _repository.clearSession();
    notifyListeners();
  }

  Future<void> _persist() async {
    final ProjectSession? s = _session;
    if (s == null) return;
    await _repository.saveSession(s);
  }

  // ------------------------------------------------------------------
  // Inicio y planificación
  // ------------------------------------------------------------------

  void goToPlanning() {
    final ProjectState? s = state;
    if (s == null || s.stage != ProjectStage.initiation) return;
    s.stage = ProjectStage.planning;
    _persist();
    notifyListeners();
  }

  /// Vuelve al acta de constitución desde la planificación.
  void backToCharter() {
    final ProjectState? s = state;
    if (s == null || s.stage != ProjectStage.planning) return;
    s.stage = ProjectStage.initiation;
    _persist();
    notifyListeners();
  }

  void setMethodology(Methodology m) {
    final ProjectState? s = state;
    if (s == null) return;
    _repository.setMethodology(s, m);
    _persist();
    notifyListeners();
  }

  void setPriority(ConstraintPriority p) {
    final ProjectState? s = state;
    if (s == null) return;
    _repository.setPriority(s, p);
    _persist();
    notifyListeners();
  }

  void hire(String roleId) {
    final ProjectState? s = state;
    if (s == null) return;
    _repository.hire(s, roleId);
    _persist();
    notifyListeners();
  }

  void release(String memberId) {
    final ProjectState? s = state;
    if (s == null) return;
    _repository.release(s, memberId);
    _persist();
    notifyListeners();
  }

  void assign(String memberId, String? packageId) {
    final ProjectState? s = state;
    if (s == null) return;
    _repository.assign(s, memberId, packageId);
    _persist();
    notifyListeners();
  }

  void autoAssign() {
    final ProjectState? s = state;
    if (s == null) return;
    _repository.autoAssign(s);
    _persist();
    notifyListeners();
  }

  void toggleScope(String packageId) {
    final ProjectState? s = state;
    if (s == null) return;
    _repository.toggleScope(s, packageId);
    _persist();
    notifyListeners();
  }

  void setQaLevel(double level) {
    final ProjectState? s = state;
    if (s == null) return;
    _repository.setQaLevel(s, level);
    _persist();
    notifyListeners();
  }

  void setPlannedPeriods(int periods) {
    _plannedPeriods = periods.clamp(3, config.totalPeriods);
    notifyListeners();
  }

  void setContingencyRate(double rate) {
    _contingencyRate = rate.clamp(0.0, config.contingencyMax).toDouble();
    notifyListeners();
  }

  List<AdvisorMessage> planningAdvice() {
    final ProjectState? s = state;
    if (s == null) return <AdvisorMessage>[];
    return _repository.planningAdvice(
      state: s,
      committedPeriods: _plannedPeriods,
      contingencyRate: _contingencyRate,
    );
  }

  /// Periodos que el alcance necesitaría con la capacidad actual.
  double periodsNeeded() {
    final ProjectState? s = state;
    if (s == null) return 0;
    final double capacity = s.effectiveCapacity(config);
    if (capacity <= 0) return double.infinity;
    return s.scopeEstimatedHours / capacity;
  }

  void commitBaseline() {
    final ProjectState? s = state;
    if (s == null || s.team.isEmpty) return;
    _repository.commitBaseline(
      state: s,
      committedPeriods: _plannedPeriods,
      contingencyRate: _contingencyRate,
    );
    _persist();
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Ejecución
  // ------------------------------------------------------------------

  void setOvertime(bool value) {
    _overtimeNextPeriod = value;
    notifyListeners();
  }

  bool get canRunPeriod {
    final ProjectState? s = state;
    if (s == null) return false;
    if (s.stage != ProjectStage.execution) return false;
    if (s.outcome.isFinished) return false;
    return s.team.isNotEmpty;
  }

  /// Personas sin trabajo valido para el periodo en curso.
  List<TeamMember> unassignedMembers() {
    final ProjectState? s = state;
    if (s == null) return <TeamMember>[];
    return s.team.where((TeamMember m) {
      final WorkPackage? p = s.packageById(m.assignedPackageId);
      if (p == null || !p.included || p.isDone) return true;
      return !s.phaseUnlocked(p.phase);
    }).toList();
  }

  Future<void> runPeriod() async {
    final ProjectSession? sess = _session;
    if (sess == null || !canRunPeriod) return;
    _lastResult = _repository.runPeriod(
      session: sess,
      overtime: _overtimeNextPeriod,
    );
    _overtimeNextPeriod = false;
    _lastRevealed = <RiskItem>[];
    if (sess.state.outcome.isFinished) {
      _report = _repository.evaluate(sess);
      await _repository.archive(sess, _report!);
      _finished = await _repository.finishedSessions();
    }
    await _persist();
    notifyListeners();
  }

  void dismissLastResult() {
    _lastResult = null;
    notifyListeners();
  }

  List<AdvisorMessage> advice() {
    final ProjectSession? sess = _session;
    if (sess == null) return <AdvisorMessage>[];
    return _repository.advise(sess);
  }

  String advisorHeadline() {
    final ProjectState? s = state;
    if (s == null) return '';
    return _repository.advisor.headline(s);
  }

  // ------------------------------------------------------------------
  // Riesgos
  // ------------------------------------------------------------------

  double get workshopCost {
    final ProjectState? s = state;
    return s == null ? 0 : _repository.workshopCost(s);
  }

  void runWorkshop() {
    final ProjectSession? sess = _session;
    if (sess == null) return;
    _lastRevealed = _repository.runWorkshop(sess.state, sess.seed);
    _persist();
    notifyListeners();
  }

  void respondToRisk(String riskId, RiskResponse response) {
    final ProjectState? s = state;
    if (s == null) return;
    _repository.respondToRisk(s, riskId, response);
    _persist();
    notifyListeners();
  }

  void clearRevealed() {
    _lastRevealed = <RiskItem>[];
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Cambios
  // ------------------------------------------------------------------

  void decideChange(String changeId, ChangeDecision decision) {
    final ProjectState? s = state;
    if (s == null) return;
    _repository.decideChange(s, changeId, decision);
    _persist();
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Cierre
  // ------------------------------------------------------------------

  Future<void> closeProject() async {
    final ProjectSession? sess = _session;
    if (sess == null) return;
    _repository.closeEarly(sess);
    _report = _repository.evaluate(sess);
    await _repository.archive(sess, _report!);
    _finished = await _repository.finishedSessions();
    await _persist();
    notifyListeners();
  }

  Future<void> clearFinished() async {
    await _repository.clearFinished();
    _finished = <Map<String, dynamic>>[];
    notifyListeners();
  }
}
