import 'dart:convert';

/// Error que devolvió el backend (ProblemDetails). [message] ya está listo
/// para mostrarse al usuario.
class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
    this.errors = const {},
  });

  /// Lee el cuerpo `application/problem+json`:
  /// `{ "status", "title", "detail", "errors": { "Password": ["..."] } }`.
  factory ApiException.fromResponse(int statusCode, String body) {
    String? detail;
    var errors = <String, List<String>>{};

    if (body.isNotEmpty) {
      try {
        final json = jsonDecode(body);
        if (json is Map<String, dynamic>) {
          detail = json['detail'] as String?;
          final rawErrors = json['errors'];
          if (rawErrors is Map<String, dynamic>) {
            errors = rawErrors.map(
              (field, messages) => MapEntry(
                field,
                (messages as List).map((m) => m.toString()).toList(),
              ),
            );
          }
        }
      } on FormatException {
        // El cuerpo no era JSON: nos quedamos con el mensaje por defecto.
      }
    }

    if (statusCode == 409 && detail == NotLinkedException.backendDetail) {
      return const NotLinkedException();
    }

    return ApiException(
      statusCode: statusCode,
      message: detail ?? _defaultMessage(statusCode),
      errors: errors,
    );
  }

  final int statusCode;
  final String message;

  /// Errores de validación por campo (solo en los 400).
  final Map<String, List<String>> errors;

  /// Primer error del campo [field], sin importar mayúsculas
  /// ("password" encuentra "Password").
  String? fieldError(String field) {
    final wanted = field.toLowerCase();
    for (final entry in errors.entries) {
      final key = entry.key.toLowerCase();
      if ((key == wanted || key.endsWith('.$wanted')) &&
          entry.value.isNotEmpty) {
        return entry.value.first;
      }
    }
    return null;
  }

  static String _defaultMessage(int statusCode) {
    if (statusCode >= 500) {
      return 'El servidor tuvo un problema. Intenta más tarde.';
    }
    return switch (statusCode) {
      400 => 'Revisa los datos ingresados.',
      401 => 'Correo o contraseña incorrectos.',
      403 => 'Esta cuenta no tiene permiso para hacer esto.',
      404 => 'No encontramos lo que buscabas.',
      409 => 'No se pudo completar la acción.',
      _ => 'Ocurrió un error inesperado (código $statusCode).',
    };
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// 409 de summary, tips o alerts cuando el acompañante aún no está
/// vinculado (D.7 del contrato). La app lo manda a la pantalla Vincular.
class NotLinkedException extends ApiException {
  const NotLinkedException() : super(statusCode: 409, message: backendDetail);

  static const backendDetail = 'Aún no estás vinculado a una gestante.';
}

/// 401 con sesión iniciada: el token venció o no es válido.
class UnauthorizedException extends ApiException {
  const UnauthorizedException()
    : super(statusCode: 401, message: 'Tu sesión expiró. Vuelve a ingresar.');
}

/// No hubo respuesta del servidor: sin internet o se agotó el tiempo.
class NoConnectionException implements Exception {
  const NoConnectionException([
    this.message = 'Sin conexión a internet. Revisa tu red e intenta de nuevo.',
  ]);

  final String message;

  @override
  String toString() => 'NoConnectionException: $message';
}
