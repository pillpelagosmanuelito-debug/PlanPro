import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../data/models/period_result.dart';

/// Resumen de lo que ocurrio al cerrar el periodo.
///
/// Se muestra siempre, incluso cuando no paso nada notable: la disciplina de
/// revisar el cierre de cada periodo es parte de lo que se esta entrenando.
class PeriodResultSheet extends StatelessWidget {
  const PeriodResultSheet({super.key, required this.result});

  final PeriodResult result;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext context, ScrollController controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
            ),
          ),
          child: Column(
            children: <Widget>[
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                  children: <Widget>[
                    Text(
                      'Cierre del periodo ${result.period}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textStrong,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.evm.reading,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _block(
                      'Capacidad',
                      <String>[
                        'Disponible: ${formatHours(result.capacity)}'
                            '${result.overtime ? ' (con horas extra)' : ''}',
                        'Aplicada al trabajo: ${formatHours(result.appliedHours)} '
                            '(${formatPercent(result.utilization)})',
                        if (result.wastedHours > 0.5)
                          'Perdida: ${formatHours(result.wastedHours)} por '
                              'asignaciones invalidas o fases bloqueadas',
                        'Costo del periodo: ${formatMoney(result.periodCost)}',
                      ],
                      Icons.groups_outlined,
                      result.wastedHours > 0.5
                          ? AppColors.danger
                          : AppColors.planning,
                    ),
                    if (result.progressByPackage.isNotEmpty)
                      _block(
                        'Avance del trabajo',
                        result.progressByPackage
                            .map((PackageProgress p) =>
                                '${p.packageName}: '
                                '${formatHours(p.hoursApplied)} · '
                                '${formatPercent(p.progressAfter)}'
                                '${p.completed ? ' · terminado' : ''}')
                            .toList(),
                        Icons.checklist,
                        AppColors.execution,
                      ),
                    if (result.completedPackages.isNotEmpty)
                      _block(
                        'Paquetes terminados',
                        result.completedPackages,
                        Icons.task_alt,
                        AppColors.success,
                      ),
                    if (result.risksTriggered.isNotEmpty)
                      _block(
                        'Riesgos materializados',
                        result.risksTriggered,
                        Icons.warning_amber_rounded,
                        AppColors.danger,
                      ),
                    if (result.defectsFound > 0.05)
                      _block(
                        'Calidad',
                        <String>[
                          'Defectos detectados: '
                              '${result.defectsFound.toStringAsFixed(1)}',
                          'Retrabajo agregado: '
                              '${formatHours(result.reworkHours)}',
                        ],
                        Icons.bug_report_outlined,
                        AppColors.warning,
                      ),
                    if (result.newChanges.isNotEmpty)
                      _block(
                        'Nuevas solicitudes de cambio',
                        result.newChanges,
                        Icons.swap_horiz,
                        AppColors.accent,
                      ),
                    _block(
                      'Indicadores',
                      <String>[
                        'SPI: ${formatIndex(result.evm.spi)} · '
                            'CPI: ${formatIndex(result.evm.cpi)}',
                        'Valor ganado: ${formatMoney(result.evm.earnedValue)}',
                        'Costo real: ${formatMoney(result.evm.actualCost)}',
                        'Proyeccion a la conclusion: '
                            '${formatMoney(result.evm.estimateAtCompletion)}',
                      ],
                      Icons.insights,
                      AppColors.info,
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Continuar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _block(
    String title,
    List<String> lines,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 7),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ...lines.map((String line) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  line,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textStrong,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
