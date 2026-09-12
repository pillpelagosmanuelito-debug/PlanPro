import 'dart:math' as math;

import '../../core/formatters.dart';
import '../models/advisor_message.dart';
import '../models/baseline.dart';
import '../models/change_request.dart';
import '../models/evm_snapshot.dart';
import '../models/methodology.dart';
import '../models/period_result.dart';
import '../models/project_case.dart';
import '../models/project_config.dart';
import '../models/project_state.dart';
import '../models/risk_item.dart';
import '../models/team_member.dart';
import '../models/work_package.dart';
import 'evm_calculator.dart';

/// Asistente de dirección de proyectos.
///
/// Es un sistema experto basado en reglas, no un modelo generativo. La
/// decisión es deliberada y tiene tres razones pedagógicas:
///
/// 1. **Auditabilidad.** Cada consejo se puede rastrear hasta una regla con
///    nombre, umbral y fundamento. Un estudiante puede discutir la regla; no
///    puede discutir una caja negra.
/// 2. **Honestidad epistémica.** El asistente lee exactamente lo que lee el
///    estudiante: estimaciones, avance reportado e indicadores. Nunca consulta
///    la duración real oculta ni los riesgos que el estudiante no identificó.
///    Si el asistente supiera el futuro, el simulador dejaría de enseñar a
///    decidir con información incompleta, que es justamente la competencia.
/// 3. **Disponibilidad.** Funciona sin conexión, sin costo por consulta y con
///    latencia cero, condiciones necesarias para un aula peruana promedio.
class PmAdvisor {
  const PmAdvisor({
    this.config = const ProjectConfig(),
    this.evm = const EvmCalculator(),
  });

  final ProjectConfig config;
  final EvmCalculator evm;

  /// Consejos para la etapa de planificación, antes de comprometer la línea
  /// base. Aquí es donde un proyecto se gana o se pierde.
  List<AdvisorMessage> planningAdvice({
    required ProjectState state,
    required int committedPeriods,
    required double contingencyRate,
  }) {
    final List<AdvisorMessage> out = <AdvisorMessage>[];
    final ProjectCase c = state.projectCase;
    final double scope = state.scopeEstimatedHours;
    final double capacity = state.effectiveCapacity(config);

    if (state.team.isEmpty) {
      out.add(const AdvisorMessage(
        ruleId: 'plan_no_team',
        area: AdvisorArea.resources,
        severity: AdvisorSeverity.critical,
        title: 'Todavía no tienes equipo',
        diagnosis:
            'Sin integrantes no hay capacidad y el proyecto no avanzará ni '
            'una hora, por buena que sea la planificación.',
        recommendation:
            'Arma el equipo antes de comprometer la línea base: es la decisión '
            'que determina cuánto trabajo cabe en cada periodo.',
      ));
      return out;
    }

    final double periodsNeeded = capacity <= 0 ? 99.0 : scope / capacity;
    if (periodsNeeded > committedPeriods + 0.4) {
      out.add(AdvisorMessage(
        ruleId: 'plan_overcommit',
        area: AdvisorArea.schedule,
        severity: AdvisorSeverity.critical,
        title: 'El plazo que quieres comprometer no cabe',
        diagnosis:
            'Con ${formatHours(scope)} de alcance y ${formatHours(capacity)} '
            'de capacidad por periodo, el trabajo tomaría '
            '${periodsNeeded.toStringAsFixed(1)} periodos aún sin ningún '
            'contratiempo. Y las estimaciones del equipo son optimistas.',
        recommendation:
            'Antes de firmar: agranda el equipo, saca alcance opcional o '
            'comprométete a un plazo mayor. Prometer una fecha imposible no '
            'la vuelve posible.',
        evidence:
            'Necesario ${periodsNeeded.toStringAsFixed(1)} periodos vs '
            '$committedPeriods comprometidos.',
      ));
    } else if (periodsNeeded < committedPeriods - 3) {
      out.add(AdvisorMessage(
        ruleId: 'plan_slack',
        area: AdvisorArea.cost,
        severity: AdvisorSeverity.insight,
        title: 'Holgura amplia, presupuesto caro',
        diagnosis:
            'El alcance cabría en ${periodsNeeded.toStringAsFixed(1)} '
            'periodos, bastante menos que los $committedPeriods que piensas '
            'comprometer. Cada periodo comprometido cuesta planilla.',
        recommendation:
            'Un plazo holgado protege, pero pagas equipo todo ese tiempo. '
            'Evalúa si conviene un equipo menor o un compromiso más corto.',
      ));
    }

    if (contingencyRate < 0.05) {
      out.add(const AdvisorMessage(
        ruleId: 'plan_no_reserve',
        area: AdvisorArea.risk,
        severity: AdvisorSeverity.warning,
        title: 'Línea base sin reserva de contingencia',
        diagnosis:
            'Estás comprometiendo el presupuesto exacto del plan. Cuando '
            'ocurra el primer riesgo (y ocurrirá), cada sol adicional será '
            'un sobrecosto frente a la línea base.',
        recommendation:
            'Reserva entre 8% y 15% para los riesgos identificados. La '
            'reserva no es desconfianza: es el precio de la incertidumbre.',
      ));
    }

    final double exposure = state.riskExposure(state.hourValue(config));
    final double reserve = capacity <= 0
        ? 0.0
        : state.teamCostPerPeriod() * committedPeriods * contingencyRate;
    if (exposure > reserve * 1.6 && exposure > 0) {
      out.add(AdvisorMessage(
        ruleId: 'plan_reserve_gap',
        area: AdvisorArea.risk,
        severity: AdvisorSeverity.warning,
        title: 'La reserva no cubre la exposición conocida',
        diagnosis:
            'Solo con los riesgos que ya identificaste, la exposición '
            'esperada es ${formatMoney(exposure)} y la reserva propuesta es '
            '${formatMoney(reserve)}.',
        recommendation:
            'Sube la reserva o trata los riesgos de mayor exposición antes de '
            'comprometerte. Y recuerda que aún hay riesgos sin identificar.',
      ));
    }

    out.addAll(_methodologyFit(state, c));

    final int juniors = state.team
        .where((TeamMember m) => m.roleId == 'junior')
        .length;
    if (juniors >= 3) {
      out.add(AdvisorMessage(
        ruleId: 'plan_junior_heavy',
        area: AdvisorArea.resources,
        severity: AdvisorSeverity.insight,
        title: 'Equipo barato, curva de aprendizaje larga',
        diagnosis:
            'Tienes $juniors juniors. Cuestan poco por periodo, pero '
            'necesitan tres periodos para rendir de verdad y mientras tanto '
            'consumen tiempo de los demás.',
        recommendation:
            'En proyectos cortos la mano de obra barata sale cara. Mezcla '
            'perfiles: alguien con criterio técnico acelera a todo el equipo.',
      ));
    }

    return out;
  }

  /// Consejos durante la ejecución.
  List<AdvisorMessage> execute({
    required ProjectState state,
    PeriodResult? last,
  }) {
    final List<AdvisorMessage> out = <AdvisorMessage>[];
    final ProjectCase c = state.projectCase;
    final Baseline? baseline = state.baseline;
    final EvmSnapshot? snap =
        state.snapshots.isEmpty ? null : state.snapshots.last;

    out.addAll(_scheduleRules(state, snap, baseline));
    out.addAll(_costRules(state, snap, c));
    out.addAll(_resourceRules(state, last));
    out.addAll(_riskRules(state, baseline));
    out.addAll(_qualityRules(state, last, snap));
    out.addAll(_stakeholderRules(state));
    out.addAll(_scopeRules(state, snap));
    if (state.period <= 3) out.addAll(_methodologyFit(state, c));

    if (out.isEmpty || out.every((AdvisorMessage m) =>
        m.severity == AdvisorSeverity.insight)) {
      if (snap != null && snap.spi >= 0.98 && snap.cpi >= 0.98) {
        out.add(AdvisorMessage(
          ruleId: 'all_good',
          area: AdvisorArea.schedule,
          severity: AdvisorSeverity.positive,
          title: 'El proyecto está bajo control',
          diagnosis:
              'SPI ${formatIndex(snap.spi)} y CPI ${formatIndex(snap.cpi)}: '
              'avanzas al ritmo comprometido y dentro del costo previsto.',
          recommendation:
              'Este es el momento de mirar hacia adelante, no de relajarse: '
              'revisa los riesgos de los próximos periodos mientras tienes '
              'margen para actuar.',
        ));
      }
    }

    out.sort((AdvisorMessage a, AdvisorMessage b) =>
        a.severity.order.compareTo(b.severity.order));
    return out;
  }

  // ------------------------------------------------------------------
  // Cronograma
  // ------------------------------------------------------------------

  List<AdvisorMessage> _scheduleRules(
    ProjectState state,
    EvmSnapshot? snap,
    Baseline? baseline,
  ) {
    final List<AdvisorMessage> out = <AdvisorMessage>[];
    if (snap == null || baseline == null) return out;

    if (snap.spi < 0.90) {
      out.add(AdvisorMessage(
        ruleId: 'spi_critical',
        area: AdvisorArea.schedule,
        severity: AdvisorSeverity.critical,
        title: 'Atraso significativo frente a la línea base',
        diagnosis:
            'El SPI es ${formatIndex(snap.spi)}: has ganado '
            '${formatMoney(snap.earnedValue)} de valor cuando el plan pedía '
            '${formatMoney(snap.plannedValue)}. El atraso no se recupera '
            'solo.',
        recommendation:
            'Elige una palanca y úsala ahora: horas extra por pocos periodos, '
            'sacar alcance opcional, o renegociar la fecha con el '
            'patrocinador. Esperar un periodo más encarece las tres.',
        evidence: 'SV ${formatMoney(snap.scheduleVariance)}',
      ));
    } else if (snap.spi < 0.97) {
      out.add(AdvisorMessage(
        ruleId: 'spi_warning',
        area: AdvisorArea.schedule,
        severity: AdvisorSeverity.warning,
        title: 'Atraso incipiente',
        diagnosis:
            'SPI ${formatIndex(snap.spi)}. Todavía es un desvío pequeño, '
            'del tamaño que se corrige sin drama si actúas este periodo.',
        recommendation:
            'Concentra la capacidad en la fase que marca el ritmo antes de '
            'que el desvío se acumule.',
      ));
    }

    final double finish =
        evm.estimatedFinishPeriod(state: state, currentPeriod: state.period);
    if (finish.isFinite && finish > baseline.committedPeriods + 0.5) {
      out.add(AdvisorMessage(
        ruleId: 'forecast_late',
        area: AdvisorArea.schedule,
        severity: AdvisorSeverity.warning,
        title: 'La proyección supera la fecha comprometida',
        diagnosis:
            'Al ritmo observado, el proyecto terminaría alrededor del periodo '
            '${finish.toStringAsFixed(1)}, contra el periodo '
            '${baseline.committedPeriods} comprometido.',
        recommendation:
            'Una proyección no es una profecía: es el resultado de seguir '
            'igual. Cambia algo (capacidad, alcance o método) o avisa la '
            'nueva fecha con tiempo.',
      ));
    }

    final ProjectPhase critical = evm.criticalPhase(state);
    if (state.phaseUnlocked(critical) && state.phaseProgress(critical) < 0.95) {
      final List<TeamMember> elsewhere = state.team.where((TeamMember m) {
        final WorkPackage? p = state.packageById(m.assignedPackageId);
        return p != null && p.phase != critical;
      }).toList();
      if (elsewhere.length >= math.max(2, state.team.length ~/ 2)) {
        out.add(AdvisorMessage(
          ruleId: 'critical_path',
          area: AdvisorArea.schedule,
          severity: AdvisorSeverity.insight,
          title: 'El cuello de botella está en ${critical.label}',
          diagnosis:
              '${critical.label} concentra el trabajo pendiente y define '
              'cuando termina el proyecto, pero ${elsewhere.length} de '
              '${state.team.length} personas están asignadas a otras fases.',
          recommendation:
              'Avanzar donde hay holgura no adelanta la fecha final. Mueve '
              'capacidad al cuello de botella aunque parezca desordenado.',
        ));
      }
    }

    return out;
  }

  // ------------------------------------------------------------------
  // Costo
  // ------------------------------------------------------------------

  List<AdvisorMessage> _costRules(
    ProjectState state,
    EvmSnapshot? snap,
    ProjectCase c,
  ) {
    final List<AdvisorMessage> out = <AdvisorMessage>[];
    if (snap == null) return out;

    if (snap.cpi < 0.90) {
      out.add(AdvisorMessage(
        ruleId: 'cpi_critical',
        area: AdvisorArea.cost,
        severity: AdvisorSeverity.critical,
        title: 'Cada sol gastado rinde menos de lo planificado',
        diagnosis:
            'CPI ${formatIndex(snap.cpi)}: por cada sol invertido obtienes '
            '${formatIndex(snap.cpi)} soles de valor. Proyectado a la '
            'conclusión, el proyecto costaría '
            '${formatMoney(snap.estimateAtCompletion)}.',
        recommendation:
            'Revisa dónde se va la capacidad: horas perdidas por asignaciones '
            'inválidas, gente en curva de aprendizaje u horas extra caras. '
            'El sobrecosto rara vez viene del precio; viene del desperdicio.',
        evidence: 'EAC ${formatMoney(snap.estimateAtCompletion)}',
      ));
    }

    if (snap.estimateAtCompletion > c.budgetCeiling) {
      out.add(AdvisorMessage(
        ruleId: 'eac_over_ceiling',
        area: AdvisorArea.cost,
        severity: AdvisorSeverity.critical,
        title: 'La proyección excede el techo del patrocinador',
        diagnosis:
            'La estimación a la conclusión es '
            '${formatMoney(snap.estimateAtCompletion)} y el techo autorizado '
            'es ${formatMoney(c.budgetCeiling)}.',
        recommendation:
            'Un proyecto que supera el techo se cancela, no se perdona. '
            'Recorta alcance opcional o reduce equipo antes de que la '
            'diferencia sea imposible de explicar.',
      ));
    }

    final double tcpi = snap.tcpi;
    if (tcpi.isFinite && tcpi > 1.10 && snap.cpi < 1.0) {
      out.add(AdvisorMessage(
        ruleId: 'tcpi_unrealistic',
        area: AdvisorArea.cost,
        severity: AdvisorSeverity.warning,
        title: 'Terminar dentro del presupuesto exige un desempeño irreal',
        diagnosis:
            'El TCPI es ${formatIndex(tcpi)}: para cerrar dentro de la línea '
            'base tendrías que rendir un ${((tcpi / math.max(snap.cpi, 0.01) - 1) * 100).toStringAsFixed(0)}% '
            'mejor de lo que has rendido hasta hoy.',
        recommendation:
            'Nadie mejora así de golpe sin cambiar algo. Ajusta la línea base '
            'formalmente o reduce el trabajo pendiente.',
      ));
    }

    return out;
  }

  // ------------------------------------------------------------------
  // Recursos
  // ------------------------------------------------------------------

  List<AdvisorMessage> _resourceRules(ProjectState state, PeriodResult? last) {
    final List<AdvisorMessage> out = <AdvisorMessage>[];

    final List<TeamMember> unassigned = state.team.where((TeamMember m) {
      final WorkPackage? p = state.packageById(m.assignedPackageId);
      if (p == null) return true;
      if (!p.included || p.isDone) return true;
      return !state.phaseUnlocked(p.phase);
    }).toList();

    if (unassigned.isNotEmpty) {
      out.add(AdvisorMessage(
        ruleId: 'unassigned',
        area: AdvisorArea.resources,
        severity: AdvisorSeverity.critical,
        title: '${unassigned.length} persona(s) sin trabajo valido',
        diagnosis:
            'Tienen asignación vacía, un paquete ya terminado o una fase '
            'todavía bloqueada. Su capacidad se pierde completa y su costo se '
            'paga igual.',
        recommendation:
            'Reasígnalas a un paquete habilitado antes de cerrar el periodo. '
            'Pagar capacidad ociosa es la forma más silenciosa de perder un '
            'presupuesto.',
        evidence: unassigned.map((TeamMember m) => m.name).join(', '),
      ));
    }

    if (last != null && last.capacity > 0 && last.utilization < 0.90) {
      out.add(AdvisorMessage(
        ruleId: 'wasted_capacity',
        area: AdvisorArea.resources,
        severity: AdvisorSeverity.warning,
        title: 'Se perdieron ${formatHours(last.wastedHours)} el periodo pasado',
        diagnosis:
            'La utilización fue ${formatPercent(last.utilization)}. Esas '
            'horas se pagaron y no produjeron avance.',
        recommendation:
            'Revisa las asignaciones al inicio de cada periodo, no al final. '
            'Es el control más barato que existe.',
      ));
    }

    final double efficiency = config.teamEfficiency(state.team.length);
    if (state.team.length >= 7 && efficiency < 0.75) {
      out.add(AdvisorMessage(
        ruleId: 'team_too_large',
        area: AdvisorArea.resources,
        severity: AdvisorSeverity.insight,
        title: 'El equipo perdió ${formatPercent(1 - efficiency)} por coordinación',
        diagnosis:
            'Con ${state.team.length} personas, la carga de comunicación se '
            'come una parte importante de la capacidad nominal. Los canales '
            'de comunicación crecen mucho más rápido que el equipo.',
        recommendation:
            'Antes de contratar otra persona, comprueba que la anterior ya '
            'está rindiendo. Un equipo grande no es un equipo rápido.',
      ));
    }

    final List<TeamMember> newcomers =
        state.team.where((TeamMember m) => m.isNewcomer).toList();
    if (newcomers.isNotEmpty && state.period >= config.totalPeriods - 4) {
      out.add(AdvisorMessage(
        ruleId: 'brooks_law',
        area: AdvisorArea.resources,
        severity: AdvisorSeverity.warning,
        title: 'Incorporar gente a esta altura atrasa el proyecto',
        diagnosis:
            'Hay ${newcomers.length} integrante(s) en curva de aprendizaje '
            'faltando pocos periodos. Rinden parcialmente y consumen tiempo '
            'de quienes ya producían.',
        recommendation:
            'Agregar personas a un proyecto atrasado lo atrasa más. Si '
            'necesitas velocidad ahora, es más barato recortar alcance.',
      ));
    }

    if (state.fatigue > 0.18) {
      out.add(AdvisorMessage(
        ruleId: 'fatigue',
        area: AdvisorArea.resources,
        severity: AdvisorSeverity.warning,
        title: 'El equipo está desgastado',
        diagnosis:
            'La fatiga acumulada por horas extra ya resta '
            '${formatPercent(state.fatigue)} de capacidad, y no se recupera '
            'en un periodo.',
        recommendation:
            'Las horas extra son un préstamo con interés: sirven para un '
            'empujón corto, no como régimen. Dale al equipo un periodo '
            'normal.',
      ));
    }

    return out;
  }

  // ------------------------------------------------------------------
  // Riesgos
  // ------------------------------------------------------------------

  List<AdvisorMessage> _riskRules(ProjectState state, Baseline? baseline) {
    final List<AdvisorMessage> out = <AdvisorMessage>[];
    final double hourValue = state.hourValue(config);

    final List<RiskItem> untreated = state.identifiedRisks
        .where((RiskItem r) =>
            !r.occurred &&
            r.response == RiskResponse.none &&
            r.window.any((int p) => p >= state.period))
        .toList();
    if (untreated.isNotEmpty) {
      untreated.sort((RiskItem a, RiskItem b) =>
          b.exposure(hourValue).compareTo(a.exposure(hourValue)));
      final RiskItem top = untreated.first;
      out.add(AdvisorMessage(
        ruleId: 'risk_untreated',
        area: AdvisorArea.risk,
        severity: AdvisorSeverity.warning,
        title: '${untreated.length} riesgo(s) identificado(s) sin respuesta',
        diagnosis:
            'El de mayor exposición es "${top.name}", con '
            '${formatMoney(top.exposure(hourValue))} esperados. Identificar '
            'un riesgo y no decidir qué hacer con él no cambia nada.',
        recommendation:
            'Elige una respuesta explícita: mitigar, transferir, evitar o '
            'aceptar con reserva. Aceptar es válido; ignorar no lo es.',
        evidence: 'Señal temprana: ${top.trigger}',
      ));
    }

    if (state.riskWorkshops == 0 && state.period >= 3) {
      out.add(const AdvisorMessage(
        ruleId: 'risk_no_workshop',
        area: AdvisorArea.risk,
        severity: AdvisorSeverity.warning,
        title: 'Nunca hiciste un análisis de riesgos',
        diagnosis:
            'Tu registro solo contiene los riesgos que el acta hizo evidentes. '
            'Los que no están en el registro no dejan de existir: ocurren sin '
            'aviso y con peor impacto porque nadie preparó la respuesta.',
        recommendation:
            'Un taller de identificación cuesta horas y dinero, y es de las '
            'inversiones más rentables del proyecto.',
      ));
    }

    final double exposure = state.riskExposure(hourValue);
    final double reserveLeft =
        (baseline?.contingencyReserve ?? 0) - state.reserveUsed;
    if (exposure > 0 && reserveLeft >= 0 && exposure > reserveLeft * 1.5) {
      out.add(AdvisorMessage(
        ruleId: 'risk_reserve_gap',
        area: AdvisorArea.risk,
        severity: AdvisorSeverity.critical,
        title: 'La reserva ya no cubre la exposición',
        diagnosis:
            'Exposición conocida ${formatMoney(exposure)} contra '
            '${formatMoney(reserveLeft)} de reserva disponible.',
        recommendation:
            'Trata los riesgos de mayor exposición o pide ampliación de '
            'reserva ahora, mientras la conversación sigue siendo preventiva.',
      ));
    }

    return out;
  }

  // ------------------------------------------------------------------
  // Calidad
  // ------------------------------------------------------------------

  List<AdvisorMessage> _qualityRules(
    ProjectState state,
    PeriodResult? last,
    EvmSnapshot? snap,
  ) {
    final List<AdvisorMessage> out = <AdvisorMessage>[];

    if (state.qaLevel < 0.35) {
      out.add(AdvisorMessage(
        ruleId: 'qa_low',
        area: AdvisorArea.quality,
        severity: AdvisorSeverity.warning,
        title: 'Aseguramiento de calidad en ${formatPercent(state.qaLevel)}',
        diagnosis:
            'Recortar calidad libera capacidad hoy, pero cada defecto que se '
            'escapa a pruebas cuesta cerca de ocho veces más corregirlo que '
            'haberlo evitado.',
        recommendation:
            'Si necesitas velocidad, es más barato sacar alcance que bajar '
            'calidad: el alcance que sacas no vuelve a cobrarse.',
      ));
    }

    if (state.qaLevel > 0.80 && snap != null && snap.spi < 0.95) {
      out.add(AdvisorMessage(
        ruleId: 'qa_excess',
        area: AdvisorArea.quality,
        severity: AdvisorSeverity.insight,
        title: 'Aseguramiento muy alto en un proyecto atrasado',
        diagnosis:
            'Con QA en ${formatPercent(state.qaLevel)} consumes '
            '${formatPercent(state.qaLevel * config.qaCapacityCost)} de la '
            'capacidad del equipo, y el cronograma ya viene apretado.',
        recommendation:
            'La calidad tiene rendimientos decrecientes. Un nivel alto pero '
            'no máximo suele ser el punto donde el retrabajo evitado todavía '
            'paga la capacidad invertida.',
      ));
    }

    if (last != null && last.defectsFound > 0.5) {
      out.add(AdvisorMessage(
        ruleId: 'defects_found',
        area: AdvisorArea.quality,
        severity: AdvisorSeverity.insight,
        title: 'Las pruebas están revelando deuda de calidad',
        diagnosis:
            'Se detectaron ${last.defectsFound.toStringAsFixed(1)} defectos y '
            'entraron ${formatHours(last.reworkHours)} de retrabajo al '
            'paquete de corrección.',
        recommendation:
            'Ese retrabajo no estaba en tu plan pero sí en tu proyecto. '
            'Considera el impacto en la fecha antes de comprometer nada nuevo.',
      ));
    }

    return out;
  }

  // ------------------------------------------------------------------
  // Interesados
  // ------------------------------------------------------------------

  List<AdvisorMessage> _stakeholderRules(ProjectState state) {
    final List<AdvisorMessage> out = <AdvisorMessage>[];

    final List<ChangeRequest> pending = state.pendingChanges;
    if (pending.isNotEmpty) {
      out.add(AdvisorMessage(
        ruleId: 'change_pending',
        area: AdvisorArea.stakeholder,
        severity: AdvisorSeverity.critical,
        title: '${pending.length} solicitud(es) de cambio sin responder',
        diagnosis:
            '"${pending.first.title}" espera decisión desde el periodo '
            '${pending.first.period}. Mientras tanto el equipo trabaja sin '
            'saber si ese alcance entra o no.',
        recommendation:
            'Responde formalmente. No decidir también es una decisión, y es '
            'la única que no puedes defender ante el patrocinador.',
      ));
    }

    final int silentAccepts = state.changes
        .where((ChangeRequest c) =>
            c.decision == ChangeDecision.acceptedWithoutBaseline)
        .length;
    if (silentAccepts > 0) {
      out.add(AdvisorMessage(
        ruleId: 'scope_creep',
        area: AdvisorArea.scope,
        severity: AdvisorSeverity.warning,
        title: 'Alcance ampliado sin mover la línea base',
        diagnosis:
            'Aceptaste $silentAccepts cambio(s) sin ajustar plazo ni '
            'presupuesto. El trabajo entró al proyecto; la promesa quedó '
            'igual. La diferencia aparecerá como atraso tuyo.',
        recommendation:
            'Todavía puedes renegociar la línea base con el sustento del '
            'cambio en la mano. Después solo tendrás excusas.',
      ));
    }

    if (state.sponsorSatisfaction < 40) {
      out.add(AdvisorMessage(
        ruleId: 'sponsor_low',
        area: AdvisorArea.stakeholder,
        severity: AdvisorSeverity.critical,
        title: 'El patrocinador perdió confianza',
        diagnosis:
            'La satisfacción está en '
            '${state.sponsorSatisfaction.toStringAsFixed(0)}/100. Por debajo '
            'de este punto los proyectos se cancelan por razones políticas, '
            'no técnicas.',
        recommendation:
            'Comunica el estado real con datos (SPI, CPI, proyección) y una '
            'propuesta concreta. La confianza se recupera con transparencia '
            'temprana, no con buenas noticias tardías.',
      ));
    }

    return out;
  }

  // ------------------------------------------------------------------
  // Alcance
  // ------------------------------------------------------------------

  List<AdvisorMessage> _scopeRules(ProjectState state, EvmSnapshot? snap) {
    final List<AdvisorMessage> out = <AdvisorMessage>[];
    if (snap == null) return out;

    final List<WorkPackage> optional = state.includedPackages
        .where((WorkPackage p) => p.optional && !p.isDone)
        .toList();
    if (optional.isNotEmpty && snap.spi < 0.93) {
      double hours = 0;
      for (final WorkPackage p in optional) {
        hours += p.estimatedHours * (1 - p.progress);
      }
      out.add(AdvisorMessage(
        ruleId: 'drop_optional',
        area: AdvisorArea.scope,
        severity: AdvisorSeverity.warning,
        title: 'Alcance opcional pendiente en un proyecto atrasado',
        diagnosis:
            '"${optional.first.name}" es alcance deseable, no crítico, y '
            'todavía consume ${formatHours(hours)} del plan.',
        recommendation:
            'Sacarlo del alcance comprometido es la palanca más rápida y más '
            'barata que tienes. Negociala antes de que la fecha se venza.',
      ));
    }

    return out;
  }

  // ------------------------------------------------------------------
  // Metodología
  // ------------------------------------------------------------------

  List<AdvisorMessage> _methodologyFit(ProjectState state, ProjectCase c) {
    final List<AdvisorMessage> out = <AdvisorMessage>[];
    final Methodology m = state.methodology;

    if (m == Methodology.predictive && c.volatileRequirements) {
      out.add(const AdvisorMessage(
        ruleId: 'fit_predictive_volatile',
        area: AdvisorArea.scope,
        severity: AdvisorSeverity.insight,
        title: 'Enfoque predictivo sobre requisitos que aún se discuten',
        diagnosis:
            'El acta advierte que el alcance no está cerrado. Con control de '
            'cambios estricto, cada ajuste obliga a rehacer análisis, diseño '
            'y documentación aprobada: el cambio cuesta más del doble.',
        recommendation:
            'No es un error garrafal, pero exige disciplina: cierra los '
            'requisitos abiertos temprano o preve reserva suficiente para el '
            'retrabajo.',
      ));
    }

    if (m == Methodology.agile && c.regulated) {
      out.add(const AdvisorMessage(
        ruleId: 'fit_agile_regulated',
        area: AdvisorArea.quality,
        severity: AdvisorSeverity.insight,
        title: 'Enfoque ágil en un entorno con exigencia documental',
        diagnosis:
            'El proyecto será revisado por una instancia formal. Un enfoque '
            'ágil absorbe bien los cambios, pero produce menos documentación '
            'y eso se cobra en el cierre.',
        recommendation:
            'Si mantienes el enfoque, agrega deliberadamente la evidencia que '
            'la supervisión pedirá. La agilidad no exime de trazabilidad.',
      ));
    }

    if (m == Methodology.agile && !c.volatileRequirements) {
      out.add(const AdvisorMessage(
        ruleId: 'fit_agile_stable',
        area: AdvisorArea.scope,
        severity: AdvisorSeverity.insight,
        title: 'Agilidad que nadie va a usar',
        diagnosis:
            'El alcance de este caso está definido y aprobado. La flexibilidad '
            'del enfoque ágil se paga en coordinación, y aquí no hay cambios '
            'que absorber.',
        recommendation:
            'La metodología se elige por el problema, no por la moda. Un '
            'alcance estable premia la planificación anticipada.',
      ));
    }

    return out;
  }

  /// Explicación del estado en una línea, para la cabecera del tablero.
  String headline(ProjectState state) {
    if (state.snapshots.isEmpty) {
      return 'Sin periodos ejecutados: los indicadores aparecerán al cerrar '
          'el primero.';
    }
    final EvmSnapshot s = state.snapshots.last;
    return '${s.reading}. SPI ${formatIndex(s.spi)}, CPI '
        '${formatIndex(s.cpi)}, proyección '
        '${formatMoney(s.estimateAtCompletion)}.';
  }
}
