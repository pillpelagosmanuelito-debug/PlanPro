/// Fases del ciclo de vida usadas por la estructura de desglose del trabajo.
enum ProjectPhase {
  analysis,
  design,
  build,
  test,
  deploy;

  String get label {
    switch (this) {
      case ProjectPhase.analysis:
        return 'Análisis';
      case ProjectPhase.design:
        return 'Diseño';
      case ProjectPhase.build:
        return 'Construcción';
      case ProjectPhase.test:
        return 'Pruebas';
      case ProjectPhase.deploy:
        return 'Implantación';
    }
  }

  int get order => index;

  /// Avance mínimo de las fases anteriores para poder trabajar en esta.
  ///
  /// No exige 100%: las fases se traslapan (fast tracking), que es como se
  /// dirige un proyecto real, y por eso el avance parcial habilita la
  /// siguiente etapa.
  double get gate {
    switch (this) {
      case ProjectPhase.analysis:
        return 0.0;
      case ProjectPhase.design:
        return 0.55;
      case ProjectPhase.build:
        return 0.50;
      case ProjectPhase.test:
        return 0.70;
      case ProjectPhase.deploy:
        return 0.80;
    }
  }

  static ProjectPhase fromName(String? name) => ProjectPhase.values.firstWhere(
        (ProjectPhase p) => p.name == name,
        orElse: () => ProjectPhase.analysis,
      );
}

/// Definición de un paquete de trabajo dentro del caso.
class PackageSpec {
  const PackageSpec({
    required this.id,
    required this.name,
    required this.phase,
    required this.estimatedHours,
    required this.complexity,
    this.optional = false,
    this.detail = '',
  });

  final String id;
  final String name;
  final ProjectPhase phase;

  /// Horas que el equipo estima. La duración real es otra cosa.
  final double estimatedHours;

  /// Multiplicador de dificultad: afecta la desviación real y los defectos.
  final double complexity;

  /// Si puede excluirse del alcance comprometido.
  final bool optional;

  final String detail;
}

/// Caso de proyecto que el estudiante dirige.
class ProjectCase {
  const ProjectCase({
    required this.id,
    required this.name,
    required this.client,
    required this.sector,
    required this.charter,
    required this.objective,
    required this.volatileRequirements,
    required this.regulated,
    required this.budgetCeiling,
    required this.targetPeriods,
    required this.packages,
    required this.riskIds,
    required this.changeHints,
  });

  final String id;
  final String name;
  final String client;
  final String sector;

  /// Acta de constitución resumida.
  final String charter;
  final String objective;

  /// Si los requisitos cambiaran durante la ejecución.
  final bool volatileRequirements;

  /// Si el entorno exige documentación y trazabilidad formal.
  final bool regulated;

  final double budgetCeiling;

  /// Plazo objetivo del patrocinador, en periodos.
  final int targetPeriods;

  final List<PackageSpec> packages;

  /// Riesgos del catalogo que aplican a este caso.
  final List<String> riskIds;

  /// Pistas que el acta deja sobre los cambios probables.
  final List<String> changeHints;

  double get totalEstimatedHours {
    double total = 0;
    for (final PackageSpec p in packages) {
      total += p.estimatedHours;
    }
    return total;
  }

  double get mandatoryEstimatedHours {
    double total = 0;
    for (final PackageSpec p in packages) {
      if (!p.optional) total += p.estimatedHours;
    }
    return total;
  }

  static const List<ProjectCase> catalog = <ProjectCase>[
    ProjectCase(
      id: 'matricula',
      name: 'Sistema de Matrícula Universitaria',
      client: 'Universidad Nacional del Centro',
      sector: 'Educación superior',
      charter:
          'La universidad matricula a 18,000 estudiantes con un sistema que '
          'se cae cada semestre. Vicerrectorado quiere el nuevo sistema listo '
          'para la matrícula de marzo. Las escuelas profesionales todavía '
          'discuten cómo será el proceso de convalidaciones y cada una pide '
          'algo distinto.',
      objective:
          'Poner en producción el sistema de matrícula antes del proceso de '
          'marzo, sin caídas el primer día.',
      volatileRequirements: true,
      regulated: false,
      budgetCeiling: 450000,
      targetPeriods: 12,
      riskIds: <String>[
        'key_person',
        'scope_pressure',
        'integration',
        'vendor_delay',
        'infra_outage',
      ],
      changeHints: <String>[
        'Las escuelas profesionales aún no acuerdan el flujo de convalidaciones.',
        'Tesorería pidió "revisar" la conciliación de pagos más adelante.',
      ],
      packages: <PackageSpec>[
        PackageSpec(
          id: 'a1',
          name: 'Relevamiento del proceso de matrícula',
          phase: ProjectPhase.analysis,
          estimatedHours: 170,
          complexity: 1.0,
          detail: 'Entrevistas con escuelas, registro académico y tesorería.',
        ),
        PackageSpec(
          id: 'a2',
          name: 'Análisis de reglas académicas',
          phase: ProjectPhase.analysis,
          estimatedHours: 125,
          complexity: 0.9,
          detail: 'Prerrequisitos, créditos, convalidaciones y excepciones.',
        ),
        PackageSpec(
          id: 'd1',
          name: 'Arquitectura de la solución',
          phase: ProjectPhase.design,
          estimatedHours: 145,
          complexity: 1.2,
          detail: 'Modelo de datos, integraciones y estrategia de despliegue.',
        ),
        PackageSpec(
          id: 'd2',
          name: 'Diseño funcional y de interfaces',
          phase: ProjectPhase.design,
          estimatedHours: 180,
          complexity: 1.0,
          detail: 'Pantallas del estudiante, del docente y de registro.',
        ),
        PackageSpec(
          id: 'c1',
          name: 'Módulo de inscripción de cursos',
          phase: ProjectPhase.build,
          estimatedHours: 290,
          complexity: 1.0,
          detail: 'Núcleo del sistema: selección de cursos y validaciones.',
        ),
        PackageSpec(
          id: 'c2',
          name: 'Módulo de pagos y conciliación',
          phase: ProjectPhase.build,
          estimatedHours: 270,
          complexity: 1.3,
          detail: 'Integración bancaria y conciliación automática.',
        ),
        PackageSpec(
          id: 'c3',
          name: 'Reportes y tablero académico',
          phase: ProjectPhase.build,
          estimatedHours: 215,
          complexity: 0.9,
          optional: true,
          detail: 'Deseable para gestión, no bloquea la matrícula.',
        ),
        PackageSpec(
          id: 'c4',
          name: 'Integración con sistema contable',
          phase: ProjectPhase.build,
          estimatedHours: 235,
          complexity: 1.4,
          detail: 'Sistema antiguo, sin documentación y con soporte externo.',
        ),
        PackageSpec(
          id: 't1',
          name: 'Pruebas integrales y de carga',
          phase: ProjectPhase.test,
          estimatedHours: 200,
          complexity: 1.0,
          detail: '18,000 estudiantes entran el mismo día a la misma hora.',
        ),
        PackageSpec(
          id: 't2',
          name: 'Corrección de defectos',
          phase: ProjectPhase.test,
          estimatedHours: 125,
          complexity: 1.0,
          detail: 'Crece con los defectos que no se evitaron antes.',
        ),
        PackageSpec(
          id: 'i1',
          name: 'Capacitación y puesta en producción',
          phase: ProjectPhase.deploy,
          estimatedHours: 170,
          complexity: 0.8,
          detail: 'Migración de datos, capacitación y acompañamiento.',
        ),
      ],
    ),
    ProjectCase(
      id: 'planta',
      name: 'Planta de Tratamiento de Agua',
      client: 'Municipalidad Provincial',
      sector: 'Infraestructura sanitaria',
      charter:
          'Obra de ampliación de una planta de tratamiento con expediente '
          'técnico aprobado y financiamiento público. El alcance está '
          'definido por el expediente y cualquier cambio exige aprobación '
          'formal. La contraloría revisará el expediente de cierre.',
      objective:
          'Ampliar la capacidad de tratamiento cumpliendo el expediente '
          'técnico, con documentación completa para la supervisión.',
      volatileRequirements: false,
      regulated: true,
      budgetCeiling: 470000,
      targetPeriods: 12,
      riskIds: <String>[
        'permits',
        'vendor_delay',
        'weather',
        'key_person',
        'quality_audit',
      ],
      changeHints: <String>[
        'La supervisión podría observar el sistema de medición de caudal.',
        'El área usuaria insinuó que faltaría un tablero de control adicional.',
      ],
      packages: <PackageSpec>[
        PackageSpec(
          id: 'a1',
          name: 'Revisión del expediente técnico',
          phase: ProjectPhase.analysis,
          estimatedHours: 155,
          complexity: 0.9,
          detail: 'Verificación de metrados, planos y compatibilidad.',
        ),
        PackageSpec(
          id: 'a2',
          name: 'Levantamiento de campo y permisos',
          phase: ProjectPhase.analysis,
          estimatedHours: 135,
          complexity: 1.1,
          detail: 'Topografía, suelos y trámites con la autoridad del agua.',
        ),
        PackageSpec(
          id: 'd1',
          name: 'Ingeniería de detalle hidráulica',
          phase: ProjectPhase.design,
          estimatedHours: 170,
          complexity: 1.2,
          detail: 'Dimensionamiento de unidades de tratamiento.',
        ),
        PackageSpec(
          id: 'd2',
          name: 'Diseño electromecánico y de control',
          phase: ProjectPhase.design,
          estimatedHours: 155,
          complexity: 1.1,
          detail: 'Bombas, tableros e instrumentación.',
        ),
        PackageSpec(
          id: 'c1',
          name: 'Obras civiles de la unidad de sedimentación',
          phase: ProjectPhase.build,
          estimatedHours: 315,
          complexity: 1.0,
          detail: 'Estructura principal de la ampliación.',
        ),
        PackageSpec(
          id: 'c2',
          name: 'Montaje electromecánico',
          phase: ProjectPhase.build,
          estimatedHours: 260,
          complexity: 1.3,
          detail: 'Depende de la llegada de equipos importados.',
        ),
        PackageSpec(
          id: 'c3',
          name: 'Sistema de telemetría',
          phase: ProjectPhase.build,
          estimatedHours: 190,
          complexity: 1.2,
          optional: true,
          detail: 'Mejora la operación, no condiciona la puesta en marcha.',
        ),
        PackageSpec(
          id: 'c4',
          name: 'Instalaciones sanitarias y eléctricas',
          phase: ProjectPhase.build,
          estimatedHours: 225,
          complexity: 1.0,
          detail: 'Conexiones de la nueva unidad con la planta existente.',
        ),
        PackageSpec(
          id: 't1',
          name: 'Pruebas hidráulicas y de calidad de agua',
          phase: ProjectPhase.test,
          estimatedHours: 190,
          complexity: 1.1,
          detail: 'Ensayos exigidos por la normativa sanitaria.',
        ),
        PackageSpec(
          id: 't2',
          name: 'Levantamiento de observaciones',
          phase: ProjectPhase.test,
          estimatedHours: 125,
          complexity: 1.0,
          detail: 'Crece con lo que no se controló durante la ejecución.',
        ),
        PackageSpec(
          id: 'i1',
          name: 'Puesta en marcha y expediente de cierre',
          phase: ProjectPhase.deploy,
          estimatedHours: 180,
          complexity: 0.9,
          detail: 'Operación asistida y documentación para la supervisión.',
        ),
      ],
    ),
    ProjectCase(
      id: 'cobranzas',
      name: 'Transformación Digital de Cobranzas',
      client: 'Caja municipal de ahorro y crédito',
      sector: 'Servicios financieros',
      charter:
          'La caja quiere digitalizar la cobranza de créditos vencidos. El '
          'negocio todavía está definiendo la estrategia de contacto y la '
          'segmentación de clientes, pero el regulador exige trazabilidad de '
          'cada gestión y protección de datos personales.',
      objective:
          'Reducir el tiempo de gestión de cobranza con un proceso digital '
          'auditable y conforme con la normativa de datos personales.',
      volatileRequirements: true,
      regulated: true,
      budgetCeiling: 460000,
      targetPeriods: 12,
      riskIds: <String>[
        'scope_pressure',
        'compliance',
        'key_person',
        'integration',
        'quality_audit',
      ],
      changeHints: <String>[
        'La gerencia comercial aún discute la segmentación de clientes.',
        'Cumplimiento podría exigir un registro adicional de consentimiento.',
      ],
      packages: <PackageSpec>[
        PackageSpec(
          id: 'a1',
          name: 'Diagnóstico del proceso de cobranza',
          phase: ProjectPhase.analysis,
          estimatedHours: 170,
          complexity: 1.0,
          detail: 'Mapeo de la gestión actual y sus tiempos.',
        ),
        PackageSpec(
          id: 'a2',
          name: 'Análisis normativo y de datos personales',
          phase: ProjectPhase.analysis,
          estimatedHours: 135,
          complexity: 1.2,
          detail: 'Requisitos de trazabilidad y consentimiento.',
        ),
        PackageSpec(
          id: 'd1',
          name: 'Diseño del nuevo proceso',
          phase: ProjectPhase.design,
          estimatedHours: 155,
          complexity: 1.0,
          detail: 'Reglas de segmentación y canales de contacto.',
        ),
        PackageSpec(
          id: 'd2',
          name: 'Arquitectura e integración con el core',
          phase: ProjectPhase.design,
          estimatedHours: 180,
          complexity: 1.3,
          detail: 'El core financiero solo permite ventanas nocturnas.',
        ),
        PackageSpec(
          id: 'c1',
          name: 'Motor de gestión de cobranza',
          phase: ProjectPhase.build,
          estimatedHours: 300,
          complexity: 1.1,
          detail: 'Asignación de carteras y seguimiento de gestiones.',
        ),
        PackageSpec(
          id: 'c2',
          name: 'Canales digitales de contacto',
          phase: ProjectPhase.build,
          estimatedHours: 245,
          complexity: 1.0,
          detail: 'Mensajería, correo y portal de pago.',
        ),
        PackageSpec(
          id: 'c3',
          name: 'Analítica de recuperación',
          phase: ProjectPhase.build,
          estimatedHours: 200,
          complexity: 1.2,
          optional: true,
          detail: 'Priorización inteligente de carteras; deseable, no crítico.',
        ),
        PackageSpec(
          id: 'c4',
          name: 'Registro de trazabilidad y consentimiento',
          phase: ProjectPhase.build,
          estimatedHours: 215,
          complexity: 1.3,
          detail: 'Exigido por el regulador para cada gestión.',
        ),
        PackageSpec(
          id: 't1',
          name: 'Pruebas funcionales y de seguridad',
          phase: ProjectPhase.test,
          estimatedHours: 200,
          complexity: 1.1,
          detail: 'Incluye prueba de protección de datos.',
        ),
        PackageSpec(
          id: 't2',
          name: 'Corrección de hallazgos',
          phase: ProjectPhase.test,
          estimatedHours: 125,
          complexity: 1.0,
          detail: 'Depende de la calidad con que se construyó.',
        ),
        PackageSpec(
          id: 'i1',
          name: 'Despliegue y capacitación de gestores',
          phase: ProjectPhase.deploy,
          estimatedHours: 170,
          complexity: 0.9,
          detail: 'Cambio de hábitos en 60 gestores de cobranza.',
        ),
      ],
    ),
  ];

  static ProjectCase byId(String id) => catalog.firstWhere(
        (ProjectCase c) => c.id == id,
        orElse: () => catalog.first,
      );
}
