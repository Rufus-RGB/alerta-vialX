import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/paleta.dart';

/// Tarjeta base: radio 16, borde fino y sombra suave (en oscuro sin sombra).
class Tarjeta extends StatelessWidget {
  const Tarjeta({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.radio = 16,
    this.sombra = true,
    this.borde = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radio;
  final bool sombra;
  final bool borde;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final forma = BorderRadius.circular(radio);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: forma,
        boxShadow: sombra && !context.esOscuro ? const [BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 4))] : null,
      ),
      child: Material(
        color: color ?? p.tarjeta,
        shape: RoundedRectangleBorder(borderRadius: forma, side: borde ? BorderSide(color: p.borde) : BorderSide.none),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
      ),
    );
  }
}

/// Título de sección ("Hoy", "Esta semana", "Recientes").
class TituloSeccion extends StatelessWidget {
  const TituloSeccion(this.texto, {super.key, this.accion, this.padding = const EdgeInsets.fromLTRB(10, 20, 4, 8)});

  final String texto;
  final Widget? accion;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: Text(texto, style: Txt.r(16, color: context.paleta.texto))),
          ?accion,
        ],
      ),
    );
  }
}

/// Ícono dentro de un círculo de color (filas de notificaciones, permisos, acciones).
class IconoCirculo extends StatelessWidget {
  const IconoCirculo({super.key, required this.icono, required this.fondo, this.color = Colors.white, this.tamano = 44, this.tamanoIcono});

  final IconData icono;
  final Color fondo;
  final Color color;
  final double tamano;
  final double? tamanoIcono;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
      child: Icon(icono, color: color, size: tamanoIcono ?? tamano / 2),
    );
  }
}

/// Fila de lista dentro de una tarjeta, con divisor opcional (Figma: 64–80 px).
class FilaLista extends StatelessWidget {
  const FilaLista({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.leading,
    this.trailing,
    this.onTap,
    this.divisor = true,
    this.estiloTitulo,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.subtituloArriba = false,
  });

  final String titulo;
  final String? subtitulo;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool divisor;
  final TextStyle? estiloTitulo;
  final EdgeInsetsGeometry padding;

  /// Para filas tipo dato ("Vehículo" arriba en gris, valor abajo en negrita).
  final bool subtituloArriba;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final tituloW = Text(titulo, style: estiloTitulo ?? Txt.nb(15, color: p.texto));
    final subW = subtitulo == null ? null : Text(subtitulo!, style: Txt.n(subtituloArriba ? 12 : 13, color: p.textoSecundario));
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: padding,
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 12)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: subtituloArriba
                        ? [?subW, const SizedBox(height: 2), tituloW]
                        : [tituloW, if (subW != null) ...[const SizedBox(height: 4), subW]],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          if (divisor) Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: Divider(color: p.divisor)),
        ],
      ),
    );
  }
}

/// Encabezado de pantalla de celular: flecha atrás (30 px) y título centrado de 22 px.
class EncabezadoPantalla extends StatelessWidget implements PreferredSizeWidget {
  const EncabezadoPantalla({super.key, this.titulo, this.onAtras, this.acciones, this.cerrar = false});

  final String? titulo;
  final VoidCallback? onAtras;
  final List<Widget>? acciones;

  /// Muestra una X a la derecha en lugar de la flecha a la izquierda (pantalla SOS).
  final bool cerrar;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final atras = onAtras ?? () => context.canPop() ? context.pop() : context.go('/');
    return AppBar(
      toolbarHeight: 72,
      automaticallyImplyLeading: false,
      leading: cerrar ? null : IconButton(tooltip: 'Atrás', onPressed: atras, icon: Icon(TablerIcons.chevron_left, size: 30, color: p.texto)),
      title: titulo == null ? null : Text(titulo!),
      actions: [
        ...?acciones,
        if (cerrar) IconButton(tooltip: 'Cerrar', onPressed: atras, icon: Icon(TablerIcons.x, size: 28, color: p.texto)),
        const SizedBox(width: 8),
      ],
    );
  }
}
