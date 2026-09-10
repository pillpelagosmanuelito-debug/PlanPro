/// Categoria del riesgo, segun las fuentes tipicas de un proyecto.
enum RiskCategory {
  technical,
  external,
  organizational,
  management;

  String get label {
    switch (this) {
      case RiskCategory.technical:
        return 'Tecnico';
      case RiskCategory.external:
        return 'Externo';
      case RiskCategory.organizational:
        return 'Organizacional';
      case RiskCategory.management:
        return 'De direccion';
    }
  }

  static RiskCategory fromName(String? name) => RiskCategory.values.firstWhere(
        (RiskCategory c) => c.name == name,
        orElse: () => RiskCategory.technical,
      );
}

/// Respuesta elegida frente a un riesgo identificado.
enum RiskResponse {
  none,
  mitigate,
  transfer,
  accept,
  avoid;

  String get label {
    switch (this) {
      case RiskResponse.none:
        return 'Sin respuesta';
      case RiskResponse.mitigate:
        return 'Mitigar';
      case RiskResponse.transfer:
        return 'Transferir';
      case RiskResponse.accept:
        return 'Aceptar';
      case RiskResponse.avoid:
        return 'Evitar';
    }
  }

  String get detail {
    switch (this) {
      case RiskResponse.none:
        return 'El riesgo queda sin tratamiento.';
      case RiskResponse.mitigate:
        return 'Reduce la probabilidad de que ocurra, con costo por adelantado.';
      case RiskResponse.transfer:
        return 'Traslada el impacto a un tercero (garantia, seguro, contrato).';
      case RiskResponse.accept:
        return 'Se asume de forma consciente y se cubre con reserva.';
      case RiskResponse.avoid:
        return 'Se elimina la causa cambiando el plan, normalmente cediendo alcance.';
    }
  }

  static RiskResponse fromName(String? name) => RiskResponse.values.firstWhere(
        (RiskResponse r) => r.name == name,
        orElse: () => RiskResponse.none,
      );
}

/// Riesgo del proyecto.
class RiskItem {
  RiskItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.baseProbability,
    required this.impactHours,
    required this.impactCost,
    required this.mitigationCost,
    required this.transferCost,
    required this.trigger,
    required this.window,
    this.identified = false,
    this.response = RiskResponse.none,
    this.occurred = false,
    this.occurredPeriod = 0,
  });

  final String id;
  final String name;
  final String description;
  final RiskCategory category;

  /// Probabilidad base de ocurrir durante la ventana.
  final double baseProbability;

  /// Impacto en horas de trabajo adicional.
  final double impactHours;

  /// Impacto directo en costo (S/).
  final double impactCost;

  final double mitigationCost;
  final double transferCost;

  /// Senial temprana que el equipo podria notar.
  final String trigger;

  /// Periodos en los que puede materializarse.
  final List<int> window;

  /// Si el estudiante lo tiene en el registro de riesgos.
  bool identified;

  RiskResponse response;

  bool occurred;
  int occurredPeriod;

  /// Probabilidad efectiva segun la respuesta elegida.
  double get effectiveProbability {
    switch (response) {
      case RiskResponse.mitigate:
        return baseProbability * 0.40;
      case RiskResponse.avoid:
        return 0.0;
      case RiskResponse.transfer:
      case RiskResponse.accept:
      case RiskResponse.none:
        return baseProbability;
    }
  }

  /// Impacto efectivo en horas segun la respuesta.
  double get effectiveImpactHours {
    switch (response) {
      case RiskResponse.transfer:
        return impactHours * 0.35;
      case RiskResponse.mitigate:
        return impactHours * 0.75;
      case RiskResponse.avoid:
        return 0.0;
      case RiskResponse.accept:
      case RiskResponse.none:
        return impactHours;
    }
  }

  /// Impacto efectivo en costo segun la respuesta.
  double get effectiveImpactCost {
    switch (response) {
      case RiskResponse.transfer:
        return impactCost * 0.25;
      case RiskResponse.mitigate:
        return impactCost * 0.75;
      case RiskResponse.avoid:
        return 0.0;
      case RiskResponse.accept:
      case RiskResponse.none:
        return impactCost;
    }
  }

  /// Costo por adelantado de la respuesta elegida.
  double get responseCost {
    switch (response) {
      case RiskResponse.mitigate:
        return mitigationCost;
      case RiskResponse.transfer:
        return transferCost;
      case RiskResponse.accept:
      case RiskResponse.avoid:
      case RiskResponse.none:
        return 0.0;
    }
  }

  /// Exposicion esperada: probabilidad por impacto monetizado.
  double exposure(double hourValue) =>
      effectiveProbability *
      (effectiveImpactCost + effectiveImpactHours * hourValue);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'identified': identified,
        'response': response.name,
        'occurred': occurred,
        'occurredPeriod': occurredPeriod,
      };

  /// Catalogo de riesgos disponibles para los casos.
  static const List<Map<String, Object>> catalog = <Map<String, Object>>[
    <String, Object>{
      'id': 'key_person',
      'name': 'Perdida del especialista clave',
      'description':
          'El integrante con mayor conocimiento del dominio renuncia o es '
          'asignado a otra emergencia de la organizacion.',
      'category': 'organizational',
      'probability': 0.35,
      'impactHours': 135.0,
      'impactCost': 12000.0,
      'mitigationCost': 9000.0,
      'transferCost': 14000.0,
      'trigger': 'Una sola persona concentra el conocimiento de un modulo.',
      'window': <int>[4, 5, 6, 7, 8],
    },
    <String, Object>{
      'id': 'scope_pressure',
      'name': 'Presion de alcance del patrocinador',
      'description':
          'Un area influyente exige incorporar funcionalidad que no estaba '
          'en el acta, con la fecha original intacta.',
      'category': 'management',
      'probability': 0.50,
      'impactHours': 120.0,
      'impactCost': 6000.0,
      'mitigationCost': 7000.0,
      'transferCost': 10000.0,
      'trigger': 'Reuniones donde aparecen "pequenios ajustes" no documentados.',
      'window': <int>[3, 4, 5, 6, 7, 8, 9],
    },
    <String, Object>{
      'id': 'integration',
      'name': 'Integracion con sistema heredado',
      'description':
          'El sistema antiguo responde distinto a lo documentado y obliga a '
          'rehacer la interfaz de integracion.',
      'category': 'technical',
      'probability': 0.45,
      'impactHours': 155.0,
      'impactCost': 8000.0,
      'mitigationCost': 11000.0,
      'transferCost': 16000.0,
      'trigger': 'Nadie en la organizacion mantiene ese sistema hace anios.',
      'window': <int>[5, 6, 7, 8, 9],
    },
    <String, Object>{
      'id': 'vendor_delay',
      'name': 'Retraso del proveedor',
      'description':
          'El proveedor incumple la fecha de entrega de equipos o licencias '
          'criticas para avanzar.',
      'category': 'external',
      'probability': 0.40,
      'impactHours': 100.0,
      'impactCost': 15000.0,
      'mitigationCost': 8000.0,
      'transferCost': 12000.0,
      'trigger': 'La orden de compra sigue sin confirmacion escrita.',
      'window': <int>[4, 5, 6, 7],
    },
    <String, Object>{
      'id': 'infra_outage',
      'name': 'Caida de la infraestructura de pruebas',
      'description':
          'El ambiente de pruebas queda inoperativo y detiene la validacion '
          'durante dias.',
      'category': 'technical',
      'probability': 0.30,
      'impactHours': 75.0,
      'impactCost': 5000.0,
      'mitigationCost': 5000.0,
      'transferCost': 9000.0,
      'trigger': 'El ambiente comparte servidores con produccion.',
      'window': <int>[7, 8, 9, 10],
    },
    <String, Object>{
      'id': 'permits',
      'name': 'Demora en permisos y autorizaciones',
      'description':
          'La autoridad competente observa el expediente y suspende el '
          'avance hasta subsanar.',
      'category': 'external',
      'probability': 0.45,
      'impactHours': 130.0,
      'impactCost': 10000.0,
      'mitigationCost': 8000.0,
      'transferCost': 13000.0,
      'trigger': 'El tramite depende de una entidad con plazos propios.',
      'window': <int>[3, 4, 5, 6],
    },
    <String, Object>{
      'id': 'weather',
      'name': 'Condiciones climaticas adversas',
      'description':
          'Lluvias fuera de temporada detienen los trabajos de campo.',
      'category': 'external',
      'probability': 0.35,
      'impactHours': 110.0,
      'impactCost': 7000.0,
      'mitigationCost': 6000.0,
      'transferCost': 11000.0,
      'trigger': 'El cronograma cruza los meses de lluvia.',
      'window': <int>[5, 6, 7, 8],
    },
    <String, Object>{
      'id': 'quality_audit',
      'name': 'Observaciones de la supervision',
      'description':
          'La supervision detecta incumplimientos y exige rehacer parte de '
          'lo ejecutado con documentacion completa.',
      'category': 'management',
      'probability': 0.40,
      'impactHours': 135.0,
      'impactCost': 9000.0,
      'mitigationCost': 9000.0,
      'transferCost': 12000.0,
      'trigger': 'Los entregables avanzan sin revision formal.',
      'window': <int>[8, 9, 10, 11],
    },
    <String, Object>{
      'id': 'compliance',
      'name': 'Requisito regulatorio adicional',
      'description':
          'El regulador precisa una exigencia que obliga a desarrollar un '
          'control que no estaba previsto.',
      'category': 'external',
      'probability': 0.40,
      'impactHours': 145.0,
      'impactCost': 8000.0,
      'mitigationCost': 10000.0,
      'transferCost': 15000.0,
      'trigger': 'La normativa esta en revision desde antes del proyecto.',
      'window': <int>[5, 6, 7, 8, 9],
    },
  ];

  static RiskItem fromCatalog(String id) {
    final Map<String, Object> raw = catalog.firstWhere(
      (Map<String, Object> r) => r['id'] == id,
      orElse: () => catalog.first,
    );
    return RiskItem(
      id: raw['id'] as String,
      name: raw['name'] as String,
      description: raw['description'] as String,
      category: RiskCategory.fromName(raw['category'] as String),
      baseProbability: (raw['probability'] as num).toDouble(),
      impactHours: (raw['impactHours'] as num).toDouble(),
      impactCost: (raw['impactCost'] as num).toDouble(),
      mitigationCost: (raw['mitigationCost'] as num).toDouble(),
      transferCost: (raw['transferCost'] as num).toDouble(),
      trigger: raw['trigger'] as String,
      window: List<int>.from(raw['window'] as List<dynamic>),
    );
  }

  factory RiskItem.fromJson(Map<String, dynamic> json) {
    final RiskItem item = RiskItem.fromCatalog(json['id'] as String? ?? '');
    item.identified = json['identified'] == true;
    item.response = RiskResponse.fromName(json['response'] as String?);
    item.occurred = json['occurred'] == true;
    item.occurredPeriod = (json['occurredPeriod'] as num?)?.toInt() ?? 0;
    return item;
  }
}
