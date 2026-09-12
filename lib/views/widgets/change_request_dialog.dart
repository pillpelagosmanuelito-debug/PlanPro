import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../data/models/change_request.dart';
import '../../data/models/project_state.dart';
import '../../data/models/work_package.dart';
import '../../viewmodels/project_viewmodel.dart';
import '../app_scope.dart';

/// Decisión sobre una solicitud de cambio.
///
/// Las cuatro opciones son las que existen en la práctica, y ninguna es
/// gratis. La opción que más contenta al patrocinador (aceptar sin mover la
/// línea base) es también la que peor termina: esa tensión es el aprendizaje.
class ChangeRequestDialog extends StatelessWidget {
  const ChangeRequestDialog({super.key, required this.change});

  final ChangeRequest change;

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel vm = AppScope.of(context);
    final ProjectState state = vm.state!;
    final bool hasOptional = state.packages.any((WorkPackage p) =>
        p.optional && p.included && p.workedHours <= 0);

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            change.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            'Solicita: ${change.requestedBy} · periodo ${change.period}',
            style: const TextStyle(fontSize: 11.5, color: AppColors.textSoft),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              change.description,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: <Widget>[
                  _row(
                    'Trabajo adicional',
                    formatHours(change.baseHours),
                  ),
                  _row(
                    'Multiplicador del enfoque',
                    '× ${state.methodology.changeCostFactor.toStringAsFixed(1)} '
                        '(${state.methodology.shortLabel})',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ..._options(context, vm, hasOptional),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Decidir después'),
        ),
      ],
    );
  }

  List<Widget> _options(
    BuildContext context,
    ProjectViewModel vm,
    bool hasOptional,
  ) {
    final List<ChangeDecision> options = <ChangeDecision>[
      ChangeDecision.acceptedWithBaseline,
      ChangeDecision.tradedOff,
      ChangeDecision.acceptedWithoutBaseline,
      ChangeDecision.rejected,
    ];

    return options.map((ChangeDecision d) {
      final bool enabled =
          d != ChangeDecision.tradedOff || hasOptional;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: enabled
              ? () {
                  vm.decideChange(change.id, d);
                  Navigator.of(context).pop();
                }
              : null,
          child: Opacity(
            opacity: enabled ? 1 : 0.45,
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          d.label,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textStrong,
                          ),
                        ),
                      ),
                      _delta(d.satisfactionDelta()),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    enabled
                        ? d.consequence
                        : 'No queda alcance opcional sin empezar que puedas '
                            'intercambiar.',
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: AppColors.textSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _delta(double value) {
    final bool positive = value >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: (positive ? AppColors.success : AppColors.danger)
            .withOpacity(0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${positive ? '+' : ''}${value.toStringAsFixed(0)} patrocinador',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: positive ? AppColors.success : AppColors.danger,
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textStrong,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
