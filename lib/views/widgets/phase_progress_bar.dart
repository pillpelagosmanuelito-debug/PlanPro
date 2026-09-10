import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../data/models/project_case.dart';
import '../../data/models/project_state.dart';

/// Barra de avance por fase, con la marca del hito que habilita la siguiente.
///
/// La marca es lo importante: ensena que las fases se traslapan y que no hace
/// falta terminar una para empezar la siguiente, pero si alcanzar un umbral.
class PhaseProgressBar extends StatelessWidget {
  const PhaseProgressBar({
    super.key,
    required this.state,
    required this.phase,
  });

  final ProjectState state;
  final ProjectPhase phase;

  Color get _color {
    switch (phase) {
      case ProjectPhase.analysis:
        return AppColors.initiation;
      case ProjectPhase.design:
        return AppColors.planning;
      case ProjectPhase.build:
        return AppColors.execution;
      case ProjectPhase.test:
        return AppColors.risk;
      case ProjectPhase.deploy:
        return AppColors.closure;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progress = state.phaseProgress(phase).clamp(0.0, 1.0);
    final bool unlocked = state.phaseUnlocked(phase);

    // Umbral que la fase SIGUIENTE exige de las anteriores.
    final int next = phase.index + 1;
    final double? gate = next < ProjectPhase.values.length
        ? ProjectPhase.values[next].gate
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                unlocked ? Icons.play_arrow_rounded : Icons.lock_outline,
                size: 14,
                color: unlocked ? _color : AppColors.textSoft,
              ),
              const SizedBox(width: 5),
              Text(
                phase.label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: unlocked ? AppColors.textStrong : AppColors.textSoft,
                ),
              ),
              const Spacer(),
              Text(
                formatPercent(progress),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: unlocked ? _color : AppColors.textSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double width = constraints.maxWidth;
              return SizedBox(
                height: 9,
                child: Stack(
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    Container(
                      width: (width * progress).clamp(0.0, width).toDouble(),
                      decoration: BoxDecoration(
                        color: unlocked
                            ? _color
                            : AppColors.textSoft.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    if (gate != null && gate > 0)
                      Positioned(
                        left: (width * gate)
                            .clamp(0.0, math.max(0.0, width - 2))
                            .toDouble(),
                        top: -2,
                        bottom: -2,
                        child: Container(
                          width: 2,
                          color: AppColors.textStrong.withOpacity(0.55),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
