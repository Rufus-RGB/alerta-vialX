import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/paleta.dart';

/// Botón principal (52 px, radio 14). Rojo por defecto; con [color] amarillo el texto es negro.
class BotonPrincipal extends StatelessWidget {
  const BotonPrincipal({
    super.key,
    required this.texto,
    required this.onPressed,
    this.icono,
    this.cargando = false,
    this.color = AppColors.rojo,
    this.alto = 52,
    this.tamanoTexto = 18,
  });

  final String texto;
  final VoidCallback? onPressed;
  final IconData? icono;
  final bool cargando;
  final Color color;
  final double alto;
  final double tamanoTexto;

  @override
  Widget build(BuildContext context) {
    final sobre = color == AppColors.amarillo || color == AppColors.amarilloRol ? Colors.black : Colors.white;
    return SizedBox(
      width: double.infinity,
      height: alto,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: sobre,
          disabledBackgroundColor: color.withValues(alpha: 0.6),
          minimumSize: Size(0, alto),
          textStyle: Txt.r(tamanoTexto),
        ),
        onPressed: cargando ? null : onPressed,
        child: cargando
            ? SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: sobre))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icono != null) ...[Icon(icono, size: tamanoTexto + 4, color: sobre), const SizedBox(width: 8)],
                  Flexible(child: Text(texto, overflow: TextOverflow.ellipsis)),
                ],
              ),
      ),
    );
  }
}

/// Botón con borde (p. ej. "Compartir").
class BotonContorno extends StatelessWidget {
  const BotonContorno({super.key, required this.texto, required this.onPressed, this.icono, this.alto = 52, this.tamanoTexto = 17});

  final String texto;
  final VoidCallback? onPressed;
  final IconData? icono;
  final double alto;
  final double tamanoTexto;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: alto,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(minimumSize: Size(0, alto), textStyle: Txt.r(tamanoTexto), padding: const EdgeInsets.symmetric(horizontal: 14)),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icono != null) ...[Icon(icono, size: 24), const SizedBox(width: 8)],
            Flexible(child: Text(texto, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

/// Enlace de dos partes: "¿No tienes cuenta? **Crear cuenta**".
class EnlaceTexto extends StatelessWidget {
  const EnlaceTexto({super.key, required this.pregunta, required this.accion, required this.onTap, this.tamano = 14});

  final String pregunta;
  final String accion;
  final VoidCallback onTap;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text.rich(
            TextSpan(
              style: Txt.n(tamano, color: context.paleta.textoSecundario),
              children: [
                TextSpan(text: '$pregunta '),
                TextSpan(text: accion, style: Txt.nb(tamano, color: AppColors.rojo)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón SOS circular del HUD (70 px, sirena blanca).
class BotonSos extends StatelessWidget {
  const BotonSos({super.key, required this.onPressed, this.tamano = 70});

  final VoidCallback onPressed;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Emergencia SOS',
      child: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x73FF292E), blurRadius: 16, offset: Offset(0, 4))],
        ),
        child: Material(
          color: AppColors.rojoSos,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox.square(
              dimension: tamano,
              child: Center(child: SvgPicture.asset('assets/icons/siren.svg', width: tamano * 36 / 70, height: tamano * 36 / 70)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón circular blanco con borde (tema, notificaciones, controles de mapa).
class BotonCircular extends StatelessWidget {
  const BotonCircular({
    super.key,
    required this.icono,
    required this.onPressed,
    this.tamano = 44,
    this.tooltip,
    this.badge = false,
    this.sombra = false,
    this.radio,
  });

  final IconData icono;
  final VoidCallback? onPressed;
  final double tamano;
  final String? tooltip;
  final bool badge;
  final bool sombra;

  /// Radio de esquina; por defecto círculo.
  final double? radio;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final forma = radio == null
        ? CircleBorder(side: sombra ? BorderSide.none : BorderSide(color: p.borde))
        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(radio!), side: sombra ? BorderSide.none : BorderSide(color: p.borde));
    final boton = Material(
      color: p.tarjeta,
      shape: forma,
      elevation: sombra ? 4 : 0,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: forma,
        onTap: onPressed,
        child: SizedBox.square(
          dimension: tamano,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icono, size: tamano * 0.46, color: p.texto),
              if (badge)
                Positioned(
                  right: tamano * 0.2,
                  top: tamano * 0.18,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(color: AppColors.rojo, shape: BoxShape.circle, border: Border.all(color: p.tarjeta, width: 1.5)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return tooltip == null ? boton : Tooltip(message: tooltip!, child: boton);
  }
}
