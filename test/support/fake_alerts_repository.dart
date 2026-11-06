import 'package:helpmom_companion/features/alerts/data/alert_model.dart';
import 'package:helpmom_companion/features/alerts/data/alerts_repository.dart';

/// Alerta de ejemplo creada [minutesAgo] minutos antes de [baseTime].
QuickAlert buildAlert({
  String id = 'a1',
  AlertType type = AlertType.tiredOrPain,
  String message = 'Siento mucho cansancio, ¿puedes ayudarme con la cena hoy?',
  int minutesAgo = 5,
  AlertStatus status = AlertStatus.pending,
  AlertResponse? response,
}) {
  return QuickAlert(
    id: id,
    type: type,
    message: message,
    createdAt: baseTime.subtract(Duration(minutes: minutesAgo)),
    status: status,
    response: response,
    respondedAt: response == null ? null : baseTime,
  );
}

final baseTime = DateTime.utc(2026, 11, 6, 15);

/// Repositorio de prueba: guarda las alertas en memoria y puede fallar a
/// pedido (fetchError y respondError).
class FakeAlertsRepository implements AlertsRepository {
  FakeAlertsRepository({List<QuickAlert> alerts = const []})
    : alerts = [...alerts];

  List<QuickAlert> alerts;
  List<QuickAlert> cached = [];

  /// Si no es null, fetchAll y fetchPending lanzan este error.
  Object? fetchError;

  /// Si no es null, respond lanza este error.
  Object? respondError;

  int fetchAllCalls = 0;
  int fetchPendingCalls = 0;
  final respondCalls = <(String, AlertResponse)>[];

  @override
  Future<List<QuickAlert>> fetchAll() async {
    fetchAllCalls++;
    if (fetchError != null) throw fetchError!;
    return [...alerts];
  }

  @override
  Future<List<QuickAlert>> fetchPending() async {
    fetchPendingCalls++;
    if (fetchError != null) throw fetchError!;
    return alerts.where((alert) => alert.isPending).toList();
  }

  @override
  Future<List<QuickAlert>> cachedAlerts() async => [...cached];

  @override
  Future<QuickAlert> respond(String alertId, AlertResponse response) async {
    respondCalls.add((alertId, response));
    if (respondError != null) throw respondError!;
    final updated = alerts
        .firstWhere((alert) => alert.id == alertId)
        .respondedWith(response, baseTime);
    alerts = [
      for (final alert in alerts) alert.id == alertId ? updated : alert,
    ];
    return updated;
  }
}
