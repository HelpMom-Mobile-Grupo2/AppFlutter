import '../../../core/api_client.dart';
import 'family_models.dart';

/// Llamadas HTTP de /api/family que usa el acompañante.
class FamilyApi {
  FamilyApi(this._client);

  final ApiClient _client;

  Future<FamilyGroup> getFamily() async {
    final json = await _client.get('/api/family');
    return FamilyGroup.fromJson(json as Map<String, dynamic>);
  }

  Future<JoinFamilyResult> join(String code) async {
    final json = await _client.post('/api/family/join', body: {'code': code});
    return JoinFamilyResult.fromJson(json as Map<String, dynamic>);
  }
}
