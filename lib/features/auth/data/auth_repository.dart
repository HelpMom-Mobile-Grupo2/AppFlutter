import '../../../core/local_db.dart';
import '../../../core/session_store.dart';
import 'auth_api.dart';
import 'auth_models.dart';

class AuthRepository {
  AuthRepository({
    required AuthApi api,
    required SessionStore session,
    required LocalDb localDb,
  }) : _api = api,
       _session = session,
       _localDb = localDb;

  final AuthApi _api;
  final SessionStore _session;
  final LocalDb _localDb;

  bool get hasSession => _session.hasSession;
  bool get termsAccepted => _session.termsAccepted;

  Future<void> acceptTerms() => _session.setTermsAccepted(true);

  /// Solo guarda la sesión si la cuenta es de acompañante.
  Future<AuthResponse> login(String email, String password) async {
    final response = await _api.login(
      LoginRequest(email: email.trim(), password: password),
    );
    await _saveIfPartner(response);
    return response;
  }

  Future<AuthResponse> register(
    String fullName,
    String email,
    String password,
  ) async {
    final response = await _api.register(
      RegisterRequest(
        fullName: fullName.trim(),
        email: email.trim(),
        password: password,
      ),
    );
    await _saveIfPartner(response);
    return response;
  }

  /// Borra la sesión, el teléfono de la madre y la caché de sqflite.
  Future<void> logout() async {
    await _session.clearSession();
    await _session.setMotherPhone(null);
    await _localDb.clear();
  }

  Future<void> _saveIfPartner(AuthResponse response) async {
    if (response.isMother) {
      throw const WrongRoleException(
        'Esta cuenta es de gestante: usa la app HelpMom para mamá',
      );
    }
    if (!response.isPartner) {
      throw const WrongRoleException('Esta cuenta no es de acompañante.');
    }
    await _session.saveSession(
      token: response.accessToken,
      userId: response.user.id,
      fullName: response.user.fullName,
      email: response.user.email,
    );
  }
}
