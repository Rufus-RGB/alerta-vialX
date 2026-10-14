import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/paleta.dart';

/// Grupo de chips de selección única: activo amarillo, inactivo blanco con sombra
/// (como los filtros "Todos / Hurto Motos / Hurto Autos" del mapa).
class GrupoChips<T> extends StatelessWidget {
  const GrupoChips({
    super.key,
    required this.opciones,
    required this.seleccionado,
    required this.etiqueta,
    required this.onChanged,
    this.icono,
    this.sombra = false,
    this.expandir = false,
    this.alto = 30,
  });

  final List<T> opciones;
  final T seleccionado;
  final String Function(T) etiqueta;
  final IconData? Function(T)? icono;
  final ValueChanged<T> onChanged;

  /// Sombra en lugar de borde (chips flotando sobre el mapa).
  final bool sombra;

  /// Reparte el ancho disponible entre los chips.
  final bool expandir;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final chips = [
      for (final o in opciones)
        _Chip(
          texto: etiqueta(o),
          icono: icono?.call(o),
          activo: o == seleccionado,
          sombra: sombra,
          alto: alto,
          compacto: expandir,
          onTap: () => onChanged(o),
        ),
    ];
    if (expandir) {
      return Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[if (i > 0) const SizedBox(width: 10), Expanded(child: chips[i])],
        ],
      );
    }
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.texto, required this.icono, required this.activo, required this.sombra, required this.alto, required this.onTap, this.compacto = false});

  final bool compacto;

  final String texto;
  final IconData? icono;
  final bool activo;
  final bool sombra;
  final double alto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final colorTexto = activo ? Colors.black : p.texto;
    return Semantics(
      selected: activo,
      button: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(alto / 2),
          boxShadow: sombra ? const [BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 4))] : null,
        ),
        child: Material(
          color: activo ? AppColors.amarillo : p.tarjeta,
          shape: StadiumBorder(side: activo || sombra ? BorderSide.none : BorderSide(color: p.borde)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Container(
              height: alto,
              padding: EdgeInsets.symmetric(horizontal: compacto ? 6 : 16),
              alignment: compacto ? Alignment.center : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icono != null) ...[Icon(icono, size: 16, color: colorTexto), const SizedBox(width: 4)],
                  Flexible(child: Text(texto, overflow: TextOverflow.ellipsis, style: Txt.r(12, color: colorTexto))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
