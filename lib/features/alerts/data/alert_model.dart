import 'package:equatable/equatable.dart';

/// Tipo de alerta "Pasa la Voz": llega como número.
enum AlertType {
  craving(1, 'Antojo'),
  tiredOrPain(2, 'Cansancio o dolor'),
  comeHere(3, 'Ven un momento'),
  sos(4, 'SOS');

  const AlertType(this.value, this.label);

  final int value;
  final String label;

  static AlertType fromValue(int value) => AlertType.values.firstWhere(
    (type) => type.value == value,
    orElse: () => throw FormatException('Tipo de alerta desconocido: $value'),
  );
}

enum AlertStatus {
  pending(1, 'Pendiente'),
  responded(2, 'Respondida');

  const AlertStatus(this.value, this.label);

  final int value;
  final String label;

  static AlertStatus fromValue(int value) => AlertStatus.values.firstWhere(
    (status) => status.value == value,
    orElse: () => throw FormatException('Estado de alerta desconocido: $value'),
  );
}

/// Respuesta de un toque del acompañante.
enum AlertResponse {
  onMyWay(1, 'Voy en camino'),
  callingNow(2, 'Te llamo ahora'),
  done(3, 'Ya me encargué');

  const AlertResponse(this.value, this.label);

  final int value;
  final String label;

  static AlertResponse fromValue(int value) => AlertResponse.values.firstWhere(
    (response) => response.value == value,
    orElse: () => throw FormatException('Respuesta desconocida: $value'),
  );
}

class QuickAlert extends Equatable {
  const QuickAlert({
    required this.id,
    required this.type,
    required this.message,
    required this.createdAt,
    required this.status,
    this.response,
    this.respondedAt,
  });

  factory QuickAlert.fromJson(Map<String, dynamic> json) {
    final response = json['response'] as int?;
    final respondedAt = json['respondedAt'] as String?;
    return QuickAlert(
      id: json['id'] as String,
      type: AlertType.fromValue(json['type'] as int),
      message: json['message'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: AlertStatus.fromValue(json['status'] as int),
      response: response == null ? null : AlertResponse.fromValue(response),
      respondedAt: respondedAt == null ? null : DateTime.parse(respondedAt),
    );
  }

  final String id;
  final AlertType type;
  final String message;
  final DateTime createdAt;
  final AlertStatus status;

  /// null mientras no haya respuesta.
  final AlertResponse? response;
  final DateTime? respondedAt;

  bool get isPending => status == AlertStatus.pending;
  bool get isSos => type == AlertType.sos;

  /// Copia ya respondida: se usa para la respuesta optimista en la UI.
  QuickAlert respondedWith(AlertResponse response, DateTime at) {
    return QuickAlert(
      id: id,
      type: type,
      message: message,
      createdAt: createdAt,
      status: AlertStatus.responded,
      response: response,
      respondedAt: at,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.value,
    'message': message,
    'createdAt': createdAt.toIso8601String(),
    'status': status.value,
    'response': response?.value,
    'respondedAt': respondedAt?.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    type,
    message,
    createdAt,
    status,
    response,
    respondedAt,
  ];
}
