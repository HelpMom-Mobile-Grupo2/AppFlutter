part of 'auth_bloc.dart';

/// Qué formulario produjo el error, para mostrarlo solo en esa pestaña.
enum AuthAction { login, register }

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Aún no aceptó los términos y condiciones.
final class AuthTermsRequired extends AuthState {
  const AuthTermsRequired();
}

/// Sin sesión: va al login.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Con sesión y vinculado a una gestante: va a Inicio.
final class AuthLinked extends AuthState {
  const AuthLinked();
}

/// Con sesión, pero sin vincular: va a Vincular.
final class AuthNotLinked extends AuthState {
  const AuthNotLinked();
}

final class AuthFailure extends AuthState {
  const AuthFailure(this.message, {this.action, this.fieldErrors = const {}});

  final String message;
  final AuthAction? action;

  /// Errores del backend por campo: 'fullName', 'email' o 'password'.
  final Map<String, String> fieldErrors;

  @override
  List<Object?> get props => [message, action, fieldErrors];
}
