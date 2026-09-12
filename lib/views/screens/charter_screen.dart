import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../data/models/project_case.dart';
import '../../data/models/project_state.dart';
import '../../data/models/risk_item.dart';
import '../../viewmodels/project_viewmodel.dart';
import '../app_scope.dart';
import '../widgets/section_card.dart';

/// Módulo 1: Inicio del proyecto.
///
/// El acta de constitución es el único documento que existe antes de decidir
/// nada. Aquí el estudiante práctica leerla buscando restricciones, supuestos
/// y señales de riesgo, no solo el objetivo.
class CharterScreen extends StatelessWidget {
  const CharterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel vm = AppScope.of(context);
    final ProjectState? state = vm.state;
    if (state == null) return const SizedBox.shrink();
    final ProjectCase c = state.projectCase;

    return Scaffold(
      appBar: AppBar(
        title: const Text('1. Inicio del proyecto'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Abandonar proyecto',
            onPressed: () => _confirmExit(context, vm),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 110),
        children: <Widget>[
          SectionCard(
            title: c.name,
            subtitle: '${c.client} · ${c.sector}',
            icon: Icons.description_outlined,
            accent: AppColors.initiation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  c.charter,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'OBJETIVO DEL PROYECTO',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.7,
                    fontWeight: FontWeight.w700,
                    color: AppColors.initiation,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  c.objective,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textStrong,
                  ),
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Restricciones que el patrocinador fija',
            subtitle: 'Lo que no se negocia al empezar',
            icon: Icons.lock_outline,
            accent: AppColors.risk,
            child: Column(
              children: <Widget>[
                _ConstraintRow(
                  icon: Icons.payments_outlined,
                  label: 'Techo de presupuesto',
                  value: formatMoney(c.budgetCeiling),
                  detail:
                      'Superarlo en más de 15% significa cancelación, no una '
                      'conversación.',
                ),
                _ConstraintRow(
                  icon: Icons.schedule,
                  label: 'Plazo objetivo',
                  value: '${c.targetPeriods} periodos '
                      '(${c.targetPeriods * 2} semanas)',
                  detail:
                      'Es la expectativa. Tú comprometerás una fecha en la '
                      'planificación, y esa será la que te midan.',
                ),
                _ConstraintRow(
                  icon: Icons.checklist_rtl,
                  label: 'Alcance mínimo',
                  value: formatHours(c.mandatoryEstimatedHours),
                  detail:
                      'Los paquetes obligatorios no se pueden excluir. El '
                      'alcance opcional sí, y es tu palanca más barata.',
                ),
                _ConstraintRow(
                  icon: Icons.priority_high,
                  label: 'Restricción prioritaria',
                  value: state.priority.label,
                  detail: state.priority.detail,
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Registro inicial de riesgos',
            subtitle: 'Solo lo que el acta hace evidente',
            icon: Icons.warning_amber_rounded,
            accent: AppColors.warning,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ...state.identifiedRisks.map((RiskItem r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Icon(
                            Icons.report_gmailerrorred_outlined,
                            size: 16,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  r.name,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textStrong,
                                  ),
                                ),
                                Text(
                                  r.description,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    height: 1.35,
                                    color: AppColors.textSoft,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                const NoteBox(
                  text: 'Estos no son todos los riesgos del proyecto: son los '
                      'que estaban a la vista. Los demás existen igual, y '
                      'solo aparecerán si dedicas tiempo a buscarlos.',
                  icon: Icons.visibility_off_outlined,
                  color: AppColors.warning,
                ),
              ],
            ),
          ),
          if (c.changeHints.isNotEmpty)
            SectionCard(
              title: 'Temas todavía abiertos',
              subtitle: 'Frases del acta que anticipan solicitudes de cambio',
              icon: Icons.pending_actions,
              accent: AppColors.info,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: c.changeHints
                    .map((String hint) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                '“',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.info,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  hint,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    height: 1.4,
                                    fontStyle: FontStyle.italic,
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
          SectionCard(
            title: 'Estructura de desglose del trabajo',
            subtitle: '${c.packages.length} paquetes, '
                '${formatHours(c.totalEstimatedHours)} estimadas por el equipo',
            icon: Icons.account_tree_outlined,
            accent: AppColors.execution,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ...ProjectPhase.values.map((ProjectPhase phase) {
                  final List<PackageSpec> list = c.packages
                      .where((PackageSpec p) => p.phase == phase)
                      .toList();
                  if (list.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          phase.label.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            letterSpacing: 0.7,
                            fontWeight: FontWeight.w700,
                            color: AppColors.execution,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...list.map((PackageSpec p) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      p.optional
                                          ? '${p.name}  (opcional)'
                                          : p.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: p.optional
                                            ? AppColors.textSoft
                                            : AppColors.textStrong,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    formatHours(p.estimatedHours),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSoft,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  );
                }),
                const NoteBox(
                  text: 'Estas horas son la estimación del equipo, no la '
                      'duración real. Históricamente las estimaciones son '
                      'optimistas: planifica con eso en mente.',
                  icon: Icons.timer_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: vm.goToPlanning,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Pasar a planificación'),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmExit(BuildContext context, ProjectViewModel vm) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Abandonar el proyecto'),
        content: const Text(
          'Se perderá la partida actual. Podrás empezar otra desde el inicio.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Seguir dirigiendo'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Abandonar'),
          ),
        ],
      ),
    );
    if (ok == true) await vm.abandonSession();
  }
}

class _ConstraintRow extends StatelessWidget {
  const _ConstraintRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 17, color: AppColors.risk),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textStrong,
                        ),
                      ),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.risk,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: AppColors.textSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
