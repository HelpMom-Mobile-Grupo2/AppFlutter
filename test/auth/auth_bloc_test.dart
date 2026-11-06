import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpmom_companion/core/api_client.dart';
import 'package:helpmom_companion/core/local_db.dart';
import 'package:helpmom_companion/core/session_store.dart';
import 'package:helpmom_companion/features/auth/bloc/auth_bloc.dart';
import 'package:helpmom_companion/features/auth/data/auth_api.dart';
import 'package:helpmom_companion/features/auth/data/auth_repository.dart';
import 'package:helpmom_companion/features/family/data/family_api.dart';
import 'package:helpmom_companion/features/family/data/family_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _json(Object body, int statusCode) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  statusCode,
  headers: {'content-type': 'application/json'},
);

Map<String, Object?> _authJson({required String role, String? familyGroupId}) {
  return {
    'user': {
      'id': 'u1',
      'email': 'carlos@mail.com',
      'fullName': 'Carlos Ruiz',
      'isActive': true,
    },
    'familyGroupId': familyGroupId,
    'role': role,
    'accessToken': 'token-123',
  };
}

void main() {
  late SessionStore session;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    session = await SessionStore.create();
  });

  AuthBloc buildBloc(MockClientHandler handler) {
    final client = ApiClient(
      sessionStore: session,
      httpClient: MockClient(handler),
      baseUrl: 'https://api.test/',
    );
    return AuthBloc(
      authRepository: AuthRepository(
        api: AuthApi(client),
        session: session,
        localDb: LocalDb(),
      ),
      familyRepository: FamilyRepository(api: FamilyApi(client)),
    );
  }

  group('AuthCheckRequested (Splash)', () {
    test('sin T&C aceptados pide los términos', () async {
      final bloc = buildBloc((_) async => throw StateError('no debe llamar'));

      final expectation = expectLater(
        bloc.stream,
        emits(const AuthTermsRequired()),
      );
      bloc.add(const AuthCheckRequested());
      await expectation;
      await bloc.close();
    });

    test('sin token va al login', () async {
      await session.setTermsAccepted(true);
      final bloc = buildBloc((_) async => throw StateError('no debe llamar'));

      final expectation = expectLater(
        bloc.stream,
        emits(const AuthUnauthenticated()),
      );
      bloc.add(const AuthCheckRequested());
      await expectation;
      await bloc.close();
    });

    test('con token y GET /api/family 404 va a Vincular', () async {
      await session.setTermsAccepted(true);
      await session.saveSession(
        token: 't',
        userId: 'u1',
        fullName: 'Carlos Ruiz',
        email: 'carlos@mail.com',
      );
      final bloc = buildBloc((request) async {
        expect(request.url.path, '/api/family');
        return http.Response('', 404);
      });

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([const AuthLoading(), const AuthNotLinked()]),
      );
      bloc.add(const AuthCheckRequested());
      await expectation;
      await bloc.close();
    });
  });

  group('AuthLoginSubmitted', () {
    test('Partner sin vincular guarda la sesión y va a Vincular', () async {
      final bloc = buildBloc(
        (_) async => _json(_authJson(role: 'Partner'), 200),
      );

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([const AuthLoading(), const AuthNotLinked()]),
      );
      bloc.add(
        const AuthLoginSubmitted(
          email: 'carlos@mail.com',
          password: '1234567890',
        ),
      );
      await expectation;

      expect(session.token, 'token-123');
      expect(session.fullName, 'Carlos Ruiz');
      await bloc.close();
    });

    test('Partner vinculado va a Inicio', () async {
      final bloc = buildBloc(
        (_) async =>
            _json(_authJson(role: 'Partner', familyGroupId: 'fam-1'), 200),
      );

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([const AuthLoading(), const AuthLinked()]),
      );
      bloc.add(
        const AuthLoginSubmitted(email: 'c@mail.com', password: '1234567890'),
      );
      await expectation;
      await bloc.close();
    });

    test('una cuenta Mother muestra el aviso y no guarda la sesión', () async {
      final bloc = buildBloc(
        (_) async =>
            _json(_authJson(role: 'Mother', familyGroupId: 'fam-1'), 200),
      );

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          const AuthLoading(),
          const AuthFailure(
            'Esta cuenta es de gestante: usa la app HelpMom para mamá',
            action: AuthAction.login,
          ),
        ]),
      );
      bloc.add(
        const AuthLoginSubmitted(email: 'd@mail.com', password: '1234567890'),
      );
      await expectation;

      expect(session.hasSession, isFalse);
      await bloc.close();
    });
  });

  test(
    'AuthRegisterSubmitted pasa los errores de validación por campo',
    () async {
      final bloc = buildBloc(
        (_) async => _json({
          'status': 400,
          'title': 'One or more validation errors occurred.',
          'errors': {
            'Email': ['El correo ya está registrado.'],
          },
        }, 400),
      );

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          const AuthLoading(),
          const AuthFailure(
            'Revisa los datos ingresados.',
            action: AuthAction.register,
            fieldErrors: {'email': 'El correo ya está registrado.'},
          ),
        ]),
      );
      bloc.add(
        const AuthRegisterSubmitted(
          fullName: 'Carlos Ruiz',
          email: 'carlos@mail.com',
          password: '1234567890',
        ),
      );
      await expectation;
      await bloc.close();
    },
  );
}
