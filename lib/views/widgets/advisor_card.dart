import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/models/advisor_message.dart';

/// Mensaje del asistente de dirección de proyectos.
///
/// Muestra siempre las tres partes: qué observa, qué significa y qué hacer.
/// Un consejo sin diagnóstico no enseña a diagnosticar.
class AdvisorCard extends StatelessWidget {
  const AdvisorCard({super.key, required this.message});

  final AdvisorMessage message;

  Color get _color {
    switch (message.severity) {
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

  IconData get _icon {
    switch (message.severity) {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.10),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                topRight: Radius.circular(13),
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(_icon, size: 16, color: _color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _color,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    message.area.label,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: _color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  message.diagnosis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        message.recommendation,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (message.evidence.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    message.evidence,
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSoft,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
