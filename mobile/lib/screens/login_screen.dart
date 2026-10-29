import 'package:flutter/material.dart';

import '../models/session.dart';
import '../services/auth_service.dart';
import '../services/reimbursement_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/brand.dart';
import '../widgets/primary_button.dart';
import '../widgets/state_views.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth, required this.onLoggedIn, this.notice});

  final AuthService auth;
  final ValueChanged<Session> onLoggedIn;

  /// Aviso opcional, p. ej. "Tu sesión expiró".
  final String? notice;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final session = await widget.auth.login(_usernameController.text, _passwordController.text);
      if (!mounted) return;
      widget.onLoggedIn(session);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message;
        _passwordController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FadeSlideIn(child: Center(child: ConswareLogo(height: 38))),
                      const SizedBox(height: 40),
                      const FadeSlideIn(
                        index: 1,
                        child: Text('¡Bienvenido!', style: AppText.pageTitle),
                      ),
                      const SizedBox(height: 8),
                      const FadeSlideIn(
                        index: 2,
                        child: Text(
                          'Ingresa con tu usuario corporativo para registrar y consultar tus reembolsos.',
                          style: AppText.subtitle,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (widget.notice != null && _error == null) ...[
                        FadeSlideIn(
                          index: 3,
                          child: _Notice(text: widget.notice!),
                        ),
                        const SizedBox(height: 16),
                      ],
                      FadeSlideIn(
                        index: 3,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: cardDecoration(radius: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _Label('Usuario'),
                              TextFormField(
                                controller: _usernameController,
                                enabled: !_submitting,
                                autofillHints: const [AutofillHints.username],
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                decoration: const InputDecoration(
                                  hintText: 'p. ej. empleado.demo',
                                  prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.navy),
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty ? 'Ingresa tu usuario.' : null,
                              ),
                              const SizedBox(height: 16),
                              const _Label('Contraseña'),
                              TextFormField(
                                controller: _passwordController,
                                enabled: !_submitting,
                                obscureText: _obscure,
                                autofillHints: const [AutofillHints.password],
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.navy),
                                  suffixIcon: IconButton(
                                    tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty ? 'Ingresa tu contraseña.' : null,
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 220),
                                child: _error == null
                                    ? const SizedBox(width: double.infinity)
                                    : Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: ErrorBanner(message: _error!),
                                      ),
                              ),
                              const SizedBox(height: 22),
                              PrimaryButton(
                                label: 'Ingresar',
                                icon: Icons.login_rounded,
                                loading: _submitting,
                                onPressed: _submit,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const FadeSlideIn(
                        index: 4,
                        child: Row(
                          children: [
                            Icon(Icons.shield_outlined, size: 18, color: AppColors.muted),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Conexión protegida con token de sesión. ¿Eres del Equipo de Finanzas? Usa el panel web de aprobación.',
                                style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy),
        ),
      );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pendingBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_rounded, color: AppColors.pending),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.text))),
        ],
      ),
    );
  }
}
