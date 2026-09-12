import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

/// Indicador compacto: valor grande, etiqueta y lectura de apoyo.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.hint,
    this.color = AppColors.primary,
    this.icon,
  });

  final String label;
  final String value;
  final String? hint;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.textStrong,
              ),
            ),
          ),
          if (hint != null) ...<Widget>[
            const SizedBox(height: 3),
            Text(
              hint!,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSoft,
                height: 1.25,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Barra de índice con referencia en 1.00.
///
/// El punto de referencia importa: un SPI de 0.9 no significa nada sin saber
/// que 1.0 es "al ritmo planificado".
class IndexBar extends StatelessWidget {
  const IndexBar({
    super.key,
    required this.label,
    required this.value,
    this.max = 1.4,
  });

  final String label;
  final double value;
  final double max;

  Color get _color {
    if (value >= 0.98) return AppColors.success;
    if (value >= 0.90) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final double safe = value.isFinite ? value.clamp(0.0, max).toDouble() : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textStrong,
              ),
            ),
            const Spacer(),
            Text(
              value.isFinite ? value.toStringAsFixed(2) : '--',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width = constraints.maxWidth;
            final double fill = (safe / max) * width;
            final double refPos = (1.0 / max) * width;
            return SizedBox(
              height: 10,
              child: Stack(
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  Container(
                    width: fill.clamp(0.0, width).toDouble(),
                    decoration: BoxDecoration(
                      color: _color,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  Positioned(
                    left: refPos
                        .clamp(0.0, math.max(0.0, width - 2))
                        .toDouble(),
                    top: 0,
                    bottom: 0,
                    child: Container(width: 2, color: AppColors.textStrong),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
