import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/paleta.dart';
import 'tarjeta.dart';

/// Tarjeta KPI de tablet/PC: etiqueta, valor grande, nota de color e ícono en círculo.
class TarjetaKpi extends StatelessWidget {
  const TarjetaKpi({
    super.key,
    required this.titulo,
    required this.valor,
    required this.nota,
    required this.colorNota,
    required this.icono,
    required this.fondoIcono,
    required this.colorIcono,
    this.grande = false,
  });

  final String titulo;
  final String valor;
  final String nota;
  final Color colorNota;
  final IconData icono;
  final Color fondoIcono;
  final Color colorIcono;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Tarjeta(
      padding: EdgeInsets.fromLTRB(16, grande ? 16 : 12, 16, grande ? 16 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: Txt.n(grande ? 13 : 12, color: p.textoSecundario)),
                SizedBox(height: grande ? 8 : 4),
                Text(valor, maxLines: 1, overflow: TextOverflow.ellipsis, style: Txt.r(grande ? 30 : 22, color: p.texto)),
                const SizedBox(height: 2),
                Text(nota, maxLines: 1, overflow: TextOverflow.ellipsis, style: Txt.nb(grande ? 12 : 11, color: colorNota)),
              ],
            ),
          ),
          IconoCirculo(icono: icono, fondo: fondoIcono, color: colorIcono, tamano: 40, tamanoIcono: 20),
        ],
      ),
    );
  }
}

/// Barras horizontales "Reportes por localidad" (rojo para los dos mayores, amarillo el resto).
class BarrasPorCategoria extends StatelessWidget {
  const BarrasPorCategoria({super.key, required this.datos, this.anchoEtiqueta = 112, this.alto = 12, this.espacio = 22, this.rojos = 2});

  final List<(String, int)> datos;
  final double anchoEtiqueta;
  final double alto;
  final double espacio;
  final int rojos;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final maximo = datos.map((d) => d.$2).fold<int>(1, (a, b) => a > b ? a : b);
    return Column(
      children: [
        for (final (i, (etiqueta, valor)) in datos.indexed)
          Padding(
            padding: EdgeInsets.only(bottom: i == datos.length - 1 ? 0 : espacio),
            child: Row(
              children: [
                SizedBox(width: anchoEtiqueta, child: Text(etiqueta, style: Txt.n(13, color: p.textoSecundario))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(alto / 2),
                    child: LinearProgressIndicator(
                      value: valor / maximo,
                      minHeight: alto,
                      color: i < rojos ? AppColors.rojo : AppColors.amarillo,
                      backgroundColor: context.esOscuro ? const Color(0xFF2A3238) : const Color(0xFFEEF0F2),
                    ),
                  ),
                ),
                SizedBox(width: 42, child: Text('$valor', textAlign: TextAlign.right, style: Txt.nb(13, color: p.texto))),
              ],
            ),
          ),
      ],
    );
  }
}

/// Avatar circular con iniciales ("LG", "SC").
class AvatarIniciales extends StatelessWidget {
  const AvatarIniciales({super.key, required this.iniciales, required this.color, this.tamano = 44});

  final String iniciales;
  final Color color;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final claro = color == AppColors.amarillo;
    return Container(
      width: tamano,
      height: tamano,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(iniciales, style: Txt.nb(tamano * 0.33, color: claro ? Colors.black : Colors.white)),
    );
  }
}

/// Par de botones "Aprobar" (verde) y "Rechazar" (borde rojo).
class BotonesAprobacion extends StatelessWidget {
  const BotonesAprobacion({super.key, required this.onAprobar, required this.onRechazar, this.alto = 40, this.compactos = false});

  final VoidCallback onAprobar;
  final VoidCallback onRechazar;
  final double alto;
  final bool compactos;

  @override
  Widget build(BuildContext context) {
    final aprobar = FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.verdeExito,
        minimumSize: Size(0, alto),
        padding: EdgeInsets.symmetric(horizontal: compactos ? 10 : 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(compactos ? 8 : 12)),
        textStyle: Txt.nb(compactos ? 13 : 15),
      ),
      onPressed: onAprobar,
      icon: Icon(TablerIcons.check, size: compactos ? 16 : 20),
      label: const Text('Aprobar'),
    );
    final rechazar = OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.rojo,
        side: const BorderSide(color: AppColors.rojo, width: 1.5),
        minimumSize: Size(0, alto),
        padding: EdgeInsets.symmetric(horizontal: compactos ? 10 : 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(compactos ? 8 : 12)),
        textStyle: Txt.nb(compactos ? 13 : 15),
      ),
      onPressed: onRechazar,
      icon: compactos ? const SizedBox.shrink() : const Icon(TablerIcons.x, size: 20),
      label: const Text('Rechazar'),
    );
    if (compactos) return Row(mainAxisSize: MainAxisSize.min, children: [aprobar, const SizedBox(width: 6), rechazar]);
    return Row(children: [Expanded(child: aprobar), const SizedBox(width: 14), Expanded(child: rechazar)]);
  }
}

/// Botón principal morado de DEV (y azul de autoridad con [color]).
class BotonAcento extends StatelessWidget {
  const BotonAcento({super.key, required this.texto, required this.onPressed, this.icono, this.color = AppColors.moradoDev, this.alto = 44});

  final String texto;
  final VoidCallback? onPressed;
  final IconData? icono;
  final Color color;
  final double alto;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: Size(0, alto),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: Txt.nb(15),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [if (icono != null) ...[Icon(icono, size: 20), const SizedBox(width: 8)], Text(texto)],
      ),
    );
  }
}

/// Tabla simple para PC: encabezados grises y filas con divisor.
class TablaSimple extends StatelessWidget {
  const TablaSimple({super.key, required this.columnas, required this.filas, this.flex, this.onFila, this.seleccionada});

  final List<String> columnas;
  final List<List<Widget>> filas;
  final List<int>? flex;
  final ValueChanged<int>? onFila;
  final int? seleccionada;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    Widget celda(int i, Widget w) => Expanded(flex: flex?[i] ?? 1, child: w);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [for (final (i, c) in columnas.indexed) celda(i, Text(c, style: Txt.nb(12, color: p.textoSecundario)))]),
        ),
        Divider(color: p.borde),
        for (final (n, fila) in filas.indexed) ...[
          Material(
            color: n == seleccionada ? p.suaveMorado : Colors.transparent,
            child: InkWell(
              onTap: onFila == null ? null : () => onFila!(n),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(children: [for (final (i, w) in fila.indexed) celda(i, w)]),
              ),
            ),
          ),
          if (n < filas.length - 1) Divider(color: p.divisor),
        ],
      ],
    );
  }
}
