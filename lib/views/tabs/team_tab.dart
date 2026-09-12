import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../data/models/project_state.dart';
import '../../data/models/team_member.dart';
import '../../data/models/work_package.dart';
import '../../viewmodels/project_viewmodel.dart';
import '../app_scope.dart';
import '../widgets/section_card.dart';

/// Asignación del equipo, periodo a periodo.
///
/// Es la decisión más repetitiva del simulador y la que más separa a quien
/// dirige de quien improvisa: la capacidad no asignada no se guarda para
/// después, simplemente se pierde.
class TeamTab extends StatelessWidget {
  const TeamTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel vm = AppScope.of(context);
    final ProjectState state = vm.state!;
    final List<WorkPackage> available = state.availablePackages();
    final int idle = vm.unassignedMembers().length;

    return ListView(
      padding: const EdgeInsets.only(top: 14, bottom: 24),
      children: <Widget>[
        SectionCard(
          title: 'Asignaciones del periodo ${state.period}',
          subtitle: idle == 0
              ? 'Todo el equipo tiene trabajo habilitado'
              : '$idle persona(s) perderán su capacidad completa',
          icon: Icons.assignment_ind_outlined,
          accent: idle == 0 ? AppColors.execution : AppColors.danger,
          trailing: TextButton(
            onPressed: vm.autoAssign,
            child: const Text('Repartir'),
          ),
          child: Column(
            children: state.team.isEmpty
                ? <Widget>[
                    const Text(
                      'No queda nadie en el equipo.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSoft,
                      ),
                    ),
                  ]
                : state.team
                    .map((TeamMember m) => _AssignmentRow(
                          member: m,
                          state: state,
                          available: available,
                          onChanged: (String? id) => vm.assign(m.id, id),
                        ))
                    .toList(),
          ),
        ),
        SectionCard(
          title: 'Reforzar el equipo',
          subtitle: 'Cuesta curva de aprendizaje y coordinación',
          icon: Icons.person_add_alt_outlined,
          accent: AppColors.planning,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ...TeamRole.catalog.map((TeamRole role) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
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
                                '${formatMoney(role.costPerPeriod)} / periodo · '
                                'rinde pleno en ${role.rampPeriods} periodo(s)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => vm.hire(role.id),
                          icon: const Icon(Icons.add_circle_outline, size: 21),
                          color: AppColors.planning,
                        ),
                      ],
                    ),
                  )),
              const NoteBox(
                text: 'Quien se incorpora ahora empieza al 45% de su '
                    'rendimiento y además consume tiempo de los demás. En un '
                    'proyecto atrasado, contratar suele atrasar más.',
                icon: Icons.trending_down,
                color: AppColors.warning,
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Efectos sobre la capacidad',
          subtitle: 'De dónde sale la capacidad efectiva del periodo',
          icon: Icons.calculate_outlined,
          accent: AppColors.info,
          child: _CapacityBreakdown(state: state, vm: vm),
        ),
      ],
    );
  }
}

class _AssignmentRow extends StatelessWidget {
  const _AssignmentRow({
    required this.member,
    required this.state,
    required this.available,
    required this.onChanged,
  });

  final TeamMember member;
  final ProjectState state;
  final List<WorkPackage> available;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final WorkPackage? current = state.packageById(member.assignedPackageId);
    final bool valid = current != null &&
        current.included &&
        !current.isDone &&
        state.phaseUnlocked(current.phase);

    final List<String> ids = available.map((WorkPackage p) => p.id).toList();
    final String? value = valid && ids.contains(current.id) ? current.id : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                valid ? Icons.person : Icons.person_off_outlined,
                size: 17,
                color: valid ? AppColors.execution : AppColors.danger,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  member.name,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
              if (member.isNewcomer)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'curva ${formatPercent(member.rampFactor)}',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              hintText: 'Sin asignación',
            ),
            items: available
                .map((WorkPackage p) => DropdownMenuItem<String>(
                      value: p.id,
                      child: Text(
                        '${p.phase.label} · ${p.name}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _CapacityBreakdown extends StatelessWidget {
  const _CapacityBreakdown({required this.state, required this.vm});

  final ProjectState state;
  final ProjectViewModel vm;

  @override
  Widget build(BuildContext context) {
    double raw = 0;
    int newcomers = 0;
    for (final TeamMember m in state.team) {
      raw += m.effectiveHours(vm.config.hoursPerPerson);
      if (m.isNewcomer) newcomers++;
    }
    final double efficiency = vm.config.teamEfficiency(state.team.length);
    final double mentoring = 1 -
        vm.config.mentoringPenaltyPerNewcomer *
            (newcomers > vm.config.maxMentoringNewcomers
                ? vm.config.maxMentoringNewcomers
                : newcomers);
    final double governance = 1 -
        state.methodology
            .governanceOverhead(regulated: state.projectCase.regulated);
    final double qa = 1 - state.qaLevel * vm.config.qaCapacityCost;
    final double fatigue = 1 - state.fatigue;

    return Column(
      children: <Widget>[
        _line('Horas nominales del equipo', formatHours(raw)),
        _line('Coordinación (${state.team.length} personas)',
            '× ${efficiency.toStringAsFixed(2)}'),
        _line('Mentoría a nuevos ($newcomers)',
            '× ${mentoring.toStringAsFixed(2)}'),
        _line('Gobernanza (${state.methodology.shortLabel})',
            '× ${governance.toStringAsFixed(2)}'),
        _line('Aseguramiento de calidad', '× ${qa.toStringAsFixed(2)}'),
        _line('Fatiga', '× ${fatigue.toStringAsFixed(2)}'),
        const Divider(height: 18),
        _line(
          'Capacidad efectiva',
          formatHours(state.effectiveCapacity(vm.config)),
          strong: true,
        ),
      ],
    );
  }

  Widget _line(String label, String value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
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
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: strong ? AppColors.info : AppColors.textSoft,
            ),
          ),
        ],
      ),
    );
  }
}
