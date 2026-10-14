import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../widgets/logo_alerta.dart';

/// Splash: se muestra mientras se restaura la sesión; el router redirige al terminar.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.fondoOscuro,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutBack,
          builder: (context, t, child) => Opacity(opacity: t.clamp(0, 1), child: Transform.scale(scale: t, child: child)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LogoAlerta(tamano: 104),
              const SizedBox(height: 24),
              Text('Alerta Vial', style: theme.textTheme.headlineLarge?.copyWith(color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                'Muévete seguro por tu ciudad',
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 40),
              const SizedBox.square(
                dimension: 28,
                child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.amarillo),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
