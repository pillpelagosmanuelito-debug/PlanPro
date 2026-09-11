import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/models/evm_snapshot.dart';

/// Curva S del proyecto: valor planificado, valor ganado y costo real.
///
/// Es el grafico canonico del control de proyectos. Se dibuja con
/// `CustomPainter` para no agregar dependencias de graficos al MVP.
class EvmChart extends StatelessWidget {
  const EvmChart({super.key, required this.snapshots});

  final List<EvmSnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    if (snapshots.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'Los indicadores apareceran al cerrar el primer periodo.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSoft),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 160,
          width: double.infinity,
          child: CustomPaint(painter: _EvmPainter(snapshots)),
        ),
        const SizedBox(height: 10),
        const Wrap(
          spacing: 14,
          runSpacing: 6,
          children: <Widget>[
            _Legend(color: AppColors.info, label: 'Valor planificado (PV)'),
            _Legend(color: AppColors.success, label: 'Valor ganado (EV)'),
            _Legend(color: AppColors.danger, label: 'Costo real (AC)'),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSoft),
        ),
      ],
    );
  }
}

class _EvmPainter extends CustomPainter {
  _EvmPainter(this.snapshots);

  final List<EvmSnapshot> snapshots;

  @override
  void paint(Canvas canvas, Size size) {
    double maxValue = 1;
    for (final EvmSnapshot s in snapshots) {
      maxValue = math.max(
        maxValue,
        math.max(s.plannedValue, math.max(s.earnedValue, s.actualCost)),
      );
    }
    maxValue *= 1.08;

    const double left = 8;
    const double bottom = 18;
    final double w = math.max(1, size.width - left - 6);
    final double h = math.max(1, size.height - bottom - 6);

    final Paint grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final double y = 6 + h * (i / 4);
      canvas.drawLine(Offset(left, y), Offset(left + w, y), grid);
    }

    final int n = snapshots.length;
    double xFor(int i) => n <= 1 ? left : left + w * (i / (n - 1));
    double yFor(double v) => 6 + h * (1 - (v / maxValue).clamp(0.0, 1.0));

    void drawSeries(double Function(EvmSnapshot) pick, Color color) {
      final Path path = Path();
      for (int i = 0; i < n; i++) {
        final Offset p = Offset(xFor(i), yFor(pick(snapshots[i])));
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 2.4
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round,
      );
      for (int i = 0; i < n; i++) {
        canvas.drawCircle(
          Offset(xFor(i), yFor(pick(snapshots[i]))),
          2.6,
          Paint()..color = color,
        );
      }
    }

    drawSeries((EvmSnapshot s) => s.plannedValue, AppColors.info);
    drawSeries((EvmSnapshot s) => s.actualCost, AppColors.danger);
    drawSeries((EvmSnapshot s) => s.earnedValue, AppColors.success);

    // Eje de periodos.
    final TextPainter tp = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    for (int i = 0; i < n; i += math.max(1, (n / 6).ceil())) {
      tp.text = TextSpan(
        text: 'P${snapshots[i].period}',
        style: const TextStyle(fontSize: 9, color: AppColors.textSoft),
      );
      tp.layout();
      tp.paint(canvas, Offset(xFor(i) - tp.width / 2, size.height - 13));
    }
  }

  @override
  bool shouldRepaint(covariant _EvmPainter oldDelegate) =>
      oldDelegate.snapshots.length != snapshots.length;
}
