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
        return 'Analisis';
      case ProjectPhase.design:
        return 'Diseno';
      case ProjectPhase.build:
        return 'Construccion';
      case ProjectPhase.test:
        return 'Pruebas';
      case ProjectPhase.deploy:
        return 'Implantacion';
    }
  }

  int get order => index;

  /// Avance minimo de las fases anteriores para poder trabajar en esta.
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

/// Definicion de un paquete de trabajo dentro del caso.
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

  /// Horas que el equipo estima. La duracion real es otra cosa.
  final double estimatedHours;

  /// Multiplicador de dificultad: afecta la desviacion real y los defectos.
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

  /// Acta de constitucion resumida.
  final String charter;
  final String objective;

  /// Si los requisitos cambiaran durante la ejecucion.
  final bool volatileRequirements;

  /// Si el entorno exige documentacion y trazabilidad formal.
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
      name: 'Sistema de Matricula Universitaria',
      client: 'Universidad Nacional del Centro',
      sector: 'Educacion superior',
      charter:
          'La universidad matricula a 18,000 estudiantes con un sistema que '
          'se cae cada semestre. Vicerrectorado quiere el nuevo sistema listo '
          'para la matricula de marzo. Las escuelas profesionales todavia '
          'discuten como sera el proceso de convalidaciones y cada una pide '
          'algo distinto.',
      objective:
          'Poner en produccion el sistema de matricula antes del proceso de '
          'marzo, sin caidas el primer dia.',
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
        'Las escuelas profesionales aun no acuerdan el flujo de convalidaciones.',
        'Tesoreria pidio "revisar" la conciliacion de pagos mas adelante.',
      ],
      packages: <PackageSpec>[
        PackageSpec(
          id: 'a1',
          name: 'Relevamiento del proceso de matricula',
          phase: ProjectPhase.analysis,
          estimatedHours: 170,
          complexity: 1.0,
          detail: 'Entrevistas con escuelas, registro academico y tesoreria.',
        ),
        PackageSpec(
          id: 'a2',
          name: 'Analisis de reglas academicas',
          phase: ProjectPhase.analysis,
          estimatedHours: 125,
          complexity: 0.9,
          detail: 'Prerrequisitos, creditos, convalidaciones y excepciones.',
        ),
        PackageSpec(
          id: 'd1',
          name: 'Arquitectura de la solucion',
          phase: ProjectPhase.design,
          estimatedHours: 145,
          complexity: 1.2,
          detail: 'Modelo de datos, integraciones y estrategia de despliegue.',
        ),
        PackageSpec(
          id: 'd2',
          name: 'Diseno funcional y de interfaces',
          phase: ProjectPhase.design,
          estimatedHours: 180,
          complexity: 1.0,
          detail: 'Pantallas del estudiante, del docente y de registro.',
        ),
        PackageSpec(
          id: 'c1',
          name: 'Modulo de inscripcion de cursos',
          phase: ProjectPhase.build,
          estimatedHours: 290,
          complexity: 1.0,
          detail: 'Nucleo del sistema: seleccion de cursos y validaciones.',
        ),
        PackageSpec(
          id: 'c2',
          name: 'Modulo de pagos y conciliacion',
          phase: ProjectPhase.build,
          estimatedHours: 270,
          complexity: 1.3,
          detail: 'Integracion bancaria y conciliacion automatica.',
        ),
        PackageSpec(
          id: 'c3',
          name: 'Reportes y tablero academico',
          phase: ProjectPhase.build,
          estimatedHours: 215,
          complexity: 0.9,
          optional: true,
          detail: 'Deseable para gestion, no bloquea la matricula.',
        ),
        PackageSpec(
          id: 'c4',
          name: 'Integracion con sistema contable',
          phase: ProjectPhase.build,
          estimatedHours: 235,
          complexity: 1.4,
          detail: 'Sistema antiguo, sin documentacion y con soporte externo.',
        ),
        PackageSpec(
          id: 't1',
          name: 'Pruebas integrales y de carga',
          phase: ProjectPhase.test,
          estimatedHours: 200,
          complexity: 1.0,
          detail: '18,000 estudiantes entran el mismo dia a la misma hora.',
        ),
        PackageSpec(
          id: 't2',
          name: 'Correccion de defectos',
          phase: ProjectPhase.test,
          estimatedHours: 125,
          complexity: 1.0,
          detail: 'Crece con los defectos que no se evitaron antes.',
        ),
        PackageSpec(
          id: 'i1',
          name: 'Capacitacion y puesta en produccion',
          phase: ProjectPhase.deploy,
          estimatedHours: 170,
          complexity: 0.8,
          detail: 'Migracion de datos, capacitacion y acompanamiento.',
        ),
      ],
    ),
    ProjectCase(
      id: 'planta',
      name: 'Planta de Tratamiento de Agua',
      client: 'Municipalidad Provincial',
      sector: 'Infraestructura sanitaria',
      charter:
          'Obra de ampliacion de una planta de tratamiento con expediente '
          'tecnico aprobado y financiamiento publico. El alcance esta '
          'definido por el expediente y cualquier cambio exige aprobacion '
          'formal. La contraloria revisara el expediente de cierre.',
      objective:
          'Ampliar la capacidad de tratamiento cumpliendo el expediente '
          'tecnico, con documentacion completa para la supervision.',
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
        'La supervision podria observar el sistema de medicion de caudal.',
        'El area usuaria insinuo que faltaria un tablero de control adicional.',
      ],
      packages: <PackageSpec>[
        PackageSpec(
          id: 'a1',
          name: 'Revision del expediente tecnico',
          phase: ProjectPhase.analysis,
          estimatedHours: 155,
          complexity: 0.9,
          detail: 'Verificacion de metrados, planos y compatibilidad.',
        ),
        PackageSpec(
          id: 'a2',
          name: 'Levantamiento de campo y permisos',
          phase: ProjectPhase.analysis,
          estimatedHours: 135,
          complexity: 1.1,
          detail: 'Topografia, suelos y tramites con la autoridad del agua.',
        ),
        PackageSpec(
          id: 'd1',
          name: 'Ingenieria de detalle hidraulica',
          phase: ProjectPhase.design,
          estimatedHours: 170,
          complexity: 1.2,
          detail: 'Dimensionamiento de unidades de tratamiento.',
        ),
        PackageSpec(
          id: 'd2',
          name: 'Diseno electromecanico y de control',
          phase: ProjectPhase.design,
          estimatedHours: 155,
          complexity: 1.1,
          detail: 'Bombas, tableros e instrumentacion.',
        ),
        PackageSpec(
          id: 'c1',
          name: 'Obras civiles de la unidad de sedimentacion',
          phase: ProjectPhase.build,
          estimatedHours: 315,
          complexity: 1.0,
          detail: 'Estructura principal de la ampliacion.',
        ),
        PackageSpec(
          id: 'c2',
          name: 'Montaje electromecanico',
          phase: ProjectPhase.build,
          estimatedHours: 260,
          complexity: 1.3,
          detail: 'Depende de la llegada de equipos importados.',
        ),
        PackageSpec(
          id: 'c3',
          name: 'Sistema de telemetria',
          phase: ProjectPhase.build,
          estimatedHours: 190,
          complexity: 1.2,
          optional: true,
          detail: 'Mejora la operacion, no condiciona la puesta en marcha.',
        ),
        PackageSpec(
          id: 'c4',
          name: 'Instalaciones sanitarias y electricas',
          phase: ProjectPhase.build,
          estimatedHours: 225,
          complexity: 1.0,
          detail: 'Conexiones de la nueva unidad con la planta existente.',
        ),
        PackageSpec(
          id: 't1',
          name: 'Pruebas hidraulicas y de calidad de agua',
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
          detail: 'Crece con lo que no se controlo durante la ejecucion.',
        ),
        PackageSpec(
          id: 'i1',
          name: 'Puesta en marcha y expediente de cierre',
          phase: ProjectPhase.deploy,
          estimatedHours: 180,
          complexity: 0.9,
          detail: 'Operacion asistida y documentacion para la supervision.',
        ),
      ],
    ),
    ProjectCase(
      id: 'cobranzas',
      name: 'Transformacion Digital de Cobranzas',
      client: 'Caja municipal de ahorro y credito',
      sector: 'Servicios financieros',
      charter:
          'La caja quiere digitalizar la cobranza de creditos vencidos. El '
          'negocio todavia esta definiendo la estrategia de contacto y la '
          'segmentacion de clientes, pero el regulador exige trazabilidad de '
          'cada gestion y proteccion de datos personales.',
      objective:
          'Reducir el tiempo de gestion de cobranza con un proceso digital '
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
        'La gerencia comercial aun discute la segmentacion de clientes.',
        'Cumplimiento podria exigir un registro adicional de consentimiento.',
      ],
      packages: <PackageSpec>[
        PackageSpec(
          id: 'a1',
          name: 'Diagnostico del proceso de cobranza',
          phase: ProjectPhase.analysis,
          estimatedHours: 170,
          complexity: 1.0,
          detail: 'Mapeo de la gestion actual y sus tiempos.',
        ),
        PackageSpec(
          id: 'a2',
          name: 'Analisis normativo y de datos personales',
          phase: ProjectPhase.analysis,
          estimatedHours: 135,
          complexity: 1.2,
          detail: 'Requisitos de trazabilidad y consentimiento.',
        ),
        PackageSpec(
          id: 'd1',
          name: 'Diseno del nuevo proceso',
          phase: ProjectPhase.design,
          estimatedHours: 155,
          complexity: 1.0,
          detail: 'Reglas de segmentacion y canales de contacto.',
        ),
        PackageSpec(
          id: 'd2',
          name: 'Arquitectura e integracion con el core',
          phase: ProjectPhase.design,
          estimatedHours: 180,
          complexity: 1.3,
          detail: 'El core financiero solo permite ventanas nocturnas.',
        ),
        PackageSpec(
          id: 'c1',
          name: 'Motor de gestion de cobranza',
          phase: ProjectPhase.build,
          estimatedHours: 300,
          complexity: 1.1,
          detail: 'Asignacion de carteras y seguimiento de gestiones.',
        ),
        PackageSpec(
          id: 'c2',
          name: 'Canales digitales de contacto',
          phase: ProjectPhase.build,
          estimatedHours: 245,
          complexity: 1.0,
          detail: 'Mensajeria, correo y portal de pago.',
        ),
        PackageSpec(
          id: 'c3',
          name: 'Analitica de recuperacion',
          phase: ProjectPhase.build,
          estimatedHours: 200,
          complexity: 1.2,
          optional: true,
          detail: 'Priorizacion inteligente de carteras; deseable, no critico.',
        ),
        PackageSpec(
          id: 'c4',
          name: 'Registro de trazabilidad y consentimiento',
          phase: ProjectPhase.build,
          estimatedHours: 215,
          complexity: 1.3,
          detail: 'Exigido por el regulador para cada gestion.',
        ),
        PackageSpec(
          id: 't1',
          name: 'Pruebas funcionales y de seguridad',
          phase: ProjectPhase.test,
          estimatedHours: 200,
          complexity: 1.1,
          detail: 'Incluye prueba de proteccion de datos.',
        ),
        PackageSpec(
          id: 't2',
          name: 'Correccion de hallazgos',
          phase: ProjectPhase.test,
          estimatedHours: 125,
          complexity: 1.0,
          detail: 'Depende de la calidad con que se construyo.',
        ),
        PackageSpec(
          id: 'i1',
          name: 'Despliegue y capacitacion de gestores',
          phase: ProjectPhase.deploy,
          estimatedHours: 170,
          complexity: 0.9,
          detail: 'Cambio de habitos en 60 gestores de cobranza.',
        ),
      ],
    ),
  ];

  static ProjectCase byId(String id) => catalog.firstWhere(
        (ProjectCase c) => c.id == id,
        orElse: () => catalog.first,
      );
}
