import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../data/models/advisor_message.dart';
import '../../data/models/methodology.dart';
import '../../data/models/project_state.dart';
import '../../data/models/team_member.dart';
import '../../data/models/work_package.dart';
import '../../viewmodels/project_viewmodel.dart';
import '../app_scope.dart';
import '../widgets/advisor_card.dart';
import '../widgets/metric_tile.dart';
import '../widgets/section_card.dart';

/// Modulo 2: Planificacion.
///
/// Aqui se decide casi todo el resultado: equipo, alcance comprometido, nivel
/// de calidad, plazo y reserva. La pantalla muestra en todo momento la unica
/// aritmetica que importa (alcance dividido entre capacidad) para que el
/// compromiso no sea un acto de fe.
class PlanningScreen extends StatelessWidget {
  const PlanningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel vm = AppScope.of(context);
    final ProjectState? state = vm.state;
    if (state == null) return const SizedBox.shrink();

    final double capacity = state.effectiveCapacity(vm.config);
    final double needed = vm.periodsNeeded();
    final double plannedCost = state.teamCostPerPeriod() * vm.plannedPeriods;
    final double reserve = plannedCost * vm.contingencyRate;
    final List<AdvisorMessage> advice = vm.planningAdvice();
    final bool ready = state.team.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('2. Planificacion'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Volver al acta',
            onPressed: vm.backToCharter,
            icon: const Icon(Icons.description_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 110),
        children: <Widget>[
          _Summary(
            capacity: capacity,
            scope: state.scopeEstimatedHours,
            needed: needed,
            committed: vm.plannedPeriods,
          ),
          SectionCard(
            title: 'Equipo del proyecto',
            subtitle: state.team.isEmpty
                ? 'Sin equipo no hay capacidad'
                : '${state.team.length} integrante(s) · '
                    '${formatMoney(state.teamCostPerPeriod())} por periodo',
            icon: Icons.groups_outlined,
            accent: AppColors.planning,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (state.team.isNotEmpty) ...<Widget>[
                  ...state.team.map((TeamMember m) => _MemberRow(
                        member: m,
                        onRemove: () => vm.release(m.id),
                      )),
                  const SizedBox(height: 10),
                ],
                const Text(
                  'PERFILES DISPONIBLES',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.7,
                    fontWeight: FontWeight.w700,
                    color: AppColors.planning,
                  ),
                ),
                const SizedBox(height: 8),
                ...TeamRole.catalog.map((TeamRole role) => _RoleRow(
                      role: role,
                      onAdd: () => vm.hire(role.id),
                    )),
                const SizedBox(height: 6),
                const NoteBox(
                  text: 'Mas gente no es mas velocidad: cada integrante '
                      'adicional resta un poco de eficiencia por coordinacion, '
                      'y quien entra despues de arrancar tarda periodos en '
                      'rendir.',
                  icon: Icons.groups_2_outlined,
                  color: AppColors.planning,
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Alcance comprometido',
            subtitle: 'Lo opcional puede quedar fuera; lo obligatorio no',
            icon: Icons.checklist,
            accent: AppColors.execution,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ...state.packages.map((WorkPackage p) => _ScopeRow(
                      package: p,
                      onToggle: p.optional ? () => vm.toggleScope(p.id) : null,
                    )),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    const Text(
                      'Total comprometido',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textStrong,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatHours(state.scopeEstimatedHours),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.execution,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Nivel de aseguramiento de calidad',
            subtitle: 'Cuanta capacidad dedicas a evitar defectos',
            icon: Icons.verified_outlined,
            accent: AppColors.info,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Slider(
                        value: state.qaLevel,
                        min: 0,
                        max: 1,
                        divisions: 10,
                        label: formatPercent(state.qaLevel),
                        onChanged: vm.setQaLevel,
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(
                        formatPercent(state.qaLevel),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Consume ${formatPercent(state.qaLevel * vm.config.qaCapacityCost)} '
                  'de la capacidad del equipo y reduce en la misma proporcion '
                  'los defectos que llegaran a pruebas.',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textSoft,
                  ),
                ),
                const SizedBox(height: 10),
                const NoteBox(
                  text: 'Corregir un defecto en pruebas cuesta cerca de ocho '
                      'veces mas que haberlo evitado al construir. Bajar '
                      'calidad no ahorra trabajo: lo aplaza y lo multiplica.',
                  icon: Icons.bug_report_outlined,
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Enfoque y restriccion',
            subtitle: 'Todavia puedes cambiarlos; despues quedan fijos',
            icon: Icons.alt_route,
            accent: AppColors.initiation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: Methodology.values
                      .map((Methodology m) => ChoiceChip(
                            label: Text(m.shortLabel),
                            selected: state.methodology == m,
                            onSelected: (_) => vm.setMethodology(m),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 6),
                Text(
                  state.methodology.description,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textSoft,
                  ),
                ),
                const Divider(height: 22),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ConstraintPriority.values
                      .map((ConstraintPriority p) => ChoiceChip(
                            label: Text(p.label),
                            selected: state.priority == p,
                            onSelected: (_) => vm.setPriority(p),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Linea base',
            subtitle: 'La promesa formal contra la que te mediran',
            icon: Icons.flag_outlined,
            accent: AppColors.closure,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'Periodos comprometidos',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textStrong,
                        ),
                      ),
                    ),
                    Text(
                      '${vm.plannedPeriods} '
                      '(${formatWeek(vm.plannedPeriods, vm.config.weeksPerPeriod)})',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.closure,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: vm.plannedPeriods.toDouble(),
                  min: 3,
                  max: vm.config.totalPeriods.toDouble(),
                  divisions: vm.config.totalPeriods - 3,
                  label: '${vm.plannedPeriods}',
                  onChanged: (double v) => vm.setPlannedPeriods(v.round()),
                ),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'Reserva de contingencia',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textStrong,
                        ),
                      ),
                    ),
                    Text(
                      '${formatPercent(vm.contingencyRate)} · '
                      '${formatMoney(reserve)}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.closure,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: vm.contingencyRate,
                  min: 0,
                  max: vm.config.contingencyMax,
                  divisions: 20,
                  label: formatPercent(vm.contingencyRate),
                  onChanged: vm.setContingencyRate,
                ),
                const SizedBox(height: 6),
                _BaselineSummary(
                  plannedCost: plannedCost,
                  reserve: reserve,
                  ceiling: state.projectCase.budgetCeiling,
                ),
              ],
            ),
          ),
          if (advice.isNotEmpty)
            SectionCard(
              title: 'Asistente de direccion',
              subtitle: 'Revision de tu plan antes de firmarlo',
              icon: Icons.support_agent,
              accent: AppColors.accent,
              child: Column(
                children: advice
                    .map((AdvisorMessage m) => AdvisorCard(message: m))
                    .toList(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: ready ? () => _confirm(context, vm) : null,
            icon: const Icon(Icons.handshake_outlined),
            label: Text(
              ready
                  ? 'Comprometer linea base y ejecutar'
                  : 'Necesitas al menos un integrante',
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirm(BuildContext context, ProjectViewModel vm) async {
    final ProjectState state = vm.state!;
    final double needed = vm.periodsNeeded();
    final bool risky = needed > vm.plannedPeriods + 0.4;

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Comprometer la linea base'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Te comprometes a entregar '
              '${formatHours(state.scopeEstimatedHours)} de alcance en '
              '${vm.plannedPeriods} periodos, con '
              '${formatMoney(state.teamCostPerPeriod() * vm.plannedPeriods * (1 + vm.contingencyRate))} '
              'incluyendo reserva.',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            if (risky) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                'La aritmetica dice que necesitarias '
                '${needed.toStringAsFixed(1)} periodos con tu capacidad '
                'actual, y eso sin contratiempos.',
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Despues de firmar no podras cambiar de metodologia, y cualquier '
              'ajuste de plazo o costo requerira una solicitud de cambio.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textSoft,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Revisar el plan'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Firmar'),
          ),
        ],
      ),
    );
    if (ok == true) vm.commitBaseline();
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.capacity,
    required this.scope,
    required this.needed,
    required this.committed,
  });

  final double capacity;
  final double scope;
  final double needed;
  final int committed;

  @override
  Widget build(BuildContext context) {
    final bool fits = needed.isFinite && needed <= committed + 0.4;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: (fits ? AppColors.success : AppColors.danger).withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (fits ? AppColors.success : AppColors.danger)
                .withOpacity(0.35),
          ),
        ),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: MetricTile(
                    label: 'Alcance',
                    value: formatHours(scope),
                    hint: 'comprometido',
                    color: AppColors.primary,
                    icon: Icons.checklist,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MetricTile(
                    label: 'Capacidad',
                    value: formatHours(capacity),
                    hint: 'por periodo',
                    color: AppColors.planning,
                    icon: Icons.groups_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MetricTile(
                    label: 'Periodos',
                    value: needed.isFinite ? needed.toStringAsFixed(1) : '--',
                    hint: 'necesarios',
                    color: fits ? AppColors.success : AppColors.danger,
                    icon: Icons.schedule,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              fits
                  ? 'El alcance cabe en los $committed periodos que piensas '
                      'comprometer. Recuerda que las estimaciones son '
                      'optimistas.'
                  : 'El alcance NO cabe en $committed periodos con esta '
                      'capacidad. Ajusta equipo, alcance o plazo antes de '
                      'firmar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: fits ? AppColors.success : AppColors.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BaselineSummary extends StatelessWidget {
  const _BaselineSummary({
    required this.plannedCost,
    required this.reserve,
    required this.ceiling,
  });

  final double plannedCost;
  final double reserve;
  final double ceiling;

  @override
  Widget build(BuildContext context) {
    final double total = plannedCost + reserve;
    final bool over = total > ceiling;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          _row('Costo planificado del equipo', formatMoney(plannedCost)),
          _row('Reserva de contingencia', formatMoney(reserve)),
          const Divider(height: 16),
          _row(
            'Presupuesto hasta la conclusion',
            formatMoney(total),
            strong: true,
            color: over ? AppColors.danger : AppColors.closure,
          ),
          _row('Techo autorizado', formatMoney(ceiling)),
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    bool strong = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
                color: AppColors.textStrong,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: color ?? AppColors.textSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.onRemove});

  final TeamMember member;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final TeamRole role = member.role;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.planning.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.person_outline,
              size: 16,
              color: AppColors.planning,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  member.name,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textStrong,
                  ),
                ),
                Text(
                  '${formatMoney(role.costPerPeriod)} / periodo · '
                  'productividad ${role.productivity.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSoft,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            color: AppColors.danger,
            tooltip: 'Retirar del equipo',
          ),
        ],
      ),
    );
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({required this.role, required this.onAdd});

  final TeamRole role;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  role.label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textStrong,
                  ),
                ),
                Text(
                  role.detail,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.3,
                    color: AppColors.textSoft,
                  ),
                ),
                Text(
                  '${formatMoney(role.costPerPeriod)} / periodo · '
                  'curva ${role.rampPeriods} periodo(s)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.planning,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline, size: 22),
            color: AppColors.planning,
            tooltip: 'Incorporar',
          ),
        ],
      ),
    );
  }
}

class _ScopeRow extends StatelessWidget {
  const _ScopeRow({required this.package, this.onToggle});

  final WorkPackage package;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final bool included = package.included;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: <Widget>[
          Icon(
            package.optional
                ? (included
                    ? Icons.check_box_outlined
                    : Icons.check_box_outline_blank)
                : Icons.lock_outline,
            size: 18,
            color: package.optional
                ? (included ? AppColors.execution : AppColors.textSoft)
                : AppColors.textSoft,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  package.name,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: included ? AppColors.textStrong : AppColors.textSoft,
                    decoration:
                        included ? null : TextDecoration.lineThrough,
                  ),
                ),
                Text(
                  '${package.phase.label} · '
                  '${formatHours(package.estimatedHours)}'
                  '${package.optional ? ' · opcional' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSoft,
                  ),
                ),
              ],
            ),
          ),
          if (onToggle != null)
            TextButton(
              onPressed: onToggle,
              child: Text(included ? 'Excluir' : 'Incluir'),
            ),
        ],
      ),
    );
  }
}
