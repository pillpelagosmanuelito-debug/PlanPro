import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/models/project_config.dart';
import '../../viewmodels/project_viewmodel.dart';
import '../app_scope.dart';
import '../widgets/section_card.dart';
import 'case_selection_screen.dart';
import 'guide_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel vm = AppScope.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: <Widget>[
            const _Header(),
            const SizedBox(height: 18),
            SectionCard(
              title: 'Dirige un proyecto real',
              subtitle: 'Cinco módulos, doce periodos, decisiones con consecuencia',
              icon: Icons.account_tree_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    ProjectBriefing.mandate,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.textStrong,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CaseSelectionScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Empezar un proyecto'),
                  ),
                ],
              ),
            ),
            SectionCard(
              title: 'Cómo funciona',
              subtitle: 'Las reglas del simulador, sin letra chica',
              icon: Icons.rule_folder_outlined,
              accent: AppColors.planning,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ...ProjectBriefing.rules.map(
                    (String rule) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Padding(
                            padding: EdgeInsets.only(top: 5, right: 8),
                            child: Icon(
                              Icons.circle,
                              size: 6,
                              color: AppColors.planning,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              rule,
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.4,
                                color: AppColors.textStrong,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const GuideScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.menu_book_outlined, size: 18),
                    label: const Text('Guía de metodologías e indicadores'),
                  ),
                ],
              ),
            ),
            SectionCard(
              title: 'Proyectos cerrados',
              subtitle: vm.finished.isEmpty
                  ? 'Todavía no has cerrado ningún proyecto'
                  : '${vm.finished.length} partida(s) en tu historial',
              icon: Icons.history,
              accent: AppColors.closure,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'Cada cierre guarda tu puntaje por competencia. Repetir el '
                    'mismo caso con otra metodología es la forma más rápida de '
                    'ver que ninguna es mejor en abstracto.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: AppColors.textSoft,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: vm.finished.isEmpty
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const HistoryScreen(),
                              ),
                            ),
                    icon: const Icon(Icons.leaderboard_outlined, size: 18),
                    label: const Text('Ver historial'),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22),
              child: Text(
                'Simulador educativo. Los casos son ficticios y están '
                'inspirados en proyectos típicos del contexto peruano.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textSoft),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_tree_rounded,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Project Management\nSimulator',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Conocer PMBOK, Scrum o Agile no es lo mismo que decidir bajo '
            'restricciones. Aquí decides.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.88),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
