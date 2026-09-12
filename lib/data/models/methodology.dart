/// Enfoques de dirección de proyectos disponibles.
///
/// La elección no es decorativa: cambia el retrabajo por cambios de alcance,
/// el costo de cada solicitud de cambio, la carga de gobernanza y el nivel de
/// cumplimiento documental que se exige en el cierre.
enum Methodology {
  predictive,
  agile,
  hybrid;

  String get label {
    switch (this) {
      case Methodology.predictive:
        return 'Predictivo (PMBOK)';
      case Methodology.agile:
        return 'Ágil (Scrum)';
      case Methodology.hybrid:
        return 'Híbrido';
    }
  }

  String get shortLabel {
    switch (this) {
      case Methodology.predictive:
        return 'Predictivo';
      case Methodology.agile:
        return 'Ágil';
      case Methodology.hybrid:
        return 'Híbrido';
    }
  }

  String get description {
    switch (this) {
      case Methodology.predictive:
        return 'Alcance definido al inicio, línea base formal y control de '
            'cambios estricto. Cada cambio obliga a rehacer análisis, diseño '
            'y documentación aprobada.';
      case Methodology.agile:
        return 'Entregas incrementales por sprints, alcance que se ajusta con '
            'el cliente. Absorbe cambios a bajo costo, pero produce menos '
            'documentación formal.';
      case Methodology.hybrid:
        return 'Fases y línea base para la parte estable, iteraciones para la '
            'parte incierta. Cuesta algo de coordinación adicional y evita '
            'los extremos de los otros dos.';
    }
  }

  String get worksWhen {
    switch (this) {
      case Methodology.predictive:
        return 'Requisitos estables y entorno regulado, donde el costo de '
            'documentar es menor que el de improvisar.';
      case Methodology.agile:
        return 'Requisitos volátiles y cliente disponible, donde el costo de '
            'equivocarse temprano es bajo.';
      case Methodology.hybrid:
        return 'Proyectos con una parte regulada y otra incierta, que es el '
            'caso más frecuente en la práctica.';
    }
  }

  /// Retrabajo agregado al trabajo real según la volatilidad del proyecto.
  double reworkFactor({required bool volatileRequirements}) {
    switch (this) {
      case Methodology.predictive:
        return volatileRequirements ? 0.30 : 0.06;
      case Methodology.agile:
        // En un proyecto estable, la ceremonia ágil no compra flexibilidad
        // que nadie necesita: solo agrega coordinación.
        return volatileRequirements ? 0.10 : 0.14;
      case Methodology.hybrid:
        return volatileRequirements ? 0.17 : 0.09;
    }
  }

  /// Multiplicador del costo en horas de cada solicitud de cambio.
  double get changeCostFactor {
    switch (this) {
      case Methodology.predictive:
        return 2.4;
      case Methodology.agile:
        return 1.0;
      case Methodology.hybrid:
        return 1.5;
    }
  }

  /// Carga de gobernanza que resta capacidad al equipo.
  double governanceOverhead({required bool regulated}) {
    switch (this) {
      case Methodology.predictive:
        return 0.02;
      case Methodology.agile:
        return regulated ? 0.10 : 0.03;
      case Methodology.hybrid:
        return 0.05;
    }
  }

  /// Cumplimiento documental exigido al cerrar un proyecto regulado (0-1).
  double get complianceLevel {
    switch (this) {
      case Methodology.predictive:
        return 1.00;
      case Methodology.agile:
        return 0.60;
      case Methodology.hybrid:
        return 0.85;
    }
  }

  static Methodology fromName(String? name) => Methodology.values.firstWhere(
        (Methodology m) => m.name == name,
        orElse: () => Methodology.hybrid,
      );
}

/// Restricción que el patrocinador declara como prioritaria.
///
/// Es la traducción práctica del triángulo alcance-tiempo-costo: algo tiene
/// que ceder, y decidir que cede antes de empezar es parte del trabajo.
enum ConstraintPriority {
  scope,
  time,
  cost;

  String get label {
    switch (this) {
      case ConstraintPriority.scope:
        return 'Alcance fijo';
      case ConstraintPriority.time:
        return 'Plazo fijo';
      case ConstraintPriority.cost:
        return 'Costo fijo';
    }
  }

  String get detail {
    switch (this) {
      case ConstraintPriority.scope:
        return 'Se entrega todo lo comprometido aunque cueste plazo o dinero.';
      case ConstraintPriority.time:
        return 'La fecha manda: si algo cede, cede el alcance opcional.';
      case ConstraintPriority.cost:
        return 'El presupuesto manda: no se contrata ni se pagan horas extra '
            'sin justificación.';
    }
  }

  static ConstraintPriority fromName(String? name) =>
      ConstraintPriority.values.firstWhere(
        (ConstraintPriority c) => c.name == name,
        orElse: () => ConstraintPriority.time,
      );
}
