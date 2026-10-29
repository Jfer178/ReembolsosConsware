import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/brand.dart';

/// Se muestra mientras se recupera la sesión guardada: el logo entra con un rebote suave.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            builder: (context, t, child) => Opacity(
              opacity: Curves.easeOut.transform(t.clamp(0, 1)),
              child: Transform.scale(scale: 0.8 + 0.2 * Curves.easeOutBack.transform(t), child: child),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConswareLogo(height: 44),
                SizedBox(height: 10),
                Text('Reembolsos de gastos', style: AppText.subtitle),
                SizedBox(height: 36),
                SizedBox.square(
                  dimension: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
