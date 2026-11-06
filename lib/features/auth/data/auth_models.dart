import 'package:equatable/equatable.dart';

class UserDto extends Equatable {
  const UserDto({
    required this.id,
    required this.email,
    required this.fullName,
    required this.isActive,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      isActive: json['isActive'] as bool,
    );
  }

  final String id;
  final String email;
  final String fullName;
  final bool isActive;

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'fullName': fullName,
    'isActive': isActive,
  };

  @override
  List<Object?> get props => [id, email, fullName, isActive];
}

/// Respuesta de login y registro. Aquí `role` llega como texto
/// ("Mother", "Partner" o "Doctor"), no como número.
class AuthResponse extends Equatable {
  const AuthResponse({
    required this.user,
    required this.familyGroupId,
    required this.role,
    required this.accessToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
      familyGroupId: json['familyGroupId'] as String?,
      role: json['role'] as String,
      accessToken: json['accessToken'] as String,
    );
  }

  static const partnerRole = 'Partner';
  static const motherRole = 'Mother';

  final UserDto user;

  /// null si es un acompañante que aún no se vinculó.
  final String? familyGroupId;
  final String role;
  final String accessToken;

  bool get isPartner => role == partnerRole;
  bool get isMother => role == motherRole;

  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'familyGroupId': familyGroupId,
    'role': role,
    'accessToken': accessToken,
  };

  @override
  List<Object?> get props => [user, familyGroupId, role, accessToken];
}

class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class RegisterRequest {
  const RegisterRequest({
    required this.fullName,
    required this.email,
    required this.password,
  });

  final String fullName;
  final String email;
  final String password;

  /// Esta app solo crea cuentas de acompañante.
  Map<String, dynamic> toJson() => {
    'email': email,
    'fullName': fullName,
    'password': password,
    'role': AuthResponse.partnerRole,
  };
}

/// La cuenta existe, pero no es de acompañante.
class WrongRoleException implements Exception {
  const WrongRoleException(this.message);

  final String message;

  @override
  String toString() => 'WrongRoleException: $message';
}
