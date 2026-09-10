import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../data/models/change_request.dart';
import '../../data/models/project_case.dart';
import '../../data/models/project_state.dart';
import '../../data/models/work_package.dart';
import '../../viewmodels/project_viewmodel.dart';
import '../app_scope.dart';
import '../widgets/change_request_dialog.dart';
import '../widgets/section_card.dart';

/// Estado del alcance: que paquete avanza, cual esta bloqueado y que cambios
/// se aceptaron.
///
/// El avance que se muestra es el que reporta el equipo sobre la estimacion
/// original. Puede llegar al 100% de lo estimado y aun asi faltar trabajo:
/// esa brecha es el corazon del ejercicio.
class ScopeTab extends StatelessWidget {
  const ScopeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel vm = AppScope.of(context);
    final ProjectState state = vm.state!;

    return ListView(
      padding: const EdgeInsets.only(top: 14, bottom: 24),
      children: <Widget>[
        ...ProjectPhase.values.map((ProjectPhase phase) {
          final List<WorkPackage> list = state.includedPackages
              .where((WorkPackage p) => p.phase == phase)
              .toList();
          if (list.isEmpty) return const SizedBox.shrink();
          final bool unlocked = state.phaseUnlocked(phase);
          return SectionCard(
            title: phase.label,
            subtitle: unlocked
                ? '${formatPercent(state.phaseProgress(phase))} de avance'
                : 'Bloqueada: falta avance en las fases anteriores '
                    '(${formatPercent(phase.gate)})',
            icon: unlocked ? Icons.lock_open_outlined : Icons.lock_outline,
            accent: unlocked ? AppColors.execution : AppColors.textSoft,
            child: Column(
              children: list
                  .map((WorkPackage p) => _PackageRow(package: p))
                  .toList(),
            ),
          );
        }),
        if (state.packages.any((WorkPackage p) => !p.included))
          SectionCard(
            title: 'Fuera del alcance comprometido',
            subtitle: 'Paquetes que decidiste no entregar',
            icon: Icons.remove_circle_outline,
            accent: AppColors.textSoft,
            child: Column(
              children: state.packages
                  .where((WorkPackage p) => !p.included)
                  .map((WorkPackage p) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                p.name,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSoft,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                            Text(
                              formatHours(p.estimatedHours),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSoft,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        if (state.changes.isNotEmpty)
          SectionCard(
            title: 'Solicitudes de cambio',
            subtitle: '${state.changes.length} recibida(s) en el proyecto',
            icon: Icons.swap_horiz,
            accent: AppColors.accent,
            child: Column(
              children: state.changes
                  .map((ChangeRequest ch) => _ChangeRow(change: ch))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _PackageRow extends StatelessWidget {
  const _PackageRow({required this.package});

  final WorkPackage package;

  @override
  Widget build(BuildContext context) {
    final double reported = package.estimatedHours <= 0
        ? 0.0
        : (package.earnedHours / package.estimatedHours).clamp(0.0, 1.0);
    final Color color =
        package.isDone ? AppColors.success : AppColors.execution;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                package.isDone
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: 15,
                color: color,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  package.name,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
              Text(
                formatPercent(reported),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: reported.toDouble(),
              minHeight: 7,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Estimado ${formatHours(package.estimatedHours)} · '
            'trabajado ${formatHours(package.workedHours)}'
            '${package.reworkHours > 0 ? ' · retrabajo ${formatHours(package.reworkHours)}' : ''}',
            style: const TextStyle(fontSize: 11, color: AppColors.textSoft),
          ),
        ],
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({required this.change});

  final ChangeRequest change;

  @override
  Widget build(BuildContext context) {
    final bool pending = change.isPending;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: pending
            ? () => showDialog<void>(
                  context: context,
                  builder: (_) => ChangeRequestDialog(change: change),
                )
            : null,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: pending
                ? AppColors.accent.withOpacity(0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: pending ? AppColors.accent : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      change.title,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textStrong,
                      ),
                    ),
                  ),
                  Text(
                    'P${change.period}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSoft,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                pending
                    ? 'Pendiente de decision · '
                        '${formatHours(change.baseHours)} de trabajo adicional'
                    : change.decision.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: pending ? AppColors.accent : AppColors.textSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
