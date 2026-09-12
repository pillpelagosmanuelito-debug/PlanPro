import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_simulator/data/models/advisor_message.dart';
import 'package:project_management_simulator/data/models/evm_snapshot.dart';
import 'package:project_management_simulator/main.dart';
import 'package:project_management_simulator/views/widgets/advisor_card.dart';
import 'package:project_management_simulator/views/widgets/evm_chart.dart';
import 'package:project_management_simulator/views/widgets/metric_tile.dart';
import 'package:project_management_simulator/views/screens/guide_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('la aplicacion arranca en la pantalla de inicio', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProjectManagementSimulatorApp());
    await tester.pumpAndSettle();

    expect(find.text('Empezar un proyecto'), findsOneWidget);
    expect(find.textContaining('Project Management'), findsWidgets);
  });

  testWidgets('se puede abrir la seleccion de caso', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProjectManagementSimulatorApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Empezar un proyecto'));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo proyecto'), findsOneWidget);
    expect(find.text('1. Elige el caso'), findsOneWidget);
    expect(find.textContaining('Sistema de Matrícula'), findsWidgets);
  });

  testWidgets('la guia de referencia se abre desde el inicio', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProjectManagementSimulatorApp());
    await tester.pumpAndSettle();

    final Finder guideButton = find.text('Guía de metodologías e indicadores');
    await tester.dragUntilVisible(
      guideButton,
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    await tester.tap(guideButton);
    await tester.pumpAndSettle();

    expect(find.text('Guía de referencia'), findsOneWidget);

    final Finder spiText = find.textContaining('SPI = EV / PV');
    await tester.dragUntilVisible(
      spiText,
      find.descendant(
        of: find.byType(GuideScreen),
        matching: find.byType(ListView),
      ),
      const Offset(0, -300),
    );
    expect(spiText, findsOneWidget);
  });

  testWidgets('el indicador acepta valores no finitos sin romperse', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: IndexBar(label: 'TCPI', value: double.infinity),
          ),
        ),
      ),
    );
    expect(find.text('--'), findsOneWidget);
  });

  testWidgets('el grafico de valor ganado avisa cuando no hay datos', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: EvmChart(snapshots: <EvmSnapshot>[])),
      ),
    );
    expect(find.textContaining('primer periodo'), findsOneWidget);
  });

  testWidgets('el grafico dibuja la curva con datos', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EvmChart(
            snapshots: <EvmSnapshot>[
              for (int i = 1; i <= 5; i++)
                EvmSnapshot(
                  period: i,
                  plannedValue: 40000.0 * i,
                  earnedValue: 35000.0 * i,
                  actualCost: 42000.0 * i,
                  budgetAtCompletion: 400000,
                ),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.textContaining('Valor ganado'), findsOneWidget);
  });

  testWidgets('el consejo muestra diagnostico y recomendacion', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AdvisorCard(
              message: AdvisorMessage(
                ruleId: 'demo',
                area: AdvisorArea.schedule,
                severity: AdvisorSeverity.critical,
                title: 'Atraso significativo',
                diagnosis: 'El SPI es 0.82.',
                recommendation: 'Recorta alcance opcional ahora.',
                evidence: 'SV -40,000',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Atraso significativo'), findsOneWidget);
    expect(find.text('El SPI es 0.82.'), findsOneWidget);
    expect(find.text('Recorta alcance opcional ahora.'), findsOneWidget);
    expect(find.text('Cronograma'), findsOneWidget);
  });
}
