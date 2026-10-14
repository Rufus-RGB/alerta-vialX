import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/paleta.dart';
import '../core/theme/theme_mode_provider.dart';
import 'botones.dart';
import 'campos.dart';

/// Encabezado de tablet/PC: título 26 px + subtítulo, buscador (solo PC), tema y notificaciones.
class EncabezadoEscritorio extends ConsumerWidget {
  const EncabezadoEscritorio({super.key, required this.titulo, this.subtitulo, this.acciones = const [], this.buscador = true});

  final String titulo;
  final String? subtitulo;
  final List<Widget> acciones;
  final bool buscador;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.paleta;
    final esPc = context.pantalla == TipoPantalla.escritorio;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: Txt.r(26, color: p.texto)),
                if (subtitulo != null) Text(subtitulo!, style: Txt.n(14, color: p.textoSecundario)),
              ],
            ),
          ),
          ...acciones,
          if (esPc && buscador) ...[
            const SizedBox(width: 16),
            SizedBox(
              width: 340,
              child: Buscador(
                hint: 'Buscar dirección, placa o zona',
                onSubmitted: (q) => context.go('/mapa?q=${Uri.encodeQueryComponent(q)}'),
              ),
            ),
          ],
          const SizedBox(width: 16),
          BotonCircular(
            icono: context.esOscuro ? TablerIcons.sun : TablerIcons.moon,
            tooltip: context.esOscuro ? 'Modo claro' : 'Modo oscuro',
            onPressed: () => ref.read(themeModeProvider.notifier).cambiar(context.esOscuro ? ThemeMode.light : ThemeMode.dark),
          ),
          const SizedBox(width: 12),
          BotonCircular(icono: TablerIcons.bell, tooltip: 'Notificaciones', badge: true, onPressed: () => context.push('/notificaciones')),
        ],
      ),
    );
  }
}

/// Fecha larga en español: "Martes, 13 de octubre".
String fechaLarga(DateTime f) {
  const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  const meses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
  return '${dias[f.weekday - 1]}, ${f.day} de ${meses[f.month - 1]}';
}
