import 'package:equatable/equatable.dart';

/// `role` dentro de `members` llega como número: 1 Mother, 2 Doctor, 3 Partner.
enum MemberRole {
  mother(1),
  doctor(2),
  partner(3);

  const MemberRole(this.value);

  final int value;

  static MemberRole fromValue(int value) => MemberRole.values.firstWhere(
    (role) => role.value == value,
    orElse: () => throw FormatException('Rol de miembro desconocido: $value'),
  );
}

class FamilyMember extends Equatable {
  const FamilyMember({
    required this.userId,
    required this.fullName,
    required this.role,
    required this.joinedAt,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      userId: json['userId'] as String,
      fullName: json['fullName'] as String,
      role: MemberRole.fromValue(json['role'] as int),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }

  final String userId;
  final String fullName;
  final MemberRole role;
  final DateTime joinedAt;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'fullName': fullName,
    'role': role.value,
    'joinedAt': joinedAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [userId, fullName, role, joinedAt];
}

class FamilyGroup extends Equatable {
  const FamilyGroup({
    required this.id,
    required this.name,
    required this.members,
  });

  factory FamilyGroup.fromJson(Map<String, dynamic> json) {
    return FamilyGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      members: (json['members'] as List)
          .map((m) => FamilyMember.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String name;
  final List<FamilyMember> members;

  /// Nombre de la gestante del grupo, o null si no aparece.
  String? get motherName {
    for (final member in members) {
      if (member.role == MemberRole.mother) return member.fullName;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'members': members.map((m) => m.toJson()).toList(),
  };

  @override
  List<Object?> get props => [id, name, members];
}

/// Respuesta de POST /api/family/join.
class JoinFamilyResult extends Equatable {
  const JoinFamilyResult({
    required this.familyGroupId,
    required this.motherName,
  });

  factory JoinFamilyResult.fromJson(Map<String, dynamic> json) {
    return JoinFamilyResult(
      familyGroupId: json['familyGroupId'] as String,
      motherName: json['motherName'] as String,
    );
  }

  final String familyGroupId;
  final String motherName;

  Map<String, dynamic> toJson() => {
    'familyGroupId': familyGroupId,
    'motherName': motherName,
  };

  @override
  List<Object?> get props => [familyGroupId, motherName];
}

/// Código de invitación: "HM-" y 4 dígitos. El backend acepta minúsculas y
/// espacios alrededor (D.8), así que la app lo normaliza antes de validar.
class InvitationCode {
  InvitationCode._();

  static final _pattern = RegExp(r'^HM-\d{4}$');

  static String normalize(String raw) => raw.trim().toUpperCase();

  static bool isValid(String raw) => _pattern.hasMatch(normalize(raw));
}
