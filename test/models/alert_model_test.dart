import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpmom_companion/features/alerts/data/alert_model.dart';

Map<String, dynamic> _decode(String source) =>
    jsonDecode(source) as Map<String, dynamic>;

void main() {
  test('QuickAlert.fromJson lee una alerta pendiente (response null)', () {
    final alert = QuickAlert.fromJson(
      _decode('''
      { "id": "guid", "type": 2, "message": "Siento mucho cansancio y molestia lumbar, ¿puedes ayudarme con la cena hoy?",
        "createdAt": "2026-11-04T10:00:00-05:00", "status": 1, "response": null, "respondedAt": null }
    '''),
    );

    expect(alert.id, 'guid');
    expect(alert.type, AlertType.tiredOrPain);
    expect(alert.message, startsWith('Siento mucho cansancio'));
    expect(alert.createdAt, DateTime.utc(2026, 11, 4, 15));
    expect(alert.status, AlertStatus.pending);
    expect(alert.isPending, isTrue);
    expect(alert.response, isNull);
    expect(alert.respondedAt, isNull);
  });

  test('QuickAlert.fromJson lee una SOS respondida', () {
    final alert = QuickAlert.fromJson(
      _decode('''
      { "id": "s1", "type": 4, "message": "Alerta automática: la medición de salud salió en rojo",
        "createdAt": "2026-11-04T15:00:00+00:00", "status": 2, "response": 1,
        "respondedAt": "2026-11-04T15:02:00+00:00" }
    '''),
    );

    expect(alert.isSos, isTrue);
    expect(alert.status, AlertStatus.responded);
    expect(alert.response, AlertResponse.onMyWay);
    expect(alert.respondedAt, DateTime.utc(2026, 11, 4, 15, 2));
  });

  test('toJson vuelve al mismo objeto', () {
    final alert = QuickAlert(
      id: 'a1',
      type: AlertType.craving,
      message: 'Tengo un antojo',
      createdAt: DateTime.utc(2026, 11, 6, 12),
      status: AlertStatus.responded,
      response: AlertResponse.done,
      respondedAt: DateTime.utc(2026, 11, 6, 12, 5),
    );

    expect(QuickAlert.fromJson(alert.toJson()), alert);
  });

  test('mapea los enums numéricos a textos en español', () {
    expect(AlertType.fromValue(1).label, 'Antojo');
    expect(AlertType.fromValue(2).label, 'Cansancio o dolor');
    expect(AlertType.fromValue(3).label, 'Ven un momento');
    expect(AlertType.fromValue(4).label, 'SOS');
    expect(AlertStatus.fromValue(1).label, 'Pendiente');
    expect(AlertStatus.fromValue(2).label, 'Respondida');
    expect(AlertResponse.fromValue(1).label, 'Voy en camino');
    expect(AlertResponse.fromValue(2).label, 'Te llamo ahora');
    expect(AlertResponse.fromValue(3).label, 'Ya me encargué');
  });

  group('sosReason', () {
    QuickAlert alertWith(AlertType type, String message) => QuickAlert(
      id: 'a1',
      type: type,
      message: message,
      createdAt: DateTime.utc(2026, 11, 6, 12),
      status: AlertStatus.pending,
    );

    test('SOS del asistente: devuelve la señal detectada', () {
      final alert = alertWith(
        AlertType.sos,
        'Alerta automática: el asistente detectó una posible emergencia: '
        'sangrado abundante',
      );

      expect(alert.sosReason, 'sangrado abundante');
    });

    test('SOS por la medición en rojo', () {
      final alert = alertWith(
        AlertType.sos,
        'Alerta automática: la medición de salud salió en rojo',
      );

      expect(alert.sosReason, 'Medición de salud en rojo');
    });

    test('null si la madre envió la SOS a mano o si no es SOS', () {
      expect(
        alertWith(
          AlertType.sos,
          'Necesito ayuda urgente. Comunícate conmigo ahora.',
        ).sosReason,
        isNull,
      );
      expect(
        alertWith(
          AlertType.tiredOrPain,
          'Alerta automática: la medición de salud salió en rojo',
        ).sosReason,
        isNull,
      );
    });
  });
}
