import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'models/session.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/reimbursement_api_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(ConswareApp(auth: AuthService()));
}

class ConswareApp extends StatelessWidget {
  const ConswareApp({super.key, required this.auth, this.apiClient});

  final AuthService auth;

  /// Permite inyectar un cliente HTTP falso en las pruebas.
  final http.Client? apiClient;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Consware Reembolsos',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      builder: (context, child) => _PhoneFrame(child: child!),
      home: AppRoot(auth: auth, apiClient: apiClient),
    );
  }
}

/// Decide qué mostrar: inicio animado mientras se recupera la sesión, login o la app.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key, required this.auth, this.apiClient});

  final AuthService auth;
  final http.Client? apiClient;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late final _service = ReimbursementApiService(
    client: widget.apiClient,
    token: () => widget.auth.token,
  );
  bool _restoring = true;
  Session? _session;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    // Tiempo mínimo para que la animación de inicio se vea completa.
    final results = await Future.wait([
      widget.auth.restore(),
      Future<void>.delayed(const Duration(milliseconds: 1100)),
    ]);
    if (!mounted) return;
    setState(() {
      _session = results.first as Session?;
      _restoring = false;
    });
  }

  Future<void> _logout({String? notice}) async {
    await widget.auth.logout();
    if (!mounted) return;
    setState(() {
      _session = null;
      _notice = notice;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (_restoring) {
      child = const SplashScreen(key: ValueKey('splash'));
    } else if (_session case final session?) {
      child = HomeShell(
        key: ValueKey(session.username),
        service: _service,
        session: session,
        onLogout: () => _logout(),
        onSessionExpired: () => _logout(notice: 'Tu sesión expiró. Inicia sesión de nuevo para continuar.'),
      );
    } else {
      child = LoginScreen(
        key: const ValueKey('login'),
        auth: widget.auth,
        notice: _notice,
        onLoggedIn: (session) => setState(() {
          _session = session;
          _notice = null;
        }),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutCubic,
      child: child,
    );
  }
}

/// En pantallas anchas (Flutter web) la app se muestra con ancho de teléfono;
/// en un celular no tiene efecto.
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.frame,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppColors.text.withValues(alpha: 0.12),
                  blurRadius: 30,
                ),
              ],
            ),
            child: ClipRect(child: child),
          ),
        ),
      ),
    );
  }
}
