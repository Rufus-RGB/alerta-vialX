import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/paleta.dart';
import '../../../widgets/app_shell.dart';
import '../../../widgets/encabezado_escritorio.dart';
import '../../../widgets/tarjeta.dart';
import '../../mapa/presentation/mapa_controller.dart';

/// Emergencia SOS: mantener presionado 3 s el botón para pedir ayuda (simulado).
class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with TickerProviderStateMixin {
  late final _presion = AnimationController(vsync: this, duration: const Duration(seconds: 3))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _enviar();
    });
  late final _pulso = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  bool _enviado = false;

  @override
  void dispose() {
    _presion.dispose();
    _pulso.dispose();
    super.dispose();
  }

  void _enviar() {
    setState(() => _enviado = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SOS enviado: compartimos tu ubicación con la Policía y tus contactos (simulación).'),
        backgroundColor: AppColors.verdeExito,
      ),
    );
  }

  Future<void> _llamar() async {
    final ok = await launchUrl(Uri.parse('tel:123'));
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el marcador. Llama al 123.')));
    }
  }

  Future<void> _compartirUbicacion() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final p = await obtenerUbicacionActual();
      messenger.showSnackBar(SnackBar(
        content: Text('Ubicación compartida con tus contactos: ${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}'),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final inferior = MediaQuery.paddingOf(context).bottom;
    final contenido = ListView(
      padding: EdgeInsets.fromLTRB(19, 8, 19, inferior + 24),
      children: [
        Text(_enviado ? 'Ayuda en camino' : '¿Estás en peligro?', textAlign: TextAlign.center, style: Txt.r(26, color: p.texto)),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35),
          child: Text(
            _enviado ? 'Mantén la app abierta. La Policía recibió tu alerta.' : 'Mantén presionado el botón 3 segundos para pedir ayuda.',
            textAlign: TextAlign.center,
            style: Txt.n(15, color: p.textoSecundario),
          ),
        ),
        const SizedBox(height: 12),
        Center(child: _botonGrande(context)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35),
          child: Text(
            'Enviaremos tu ubicación a la Policía y a tus contactos de emergencia.',
            textAlign: TextAlign.center,
            style: Txt.n(13, color: p.textoSecundario),
          ),
        ),
        const SizedBox(height: 20),
        Tarjeta(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _accion(context, TablerIcons.phone, AppColors.rojo, 'Llamar al 123', 'Línea de emergencias', _llamar),
              _accion(context, TablerIcons.urgent, AppColors.amarillo, 'Alerta rápida de hurto', 'Avisa a conductores cerca', () => context.go('/reporte')),
              _accion(context, TablerIcons.current_location, AppColors.azulAutoridad, 'Compartir mi ubicación', 'Con tus contactos de emergencia', _compartirUbicacion, ultima: true),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Text('Contactos:', style: Txt.n(13, color: p.textoSecundario)),
            const SizedBox(width: 10),
            for (final c in const ['Mamá', 'Hermano']) ...[
              Container(
                height: 36,
                padding: const EdgeInsets.fromLTRB(4, 4, 14, 4),
                decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(18)),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: AppColors.amarillo, shape: BoxShape.circle),
                      child: Text(c[0], style: Txt.nb(13, color: Colors.black)),
                    ),
                    const SizedBox(width: 8),
                    Text(c, style: Txt.nb(13, color: p.texto)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );

    if (!context.esCelular) {
      return Padding(
        padding: paddingEscritorio,
        child: Column(
          children: [
            const EncabezadoEscritorio(titulo: 'Emergencia', subtitulo: 'Pide ayuda en segundos'),
            Expanded(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: contenido))),
          ],
        ),
      );
    }
    return Scaffold(appBar: const EncabezadoPantalla(titulo: 'Emergencia', cerrar: true), body: contenido);
  }

  Widget _botonGrande(BuildContext context) {
    final p = context.paleta;
    final halo = context.esOscuro ? 0.18 : 0.10;
    return SizedBox.square(
      dimension: 260,
      child: AnimatedBuilder(
        animation: Listenable.merge([_presion, _pulso]),
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            for (final (tam, alfa) in [(260.0, halo), (220.0, halo * 1.6), (180.0, halo * 2.4)])
              Transform.scale(
                scale: 1 + (_enviado ? 0 : 0.04 * (1 - (_pulso.value - tam / 520).abs())),
                child: Container(
                  width: tam,
                  height: tam,
                  decoration: BoxDecoration(color: AppColors.rojo.withValues(alpha: alfa), shape: BoxShape.circle),
                ),
              ),
            SizedBox.square(
              dimension: 152,
              child: CircularProgressIndicator(
                value: _presion.value,
                strokeWidth: 6,
                color: p.texto,
                backgroundColor: Colors.transparent,
              ),
            ),
            Semantics(
              button: true,
              label: 'Mantén presionado para enviar SOS',
              child: GestureDetector(
                onTapDown: _enviado ? null : (_) => _presion.forward(from: 0),
                onTapUp: _enviado ? null : (_) => _presion.isCompleted ? null : _presion.reverse(),
                onTapCancel: _enviado ? null : () => _presion.isCompleted ? null : _presion.reverse(),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: _enviado ? AppColors.verdeExito : AppColors.rojo,
                    shape: BoxShape.circle,
                    boxShadow: const [BoxShadow(color: Color(0x80FF292E), blurRadius: 12, offset: Offset(0, 8))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _enviado
                          ? const Icon(TablerIcons.check, size: 56, color: Colors.white)
                          : SvgPicture.asset('assets/icons/siren.svg', width: 56, height: 56),
                      const SizedBox(height: 2),
                      Text(_enviado ? 'Enviado' : 'SOS', style: Txt.r(22, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accion(BuildContext context, IconData icono, Color color, String titulo, String sub, VoidCallback onTap, {bool ultima = false}) {
    return FilaLista(
      titulo: titulo,
      subtitulo: sub,
      divisor: !ultima,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      onTap: onTap,
      leading: IconoCirculo(icono: icono, fondo: color, color: color == AppColors.amarillo ? Colors.black : Colors.white, tamano: 40, tamanoIcono: 20),
    );
  }
}
