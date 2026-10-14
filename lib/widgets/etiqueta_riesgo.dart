import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/paleta.dart';

enum NivelRiesgo {
  alto('Alto Riesgo', 'Alto', AppColors.rojo),
  medio('Riesgo Medio', 'Medio', AppColors.amarillo),
  bajo('Riesgo Bajo', 'Bajo', AppColors.verdeExito),
  info('Información', 'Info', AppColors.verdeExito);

  const NivelRiesgo(this.etiqueta, this.corta, this.color);
  final String etiqueta;
  final String corta;
  final Color color;

  Color fondo(Paleta p) => switch (this) {
        NivelRiesgo.alto => p.suaveRojo,
        NivelRiesgo.medio => p.suaveAmarillo,
        NivelRiesgo.bajo || NivelRiesgo.info => p.suaveVerde,
      };

  Color texto(Paleta p) => switch (this) {
        NivelRiesgo.alto => p.textoAlto,
        NivelRiesgo.medio => p.textoMedio,
        NivelRiesgo.bajo || NivelRiesgo.info => AppColors.verdeExito,
      };
}

/// Píldora de nivel de riesgo ("Alto Riesgo" en rosado, "Riesgo Medio" en crema).
class EtiquetaRiesgo extends StatelessWidget {
  const EtiquetaRiesgo(this.nivel, {super.key, this.corta = false, this.ancho});

  final NivelRiesgo nivel;

  /// "Alto" / "Medio" en vez de "Alto Riesgo".
  final bool corta;

  /// Ancho fijo (en el Figma de celular: 118 px).
  final double? ancho;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Container(
      width: ancho,
      height: corta ? 22 : 24,
      padding: EdgeInsets.symmetric(horizontal: corta ? 10 : 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: nivel.fondo(p), borderRadius: BorderRadius.circular(12)),
      child: Text(corta ? nivel.corta : nivel.etiqueta, style: Txt.nb(corta ? 11 : 12, color: nivel.texto(p))),
    );
  }
}

/// Etiqueta genérica en píldora con color suave (estados de reporte, roles, etc.).
class Pildora extends StatelessWidget {
  const Pildora(this.texto, {super.key, required this.fondo, required this.color, this.icono});

  final String texto;
  final Color fondo;
  final Color color;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[Icon(icono, size: 13, color: color), const SizedBox(width: 4)],
          Text(texto, style: Txt.nb(11, color: color)),
        ],
      ),
    );
  }
}
