import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/reimbursement.dart';

/// Error ya traducido a un mensaje que se puede mostrar al usuario.
class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// La API respondió 401: el token expiró o ya no es válido; hay que volver al login.
class SessionExpiredException extends ApiException {
  const SessionExpiredException()
      : super('Tu sesión expiró. Inicia sesión de nuevo para continuar.');
}

class ReimbursementApiService {
  ReimbursementApiService({http.Client? client, required String? Function() token})
      : _client = client ?? http.Client(),
        _currentToken = token;

  final http.Client _client;
  final String? Function() _currentToken;

  static const _invalidResponse = 'El servidor envió una respuesta inesperada.';

  Map<String, String> get _headers {
    final token = _currentToken();
    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// La API identifica al empleado por su token y devuelve solo sus solicitudes.
  Future<List<Reimbursement>> getMyReimbursements() async {
    final body = await _send(
        () => _client.get(Uri.parse(ApiConfig.reimbursementsUrl), headers: _headers));
    if (body is! List) throw const ApiException(_invalidResponse);

    return _parse(() => body
        .map((item) => Reimbursement.fromJson(item as Map<String, dynamic>))
        .toList());
  }

  Future<Reimbursement> createReimbursement({
    required int amount,
    required String category,
    required String description,
  }) async {
    final payload = jsonEncode({
      'amount': amount,
      'category': category,
      'description': description,
    });

    final body = await _send(() => _client.post(
          Uri.parse(ApiConfig.reimbursementsUrl),
          headers: {..._headers, 'Content-Type': 'application/json; charset=utf-8'},
          body: payload,
        ));
    if (body is! Map<String, dynamic>) throw const ApiException(_invalidResponse);

    return _parse(() => Reimbursement.fromJson(body));
  }

  /// Ejecuta la petición y devuelve el JSON decodificado; cualquier fallo sale como [ApiException].
  Future<Object?> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw const ApiException('El servidor tardó demasiado en responder. Intenta de nuevo.');
    } on http.ClientException {
      throw const ApiException(
          'No se pudo conectar con el servidor. Verifica tu conexión y que la API esté encendida.');
    }

    final body = _tryDecode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) return body;
    if (response.statusCode == 401) throw const SessionExpiredException();

    // La API responde los errores como {"message": "..."}.
    final message = body is Map && body['message'] is String
        ? body['message'] as String
        : _messageForStatus(response.statusCode);
    throw ApiException(message);
  }

  Object? _tryDecode(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      return null;
    }
  }

  T _parse<T>(T Function() parse) {
    try {
      return parse();
    } on TypeError {
      throw const ApiException(_invalidResponse);
    } on FormatException {
      throw const ApiException(_invalidResponse);
    }
  }

  String _messageForStatus(int statusCode) => switch (statusCode) {
        400 => 'Los datos enviados no son válidos.',
        404 => 'No se encontró la solicitud.',
        409 => 'La solicitud ya fue decidida.',
        >= 500 => 'El servidor tuvo un problema. Intenta más tarde.',
        _ => 'Error inesperado del servidor (código $statusCode).',
      };
}
