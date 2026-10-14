import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/paleta.dart';
import '../features/reporte/domain/reporte.dart';
import 'app_shell.dart';
import 'encabezado_escritorio.dart';
import 'etiqueta_riesgo.dart';
import 'tarjeta.dart';

/// Pantalla secundaria: en celular, encabezado con flecha atrás y lista;
/// en tablet/PC, encabezado de escritorio y contenido con ancho máximo.
class PantallaSecundaria extends StatelessWidget {
  const PantallaSecundaria({
    super.key,
    required this.titulo,
    required this.children,
    this.subtitulo,
    this.acciones,
    this.anchoMaximo = 640,
    this.padding = const EdgeInsets.fromLTRB(19, 4, 19, 24),
  });

  final String titulo;
  final String? subtitulo;
  final List<Widget> children;
  final List<Widget>? acciones;
  final double anchoMaximo;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    if (!context.esCelular) {
      return SingleChildScrollView(
        padding: paddingEscritorio,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EncabezadoEscritorio(titulo: titulo, subtitulo: subtitulo, acciones: acciones ?? const []),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: anchoMaximo),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
            ),
          ],
        ),
      );
    }
    final inferior = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      appBar: EncabezadoPantalla(titulo: titulo, acciones: acciones),
      body: ListView(padding: padding.copyWith(bottom: padding.bottom + inferior), children: children),
    );
  }
}

/// Fila con ícono, texto en negrita, valor/chevron a la derecha (Ajustes, Privacidad, Perfil).
class FilaOpcion extends StatelessWidget {
  const FilaOpcion({
    super.key,
    required this.icono,
    required this.texto,
    this.onTap,
    this.valor,
    this.trailing,
    this.divisor = true,
    this.color,
    this.fondoIcono,
    this.subtitulo,
  });

  final IconData icono;
  final String texto;
  final VoidCallback? onTap;
  final String? valor;
  final Widget? trailing;
  final bool divisor;
  final Color? color;

  /// Si se da, el ícono va en un círculo de 36 px con este fondo.
  final Color? fondoIcono;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final colorIcono = fondoIcono != null ? (context.esOscuro ? AppColors.amarillo : const Color(0xFFB88600)) : (color ?? p.texto);
    return FilaLista(
      titulo: texto,
      subtitulo: subtitulo,
      divisor: divisor,
      onTap: onTap,
      estiloTitulo: Txt.nb(15, color: color ?? p.texto),
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
      leading: fondoIcono != null
          ? IconoCirculo(icono: icono, fondo: fondoIcono!, color: colorIcono, tamano: 36, tamanoIcono: 20)
          : Icon(icono, size: 24, color: colorIcono),
      trailing: trailing ??
          (valor != null
              ? Text(valor!, style: Txt.n(14, color: p.textoSecundario))
              : (onTap != null ? Icon(Icons.chevron_right_rounded, color: p.textoSecundario) : null)),
    );
  }
}

/// Píldora del estado de un reporte (En atención, Recuperado, Cerrado…).
Widget pildoraEstado(BuildContext context, EstadoReporte e) {
  final p = context.paleta;
  return switch (e) {
    EstadoReporte.enAtencion || EstadoReporte.enviado || EstadoReporte.recibido => Pildora(e.etiqueta, fondo: p.suaveAmarillo, color: p.textoMedio),
    EstadoReporte.recuperado => Pildora(e.etiqueta, fondo: p.suaveVerde, color: AppColors.verdeExito),
    EstadoReporte.cerrado => Pildora(e.etiqueta, fondo: p.chip, color: p.textoSecundario),
  };
}
