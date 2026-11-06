import '../../../core/api_client.dart';
import 'alert_model.dart';

/// Llamadas HTTP de /api/alerts.
class AlertsApi {
  AlertsApi(this._client);

  final ApiClient _client;

  /// Sin filtro el backend devuelve todas (`all`, D.3).
  Future<List<QuickAlert>> getAlerts({bool pendingOnly = false}) async {
    final json = await _client.get(
      '/api/alerts',
      query: pendingOnly ? {'status': 'pending'} : null,
    );
    return (json as List)
        .map((alert) => QuickAlert.fromJson(alert as Map<String, dynamic>))
        .toList();
  }

  Future<QuickAlert> respond(String alertId, AlertResponse response) async {
    final json = await _client.post(
      '/api/alerts/$alertId/respond',
      body: {'response': response.value},
    );
    return QuickAlert.fromJson(json as Map<String, dynamic>);
  }
}
