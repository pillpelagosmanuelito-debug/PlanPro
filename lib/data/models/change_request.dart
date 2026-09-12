/// Decisión del director frente a una solicitud de cambio.
enum ChangeDecision {
  pending,
  acceptedWithoutBaseline,
  acceptedWithBaseline,
  tradedOff,
  rejected;

  String get label {
    switch (this) {
      case ChangeDecision.pending:
        return 'Pendiente';
      case ChangeDecision.acceptedWithoutBaseline:
        return 'Aceptada sin ajustar la línea base';
      case ChangeDecision.acceptedWithBaseline:
        return 'Aceptada renegociando plazo o costo';
      case ChangeDecision.tradedOff:
        return 'Aceptada quitando alcance equivalente';
      case ChangeDecision.rejected:
        return 'Rechazada formalmente';
    }
  }

  String get consequence {
    switch (this) {
      case ChangeDecision.pending:
        return 'El patrocinador espera respuesta.';
      case ChangeDecision.acceptedWithoutBaseline:
        return 'El trabajo entra al proyecto pero la línea base no se mueve: '
            'el atraso aparecerá después y será tuyo.';
      case ChangeDecision.acceptedWithBaseline:
        return 'Se agrega el trabajo y se ajusta formalmente la línea base. '
            'Es lo correcto, aunque el patrocinador no lo celebre.';
      case ChangeDecision.tradedOff:
        return 'Entra el cambio y sale alcance opcional equivalente: el '
            'proyecto no crece.';
      case ChangeDecision.rejected:
        return 'El alcance se protege, pero el patrocinador registra la '
            'negativa.';
    }
  }

  static ChangeDecision fromName(String? name) =>
      ChangeDecision.values.firstWhere(
        (ChangeDecision d) => d.name == name,
        orElse: () => ChangeDecision.pending,
      );

  /// Efecto sobre la satisfacción del patrocinador si se toma esta decisión.
  double satisfactionDelta() {
    switch (this) {
      case ChangeDecision.pending:
        return 0;
      case ChangeDecision.acceptedWithoutBaseline:
        return 4;
      case ChangeDecision.acceptedWithBaseline:
        return 1;
      case ChangeDecision.tradedOff:
        return -2;
      case ChangeDecision.rejected:
        return -8;
    }
  }
}

/// Solicitud de cambio de alcance durante la ejecución.
class ChangeRequest {
  ChangeRequest({
    required this.id,
    required this.period,
    required this.title,
    required this.requestedBy,
    required this.description,
    required this.baseHours,
    required this.targetPackageIds,
    this.decision = ChangeDecision.pending,
    this.appliedHours = 0,
  });

  final String id;

  /// Periodo en que aparece.
  final int period;

  final String title;
  final String requestedBy;
  final String description;

  /// Horas base del cambio, antes del multiplicador de la metodología.
  final double baseHours;

  /// Paquetes sobre los que recae el trabajo adicional.
  final List<String> targetPackageIds;

  ChangeDecision decision;

  /// Horas realmente agregadas al proyecto tras la decisión.
  double appliedHours;

  bool get isPending => decision == ChangeDecision.pending;

  /// Efecto sobre la satisfacción del patrocinador.
  double satisfactionDelta() => decision.satisfactionDelta();

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'period': period,
        'title': title,
        'requestedBy': requestedBy,
        'description': description,
        'baseHours': baseHours,
        'targetPackageIds': targetPackageIds,
        'decision': decision.name,
        'appliedHours': appliedHours,
      };

  factory ChangeRequest.fromJson(Map<String, dynamic> json) => ChangeRequest(
        id: json['id'] as String? ?? 'ch',
        period: (json['period'] as num?)?.toInt() ?? 1,
        title: json['title'] as String? ?? '',
        requestedBy: json['requestedBy'] as String? ?? '',
        description: json['description'] as String? ?? '',
        baseHours: (json['baseHours'] as num?)?.toDouble() ?? 0,
        targetPackageIds:
            ((json['targetPackageIds'] as List<dynamic>?) ?? <dynamic>[])
                .map((dynamic e) => e.toString())
                .toList(),
        decision: ChangeDecision.fromName(json['decision'] as String?),
        appliedHours: (json['appliedHours'] as num?)?.toDouble() ?? 0,
      );
}
