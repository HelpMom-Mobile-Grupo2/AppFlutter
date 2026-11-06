import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpmom_companion/features/family/data/family_models.dart';

void main() {
  group('FamilyGroup.fromJson', () {
    final json = jsonDecode('''
      { "id": "guid", "name": "Familia de Daniela Gómez",
        "members": [ { "userId": "m1", "fullName": "Daniela Gómez", "role": 1, "joinedAt": "2026-11-03T01:00:00+00:00" },
                     { "userId": "p1", "fullName": "Carlos Ruiz", "role": 3, "joinedAt": "2026-11-04T10:00:00-05:00" } ] }
    ''') as Map<String, dynamic>;

    test('lee el grupo y sus miembros con el rol numérico', () {
      final group = FamilyGroup.fromJson(json);

      expect(group.id, 'guid');
      expect(group.name, 'Familia de Daniela Gómez');
      expect(group.members, hasLength(2));
      expect(group.members[0].role, MemberRole.mother);
      expect(group.members[1].role, MemberRole.partner);
      expect(group.motherName, 'Daniela Gómez');
    });

    test('compara las fechas por su valor, no por el texto (D.11)', () {
      final joinedAt = FamilyGroup.fromJson(json).members[1].joinedAt;

      expect(joinedAt, DateTime.parse('2026-11-04T15:00:00+00:00'));
    });

    test('toJson vuelve al mismo objeto', () {
      final group = FamilyGroup.fromJson(json);

      expect(FamilyGroup.fromJson(group.toJson()), group);
    });

    test('motherName es null si no hay gestante en la lista', () {
      const group = FamilyGroup(id: 'g', name: 'Familia', members: []);

      expect(group.motherName, isNull);
    });
  });

  test('JoinFamilyResult.fromJson lee el JSON del contrato', () {
    final result = JoinFamilyResult.fromJson(
      jsonDecode('{ "familyGroupId": "guid", "motherName": "Daniela Gómez" }')
          as Map<String, dynamic>,
    );

    expect(result.familyGroupId, 'guid');
    expect(result.motherName, 'Daniela Gómez');
  });

  group('InvitationCode', () {
    test('acepta HM- y 4 dígitos, en minúsculas y con espacios', () {
      expect(InvitationCode.isValid('HM-9428'), isTrue);
      expect(InvitationCode.isValid('  hm-9428 '), isTrue);
      expect(InvitationCode.normalize('  hm-9428 '), 'HM-9428');
    });

    test('rechaza otros formatos', () {
      expect(InvitationCode.isValid(''), isFalse);
      expect(InvitationCode.isValid('HM-942'), isFalse);
      expect(InvitationCode.isValid('HM-94281'), isFalse);
      expect(InvitationCode.isValid('HM9428'), isFalse);
      expect(InvitationCode.isValid('XX-9428'), isFalse);
      expect(InvitationCode.isValid('HM-ABCD'), isFalse);
    });
  });
}
