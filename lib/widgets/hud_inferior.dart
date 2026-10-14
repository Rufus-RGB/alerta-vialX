import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/paleta.dart';
import 'botones.dart';
import 'navegacion.dart';

/// HUD inferior de celular: 2 pestañas + botón SOS flotante con curva + 2 pestañas.
/// Medidas del Figma: alto 120, curva central de 148 px, SOS de 70 px a 7 px del borde.
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

  static const alto = 120.0;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final inferior = MediaQuery.paddingOf(context).bottom;
    Widget tab(int i) => SizedBox(
          width: 80,
          child: _TabHud(destino: destinos[i], activo: i == indiceActivo, onTap: () => onDestino(destinos[i])),
        );

    return SizedBox(
      height: alto + inferior,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: CustomPaint(painter: _CurvaHud(color: p.hud, sombra: context.esOscuro ? Colors.black54 : const Color(0x14000000)))),
          Positioned(
            left: 10,
            right: 10,
            top: 50,
            child: Row(
              children: [tab(0), tab(1), const Spacer(), tab(2), tab(3)],
            ),
          ),
          Positioned(top: 7, left: 0, right: 0, child: Center(child: BotonSos(onPressed: onSos))),
        ],
      ),
    );
  }
}

class _TabHud extends StatelessWidget {
  const _TabHud({required this.destino, required this.activo, required this.onTap});

  final DestinoNav destino;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final colorIcono = activo ? (context.esOscuro ? AppColors.amarillo : Colors.black) : p.hudInactivo;
    return Semantics(
      selected: activo,
      button: true,
      label: destino.etiqueta,
      child: InkResponse(
        onTap: onTap,
        radius: 40,
        child: SizedBox(
          height: 66,
          child: Column(
            children: [
              Icon(activo ? (destino.iconoActivo ?? destino.icono) : destino.icono, size: 28, color: colorIcono),
              const SizedBox(height: 5),
              Text(
                destino.etiqueta,
                style: activo ? Txt.nb(13, color: p.texto) : Txt.n(13, color: p.hudInactivo),
              ),
              if (activo) ...[
                const SizedBox(height: 5),
                Container(width: 44, height: 4, decoration: BoxDecoration(color: AppColors.amarillo, borderRadius: BorderRadius.circular(2))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Fondo del HUD con la curva que abraza el botón SOS (trazado exportado del Figma).
class _CurvaHud extends CustomPainter {
  _CurvaHud({required this.color, required this.sombra});

  final Color color;
  final Color sombra;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final c = w / 2;
    final path = Path()
      ..moveTo(0, 64)
      ..cubicTo(0, 50.75, 10.75, 40, 24, 40)
      ..lineTo(c - 74, 40)
      ..cubicTo(c - 58, 40, c - 50, 33, c - 43, 22)
      ..cubicTo(c - 35, 9, c - 20, 0, c, 0)
      ..cubicTo(c + 20, 0, c + 35, 9, c + 43, 22)
      ..cubicTo(c + 50, 33, c + 58, 40, c + 74, 40)
      ..lineTo(w - 24, 40)
      ..cubicTo(w - 10.75, 40, w, 50.75, w, 64)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawShadow(path.shift(const Offset(0, -4)), sombra, 9, false);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_CurvaHud old) => old.color != color || old.sombra != sombra;
}
