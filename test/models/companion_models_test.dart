import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpmom_companion/features/companion/data/companion_summary.dart';
import 'package:helpmom_companion/features/companion/data/daily_tip.dart';

Map<String, dynamic> _decode(String source) =>
    jsonDecode(source) as Map<String, dynamic>;

void main() {
  group('CompanionSummary.fromJson', () {
    test('lee los seis campos del contrato', () {
      final summary = CompanionSummary.fromJson(
        _decode('''
        { "motherName": "Daniela Gómez", "gestationalWeeks": 25, "gestationalDays": 1,
          "healthLight": 1, "healthSummary": "Valores dentro del rango de referencia simulado.",
          "measuredAt": "2026-11-03T01:00:00+00:00" }
      '''),
      );

      expect(summary.motherName, 'Daniela Gómez');
      expect(summary.gestationalWeeks, 25);
      expect(summary.gestationalDays, 1);
      expect(summary.healthLight, HealthLight.green);
      expect(
        summary.healthSummary,
        'Valores dentro del rango de referencia simulado.',
      );
      expect(summary.measuredAt, DateTime.utc(2026, 11, 3, 1));
    });

    test('acepta los null de D.2 (sin embarazo ni mediciones)', () {
      final summary = CompanionSummary.fromJson(
        _decode('''
        { "motherName": "Daniela Gómez", "gestationalWeeks": null, "gestationalDays": null,
          "healthLight": null, "healthSummary": null, "measuredAt": null }
      '''),
      );

      expect(summary.motherName, 'Daniela Gómez');
      expect(summary.gestationalWeeks, isNull);
      expect(summary.gestationalDays, isNull);
      expect(summary.healthLight, isNull);
      expect(summary.healthSummary, isNull);
      expect(summary.measuredAt, isNull);
    });

    test('mapea healthLight 1/2/3 a Verde/Amarillo/Rojo', () {
      expect(HealthLight.fromValue(1).label, 'Verde');
      expect(HealthLight.fromValue(2).label, 'Amarillo');
      expect(HealthLight.fromValue(3).label, 'Rojo');
      expect(() => HealthLight.fromValue(9), throwsFormatException);
    });

    test('toJson vuelve al mismo objeto', () {
      final summary = CompanionSummary(
        motherName: 'Daniela Gómez',
        gestationalWeeks: 25,
        gestationalDays: 1,
        healthLight: HealthLight.red,
        healthSummary: 'Revisa con tu médico.',
        measuredAt: DateTime.utc(2026, 11, 3, 1),
      );

      expect(CompanionSummary.fromJson(summary.toJson()), summary);
    });
  });

  test('DailyTip.fromJson lee el JSON del contrato', () {
    final tip = DailyTip.fromJson(
      _decode('''
      { "id": "guid", "title": "Evita que cargue peso o paquetes", "body": "Desde el segundo trimestre...", "done": false }
    '''),
    );

    expect(tip.id, 'guid');
    expect(tip.title, 'Evita que cargue peso o paquetes');
    expect(tip.body, 'Desde el segundo trimestre...');
    expect(tip.done, isFalse);
    expect(DailyTip.fromJson(tip.toJson()), tip);
  });
}
