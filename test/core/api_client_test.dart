import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpmom_companion/core/api_client.dart';
import 'package:helpmom_companion/core/api_exception.dart';
import 'package:helpmom_companion/core/session_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SessionStore session;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    session = await SessionStore.create();
    await session.saveSession(
      token: 'abc123',
      userId: 'u1',
      fullName: 'Carlos Ruiz',
      email: 'carlos@mail.com',
    );
  });

  ApiClient buildClient(
    MockClientHandler handler, {
    Future<void> Function()? onUnauthorized,
    Duration timeout = const Duration(seconds: 60),
    Duration slowThreshold = const Duration(seconds: 3),
  }) {
    return ApiClient(
      sessionStore: session,
      httpClient: MockClient(handler),
      baseUrl: 'https://api.test/',
      onUnauthorized: onUnauthorized,
      timeout: timeout,
      slowThreshold: slowThreshold,
    );
  }

  http.Response jsonResponse(Object body, int statusCode) =>
      http.Response.bytes(
        utf8.encode(jsonEncode(body)),
        statusCode,
        headers: {'content-type': 'application/json'},
      );

  http.Response problem(int statusCode, Map<String, Object?> body) =>
      http.Response.bytes(
        utf8.encode(jsonEncode(body)),
        statusCode,
        headers: {'content-type': 'application/problem+json'},
      );

  test('agrega Bearer y JSON, y decodifica tildes en UTF-8', () async {
    late http.Request sent;
    final client = buildClient((request) async {
      sent = request;
      return jsonResponse({'motherName': 'Daniela Gómez'}, 200);
    });

    final json = await client.get('/api/companion/summary');

    expect(sent.url.toString(), 'https://api.test/api/companion/summary');
    expect(sent.headers['Authorization'], 'Bearer abc123');
    expect(sent.headers['Content-Type'], startsWith('application/json'));
    expect(json['motherName'], 'Daniela Gómez');
  });

  test('arma los query parameters y codifica el body', () async {
    late http.Request sent;
    final client = buildClient((request) async {
      sent = request;
      return http.Response('', 204);
    });

    await client.get('/api/alerts', query: {'status': 'pending'});
    expect(sent.url.toString(), 'https://api.test/api/alerts?status=pending');

    final result = await client.post(
      '/api/alerts/a1/respond',
      body: {'response': 1},
    );
    expect(jsonDecode(sent.body), {'response': 1});
    expect(result, isNull);
  });

  test('sin auth no envía el token', () async {
    late http.Request sent;
    final client = buildClient((request) async {
      sent = request;
      return jsonResponse({}, 200);
    });

    await client.post('/api/auth/login', body: {}, auth: false);

    expect(sent.headers.containsKey('Authorization'), isFalse);
  });

  test(
    'convierte ProblemDetails en ApiException con errores por campo',
    () async {
      final client = buildClient(
        (_) async => problem(400, {
          'status': 400,
          'title': 'One or more validation errors occurred.',
          'detail': 'La contraseña no es válida.',
          'errors': {
            'Password': ['La contraseña debe tener entre 10 y 128 caracteres.'],
          },
        }),
      );

      await expectLater(
        client.post('/api/auth/register', body: {}, auth: false),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having(
                (e) => e.message,
                'message',
                'La contraseña no es válida.',
              )
              .having(
                (e) => e.fieldError('password'),
                'fieldError',
                'La contraseña debe tener entre 10 y 128 caracteres.',
              ),
        ),
      );
    },
  );

  test('usa un mensaje en español si el error no trae detail', () async {
    final client = buildClient((_) async => http.Response('', 403));

    await expectLater(
      client.get('/api/family'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Esta cuenta no tiene permiso para hacer esto.',
        ),
      ),
    );
  });

  test('409 "no vinculado" se convierte en NotLinkedException', () async {
    final client = buildClient(
      (_) async => problem(409, {
        'status': 409,
        'title': 'Conflict',
        'detail': 'Aún no estás vinculado a una gestante.',
      }),
    );

    await expectLater(
      client.get('/api/companion/summary'),
      throwsA(isA<NotLinkedException>()),
    );
  });

  test('otro 409 sigue siendo ApiException con el detail', () async {
    final client = buildClient(
      (_) async => problem(409, {
        'status': 409,
        'detail': 'Esta gestante ya tiene un acompañante vinculado.',
      }),
    );

    await expectLater(
      client.post('/api/family/join', body: {'code': 'HM-1234'}),
      throwsA(
        isA<ApiException>()
            .having((e) => e is NotLinkedException, 'isNotLinked', isFalse)
            .having(
              (e) => e.message,
              'message',
              'Esta gestante ya tiene un acompañante vinculado.',
            ),
      ),
    );
  });

  test('401 con sesión borra el token y avisa con onUnauthorized', () async {
    var called = false;
    final client = buildClient(
      (_) async => http.Response('', 401),
      onUnauthorized: () async => called = true,
    );

    await expectLater(
      client.get('/api/alerts'),
      throwsA(isA<UnauthorizedException>()),
    );
    expect(called, isTrue);
    expect(session.token, isNull);
  });

  test('401 en el login no cierra la sesión', () async {
    var called = false;
    final client = buildClient(
      (_) async => http.Response('', 401),
      onUnauthorized: () async => called = true,
    );

    await expectLater(
      client.post('/api/auth/login', body: {}, auth: false),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Correo o contraseña incorrectos.',
        ),
      ),
    );
    expect(called, isFalse);
  });

  test('SocketException se convierte en NoConnectionException', () async {
    final client = buildClient(
      (_) async => throw const SocketException('Failed host lookup'),
    );

    await expectLater(
      client.get('/api/alerts'),
      throwsA(isA<NoConnectionException>()),
    );
  });

  test('si se agota el tiempo lanza NoConnectionException', () async {
    final client = buildClient((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return jsonResponse({}, 200);
    }, timeout: const Duration(milliseconds: 20));

    await expectLater(
      client.get('/api/alerts'),
      throwsA(isA<NoConnectionException>()),
    );
  });

  test('avisa "Conectando…" cuando la llamada tarda más del umbral', () async {
    final client = buildClient((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return jsonResponse({}, 200);
    }, slowThreshold: const Duration(milliseconds: 20));

    final values = <bool>[];
    client.isWakingServer.addListener(
      () => values.add(client.isWakingServer.value),
    );

    await client.get('/api/family');

    expect(values, [true, false]);
  });
}
