import 'package:equatable/equatable.dart';

/// Semáforo de salud: llega como número (1, 2 o 3).
enum HealthLight {
  green(1, 'Verde'),
  yellow(2, 'Amarillo'),
  red(3, 'Rojo');

  const HealthLight(this.value, this.label);

  final int value;
  final String label;

  static HealthLight fromValue(int value) => HealthLight.values.firstWhere(
    (light) => light.value == value,
    orElse: () => throw FormatException('healthLight desconocido: $value'),
  );
}

/// Resumen para el acompañante. Nunca trae valores clínicos ni síntomas.
class CompanionSummary extends Equatable {
  const CompanionSummary({
    required this.motherName,
    this.gestationalWeeks,
    this.gestationalDays,
    this.healthLight,
    this.healthSummary,
    this.measuredAt,
  });

  factory CompanionSummary.fromJson(Map<String, dynamic> json) {
    final light = json['healthLight'] as int?;
    final measuredAt = json['measuredAt'] as String?;
    return CompanionSummary(
      motherName: json['motherName'] as String,
      gestationalWeeks: json['gestationalWeeks'] as int?,
      gestationalDays: json['gestationalDays'] as int?,
      healthLight: light == null ? null : HealthLight.fromValue(light),
      healthSummary: json['healthSummary'] as String?,
      measuredAt: measuredAt == null ? null : DateTime.parse(measuredAt),
    );
  }

  final String motherName;

  /// null si la gestante aún no registró su embarazo (D.2).
  final int? gestationalWeeks;
  final int? gestationalDays;

  /// null si aún no hay mediciones (D.2).
  final HealthLight? healthLight;
  final String? healthSummary;
  final DateTime? measuredAt;

  Map<String, dynamic> toJson() => {
    'motherName': motherName,
    'gestationalWeeks': gestationalWeeks,
    'gestationalDays': gestationalDays,
    'healthLight': healthLight?.value,
    'healthSummary': healthSummary,
    'measuredAt': measuredAt?.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    motherName,
    gestationalWeeks,
    gestationalDays,
    healthLight,
    healthSummary,
    measuredAt,
  ];
}
