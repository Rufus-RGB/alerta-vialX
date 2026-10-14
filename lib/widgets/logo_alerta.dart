import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Logo: cuadro rojo redondeado con ícono de advertencia amarillo.
class LogoAlerta extends StatelessWidget {
  const LogoAlerta({super.key, this.tamano = 72});

  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        color: AppColors.rojo,
        borderRadius: BorderRadius.circular(tamano * 0.28),
        boxShadow: [
          BoxShadow(color: AppColors.rojo.withValues(alpha: 0.35), blurRadius: tamano * 0.3, offset: Offset(0, tamano * 0.08)),
        ],
      ),
      child: Icon(Icons.warning_rounded, color: AppColors.amarillo, size: tamano * 0.62),
    );
  }
}
