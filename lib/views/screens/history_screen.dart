import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../viewmodels/project_viewmodel.dart';
import '../app_scope.dart';
import '../widgets/section_card.dart';

/// Historial de proyectos cerrados.
///
/// Sirve para comparar partidas: mismo caso, distinta metodología, distinto
/// resultado. Esa comparación es la evidencia que convence más que cualquier
/// definición de manual.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel vm = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proyectos cerrados'),
        actions: <Widget>[
          if (vm.finished.isNotEmpty)
            IconButton(
              tooltip: 'Borrar historial',
              onPressed: () async {
                final bool? ok = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext ctx) => AlertDialog(
                    title: const Text('Borrar historial'),
                    content: const Text(
                      'Se eliminarán todos los registros de partidas cerradas.',
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Borrar'),
                      ),
                    ],
                  ),
                );
                if (ok == true) await vm.clearFinished();
              },
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: vm.finished.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Todavía no has cerrado ningún proyecto.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textSoft),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              children: vm.finished.map((Map<String, dynamic> row) {
                final double score =
                    (row['score'] as num?)?.toDouble() ?? 0;
                final Color color = score >= 85
                    ? AppColors.success
                    : score >= 70
                        ? AppColors.info
                        : score >= 55
                            ? AppColors.warning
                            : AppColors.danger;
                return SectionCard(
                  title: row['caseName'] as String? ?? 'Proyecto',
                  subtitle: '${row['methodology'] ?? ''} · '
                      'semilla ${row['seed'] ?? ''}',
                  icon: Icons.flag_outlined,
                  accent: color,
                  trailing: Text(
                    score.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      _line('Desenlace', row['outcome'] as String? ?? '--'),
                      _line('Periodos usados', '${row['periods'] ?? '--'}'),
                      _line(
                        'Costo final',
                        formatMoney((row['cost'] as num?)?.toDouble() ?? 0),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textStrong,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSoft,
            ),
          ),
        ],
      ),
    );
  }
}
