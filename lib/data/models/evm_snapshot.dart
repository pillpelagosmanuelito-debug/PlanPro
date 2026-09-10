/// Fotografia de gestion del valor ganado en un periodo.
///
/// Es el instrumental estandar de control de proyectos: con tres numeros
/// (PV, EV, AC) se responde si el proyecto esta atrasado, sobrecostado, o
/// ambas cosas, y cuanto costara terminarlo si nada cambia.
class EvmSnapshot {
  const EvmSnapshot({
    required this.period,
    required this.plannedValue,
    required this.earnedValue,
    required this.actualCost,
    required this.budgetAtCompletion,
  });

  final int period;

  /// Valor planificado: cuanto deberia haberse ejecutado a la fecha.
  final double plannedValue;

  /// Valor ganado: cuanto vale lo realmente terminado.
  final double earnedValue;

  /// Costo real incurrido.
  final double actualCost;

  final double budgetAtCompletion;

  /// Variacion de cronograma en dinero.
  double get scheduleVariance => earnedValue - plannedValue;

  /// Variacion de costo en dinero.
  double get costVariance => earnedValue - actualCost;

  /// Indice de desempenio del cronograma.
  double get spi => plannedValue <= 0 ? 1.0 : earnedValue / plannedValue;

  /// Indice de desempenio del costo.
  double get cpi => actualCost <= 0 ? 1.0 : earnedValue / actualCost;

  /// Estimacion a la conclusion, asumiendo que el desempenio se mantiene.
  double get estimateAtCompletion =>
      cpi <= 0 ? budgetAtCompletion : budgetAtCompletion / cpi;

  /// Estimacion para terminar.
  double get estimateToComplete => estimateAtCompletion - actualCost;

  /// Variacion a la conclusion: cuanto se saldra del presupuesto.
  double get varianceAtCompletion => budgetAtCompletion - estimateAtCompletion;

  /// Indice de desempenio del trabajo por completar.
  double get tcpi {
    final double remainingWork = budgetAtCompletion - earnedValue;
    final double remainingFunds = budgetAtCompletion - actualCost;
    if (remainingFunds <= 0) return double.infinity;
    return remainingWork / remainingFunds;
  }

  /// Avance fisico expresado como fraccion del presupuesto.
  double get progress =>
      budgetAtCompletion <= 0 ? 0.0 : earnedValue / budgetAtCompletion;

  /// Lectura en lenguaje de direccion de proyectos.
  String get reading {
    final bool late = spi < 0.95;
    final bool over = cpi < 0.95;
    if (late && over) return 'Atrasado y sobrecostado';
    if (late) return 'Atrasado, dentro de costo';
    if (over) return 'En fecha, pero sobrecostado';
    if (spi > 1.05 && cpi > 1.05) return 'Adelantado y por debajo del costo';
    return 'Dentro de lo planificado';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'period': period,
        'plannedValue': plannedValue,
        'earnedValue': earnedValue,
        'actualCost': actualCost,
        'budgetAtCompletion': budgetAtCompletion,
      };

  factory EvmSnapshot.fromJson(Map<String, dynamic> json) => EvmSnapshot(
        period: (json['period'] as num?)?.toInt() ?? 1,
        plannedValue: (json['plannedValue'] as num?)?.toDouble() ?? 0,
        earnedValue: (json['earnedValue'] as num?)?.toDouble() ?? 0,
        actualCost: (json['actualCost'] as num?)?.toDouble() ?? 0,
        budgetAtCompletion:
            (json['budgetAtCompletion'] as num?)?.toDouble() ?? 1,
      );
}
