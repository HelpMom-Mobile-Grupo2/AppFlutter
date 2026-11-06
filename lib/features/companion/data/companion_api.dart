import '../../../core/api_client.dart';
import 'companion_summary.dart';
import 'daily_tip.dart';

/// Llamadas HTTP de /api/companion (solo rol Partner).
class CompanionApi {
  CompanionApi(this._client);

  final ApiClient _client;

  Future<CompanionSummary> getSummary() async {
    final json = await _client.get('/api/companion/summary');
    return CompanionSummary.fromJson(json as Map<String, dynamic>);
  }

  Future<List<DailyTip>> getTodayTips() async {
    final json = await _client.get('/api/companion/tips/today');
    return (json as List)
        .map((tip) => DailyTip.fromJson(tip as Map<String, dynamic>))
        .toList();
  }

  /// 204 sin cuerpo. Es idempotente: marcarlo dos veces no falla.
  Future<void> markTipDone(String tipId) async {
    await _client.post('/api/companion/tips/$tipId/done');
  }
}
