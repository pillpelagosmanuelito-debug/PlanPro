/// Competencias evaluadas por el simulador.
enum PmCompetency {
  planning,
  resources,
  risk,
  time;

  String get label {
    switch (this) {
      case PmCompetency.planning:
        return 'Planificación';
      case PmCompetency.resources:
        return 'Gestión de recursos';
      case PmCompetency.risk:
        return 'Gestión de riesgos';
      case PmCompetency.time:
        return 'Gestión del tiempo';
    }
  }

  String get definition {
    switch (this) {
      case PmCompetency.planning:
        return 'Comprometer una línea base realista, con alcance, plazo, '
            'equipo y reserva coherentes entre sí.';
      case PmCompetency.resources:
        return 'Asignar el equipo al trabajo correcto, sin capacidad ociosa '
            'ni incorporaciones que cuesten más de lo que aportan.';
      case PmCompetency.risk:
        return 'Identificar riesgos antes de que ocurran y responder según su '
            'exposición, no según la urgencia del día.';
      case PmCompetency.time:
        return 'Sostener el cronograma: leer los índices a tiempo y corregir '
            'donde está el cuello de botella.';
    }
  }
}

/// Puntaje de una competencia con su evidencia.
class CompetencyScore {
  const CompetencyScore({
    required this.competency,
    required this.score,
    required this.strengths,
    required this.gaps,
  });

  final PmCompetency competency;
  final double score;
  final List<String> strengths;
  final List<String> gaps;

  String get level {
    if (score >= 85) return 'Destacado';
    if (score >= 70) return 'Competente';
    if (score >= 55) return 'En desarrollo';
    return 'Inicial';
  }
}

/// Contraste entre lo estimado y lo que realmente costó.
class EstimateGap {
  const EstimateGap({
    required this.packageName,
    required this.estimatedHours,
    required this.realHours,
    required this.completed,
  });

  final String packageName;
  final double estimatedHours;
  final double realHours;
  final bool completed;

  double get deviation =>
      estimatedHours <= 0 ? 0 : (realHours - estimatedHours) / estimatedHours;
}

/// Informe final del proyecto.
class EvaluationReport {
  const EvaluationReport({
    required this.scores,
    required this.estimateGaps,
    required this.headline,
    required this.verdict,
    required this.narrative,
    required this.nextSteps,
    required this.periodsUsed,
    required this.committedPeriods,
    required this.finalCost,
    required this.budgetAtCompletion,
    required this.budgetCeiling,
    required this.scopeDelivered,
    required this.escapedDefects,
    required this.sponsorSatisfaction,
    required this.risksIdentified,
    required this.risksTotal,
    required this.risksMaterialized,
    required this.risksUnidentifiedHit,
    required this.finalCpi,
    required this.finalSpi,
    required this.wastedHours,
    required this.complianceIssue,
  });

  final List<CompetencyScore> scores;
  final List<EstimateGap> estimateGaps;

  final String headline;
  final String verdict;
  final String narrative;
  final List<String> nextSteps;

  final int periodsUsed;
  final int committedPeriods;

  final double finalCost;
  final double budgetAtCompletion;
  final double budgetCeiling;

  /// Fracción del alcance comprometido efectivamente entregada.
  final double scopeDelivered;

  final double escapedDefects;
  final double sponsorSatisfaction;

  final int risksIdentified;
  final int risksTotal;
  final int risksMaterialized;

  /// Riesgos que golpearon sin haber sido identificados.
  final int risksUnidentifiedHit;

  final double finalCpi;
  final double finalSpi;

  /// Horas de equipo perdidas por mala asignación o bloqueo de fases.
  final double wastedHours;

  /// Si el cierre tuvo observaciones por documentación insuficiente.
  final bool complianceIssue;

  double get scheduleVariancePeriods =>
      (periodsUsed - committedPeriods).toDouble();

  double get costVariance => budgetAtCompletion - finalCost;

  double get overallScore {
    if (scores.isEmpty) return 0;
    double sum = 0;
    for (final CompetencyScore s in scores) {
      sum += s.score;
    }
    return sum / scores.length;
  }

  CompetencyScore scoreFor(PmCompetency c) => scores.firstWhere(
        (CompetencyScore s) => s.competency == c,
        orElse: () => CompetencyScore(
          competency: c,
          score: 0,
          strengths: const <String>[],
          gaps: const <String>[],
        ),
      );
}
