import 'dart:math' as math;

import '../../core/formatters.dart';
import '../models/baseline.dart';
import '../models/change_request.dart';
import '../models/evaluation_report.dart';
import '../models/evm_snapshot.dart';
import '../models/period_result.dart';
import '../models/project_case.dart';
import '../models/project_config.dart';
import '../models/project_state.dart';
import '../models/risk_item.dart';
import '../models/work_package.dart';

/// Construye el informe de cierre.
///
/// La evaluacion no premia terminar: premia dirigir. Un proyecto entregado a
/// fuerza de horas extra, con la reserva quemada y el patrocinador molesto, no
/// puntua mejor que uno entregado con holgura y trazabilidad. Cada competencia
/// se califica con evidencia observable de la partida, de modo que el
/// estudiante pueda discutir el puntaje mirando sus propias decisiones.
class EvaluationService {
  const EvaluationService({this.config = const ProjectConfig()});

  final ProjectConfig config;

  EvaluationReport build({
    required ProjectState state,
    required List<PeriodResult> history,
  }) {
    final ProjectCase c = state.projectCase;
    final Baseline? baseline = state.baseline;
    final int periodsUsed = history.length;
    final int committed = baseline?.committedPeriods ?? c.targetPeriods;
    final EvmSnapshot? last =
        state.snapshots.isEmpty ? null : state.snapshots.last;

    double capacityTotal = 0;
    double appliedTotal = 0;
    double wastedTotal = 0;
    for (final PeriodResult r in history) {
      capacityTotal += r.capacity;
      appliedTotal += r.appliedHours;
      wastedTotal += r.wastedHours;
    }
    final double utilization =
        capacityTotal <= 0 ? 0.0 : appliedTotal / capacityTotal;

    final double scopeDelivered = _scopeDelivered(state);
    final bool complianceIssue = c.regulated &&
        state.methodology.complianceLevel < 0.80;

    final List<CompetencyScore> scores = <CompetencyScore>[
      _planning(state, baseline, c, periodsUsed, committed),
      _resources(state, utilization, wastedTotal),
      _risk(state),
      _time(state, last, periodsUsed, committed),
    ];

    return EvaluationReport(
      scores: scores,
      estimateGaps: _gaps(state),
      headline: _headline(state, periodsUsed, committed),
      verdict: _verdict(state, scores),
      narrative: _narrative(state, c, baseline, periodsUsed, committed, last),
      nextSteps: _nextSteps(scores),
      periodsUsed: periodsUsed,
      committedPeriods: committed,
      finalCost: state.actualCost,
      budgetAtCompletion: baseline?.budgetAtCompletion ?? c.budgetCeiling,
      budgetCeiling: c.budgetCeiling,
      scopeDelivered: scopeDelivered,
      escapedDefects: state.escapedDefects,
      sponsorSatisfaction: state.sponsorSatisfaction,
      risksIdentified: state.identifiedRisks.length,
      risksTotal: state.risks.length,
      risksMaterialized: state.risks.where((RiskItem r) => r.occurred).length,
      risksUnidentifiedHit: state.risks
          .where((RiskItem r) => r.occurred && !r.identified)
          .length,
      finalCpi: last?.cpi ?? 0,
      finalSpi: last?.spi ?? 0,
      wastedHours: wastedTotal,
      complianceIssue: complianceIssue,
    );
  }

  double _scopeDelivered(ProjectState state) {
    final List<WorkPackage> included = state.includedPackages;
    if (included.isEmpty) return 0;
    double estimated = 0;
    double done = 0;
    for (final WorkPackage p in included) {
      estimated += p.estimatedHours;
      done += p.earnedHours;
    }
    return estimated <= 0 ? 0.0 : (done / estimated).clamp(0.0, 1.0).toDouble();
  }

  // ------------------------------------------------------------------
  // Planificacion
  // ------------------------------------------------------------------

  CompetencyScore _planning(
    ProjectState state,
    Baseline? baseline,
    ProjectCase c,
    int periodsUsed,
    int committed,
  ) {
    final List<String> strengths = <String>[];
    final List<String> gaps = <String>[];
    double score = 50;

    if (baseline == null) {
      return const CompetencyScore(
        competency: PmCompetency.planning,
        score: 20,
        strengths: <String>[],
        gaps: <String>[
          'Nunca comprometiste una linea base: sin promesa formal no hay nada '
              'contra que medir el desempenio.',
        ],
      );
    }

    // Realismo del compromiso.
    final int slip = periodsUsed - committed;
    if (slip <= 0) {
      score += 24;
      strengths.add(
          'Comprometiste $committed periodos y cerraste en $periodsUsed: la '
          'promesa era alcanzable y la sostuviste.');
    } else if (slip == 1) {
      score += 8;
      gaps.add(
          'Terminaste un periodo despues de lo comprometido. Un desvio '
          'pequenio, pero es la fecha que el patrocinador anuncio.');
    } else {
      score -= 6 + math.min(14, slip * 4).toDouble();
      gaps.add(
          'El proyecto tomo $periodsUsed periodos contra $committed '
          'comprometidos: la linea base era optimista desde el dia uno.');
    }

    // Reserva de contingencia.
    final double reserveRate = baseline.plannedCost <= 0
        ? 0.0
        : baseline.contingencyReserve / baseline.plannedCost;
    if (reserveRate >= 0.06 && reserveRate <= 0.20) {
      score += 14;
      strengths.add(
          'Declaraste ${formatPercent(reserveRate)} de reserva de '
          'contingencia: ni imprudente ni inflada.');
    } else if (reserveRate < 0.06) {
      score -= 10;
      gaps.add(
          'La reserva fue apenas ${formatPercent(reserveRate)}. Sin colchon, '
          'cualquier riesgo se convierte en sobrecosto frente a la linea '
          'base.');
    } else {
      score -= 4;
      gaps.add(
          'Reservaste ${formatPercent(reserveRate)}: una reserva excesiva '
          'inmoviliza presupuesto y suele leerse como falta de analisis.');
    }

    // Capacidad comprometida frente al alcance.
    final double capacityPerPeriod =
        baseline.teamSize * config.hoursPerPerson * 0.85;
    final double needed = capacityPerPeriod <= 0
        ? 99.0
        : baseline.scopeHours / capacityPerPeriod;
    if (needed > committed + 0.5) {
      score -= 12;
      gaps.add(
          'El alcance comprometido requeria cerca de '
          '${needed.toStringAsFixed(1)} periodos con el equipo declarado: la '
          'aritmetica ya no cerraba antes de empezar.');
    } else {
      score += 6;
      strengths.add(
          'El alcance comprometido era compatible con la capacidad del equipo '
          'que declaraste.');
    }

    // Gestion formal de cambios.
    final int silent = state.changes
        .where((ChangeRequest ch) =>
            ch.decision == ChangeDecision.acceptedWithoutBaseline)
        .length;
    final int formal = state.changes
        .where((ChangeRequest ch) =>
            ch.decision == ChangeDecision.acceptedWithBaseline ||
            ch.decision == ChangeDecision.tradedOff)
        .length;
    if (silent > 0) {
      score -= 8.0 * silent;
      gaps.add(
          'Aceptaste $silent cambio(s) sin ajustar la linea base: el trabajo '
          'crecio y la promesa no, que es la definicion operativa del '
          'deslizamiento de alcance.');
    }
    if (formal > 0) {
      score += 8.0 * formal;
      strengths.add(
          'Procesaste $formal cambio(s) de manera formal, ajustando la linea '
          'base o compensando alcance.');
    }

    return CompetencyScore(
      competency: PmCompetency.planning,
      score: score.clamp(0.0, 100.0).toDouble(),
      strengths: strengths,
      gaps: gaps,
    );
  }

  // ------------------------------------------------------------------
  // Recursos
  // ------------------------------------------------------------------

  CompetencyScore _resources(
    ProjectState state,
    double utilization,
    double wasted,
  ) {
    final List<String> strengths = <String>[];
    final List<String> gaps = <String>[];

    double score = (utilization * 105).clamp(0.0, 100.0).toDouble();

    if (utilization >= 0.97) {
      strengths.add(
          'Utilizacion de ${formatPercent(utilization)}: casi toda la '
          'capacidad que pagaste produjo avance.');
    } else if (wasted > 1) {
      gaps.add(
          'Se perdieron ${formatHours(wasted)} por asignaciones invalidas o '
          'fases bloqueadas. Esa capacidad se pago igual.');
    }

    final double efficiency = config.teamEfficiency(state.team.length);
    if (state.team.length >= 8 && efficiency < 0.72) {
      score -= 10;
      gaps.add(
          'Con ${state.team.length} personas, la coordinacion se llevo '
          '${formatPercent(1 - efficiency)} de la capacidad nominal.');
    } else if (state.team.length >= 3 && state.team.length <= 6) {
      score += 5;
      strengths.add(
          'Mantuviste un equipo de ${state.team.length} personas, un tamanio '
          'donde la comunicacion todavia no se come el trabajo.');
    }

    final int lateHires = state.team
        .where((m) => m.joinedPeriod > config.totalPeriods - 4)
        .length;
    if (lateHires > 0) {
      score -= 8.0 * lateHires;
      gaps.add(
          'Incorporaste $lateHires persona(s) en el tramo final: llegaron en '
          'curva de aprendizaje y restaron mas de lo que sumaron.');
    }

    if (state.overtimePeriods > 4) {
      score -= 10;
      gaps.add(
          'Autorizaste horas extra en ${state.overtimePeriods} periodos. El '
          'sobreesfuerzo sostenido acumula fatiga y encarece cada hora un '
          '60%.');
    } else if (state.overtimePeriods > 0 && state.overtimePeriods <= 2) {
      score += 4;
      strengths.add(
          'Usaste horas extra de forma puntual (${state.overtimePeriods} '
          'periodo(s)), que es para lo que sirven.');
    }

    return CompetencyScore(
      competency: PmCompetency.resources,
      score: score.clamp(0.0, 100.0).toDouble(),
      strengths: strengths,
      gaps: gaps,
    );
  }

  // ------------------------------------------------------------------
  // Riesgos
  // ------------------------------------------------------------------

  CompetencyScore _risk(ProjectState state) {
    final List<String> strengths = <String>[];
    final List<String> gaps = <String>[];
    double score = 45;

    final int total = state.risks.length;
    final int identified = state.identifiedRisks.length;
    final double coverage = total <= 0 ? 0.0 : identified / total;
    score += coverage * 25;

    if (state.riskWorkshops > 0) {
      strengths.add(
          'Realizaste ${state.riskWorkshops} analisis de riesgos y ampliaste '
          'el registro mas alla de lo obvio ($identified de $total).');
    } else {
      score -= 12;
      gaps.add(
          'Nunca ampliaste el registro de riesgos: trabajaste toda la partida '
          'con los pocos que el acta hizo evidentes.');
    }

    final List<RiskItem> occurred =
        state.risks.where((RiskItem r) => r.occurred).toList();
    final int blindHits =
        occurred.where((RiskItem r) => !r.identified).length;
    if (blindHits > 0) {
      score -= 10.0 * blindHits;
      gaps.add(
          '$blindHits riesgo(s) golpearon sin estar en tu registro, con '
          'impacto agravado por la falta de respuesta preparada.');
    }

    final int treated = state.identifiedRisks
        .where((RiskItem r) => r.response != RiskResponse.none)
        .length;
    if (identified > 0) {
      final double treatRate = treated / identified;
      score += treatRate * 20;
      if (treatRate >= 0.7) {
        strengths.add(
            'Decidiste una respuesta explicita para ${formatPercent(treatRate)} '
            'de los riesgos identificados.');
      } else {
        gaps.add(
            'Solo ${formatPercent(treatRate)} de los riesgos identificados '
            'recibieron respuesta. Identificar sin decidir no reduce la '
            'exposicion.');
      }
    }

    final int mitigatedAndAvoided = occurred
        .where((RiskItem r) =>
            r.response == RiskResponse.mitigate ||
            r.response == RiskResponse.transfer)
        .length;
    if (mitigatedAndAvoided > 0) {
      score += 6;
      strengths.add(
          'Cuando ocurrieron riesgos que habias tratado, el impacto llego '
          'amortiguado: para eso servia el tratamiento.');
    }

    return CompetencyScore(
      competency: PmCompetency.risk,
      score: score.clamp(0.0, 100.0).toDouble(),
      strengths: strengths,
      gaps: gaps,
    );
  }

  // ------------------------------------------------------------------
  // Tiempo
  // ------------------------------------------------------------------

  CompetencyScore _time(
    ProjectState state,
    EvmSnapshot? last,
    int periodsUsed,
    int committed,
  ) {
    final List<String> strengths = <String>[];
    final List<String> gaps = <String>[];
    double score = 45;

    final double spi = last?.spi ?? 0;
    score += (spi.clamp(0.0, 1.2) * 40);

    switch (state.outcome) {
      case ProjectOutcome.delivered:
        score += 15;
        strengths.add(
            'Entregaste el alcance comprometido dentro del plazo: SPI final '
            '${formatIndex(spi)}.');
        break;
      case ProjectOutcome.deliveredLate:
        gaps.add(
            'Entregaste, pero ${formatPeriods(
                (periodsUsed - committed).toDouble())} despues de lo '
            'comprometido.');
        break;
      case ProjectOutcome.abandoned:
        score -= 18;
        gaps.add(
            'El calendario se agoto con el proyecto inconcluso: en la '
            'practica, el alcance no entregado equivale a inversion perdida.');
        break;
      case ProjectOutcome.cancelled:
        score -= 25;
        gaps.add(
            'El proyecto se cancelo antes de terminar. La gestion del tiempo '
            'dejo de ser el problema principal mucho antes del cierre.');
        break;
      case ProjectOutcome.running:
        break;
    }

    // Reaccion temprana: se mide si el SPI mejoro despues de caer.
    final List<EvmSnapshot> snaps = state.snapshots;
    if (snaps.length >= 4) {
      double worst = 2;
      int worstIndex = 0;
      for (int i = 1; i < snaps.length; i++) {
        if (snaps[i].spi < worst) {
          worst = snaps[i].spi;
          worstIndex = i;
        }
      }
      if (worst < 0.92 && worstIndex < snaps.length - 1) {
        final double recovered = snaps.last.spi - worst;
        if (recovered > 0.06) {
          score += 8;
          strengths.add(
              'El SPI cayo a ${formatIndex(worst)} y lo recuperaste hasta '
              '${formatIndex(snaps.last.spi)}: leiste el indicador y '
              'corregiste a tiempo.');
        } else {
          gaps.add(
              'El SPI cayo a ${formatIndex(worst)} y nunca se recupero. Los '
              'indices avisan con periodos de anticipacion; sirven solo si se '
              'actua sobre ellos.');
        }
      }
    }

    return CompetencyScore(
      competency: PmCompetency.time,
      score: score.clamp(0.0, 100.0).toDouble(),
      strengths: strengths,
      gaps: gaps,
    );
  }

  // ------------------------------------------------------------------
  // Brechas de estimacion
  // ------------------------------------------------------------------

  List<EstimateGap> _gaps(ProjectState state) {
    final List<EstimateGap> out = <EstimateGap>[];
    for (final WorkPackage p in state.includedPackages) {
      out.add(EstimateGap(
        packageName: p.name,
        estimatedHours: p.estimatedHours,
        realHours: p.realHours,
        completed: p.isDone,
      ));
    }
    out.sort((EstimateGap a, EstimateGap b) =>
        b.deviation.compareTo(a.deviation));
    return out;
  }

  // ------------------------------------------------------------------
  // Textos
  // ------------------------------------------------------------------

  String _headline(ProjectState state, int periodsUsed, int committed) {
    switch (state.outcome) {
      case ProjectOutcome.delivered:
        return 'Proyecto entregado en $periodsUsed periodos, dentro del plazo '
            'comprometido.';
      case ProjectOutcome.deliveredLate:
        return 'Proyecto entregado en $periodsUsed periodos, '
            '${formatPeriods((periodsUsed - committed).toDouble())} sobre lo '
            'comprometido.';
      case ProjectOutcome.cancelled:
        return 'Proyecto cancelado en el periodo $periodsUsed.';
      case ProjectOutcome.abandoned:
        return 'El calendario se agoto con el proyecto inconcluso.';
      case ProjectOutcome.running:
        return 'Proyecto en curso.';
    }
  }

  String _verdict(ProjectState state, List<CompetencyScore> scores) {
    double sum = 0;
    for (final CompetencyScore s in scores) {
      sum += s.score;
    }
    final double avg = scores.isEmpty ? 0.0 : sum / scores.length;
    if (state.outcome == ProjectOutcome.cancelled) {
      return 'Direccion no sostenible: el proyecto perdio el respaldo antes '
          'de poder demostrar resultados.';
    }
    if (avg >= 85) {
      return 'Direccion solida: comprometiste algo alcanzable y lo sostuviste '
          'con instrumentos, no con suerte.';
    }
    if (avg >= 70) {
      return 'Direccion competente con margen de mejora: las decisiones '
          'gruesas fueron correctas y las finas costaron dinero.';
    }
    if (avg >= 55) {
      return 'Direccion en desarrollo: sabes que instrumentos existen, todavia '
          'no los usas para decidir a tiempo.';
    }
    return 'Direccion inicial: las decisiones se tomaron reaccionando a los '
        'hechos en lugar de anticiparlos.';
  }

  String _narrative(
    ProjectState state,
    ProjectCase c,
    Baseline? baseline,
    int periodsUsed,
    int committed,
    EvmSnapshot? last,
  ) {
    final StringBuffer b = StringBuffer();
    b.write('Dirigiste "${c.name}" con enfoque '
        '${state.methodology.shortLabel} y prioridad de restriccion '
        '"${state.priority.label}". ');

    if (baseline != null) {
      b.write('Comprometiste $committed periodos y '
          '${formatMoney(baseline.budgetAtCompletion)} incluyendo reserva. ');
    }

    b.write('Cerraste con un costo real de '
        '${formatMoney(state.actualCost)} sobre un techo de '
        '${formatMoney(c.budgetCeiling)}');
    if (last != null) {
      b.write(', con CPI ${formatIndex(last.cpi)} y SPI '
          '${formatIndex(last.spi)}');
    }
    b.write('. ');

    final int blind = state.risks
        .where((RiskItem r) => r.occurred && !r.identified)
        .length;
    if (blind > 0) {
      b.write('$blind riesgo(s) te golpearon sin estar en el registro; en un '
          'proyecto real esa es la diferencia entre un contratiempo y una '
          'crisis. ');
    }

    if (state.escapedDefects > 0.5) {
      b.write('Quedaron ${state.escapedDefects.toStringAsFixed(1)} defectos '
          'sin detectar, que el cliente encontrara en operacion. ');
    }

    if (c.regulated && state.methodology.complianceLevel < 0.80) {
      b.write('El cierre quedo observado por documentacion insuficiente: en '
          'un entorno regulado, la trazabilidad es parte del entregable. ');
    }

    b.write('La satisfaccion del patrocinador termino en '
        '${state.sponsorSatisfaction.toStringAsFixed(0)}/100.');
    return b.toString();
  }

  List<String> _nextSteps(List<CompetencyScore> scores) {
    final List<CompetencyScore> sorted = List<CompetencyScore>.from(scores)
      ..sort((CompetencyScore a, CompetencyScore b) =>
          a.score.compareTo(b.score));
    final List<String> out = <String>[];
    for (final CompetencyScore s in sorted.take(2)) {
      switch (s.competency) {
        case PmCompetency.planning:
          out.add(
              'Repite el caso comprometiendo la linea base solo despues de '
              'dividir el alcance entre la capacidad real del equipo, y '
              'declara la reserva a partir de la exposicion, no del instinto.');
          break;
        case PmCompetency.resources:
          out.add(
              'Antes de cerrar cada periodo, verifica que las cuatro '
              'preguntas tengan respuesta: quien trabaja, en que paquete, si '
              'la fase esta habilitada y si esa fase es la que manda.');
          break;
        case PmCompetency.risk:
          out.add(
              'Haz el analisis de riesgos en los primeros dos periodos y '
              'ordena el registro por exposicion, no por miedo. Trata los dos '
              'primeros y acepta el resto conscientemente.');
          break;
        case PmCompetency.time:
          out.add(
              'Revisa el SPI cada periodo y fija una regla previa: si baja de '
              '0.95 dos veces seguidas, actuas. Decidir el umbral antes de la '
              'crisis es lo que separa dirigir de apagar incendios.');
          break;
      }
    }
    out.add(
        'Vuelve a jugar el mismo caso con la misma semilla y otra metodologia: '
        'la comparacion directa ensena mas que cualquier definicion.');
    return out;
  }
}
