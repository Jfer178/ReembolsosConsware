import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 56),
        child: Center(child: CircularProgressIndicator()),
      );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: AppColors.rejectedBg, shape: BoxShape.circle),
            child: const Icon(Icons.cloud_off_rounded, size: 32, color: AppColors.rejected),
          ),
          const SizedBox(height: 16),
          const Text(
            'No se pudo cargar la información',
            textAlign: TextAlign.center,
            style: AppText.sectionTitle,
          ),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: AppText.subtitle),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: AppColors.tile, shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_rounded, size: 34, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center, style: AppText.subtitle),
        ],
      ),
    );
  }
}

/// Error que no reemplaza la pantalla (p. ej. al enviar el formulario).
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.rejectedBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_rounded, color: AppColors.rejected, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 13, color: AppColors.text))),
        ],
      ),
    );
  }
}
