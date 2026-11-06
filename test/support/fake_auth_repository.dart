import 'package:helpmom_companion/core/local_db.dart';
import 'package:helpmom_companion/core/session_store.dart';
import 'package:helpmom_companion/features/auth/data/auth_api.dart';
import 'package:helpmom_companion/features/auth/data/auth_models.dart';
import 'package:helpmom_companion/features/auth/data/auth_repository.dart';

/// Repositorio de prueba para cerrar sesión sin tocar sqflite.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this.store);

  /// Sesión real (shared_preferences simulado) que borra el logout.
  final SessionStore store;
  var logoutCalls = 0;

  // El fake no usa la API ni sqflite.
  @override
  AuthApi get api => throw UnimplementedError();

  @override
  LocalDb get localDb => throw UnimplementedError();

  @override
  SessionStore get session => store;

  @override
  bool get hasSession => store.hasSession;

  @override
  bool get termsAccepted => store.termsAccepted;

  @override
  Future<void> acceptTerms() => store.setTermsAccepted(true);

  @override
  Future<AuthResponse> login(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<AuthResponse> register(
    String fullName,
    String email,
    String password,
  ) => throw UnimplementedError();

  @override
  Future<void> logout() async {
    logoutCalls++;
    await store.clearSession();
    await store.setMotherPhone(null);
  }
}
