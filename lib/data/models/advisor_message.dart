/// Área de la dirección de proyectos a la que apunta el asistente.
enum AdvisorArea {
  scope,
  schedule,
  cost,
  resources,
  risk,
  quality,
  stakeholder;

  String get label {
    switch (this) {
      case AdvisorArea.scope:
        return 'Alcance';
      case AdvisorArea.schedule:
        return 'Cronograma';
      case AdvisorArea.cost:
        return 'Costo';
      case AdvisorArea.resources:
        return 'Recursos';
      case AdvisorArea.risk:
        return 'Riesgos';
      case AdvisorArea.quality:
        return 'Calidad';
      case AdvisorArea.stakeholder:
        return 'Interesados';
    }
  }
}

/// Urgencia del mensaje.
enum AdvisorSeverity {
  critical,
  warning,
  insight,
  positive;

  String get label {
    switch (this) {
      case AdvisorSeverity.critical:
        return 'Crítico';
      case AdvisorSeverity.warning:
        return 'Atención';
      case AdvisorSeverity.insight:
        return 'Análisis';
      case AdvisorSeverity.positive:
        return 'Bien dirigido';
    }
  }

  int get order {
    switch (this) {
      case AdvisorSeverity.critical:
        return 0;
      case AdvisorSeverity.warning:
        return 1;
      case AdvisorSeverity.insight:
        return 2;
      case AdvisorSeverity.positive:
        return 3;
    }
  }
}

/// Mensaje del asistente de dirección de proyectos.
class AdvisorMessage {
  const AdvisorMessage({
    required this.ruleId,
    required this.area,
    required this.severity,
    required this.title,
    required this.diagnosis,
    required this.recommendation,
    this.evidence = '',
  });

  final String ruleId;
  final AdvisorArea area;
  final AdvisorSeverity severity;
  final String title;
  final String diagnosis;
  final String recommendation;
  final String evidence;
}
