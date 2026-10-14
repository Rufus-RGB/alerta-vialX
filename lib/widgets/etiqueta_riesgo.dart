import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_colors.dart';

enum NivelRiesgo {
  alto('Riesgo alto', AppColors.rojo),
  medio('Riesgo medio', AppColors.amarillo),
  bajo('Riesgo bajo', AppColors.verdeExito);

  const NivelRiesgo(this.etiqueta, this.color);
  final String etiqueta;
  final Color color;
}

/// Píldora de color según el nivel de riesgo.
class EtiquetaRiesgo extends StatelessWidget {
  const EtiquetaRiesgo(this.nivel, {super.key});

  final NivelRiesgo nivel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: nivel.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: nivel.color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: nivel.color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            nivel.etiqueta,
            style: GoogleFonts.mPlusRounded1c(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: nivel == NivelRiesgo.medio ? const Color(0xFFB88900) : nivel.color,
            ),
          ),
        ],
      ),
    );
  }
}
