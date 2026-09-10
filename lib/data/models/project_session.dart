import 'period_result.dart';
import 'project_state.dart';

/// Partida completa: el proyecto, su historia y la semilla que lo genero.
///
/// La semilla se guarda porque es lo que hace comparable el ejercicio: dos
/// estudiantes con la misma semilla enfrentan exactamente el mismo proyecto,
/// asi que la diferencia de resultados se explica por como dirigieron y no
/// por como les fue.
class ProjectSession {
  ProjectSession({
    required this.id,
    required this.seed,
    required this.startedAt,
    required this.state,
    required this.history,
    this.playerName = '',
  });

  final String id;
  final int seed;
  final DateTime startedAt;
  final ProjectState state;
  final List<PeriodResult> history;
  String playerName;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'seed': seed,
        'startedAt': startedAt.toIso8601String(),
        'playerName': playerName,
        'state': state.toJson(),
        'history': history.map((PeriodResult r) => r.toJson()).toList(),
      };

  factory ProjectSession.fromJson(Map<String, dynamic> json) => ProjectSession(
        id: json['id'] as String? ?? 'session',
        seed: (json['seed'] as num?)?.toInt() ?? 1000,
        startedAt:
            DateTime.tryParse(json['startedAt'] as String? ?? '') ??
                DateTime.now(),
        playerName: json['playerName'] as String? ?? '',
        state: ProjectState.fromJson(
          Map<String, dynamic>.from(
              (json['state'] as Map<dynamic, dynamic>?) ?? <String, dynamic>{}),
        ),
        history: ((json['history'] as List<dynamic>?) ?? <dynamic>[])
            .map((dynamic e) =>
                PeriodResult.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}
