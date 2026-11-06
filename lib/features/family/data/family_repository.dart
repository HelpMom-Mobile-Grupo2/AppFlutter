import '../../../core/api_exception.dart';
import 'family_api.dart';
import 'family_models.dart';

class FamilyRepository {
  FamilyRepository({required this.api});

  final FamilyApi api;

  /// Grupo familiar del acompañante, o null si aún no está vinculado (404).
  Future<FamilyGroup?> getFamily() async {
    try {
      return await api.getFamily();
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<JoinFamilyResult> join(String code) =>
      api.join(InvitationCode.normalize(code));
}
