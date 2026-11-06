import '../../../core/api_client.dart';
import 'auth_models.dart';

/// Llamadas HTTP de /api/auth. Login y registro van sin token.
class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<AuthResponse> login(LoginRequest request) async {
    final json = await _client.post(
      '/api/auth/login',
      body: request.toJson(),
      auth: false,
    );
    return AuthResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    final json = await _client.post(
      '/api/auth/register',
      body: request.toJson(),
      auth: false,
    );
    return AuthResponse.fromJson(json as Map<String, dynamic>);
  }
}
