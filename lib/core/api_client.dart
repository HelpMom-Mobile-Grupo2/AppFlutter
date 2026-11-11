import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'app_config.dart';
import 'session_store.dart';

/// Único cliente HTTP de la app. Agrega el token, convierte los errores en
/// excepciones y avisa cuando el servidor tarda en despertar.
class ApiClient {
  ApiClient({
    required SessionStore sessionStore,
    http.Client? httpClient,
    this.baseUrl = AppConfig.baseUrl,
    this.onUnauthorized,
    this.timeout = const Duration(seconds: 60),
    this.slowThreshold = const Duration(seconds: 3),
  }) : _session = sessionStore,
       _http = httpClient ?? http.Client();

  final SessionStore _session;
  final http.Client _http;
  final String baseUrl;

  /// Se llama cuando el backend responde 401 con la sesión iniciada, después
  /// de borrar el token. En main.dart navega al login.
  final Future<void> Function()? onUnauthorized;

  /// Render (plan gratis) tarda hasta ~50 s en despertar.
  final Duration timeout;

  /// Desde cuándo se muestra "Conectando con el servidor…".
  final Duration slowThreshold;

  /// true mientras alguna llamada lleva más de [slowThreshold].
  final isWakingServer = ValueNotifier<bool>(false);
  int _slowRequests = 0;

  /// [auth] en false para login y registro: ahí no hay token y un 401 solo
  /// significa credenciales incorrectas.
  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) => _send('GET', path, query: query, auth: auth);

  Future<dynamic> post(String path, {Object? body, bool auth = true}) =>
      _send('POST', path, body: body, auth: auth);

  Future<dynamic> delete(String path) => _send('DELETE', path, auth: true);

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    required bool auth,
  }) async {
    final uri = Uri.parse(baseUrl)
        .resolve(path)
        .replace(queryParameters: query);

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = _session.token;
    if (auth && token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    var isSlow = false;
    final slowTimer = Timer(slowThreshold, () {
      isSlow = true;
      _changeSlowRequests(1);
    });

    final http.Response response;
    try {
      final request = switch (method) {
        'GET' => _http.get(uri, headers: headers),
        'DELETE' => _http.delete(uri, headers: headers),
        _ => _http.post(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        ),
      };
      response = await request.timeout(timeout);
    } on SocketException {
      throw const NoConnectionException();
    } on http.ClientException {
      throw const NoConnectionException();
    } on TimeoutException {
      throw const NoConnectionException(
        'El servidor tardó demasiado en responder. Intenta de nuevo.',
      );
    } finally {
      slowTimer.cancel();
      if (isSlow) _changeSlowRequests(-1);
    }

    return _handleResponse(response, auth);
  }

  Future<dynamic> _handleResponse(http.Response response, bool auth) async {
    final statusCode = response.statusCode;
    // bodyBytes + utf8: así las tildes y la ñ llegan bien aunque el servidor
    // no indique el charset.
    final text = utf8.decode(response.bodyBytes);

    if (statusCode >= 200 && statusCode < 300) {
      return text.isEmpty ? null : jsonDecode(text);
    }

    if (statusCode == 401 && auth) {
      await _session.clearSession();
      await onUnauthorized?.call();
      throw const UnauthorizedException();
    }

    throw ApiException.fromResponse(statusCode, text);
  }

  void _changeSlowRequests(int delta) {
    _slowRequests += delta;
    isWakingServer.value = _slowRequests > 0;
  }
}
