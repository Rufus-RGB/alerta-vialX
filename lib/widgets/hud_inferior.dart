import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_colors.dart';
import 'botones.dart';
import 'navegacion.dart';

/// HUD inferior para móvil: 2 destinos + SOS flotante al centro + 2 destinos.
class HudInferior extends StatelessWidget {
  const HudInferior({
    super.key,
    required this.destinos,
    required this.indiceActivo,
    required this.onDestino,
    required this.onSos,
  }) : assert(destinos.length == 4);

  final List<DestinoNav> destinos;
  final int indiceActivo;
  final ValueChanged<DestinoNav> onDestino;
  final VoidCallback onSos;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget item(int i) => Expanded(
          child: _ItemHud(destino: destinos[i], activo: i == indiceActivo, onTap: () => onDestino(destinos[i])),
        );

    return SizedBox(
      height: 96,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 72,
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(top: BorderSide(color: scheme.outlineVariant)),
            ),
            child: SafeArea(
              top: false,
              child: Row(children: [item(0), item(1), const SizedBox(width: 84), item(2), item(3)]),
            ),
          ),
          Positioned(top: 0, child: BotonSos(onPressed: onSos)),
        ],
      ),
    );
  }
}

class _ItemHud extends StatelessWidget {
  const _ItemHud({required this.destino, required this.activo, required this.onTap});

  final DestinoNav destino;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = activo ? AppColors.rojo : Theme.of(context).colorScheme.onSurfaceVariant;
    return InkResponse(
      onTap: onTap,
      child: Semantics(
        selected: activo,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(destino.icono, color: color),
            const SizedBox(height: 2),
            Text(
              destino.etiqueta,
              style: GoogleFonts.mPlusRounded1c(fontSize: 12, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
