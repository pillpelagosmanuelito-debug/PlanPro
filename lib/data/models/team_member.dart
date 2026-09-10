/// Perfiles disponibles para armar el equipo.
class TeamRole {
  const TeamRole({
    required this.id,
    required this.label,
    required this.costPerPeriod,
    required this.productivity,
    required this.rampPeriods,
    required this.detail,
  });

  final String id;
  final String label;

  /// Costo por periodo (quincena) en soles.
  final double costPerPeriod;

  /// Horas efectivas por hora nominal.
  final double productivity;

  /// Periodos que tarda en alcanzar el rendimiento pleno al incorporarse.
  final int rampPeriods;

  final String detail;

  static const List<TeamRole> catalog = <TeamRole>[
    TeamRole(
      id: 'analista',
      label: 'Analista funcional',
      costPerPeriod: 6200,
      productivity: 1.00,
      rampPeriods: 1,
      detail: 'Levanta requisitos y traduce el negocio al equipo tecnico.',
    ),
    TeamRole(
      id: 'senior',
      label: 'Especialista senior',
      costPerPeriod: 9000,
      productivity: 1.35,
      rampPeriods: 2,
      detail: 'Alta productividad y criterio tecnico; escaso y caro.',
    ),
    TeamRole(
      id: 'junior',
      label: 'Profesional junior',
      costPerPeriod: 4300,
      productivity: 0.70,
      rampPeriods: 3,
      detail: 'Barato, pero necesita tres periodos para rendir de verdad.',
    ),
    TeamRole(
      id: 'qa',
      label: 'Aseguramiento de calidad',
      costPerPeriod: 5400,
      productivity: 0.95,
      rampPeriods: 1,
      detail: 'Detecta defectos antes de que lleguen al cliente.',
    ),
    TeamRole(
      id: 'especialista',
      label: 'Consultor experto',
      costPerPeriod: 10500,
      productivity: 1.45,
      rampPeriods: 2,
      detail: 'Resuelve lo que nadie mas puede; el perfil mas costoso.',
    ),
  ];

  static TeamRole byId(String id) => catalog.firstWhere(
        (TeamRole r) => r.id == id,
        orElse: () => catalog.first,
      );
}

/// Integrante concreto del equipo.
class TeamMember {
  TeamMember({
    required this.id,
    required this.roleId,
    required this.name,
    required this.joinedPeriod,
    this.periodsOnTeam = 0,
    this.assignedPackageId,
  });

  final String id;
  final String roleId;
  final String name;

  /// Periodo en que se incorporo (1 = desde el inicio).
  final int joinedPeriod;

  /// Periodos completos que lleva en el equipo.
  int periodsOnTeam;

  /// Paquete al que esta asignado en el periodo en curso.
  String? assignedPackageId;

  TeamRole get role => TeamRole.byId(roleId);

  /// Rendimiento por curva de aprendizaje (0.45 a 1.0).
  double get rampFactor {
    final int ramp = role.rampPeriods;
    if (periodsOnTeam >= ramp) return 1.0;
    return 0.45 + 0.55 * (periodsOnTeam / (ramp <= 0 ? 1 : ramp));
  }

  bool get isNewcomer => periodsOnTeam < role.rampPeriods;

  /// Horas efectivas que aporta en un periodo, antes de efectos de equipo.
  double effectiveHours(double hoursPerPerson) =>
      hoursPerPerson * role.productivity * rampFactor;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'roleId': roleId,
        'name': name,
        'joinedPeriod': joinedPeriod,
        'periodsOnTeam': periodsOnTeam,
        'assignedPackageId': assignedPackageId,
      };

  factory TeamMember.fromJson(Map<String, dynamic> json) => TeamMember(
        id: json['id'] as String? ?? 'm',
        roleId: json['roleId'] as String? ?? 'analista',
        name: json['name'] as String? ?? 'Integrante',
        joinedPeriod: (json['joinedPeriod'] as num?)?.toInt() ?? 1,
        periodsOnTeam: (json['periodsOnTeam'] as num?)?.toInt() ?? 0,
        assignedPackageId: json['assignedPackageId'] as String?,
      );
}
