import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../data/models/change_request.dart';
import '../../data/models/project_state.dart';
import '../../viewmodels/project_viewmodel.dart';
import '../app_scope.dart';
import '../tabs/advisor_tab.dart';
import '../tabs/dashboard_tab.dart';
import '../tabs/risk_tab.dart';
import '../tabs/scope_tab.dart';
import '../tabs/team_tab.dart';
import '../widgets/change_request_dialog.dart';
import '../widgets/period_result_sheet.dart';

/// Módulo 3: Ejecución.
///
/// Cada periodo el estudiante decide asignaciones, respuestas a riesgos,
/// solicitudes de cambio y horas extra, y después cierra el periodo para ver
/// las consecuencias. La estructura de pestañas replica las áreas de
/// conocimiento que un director revisa cada semana.
class ExecutionScreen extends StatefulWidget {
  const ExecutionScreen({super.key});

  @override
  State<ExecutionScreen> createState() => _ExecutionScreenState();
}

class _ExecutionScreenState extends State<ExecutionScreen> {
  int _tab = 0;

  static const List<String> _titles = <String>[
    'Tablero',
    'Equipo',
    'Alcance',
    'Riesgos',
    'Asistente',
  ];

  Future<void> _runPeriod(ProjectViewModel vm) async {
    final ProjectState? state = vm.state;
    if (state == null) return;

    final int idle = vm.unassignedMembers().length;
    if (idle > 0) {
      final bool? go = await showDialog<bool>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: Text('$idle persona(s) sin trabajo valido'),
          content: const Text(
            'Su capacidad se perderá completa y su costo se pagará igual. '
            'Puedes reasignarlas antes de cerrar el periodo.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Reasignar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Cerrar igual'),
            ),
          ],
        ),
      );
      if (go != true) {
        setState(() => _tab = 1);
        return;
      }
    }

    await vm.runPeriod();
    if (!mounted) return;
    final ProjectViewModel current = AppScope.read(context);
    if (current.lastResult != null && !current.state!.outcome.isFinished) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PeriodResultSheet(result: current.lastResult!),
      );
      if (mounted) current.dismissLastResult();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel vm = AppScope.of(context);
    final ProjectState? state = vm.state;
    if (state == null) return const SizedBox.shrink();

    final List<ChangeRequest> pending = state.pendingChanges;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _titles[_tab],
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            Text(
              'Periodo ${state.period} de ${vm.config.totalPeriods} · '
              '${formatWeek(state.period, vm.config.weeksPerPeriod)}',
              style: const TextStyle(fontSize: 11.5, color: Colors.white70),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Cerrar el proyecto ahora',
            onPressed: () => _confirmClose(context, vm),
            icon: const Icon(Icons.flag_outlined),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          if (pending.isNotEmpty)
            _ChangeBanner(
              change: pending.first,
              onOpen: () => showDialog<void>(
                context: context,
                builder: (_) => ChangeRequestDialog(change: pending.first),
              ),
            ),
          Expanded(child: _body(_tab)),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _RunBar(onRun: () => _runPeriod(vm)),
          NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (int i) => setState(() => _tab = i),
            height: 62,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Tablero',
              ),
              NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups),
                label: 'Equipo',
              ),
              NavigationDestination(
                icon: Icon(Icons.checklist_outlined),
                selectedIcon: Icon(Icons.checklist),
                label: 'Alcance',
              ),
              NavigationDestination(
                icon: Icon(Icons.warning_amber_outlined),
                selectedIcon: Icon(Icons.warning_amber_rounded),
                label: 'Riesgos',
              ),
              NavigationDestination(
                icon: Icon(Icons.support_agent_outlined),
                selectedIcon: Icon(Icons.support_agent),
                label: 'Asistente',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _body(int index) {
    switch (index) {
      case 1:
        return const TeamTab();
      case 2:
        return const ScopeTab();
      case 3:
        return const RiskTab();
      case 4:
        return const AdvisorTab();
      case 0:
      default:
        return const DashboardTab();
    }
  }

  Future<void> _confirmClose(BuildContext context, ProjectViewModel vm) async {
    final ProjectState state = vm.state!;
    final bool complete = state.isComplete;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Cerrar el proyecto'),
        content: Text(
          complete
              ? 'El alcance comprometido está terminado. Se emitirá el informe '
                  'de cierre con tu evaluación por competencias.'
              : 'Todavía queda alcance comprometido sin entregar. Cerrar ahora '
                  'registra el proyecto como no completado, y eso pesa en la '
                  'evaluación.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Seguir dirigiendo'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
    if (ok == true) await vm.closeProject();
  }
}

class _RunBar extends StatelessWidget {
  const _RunBar({required this.onRun});

  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel vm = AppScope.of(context);
    final ProjectState state = vm.state!;
    final double cost = state.teamCostPerPeriod() *
        (vm.overtimeNextPeriod ? vm.config.overtimeCostFactor : 1);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Switch(
                value: vm.overtimeNextPeriod,
                onChanged: vm.setOvertime,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Autorizar horas extra',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textStrong,
                      ),
                    ),
                    Text(
                      '+${formatPercent(vm.config.overtimeCapacityGain)} de '
                      'capacidad, costo ${formatMoney(cost)} y fatiga',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: vm.canRunPeriod ? onRun : null,
              icon: const Icon(Icons.play_circle_outline),
              label: Text('Cerrar periodo ${state.period}'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangeBanner extends StatelessWidget {
  const _ChangeBanner({required this.change, required this.onOpen});

  final ChangeRequest change;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent.withOpacity(0.12),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 18,
                color: AppColors.accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Solicitud de cambio pendiente',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: AppColors.accent,
                      ),
                    ),
                    Text(
                      change.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textStrong,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.accent),
            ],
          ),
        ),
      ),
    );
  }
}
