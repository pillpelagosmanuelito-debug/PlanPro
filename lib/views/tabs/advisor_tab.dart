import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/models/advisor_message.dart';
import '../../viewmodels/project_viewmodel.dart';
import '../app_scope.dart';
import '../widgets/advisor_card.dart';
import '../widgets/section_card.dart';

/// Asistente de dirección de proyectos.
///
/// Muestra el análisis del estado actual agrupado por urgencia. La cabecera
/// explica que el asistente ve exactamente lo mismo que el estudiante: es una
/// aclaración honesta y también una lección sobre los límites de cualquier
/// herramienta de apoyo a la decisión.
class AdvisorTab extends StatelessWidget {
  const AdvisorTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel vm = AppScope.of(context);
    final List<AdvisorMessage> messages = vm.advice();

    final Map<AdvisorSeverity, List<AdvisorMessage>> grouped =
        <AdvisorSeverity, List<AdvisorMessage>>{};
    for (final AdvisorMessage m in messages) {
      grouped.putIfAbsent(m.severity, () => <AdvisorMessage>[]).add(m);
    }

    return ListView(
      padding: const EdgeInsets.only(top: 14, bottom: 24),
      children: <Widget>[
        SectionCard(
          title: 'Lectura del proyecto',
          subtitle: vm.advisorHeadline(),
          icon: Icons.support_agent,
          accent: AppColors.accent,
          child: const NoteBox(
            text: 'El asistente aplica reglas de dirección de proyectos sobre '
                'la misma información que ves tú: estimaciones, avance '
                'reportado e indicadores. No conoce la duración real de los '
                'paquetes ni los riesgos que no has identificado. Sus '
                'consejos son buenos en la medida en que tu información lo '
                'sea.',
            icon: Icons.visibility_outlined,
            color: AppColors.accent,
          ),
        ),
        if (messages.isEmpty)
          const SectionCard(
            title: 'Sin observaciones',
            subtitle: 'Nada que corregir con la información disponible',
            icon: Icons.check_circle_outline,
            accent: AppColors.success,
            child: Text(
              'Que no haya alertas no significa que no haya riesgo: significa '
              'que ninguna regla se activó con lo que hoy sabes.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.textSoft,
              ),
            ),
          ),
        ...AdvisorSeverity.values.map((AdvisorSeverity severity) {
          final List<AdvisorMessage> list =
              grouped[severity] ?? <AdvisorMessage>[];
          if (list.isEmpty) return const SizedBox.shrink();
          return SectionCard(
            title: severity.label,
            subtitle: '${list.length} observación(es)',
            icon: _iconFor(severity),
            accent: _colorFor(severity),
            child: Column(
              children: list
                  .map((AdvisorMessage m) => AdvisorCard(message: m))
                  .toList(),
            ),
          );
        }),
      ],
    );
  }

  IconData _iconFor(AdvisorSeverity s) {
    switch (s) {
      case AdvisorSeverity.critical:
        return Icons.error_outline;
      case AdvisorSeverity.warning:
        return Icons.warning_amber_rounded;
      case AdvisorSeverity.insight:
        return Icons.psychology_outlined;
      case AdvisorSeverity.positive:
        return Icons.check_circle_outline;
    }
  }

  Color _colorFor(AdvisorSeverity s) {
    switch (s) {
      case AdvisorSeverity.critical:
        return AppColors.danger;
      case AdvisorSeverity.warning:
        return AppColors.warning;
      case AdvisorSeverity.insight:
        return AppColors.info;
      case AdvisorSeverity.positive:
        return AppColors.success;
    }
  }
}
