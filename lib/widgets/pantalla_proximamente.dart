import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/paleta.dart';
import 'app_shell.dart';
import 'encabezado_escritorio.dart';
import 'tarjeta.dart';

/// Marcador para pantallas que llegan en sprints posteriores.
class PantallaProximamente extends StatelessWidget {
  const PantallaProximamente({super.key, required this.titulo, required this.icono, required this.color, this.descripcion});

  final String titulo;
  final IconData icono;
  final Color color;
  final String? descripcion;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final contenido = Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconoCirculo(icono: icono, fondo: color.withValues(alpha: 0.15), color: color, tamano: 88),
            const SizedBox(height: 20),
            Text('Próximamente', style: Txt.r(24, color: p.texto)),
            const SizedBox(height: 8),
            Text(
              descripcion ?? 'Esta sección estará disponible en un próximo sprint.',
              textAlign: TextAlign.center,
              style: Txt.n(15, color: p.textoSecundario),
            ),
          ],
        ),
      ),
    );
    if (!context.esCelular) {
      return Padding(
        padding: paddingEscritorio,
        child: Column(children: [EncabezadoEscritorio(titulo: titulo), Expanded(child: contenido)]),
      );
    }
    return Scaffold(appBar: EncabezadoPantalla(titulo: titulo), body: contenido);
  }
}
