import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/paleta.dart';
import '../../../widgets/app_shell.dart';
import '../../../widgets/encabezado_escritorio.dart';
import '../../../widgets/tarjeta.dart';
import '../data/alertas_repository.dart';

/// Configurar alertas: tipos, radio (1–5 km) y notificaciones. Se guarda en SharedPreferences.
class ConfigurarAlertasScreen extends ConsumerWidget {
  const ConfigurarAlertasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.paleta;
    final c = ref.watch(configAlertasProvider);
    void cambiar(ConfigAlertas n) => ref.read(configAlertasProvider.notifier).cambiar(n);

    Widget tipo(IconData icono, Color color, String texto, bool valor, ValueChanged<bool> on, {bool ultimo = false}) => FilaLista(
          titulo: texto,
          divisor: !ultimo,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          leading: IconoCirculo(icono: icono, fondo: color, color: color == AppColors.amarillo ? Colors.black : Colors.white, tamano: 36, tamanoIcono: 20),
          trailing: Switch(value: valor, onChanged: on),
          onTap: () => on(!valor),
        );
    Widget notif(IconData icono, String texto, bool valor, ValueChanged<bool> on, {bool ultimo = false}) => FilaLista(
          titulo: texto,
          divisor: !ultimo,
          padding: const EdgeInsets.fromLTRB(18, 12, 16, 12),
          leading: Icon(icono, size: 24, color: p.texto),
          trailing: Switch(value: valor, onChanged: on),
          onTap: () => on(!valor),
        );

    final contenido = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TituloSeccion('Tipos de alerta', padding: EdgeInsets.fromLTRB(10, 4, 4, 8)),
        Tarjeta(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              tipo(TablerIcons.urgent, AppColors.rojo, 'Hurtos cerca de mí', c.hurtos, (v) => cambiar(c.copyWith(hurtos: v))),
              tipo(TablerIcons.trending_up, AppColors.amarillo, 'Aumento de reportes', c.aumento, (v) => cambiar(c.copyWith(aumento: v))),
              tipo(TablerIcons.alert_triangle, AppColors.rojo, 'Zonas de alto riesgo', c.zonas, (v) => cambiar(c.copyWith(zonas: v))),
              tipo(TablerIcons.shield, const Color(0xFF2E6B4F), 'CAI cercanos', c.cai, (v) => cambiar(c.copyWith(cai: v)), ultimo: true),
            ],
          ),
        ),
        const TituloSeccion('Radio de alerta', padding: EdgeInsets.fromLTRB(10, 18, 4, 8)),
        Tarjeta(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Text('Avisarme de incidentes a menos de', style: Txt.n(13, color: p.textoSecundario))),
                  Text('${c.radioKm.round()} km', style: Txt.nb(15, color: p.texto)),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.amarillo,
                  inactiveTrackColor: context.esOscuro ? const Color(0xFF2A3238) : const Color(0xFFD9D9D9),
                  thumbColor: p.tarjeta,
                  overlayColor: AppColors.amarillo.withValues(alpha: 0.15),
                  trackHeight: 6,
                  thumbShape: _Perilla(borde: AppColors.amarillo, relleno: p.tarjeta),
                ),
                child: Slider(
                  value: c.radioKm,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: '${c.radioKm.round()} km',
                  onChanged: (v) => cambiar(c.copyWith(radioKm: v)),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [for (final t in ['1 km', '3 km', '5 km']) Text(t, style: Txt.n(12, color: p.textoSecundario))],
              ),
            ],
          ),
        ),
        const TituloSeccion('Notificaciones', padding: EdgeInsets.fromLTRB(10, 18, 4, 8)),
        Tarjeta(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              notif(TablerIcons.volume, 'Sonido', c.sonido, (v) => cambiar(c.copyWith(sonido: v))),
              notif(TablerIcons.device_mobile_vibration, 'Vibración', c.vibracion, (v) => cambiar(c.copyWith(vibracion: v))),
              notif(TablerIcons.moon, 'No molestar (10 p. m. – 6 a. m.)', c.noMolestar, (v) => cambiar(c.copyWith(noMolestar: v)), ultimo: true),
            ],
          ),
        ),
      ],
    );

    if (!context.esCelular) {
      return SingleChildScrollView(
        padding: paddingEscritorio,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EncabezadoEscritorio(titulo: 'Configurar alertas', subtitulo: 'Elige qué alertas recibir y a qué distancia'),
            ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: contenido),
          ],
        ),
      );
    }
    final inferior = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      appBar: const EncabezadoPantalla(titulo: 'Configurar alertas'),
      body: ListView(padding: EdgeInsets.fromLTRB(19, 4, 19, inferior + 24), children: [contenido]),
    );
  }
}

/// Perilla del slider: círculo blanco con borde amarillo de 3 px (22 px).
class _Perilla extends SliderComponentShape {
  const _Perilla({required this.borde, required this.relleno});

  final Color borde;
  final Color relleno;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size.square(22);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    context.canvas
      ..drawCircle(center, 11, Paint()..color = relleno)
      ..drawCircle(
        center,
        9.5,
        Paint()
          ..color = borde
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
  }
}
