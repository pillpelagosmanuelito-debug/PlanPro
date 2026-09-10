import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../data/models/evaluation_report.dart';
import '../../data/models/project_state.dart';
import '../../viewmodels/project_viewmodel.dart';
import '../app_scope.dart';
import '../widgets/evm_chart.dart';
import '../widgets/metric_tile.dart';
import '../widgets/section_card.dart';

/// Modulo 5: Cierre.
///
/// El informe compara lo prometido con lo entregado y califica cuatro
/// competencias con evidencia de la propia partida. La seccion de brechas de
/// estimacion revela por fin las duraciones reales: es el momento en que el
/// estudiante ve cuanto se equivoco su plan y por que.
class ClosureScreen extends StatelessWidget {
  const ClosureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel vm = AppScope.of(context);
    final ProjectState? state = vm.state;
    final EvaluationReport? report = vm.report;
    if (state == null || report == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final Color outcomeColor = _outcomeColor(state.outcome);

    return Scaffold(
      appBar: AppBar(title: const Text('5. Cierre del proyecto')),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 110),
        children: <Widget>[
          _Verdict(
            report: report,
            outcome: state.outcome.label,
            color: outcomeColor,
          ),
          SectionCard(
            title: 'Lo prometido contra lo entregado',
            icon: Icons.compare_arrows,
            accent: AppColors.closure,
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: MetricTile(
                        label: 'Plazo',
                        value: '${report.periodsUsed}/'
                            '${report.committedPeriods}',
                        hint: 'periodos usados / comprometidos',
                        color: report.periodsUsed <= report.committedPeriods
                            ? AppColors.success
                            : AppColors.danger,
                        icon: Icons.schedule,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MetricTile(
                        label: 'Costo',
                        value: formatMoneyCompact(report.finalCost),
                        hint: 'base ${formatMoneyCompact(report.budgetAtCompletion)}',
                        color: report.finalCost <= report.budgetAtCompletion
                            ? AppColors.success
                            : AppColors.danger,
                        icon: Icons.payments_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: MetricTile(
                        label: 'Alcance',
                        value: formatPercent(report.scopeDelivered),
                        hint: 'del compromiso entregado',
                        color: report.scopeDelivered >= 0.999
                            ? AppColors.success
                            : AppColors.warning,
                        icon: Icons.checklist,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MetricTile(
                        label: 'Patrocinador',
                        value: '${report.sponsorSatisfaction.toStringAsFixed(0)}'
                            '/100',
                        hint: 'satisfaccion final',
                        color: report.sponsorSatisfaction >= 55
                            ? AppColors.success
                            : AppColors.danger,
                        icon: Icons.sentiment_satisfied_alt_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  report.narrative,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: AppColors.textStrong,
                  ),
                ),
                if (report.complianceIssue) ...<Widget>[
                  const SizedBox(height: 12),
                  const NoteBox(
                    text: 'Cierre con observaciones: el entorno exigia '
                        'documentacion formal y el enfoque elegido produjo '
                        'menos evidencia de la requerida.',
                    icon: Icons.gavel_outlined,
                    color: AppColors.danger,
                  ),
                ],
              ],
            ),
          ),
          SectionCard(
            title: 'Evaluacion por competencias',
            subtitle: 'Puntaje general ${report.overallScore.toStringAsFixed(0)}/100',
            icon: Icons.school_outlined,
            accent: AppColors.initiation,
            child: Column(
              children: report.scores
                  .map((CompetencyScore s) => _CompetencyBlock(score: s))
                  .toList(),
            ),
          ),
          SectionCard(
            title: 'Curva del proyecto',
            subtitle: 'SPI final ${formatIndex(report.finalSpi)} · '
                'CPI final ${formatIndex(report.finalCpi)}',
            icon: Icons.insights,
            accent: AppColors.info,
            child: EvmChart(snapshots: state.snapshots),
          ),
          SectionCard(
            title: 'Estimacion contra realidad',
            subtitle: 'Ahora si: cuanto duraba realmente cada paquete',
            icon: Icons.timer_outlined,
            accent: AppColors.warning,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ...report.estimateGaps.take(8).map(
                      (EstimateGap g) => _GapRow(gap: g),
                    ),
                const SizedBox(height: 6),
                const NoteBox(
                  text: 'Esta tabla no estaba disponible durante la partida, '
                      'igual que en un proyecto real. La leccion no es que las '
                      'estimaciones fallen: es que fallan siempre en la misma '
                      'direccion, y planificar sabiendolo es gratis.',
                  icon: Icons.trending_up,
                  color: AppColors.warning,
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Gestion de riesgos',
            subtitle: '${report.risksIdentified} de ${report.risksTotal} '
                'identificados · ${report.risksMaterialized} ocurrieron',
            icon: Icons.shield_outlined,
            accent: AppColors.risk,
            child: Column(
              children: <Widget>[
                _line('Riesgos en tu registro',
                    '${report.risksIdentified} de ${report.risksTotal}'),
                _line('Riesgos que se materializaron',
                    '${report.risksMaterialized}'),
                _line(
                  'Golpearon sin estar identificados',
                  '${report.risksUnidentifiedHit}',
                  color: report.risksUnidentifiedHit > 0
                      ? AppColors.danger
                      : AppColors.success,
                ),
                _line('Horas de equipo perdidas',
                    formatHours(report.wastedHours)),
                _line(
                  'Defectos que llegaron al cliente',
                  report.escapedDefects.toStringAsFixed(1),
                  color: report.escapedDefects > 2
                      ? AppColors.danger
                      : AppColors.textSoft,
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Que practicar despues',
            icon: Icons.flag_circle_outlined,
            accent: AppColors.execution,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: report.nextSteps
                  .map((String step) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Padding(
                              padding: EdgeInsets.only(top: 4, right: 8),
                              child: Icon(
                                Icons.arrow_forward,
                                size: 14,
                                color: AppColors.execution,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                step,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  height: 1.45,
                                  color: AppColors.textStrong,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: vm.abandonSession,
            icon: const Icon(Icons.replay),
            label: const Text('Dirigir otro proyecto'),
          ),
        ),
      ),
    );
  }

  Color _outcomeColor(ProjectOutcome outcome) {
    switch (outcome) {
      case ProjectOutcome.delivered:
        return AppColors.success;
      case ProjectOutcome.deliveredLate:
        return AppColors.warning;
      case ProjectOutcome.cancelled:
      case ProjectOutcome.abandoned:
        return AppColors.danger;
      case ProjectOutcome.running:
        return AppColors.info;
    }
  }

  Widget _line(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textStrong,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: color ?? AppColors.risk,
            ),
          ),
        ],
      ),
    );
  }
}

class _Verdict extends StatelessWidget {
  const _Verdict({
    required this.report,
    required this.outcome,
    required this.color,
  });

  final EvaluationReport report;
  final String outcome;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  outcome.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9.5,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${report.overallScore.toStringAsFixed(0)}/100',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.headline,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            report.verdict,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: AppColors.textSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompetencyBlock extends StatelessWidget {
  const _CompetencyBlock({required this.score});

  final CompetencyScore score;

  Color get _color {
    if (score.score >= 85) return AppColors.success;
    if (score.score >= 70) return AppColors.info;
    if (score.score >= 55) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  score.competency.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
              Text(
                '${score.score.toStringAsFixed(0)} · ${score.level}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (score.score / 100).clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(_color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            score.competency.definition,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.35,
              fontStyle: FontStyle.italic,
              color: AppColors.textSoft,
            ),
          ),
          ...score.strengths.map((String s) => _bullet(s, true)),
          ...score.gaps.map((String s) => _bullet(s, false)),
        ],
      ),
    );
  }

  Widget _bullet(String text, bool positive) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 7),
            child: Icon(
              positive ? Icons.add_circle_outline : Icons.remove_circle_outline,
              size: 13,
              color: positive ? AppColors.success : AppColors.danger,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GapRow extends StatelessWidget {
  const _GapRow({required this.gap});

  final EstimateGap gap;

  @override
  Widget build(BuildContext context) {
    final double deviation = gap.deviation;
    final Color color = deviation > 0.25
        ? AppColors.danger
        : deviation > 0.10
            ? AppColors.warning
            : AppColors.success;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  gap.packageName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
              Text(
                '${deviation >= 0 ? '+' : ''}'
                '${(deviation * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          Text(
            'Estimado ${formatHours(gap.estimatedHours)} · '
            'real ${formatHours(gap.realHours)}'
            '${gap.completed ? '' : ' · quedo inconcluso'}',
            style: const TextStyle(fontSize: 11, color: AppColors.textSoft),
          ),
        ],
      ),
    );
  }
}
