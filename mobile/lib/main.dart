import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'services/reimbursement_api_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(ConswareApp(service: ReimbursementApiService()));
}

class ConswareApp extends StatelessWidget {
  const ConswareApp({super.key, required this.service});

  final ReimbursementApiService service;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Consware Reembolsos',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      builder: (context, child) => _PhoneFrame(child: child!),
      home: HomeShell(service: service),
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
