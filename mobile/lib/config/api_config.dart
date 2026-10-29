import 'package:flutter/foundation.dart';

class ApiConfig {
  // Permite apuntar a otra API sin tocar código:
  // flutter run --dart-define=API_URL=http://192.168.1.10:5080/api
  static const _overrideUrl = String.fromEnvironment('API_URL');

  static String get apiRoot {
    if (_overrideUrl.isNotEmpty) return _overrideUrl;
    if (kIsWeb) return 'http://localhost:5080/api';
    // Desde el emulador Android, 10.0.2.2 es el equipo anfitrión; localhost sería el propio emulador.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5080/api';
    }
    return 'http://localhost:5080/api';
  }

  static String get reimbursementsUrl => '$apiRoot/reimbursements';
  static String get loginUrl => '$apiRoot/auth/login';

  static const timeout = Duration(seconds: 10);
}
