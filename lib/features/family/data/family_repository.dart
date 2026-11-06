import '../../../core/api_exception.dart';
import 'family_api.dart';
import 'family_models.dart';

class FamilyRepository {
  FamilyRepository({required this._api});

  final FamilyApi _api;

  /// Grupo familiar del acompañante, o null si aún no está vinculado (404).
  Future<FamilyGroup?> getFamily() async {
    try {
      return await _api.getFamily();
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<JoinFamilyResult> join(String code) =>
      _api.join(InvitationCode.normalize(code));
}
