import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpmom_companion/features/auth/data/auth_models.dart';

void main() {
  group('AuthResponse.fromJson', () {
    test('lee el JSON del contrato', () {
      final json = jsonDecode('''
        { "user": { "id": "guid", "email": "dani@mail.com", "fullName": "Daniela Gómez", "isActive": true },
          "familyGroupId": "guid-familia", "role": "Mother", "accessToken": "eyJ..." }
      ''') as Map<String, dynamic>;

      final response = AuthResponse.fromJson(json);

      expect(response.user.id, 'guid');
      expect(response.user.email, 'dani@mail.com');
      expect(response.user.fullName, 'Daniela Gómez');
      expect(response.user.isActive, isTrue);
      expect(response.familyGroupId, 'guid-familia');
      expect(response.role, 'Mother');
      expect(response.isMother, isTrue);
      expect(response.isPartner, isFalse);
      expect(response.accessToken, 'eyJ...');
    });

    test('acepta familyGroupId null (Partner sin vincular)', () {
      final json = jsonDecode('''
        { "user": { "id": "u2", "email": "carlos@mail.com", "fullName": "Carlos Ruiz", "isActive": true },
          "familyGroupId": null, "role": "Partner", "accessToken": "eyJ..." }
      ''') as Map<String, dynamic>;

      final response = AuthResponse.fromJson(json);

      expect(response.familyGroupId, isNull);
      expect(response.isPartner, isTrue);
    });

    test('toJson vuelve al mismo objeto', () {
      const response = AuthResponse(
        user: UserDto(
          id: 'u2',
          email: 'carlos@mail.com',
          fullName: 'Carlos Ruiz',
          isActive: true,
        ),
        familyGroupId: null,
        role: 'Partner',
        accessToken: 't',
      );

      expect(AuthResponse.fromJson(response.toJson()), response);
    });
  });

  test('RegisterRequest siempre envía role "Partner"', () {
    const request = RegisterRequest(
      fullName: 'Carlos Ruiz',
      email: 'carlos@mail.com',
      password: '1234567890',
    );

    expect(request.toJson(), {
      'email': 'carlos@mail.com',
      'fullName': 'Carlos Ruiz',
      'password': '1234567890',
      'role': 'Partner',
    });
  });
}
