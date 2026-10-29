import 'package:flutter/foundation.dart';

class ApiConfig {
  // Permite apuntar a otra API sin tocar código:
  // flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5080/api/reimbursements
  static const _overrideUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_overrideUrl.isNotEmpty) return _overrideUrl;
    if (kIsWeb) return 'http://localhost:5080/api/reimbursements';
    // Desde el emulador Android, 10.0.2.2 es el equipo anfitrión; localhost sería el propio emulador.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5080/api/reimbursements';
    }
    return 'http://localhost:5080/api/reimbursements';
  }

  static const timeout = Duration(seconds: 10);

  // Identificación simplificada admitida por el enunciado (sin login).
  static const employeeName = 'Empleado Demo';
}
