import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../data/models/methodology.dart';
import '../../data/models/project_case.dart';
import '../../data/services/project_generator.dart';
import '../../viewmodels/project_viewmodel.dart';
import '../app_scope.dart';
import '../widgets/section_card.dart';

/// Eleccion del caso, el enfoque y la restriccion prioritaria.
///
/// Las tres decisiones se toman juntas a proposito: elegir metodologia sin
/// mirar el caso es el error que este simulador quiere hacer visible.
class CaseSelectionScreen extends StatefulWidget {
  const CaseSelectionScreen({super.key});

  @override
  State<CaseSelectionScreen> createState() => _CaseSelectionScreenState();
}

class _CaseSelectionScreenState extends State<CaseSelectionScreen> {
  String _caseId = ProjectCase.catalog.first.id;
  Methodology _methodology = Methodology.hybrid;
  ConstraintPriority _priority = ConstraintPriority.time;
  final TextEditingController _seedController = TextEditingController();

  @override
  void dispose() {
    _seedController.dispose();
    super.dispose();
  }

  ProjectCase get _case => ProjectCase.byId(_caseId);

  Future<void> _start() async {
    final ProjectViewModel vm = AppScope.read(context);
    final int? seed = int.tryParse(_seedController.text.trim());
    final NavigatorState navigator = Navigator.of(context);
    await vm.startSession(
      caseId: _caseId,
      methodology: _methodology,
      priority: _priority,
      seed: seed,
    );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo proyecto')),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 100),
        children: <Widget>[
          SectionCard(
            title: '1. Elige el caso',
            subtitle: 'Cada uno tiene una naturaleza distinta',
            icon: Icons.work_outline,
            child: Column(
              children: ProjectCase.catalog.map((ProjectCase c) {
                final bool selected = c.id == _caseId;
                return _SelectableTile(
                  selected: selected,
                  onTap: () => setState(() => _caseId = c.id),
                  title: c.name,
                  subtitle: '${c.client} · ${c.sector}',
                  detail:
                      'Techo ${formatMoney(c.budgetCeiling)} · '
                      '${c.targetPeriods} periodos · '
                      '${formatHours(c.totalEstimatedHours)} estimadas',
                  tags: <String>[
                    if (c.volatileRequirements)
                      'Requisitos en discusion'
                    else
                      'Alcance definido',
                    if (c.regulated) 'Entorno regulado' else 'Sin supervision formal',
                  ],
                );
              }).toList(),
            ),
          ),
          SectionCard(
            title: '2. Lee el acta antes de elegir enfoque',
            icon: Icons.description_outlined,
            accent: AppColors.initiation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _case.charter,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 12),
                NoteBox(
                  text: _case.volatileRequirements
                      ? 'Este caso tiene requisitos abiertos: habra cambios '
                          'durante la ejecucion, y cada enfoque los cobra a un '
                          'precio distinto.'
                      : 'Este caso tiene el alcance definido y aprobado: aqui '
                          'la flexibilidad se paga sin comprar nada.',
                  icon: Icons.info_outline,
                ),
              ],
            ),
          ),
          SectionCard(
            title: '3. Enfoque de direccion',
            subtitle: 'PMBOK, Scrum o una combinacion',
            icon: Icons.alt_route,
            accent: AppColors.planning,
            child: Column(
              children: Methodology.values.map((Methodology m) {
                return _SelectableTile(
                  selected: m == _methodology,
                  onTap: () => setState(() => _methodology = m),
                  title: m.label,
                  subtitle: m.description,
                  detail: 'Funciona cuando: ${m.worksWhen}',
                );
              }).toList(),
            ),
          ),
          SectionCard(
            title: '4. Restriccion prioritaria',
            subtitle: 'Que defiendes cuando algo tenga que ceder',
            icon: Icons.balance,
            accent: AppColors.risk,
            child: Column(
              children: ConstraintPriority.values.map((ConstraintPriority p) {
                return _SelectableTile(
                  selected: p == _priority,
                  onTap: () => setState(() => _priority = p),
                  title: p.label,
                  subtitle: p.detail,
                );
              }).toList(),
            ),
          ),
          SectionCard(
            title: 'Semilla (opcional)',
            subtitle: 'Para que toda la clase enfrente el mismo proyecto',
            icon: Icons.casino_outlined,
            accent: AppColors.closure,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextField(
                  controller: _seedController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Ejemplo: 2024',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Con la misma semilla, las duraciones reales ocultas y los '
                  'riesgos son identicos para todos. Las diferencias de '
                  'resultado seran solo de direccion.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textSoft,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Si lo dejas vacio se usara una semilla aleatoria '
                  '(ej. ${ProjectGenerator.randomSeed()}).',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSoft,
                  ),
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
            onPressed: _start,
            icon: const Icon(Icons.assignment_turned_in_outlined),
            label: const Text('Recibir el acta de constitucion'),
          ),
        ),
      ),
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.selected,
    required this.onTap,
    required this.title,
    required this.subtitle,
    this.detail,
    this.tags = const <String>[],
  });

  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final String? detail;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withOpacity(0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 18,
                color: selected ? AppColors.primary : AppColors.textSoft,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textStrong,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.textSoft,
                      ),
                    ),
                    if (detail != null) ...<Widget>[
                      const SizedBox(height: 5),
                      Text(
                        detail!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          height: 1.3,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (tags.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: tags
                            .map((String t) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border:
                                        Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    t,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.textSoft,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
