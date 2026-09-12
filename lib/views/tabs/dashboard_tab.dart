import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../data/models/evm_snapshot.dart';
import '../../data/models/project_case.dart';
import '../../data/models/project_state.dart';
import '../../viewmodels/project_viewmodel.dart';
import '../app_scope.dart';
import '../widgets/evm_chart.dart';
import '../widgets/metric_tile.dart';
import '../widgets/phase_progress_bar.dart';
import '../widgets/section_card.dart';

/// Tablero de control del proyecto.
///
/// Reune los tres números del valor ganado, la lectura en lenguaje llano y el
/// estado de cada fase. La idea es que el estudiante aprenda a mirar primero
/// los índices y después los detalles.
class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel vm = AppScope.of(context);
    final ProjectState state = vm.state!;
    final ProjectCase c = state.projectCase;
    final EvmSnapshot? snap =
        state.snapshots.isEmpty ? null : state.snapshots.last;
    final double ceilingUse = state.actualCost / c.budgetCeiling;

    return ListView(
      padding: const EdgeInsets.only(top: 14, bottom: 24),
      children: <Widget>[
        SectionCard(
          title: 'Estado del proyecto',
          subtitle: vm.advisorHeadline(),
          icon: Icons.speed,
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: MetricTile(
                      label: 'Avance',
                      value: formatPercent(state.progress),
                      hint: 'del alcance comprometido',
                      color: AppColors.execution,
                      icon: Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MetricTile(
                      label: 'Costo real',
                      value: formatMoneyCompact(state.actualCost),
                      hint: '${formatPercent(ceilingUse)} del techo',
                      color: ceilingUse > 0.9
                          ? AppColors.danger
                          : AppColors.primary,
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
                      label: 'Patrocinador',
                      value: '${state.sponsorSatisfaction.toStringAsFixed(0)}'
                          '/100',
                      hint: 'satisfacción',
                      color: state.sponsorSatisfaction < 45
                          ? AppColors.danger
                          : AppColors.info,
                      icon: Icons.sentiment_satisfied_alt_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MetricTile(
                      label: 'Capacidad',
                      value: formatHours(state.effectiveCapacity(vm.config)),
                      hint: 'este periodo',
                      color: AppColors.planning,
                      icon: Icons.groups_outlined,
                    ),
                  ),
                ],
              ),
              if (state.fatigue > 0.01) ...<Widget>[
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.battery_alert_outlined,
                      size: 15,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Fatiga acumulada: ${formatPercent(state.fatigue)} '
                        'menos de capacidad efectiva.',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        SectionCard(
          title: 'Gestión del valor ganado',
          subtitle: snap == null
              ? 'Se calcula al cerrar el primer periodo'
              : snap.reading,
          icon: Icons.insights,
          accent: AppColors.info,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              EvmChart(snapshots: state.snapshots),
              if (snap != null) ...<Widget>[
                const SizedBox(height: 16),
                IndexBar(label: 'SPI · cronograma', value: snap.spi),
                const SizedBox(height: 12),
                IndexBar(label: 'CPI · costo', value: snap.cpi),
                const SizedBox(height: 16),
                _EvmRow(
                  label: 'Valor planificado (PV)',
                  value: formatMoney(snap.plannedValue),
                  help: 'Lo que el plan decía que debería estar ejecutado hoy.',
                ),
                _EvmRow(
                  label: 'Valor ganado (EV)',
                  value: formatMoney(snap.earnedValue),
                  help: 'Lo que realmente vale el trabajo terminado.',
                ),
                _EvmRow(
                  label: 'Costo real (AC)',
                  value: formatMoney(snap.actualCost),
                  help: 'Lo que llevas gastado, hayas avanzado o no.',
                ),
                const Divider(height: 20),
                _EvmRow(
                  label: 'Estimación a la conclusión (EAC)',
                  value: formatMoney(snap.estimateAtCompletion),
                  help: 'Cuánto costará terminar si el desempeño se mantiene.',
                  strong: true,
                ),
                _EvmRow(
                  label: 'Variación a la conclusión (VAC)',
                  value: formatMoney(snap.varianceAtCompletion),
                  help: snap.varianceAtCompletion >= 0
                      ? 'Terminarías por debajo del presupuesto.'
                      : 'Terminarías por encima del presupuesto.',
                  color: snap.varianceAtCompletion >= 0
                      ? AppColors.success
                      : AppColors.danger,
                ),
              ],
            ],
          ),
        ),
        SectionCard(
          title: 'Avance por fase',
          subtitle: 'La marca indica el hito que habilita la fase siguiente',
          icon: Icons.layers_outlined,
          accent: AppColors.execution,
          child: Column(
            children: ProjectPhase.values
                .map((ProjectPhase p) =>
                    PhaseProgressBar(state: state, phase: p))
                .toList(),
          ),
        ),
        SectionCard(
          title: 'Línea base comprometida',
          subtitle: 'Contra esto te medirán al cerrar',
          icon: Icons.flag_outlined,
          accent: AppColors.closure,
          child: Column(
            children: <Widget>[
              _EvmRow(
                label: 'Plazo comprometido',
                value: '${state.baseline?.committedPeriods ?? 0} periodos',
                help: 'Vas en el periodo ${state.period}.',
              ),
              _EvmRow(
                label: 'Presupuesto con reserva',
                value: formatMoney(state.baseline?.budgetAtCompletion ?? 0),
                help: 'Techo autorizado ${formatMoney(c.budgetCeiling)}.',
              ),
              _EvmRow(
                label: 'Alcance comprometido',
                value: formatHours(state.scopeEstimatedHours),
                help: state.baseline != null &&
                        state.baseline!.revisions > 0
                    ? 'Línea base revisada formalmente '
                        '${state.baseline!.revisions} vez(ces).'
                    : 'Sin revisiones formales de la línea base.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EvmRow extends StatelessWidget {
  const _EvmRow({
    required this.label,
    required this.value,
    required this.help,
    this.strong = false,
    this.color,
  });

  final String label;
  final String value;
  final String help;
  final bool strong;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: color ?? AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            help,
            style: const TextStyle(
              fontSize: 11,
              height: 1.3,
              color: AppColors.textSoft,
            ),
          ),
        ],
      ),
    );
  }
}
