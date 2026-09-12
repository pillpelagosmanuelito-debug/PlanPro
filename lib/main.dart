import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'data/models/project_state.dart';
import 'viewmodels/project_viewmodel.dart';
import 'views/app_scope.dart';
import 'views/screens/charter_screen.dart';
import 'views/screens/closure_screen.dart';
import 'views/screens/execution_screen.dart';
import 'views/screens/home_screen.dart';
import 'views/screens/planning_screen.dart';

void main() {
  runApp(const ProjectManagementSimulatorApp());
}

class ProjectManagementSimulatorApp extends StatefulWidget {
  const ProjectManagementSimulatorApp({super.key});

  @override
  State<ProjectManagementSimulatorApp> createState() =>
      _ProjectManagementSimulatorAppState();
}

class _ProjectManagementSimulatorAppState
    extends State<ProjectManagementSimulatorApp> {
  late final ProjectViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProjectViewModel();
    _viewModel.init();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      viewModel: _viewModel,
      child: MaterialApp(
        title: 'Project Management Simulator',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        home: const RootScreen(),
      ),
    );
  }
}

/// Decide qué pantalla corresponde a la etapa actual de la partida.
class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel vm = AppScope.of(context);

    if (vm.status == ViewStatus.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final ProjectState? state = vm.state;
    if (state == null) return const HomeScreen();

    if (state.outcome.isFinished || state.stage == ProjectStage.closure) {
      return const ClosureScreen();
    }

    switch (state.stage) {
      case ProjectStage.initiation:
        return const CharterScreen();
      case ProjectStage.planning:
        return const PlanningScreen();
      case ProjectStage.execution:
        return const ExecutionScreen();
      case ProjectStage.closure:
        return const ClosureScreen();
    }
  }
}
