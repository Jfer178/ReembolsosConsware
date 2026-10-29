import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/session.dart';
import 'reimbursement_api_service.dart';

/// Dónde se guarda la sesión entre aperturas de la app.
abstract class SessionStorage {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

/// Almacenamiento cifrado del sistema (Keychain en iOS, almacenamiento cifrado en Android).
class SecureSessionStorage implements SessionStorage {
  static const _key = 'consware_session';
  final _storage = const FlutterSecureStorage();

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

class AuthService {
  AuthService({http.Client? client, SessionStorage? storage})
      : _client = client ?? http.Client(),
        _storage = storage ?? SecureSessionStorage();

  final http.Client _client;
  final SessionStorage _storage;

  Session? _session;
  Session? get session => _session;
  String? get token => _session?.token;

  /// Recupera la sesión guardada si sigue vigente.
  Future<Session?> restore() async {
    try {
      final raw = await _storage.read();
      if (raw == null) return null;
      final session = Session.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (session.isExpired || !session.isEmployee) {
        await _storage.clear();
        return null;
      }
      return _session = session;
    } on Exception {
      await logout();
      return null;
    }
  }

  Future<Session> login(String username, String password) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(ApiConfig.loginUrl),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({'username': username.trim(), 'password': password}),
          )
          .timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw const ApiException('El servidor tardó demasiado en responder. Intenta de nuevo.');
    } on http.ClientException {
      throw const ApiException('No se pudo conectar con el servidor. Verifica tu conexión.');
    }

    final body = _tryDecode(response);
    if (response.statusCode != 200) {
      final message = body is Map && body['message'] is String
          ? body['message'] as String
          : 'No se pudo iniciar sesión (código ${response.statusCode}).';
      throw ApiException(message);
    }

    final Session session;
    try {
      session = Session.fromLoginJson(body as Map<String, dynamic>);
    } on Object {
      throw const ApiException('El servidor envió una respuesta inesperada.');
    }

    // La app es solo para empleados; el aprobador trabaja desde el panel web.
    if (!session.isEmployee) {
      throw const ApiException(
          'Esta app es para empleados. El Equipo de Finanzas usa el panel web de aprobación.');
    }

    _session = session;
    await _storage.write(jsonEncode(session.toJson()));
    return session;
  }

  Future<void> logout() async {
    _session = null;
    await _storage.clear();
  }

  Object? _tryDecode(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      return null;
    }
  }
}
