import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api_exception.dart';
import '../../../core/app_routes.dart';
import '../../family/data/family_repository.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Ruta a la que lleva cada estado de sesión, o null si hay que quedarse.
String? routeForAuthState(AuthState state) => switch (state) {
  AuthTermsRequired() => AppRoutes.terms,
  AuthUnauthenticated() => AppRoutes.login,
  AuthLinked() => AppRoutes.home,
  AuthNotLinked() => AppRoutes.link,
  _ => null,
};

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepository authRepository,
    required FamilyRepository familyRepository,
  }) : _auth = authRepository,
       _family = familyRepository,
       super(const AuthInitial()) {
    on<AuthCheckRequested>((event, emit) => _check(emit));
    on<AuthTermsAccepted>(_onTermsAccepted);
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthRegisterSubmitted>(_onRegisterSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final AuthRepository _auth;
  final FamilyRepository _family;

  Future<void> _check(Emitter<AuthState> emit) async {
    if (!_auth.termsAccepted) return emit(const AuthTermsRequired());
    if (!_auth.hasSession) return emit(const AuthUnauthenticated());

    emit(const AuthLoading());
    try {
      final family = await _family.getFamily();
      emit(family == null ? const AuthNotLinked() : const AuthLinked());
    } on UnauthorizedException {
      // El ApiClient ya borró la sesión y llevó al login.
    } on NoConnectionException {
      // Sin internet entramos igual: Inicio y Alertas muestran lo guardado.
      emit(const AuthLinked());
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    }
  }

  Future<void> _onTermsAccepted(
    AuthTermsAccepted event,
    Emitter<AuthState> emit,
  ) async {
    await _auth.acceptTerms();
    await _check(emit);
  }

  Future<void> _onLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) {
    return _authenticate(
      emit,
      AuthAction.login,
      () => _auth.login(event.email, event.password),
    );
  }

  Future<void> _onRegisterSubmitted(
    AuthRegisterSubmitted event,
    Emitter<AuthState> emit,
  ) {
    return _authenticate(
      emit,
      AuthAction.register,
      () => _auth.register(event.fullName, event.email, event.password),
    );
  }

  Future<void> _authenticate(
    Emitter<AuthState> emit,
    AuthAction action,
    Future<AuthResponse> Function() request,
  ) async {
    emit(const AuthLoading());
    try {
      final response = await request();
      // El login devuelve el familyGroupId real (D.5): null = sin vincular.
      emit(
        response.familyGroupId == null
            ? const AuthNotLinked()
            : const AuthLinked(),
      );
    } on WrongRoleException catch (e) {
      emit(AuthFailure(e.message, action: action));
    } on ApiException catch (e) {
      emit(
        AuthFailure(e.message, action: action, fieldErrors: _fieldErrors(e)),
      );
    } on NoConnectionException catch (e) {
      emit(AuthFailure(e.message, action: action));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _auth.logout();
    emit(const AuthUnauthenticated());
  }

  Map<String, String> _fieldErrors(ApiException e) {
    final result = <String, String>{};
    for (final field in const ['fullName', 'email', 'password']) {
      final error = e.fieldError(field);
      if (error != null) result[field] = error;
    }
    return result;
  }
}
