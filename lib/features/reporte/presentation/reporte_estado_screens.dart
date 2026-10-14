import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/paleta.dart';
import '../../../widgets/app_shell.dart';
import '../../../widgets/botones.dart';
import '../../../widgets/encabezado_escritorio.dart';
import '../../../widgets/pantalla_secundaria.dart' show pildoraEstado;
import '../../../widgets/tarjeta.dart';
import '../../mapa/domain/modelos_mapa.dart';
import '../data/reporte_repository.dart';
import '../domain/reporte.dart';

/// Marco para pantallas centradas de una columna (celular a pantalla completa; tablet/PC en 480 px).
class _Marco extends StatelessWidget {
  const _Marco({required this.titulo, required this.child, this.cerrar = false, this.subtitulo});

  final String? titulo;
  final String? subtitulo;
  final Widget child;
  final bool cerrar;

  @override
  Widget build(BuildContext context) {
    final inferior = MediaQuery.paddingOf(context).bottom;
    if (!context.esCelular) {
      return SingleChildScrollView(
        padding: paddingEscritorio,
        child: Column(
          children: [
            EncabezadoEscritorio(titulo: titulo ?? 'Reporte', subtitulo: subtitulo),
            Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: child)),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: EncabezadoPantalla(
        titulo: cerrar ? null : titulo,
        cerrar: cerrar,
        onAtras: cerrar ? () => context.go('/inicio') : null,
      ),
      body: ListView(padding: EdgeInsets.fromLTRB(19, 0, 19, inferior + 24), children: [child]),
    );
  }
}

/// Círculo con dos halos (éxito, sin conexión).
class _IconoHalo extends StatelessWidget {
  const _IconoHalo({required this.icono, required this.color});

  final IconData icono;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 150,
        height: 150,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
        child: Container(
          width: 120,
          height: 120,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.25), shape: BoxShape.circle),
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icono, size: 44, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// ---------------- Reporte enviado ----------------

class ReporteEnviadoScreen extends ConsumerWidget {
  const ReporteEnviadoScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.paleta;
    final reporte = ref.watch(reportePorIdProvider(id)).value;
    Widget dato(IconData icono, String etiqueta, String valor, {bool ultimo = false}) => FilaLista(
          subtituloArriba: true,
          subtitulo: etiqueta,
          titulo: valor,
          divisor: !ultimo,
          leading: IconoCirculo(icono: icono, fondo: p.chip, color: p.texto, tamano: 40, tamanoIcono: 20),
        );
    return _Marco(
      titulo: 'Reporte enviado',
      cerrar: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const _IconoHalo(icono: TablerIcons.check, color: AppColors.verdeExito),
          const SizedBox(height: 26),
          Text('¡Reporte enviado!', textAlign: TextAlign.center, style: Txt.r(26, color: p.texto)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Tu reporte ya aparece en el mapa y lo recibió la autoridad más cercana.',
              textAlign: TextAlign.center,
              style: Txt.n(15, color: p.textoSecundario),
            ),
          ),
          const SizedBox(height: 40),
          Tarjeta(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                dato(TablerIcons.hash, 'Número de reporte', id),
                dato(TablerIcons.shield_check, 'Notificado a', reporte?.notificadoA ?? 'CAI Chapinero · 1,2 km'),
                dato(TablerIcons.users, 'Conductores alertados', '${reporte?.conductoresAlertados ?? 120} cerca de la zona', ultimo: true),
              ],
            ),
          ),
          const SizedBox(height: 60),
          BotonPrincipal(
            texto: 'Ver estado del reporte',
            icono: TablerIcons.arrow_right,
            iconoDerecha: true,
            color: AppColors.amarillo,
            alto: 50,
            onPressed: () => context.go('/reporte/estado/$id'),
          ),
          const SizedBox(height: 12),
          BotonContorno(texto: 'Volver al inicio', alto: 50, tamanoTexto: 18, onPressed: () => context.go('/inicio')),
        ],
      ),
    );
  }
}

// ---------------- Estado del reporte ----------------

class EstadoReporteScreen extends ConsumerWidget {
  const EstadoReporteScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.paleta;
    final async = ref.watch(reportePorIdProvider(id));
    return _Marco(
      titulo: 'Mi reporte',
      subtitulo: 'Seguimiento del reporte $id',
      child: async.when(
        loading: () => const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
        error: (e, _) => Text('Error: $e'),
        data: (r) {
          if (r == null) return Padding(padding: const EdgeInsets.all(40), child: Text('No encontramos el reporte $id', textAlign: TextAlign.center));
          final b = r.borrador;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Tarjeta(
                child: Row(
                  children: [
                    IconoCirculo(
                      icono: b.vehiculo == TipoVehiculo.moto ? TablerIcons.motorbike : TablerIcons.car,
                      fondo: AppColors.amarillo,
                      color: Colors.black,
                      tamano: 52,
                      tamanoIcono: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${b.nombreVehiculo} · ${b.placa}', style: Txt.nb(16, color: p.texto)),
                          Text('${b.modelo} · ${b.barrio}', style: Txt.n(13, color: p.textoSecundario)),
                        ],
                      ),
                    ),
                    pildoraEstado(context, r.estado),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(padding: const EdgeInsets.only(left: 10, bottom: 12), child: Text('Seguimiento', style: Txt.r(16, color: p.texto))),
              for (var i = 0; i < r.seguimiento.length; i++) _PasoLinea(paso: r.seguimiento[i], ultimo: i == r.seguimiento.length - 1),
              const SizedBox(height: 20),
              Tarjeta(
                child: Row(
                  children: [
                    const IconoCirculo(icono: TablerIcons.shield_check, fondo: AppColors.azulAutoridad, tamano: 52, tamanoIcono: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.agente, style: Txt.nb(16, color: p.texto)),
                          Text(r.unidadAgente, style: Txt.n(13, color: p.textoSecundario)),
                        ],
                      ),
                    ),
                    Material(
                      color: AppColors.verdeExito,
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Llamar al agente',
                        onPressed: () => launchUrl(Uri.parse('tel:123')),
                        icon: const Icon(TablerIcons.phone, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              BotonPrincipal(
                texto: 'Llamar al 123',
                icono: TablerIcons.phone,
                iconoDerecha: true,
                alto: 50,
                onPressed: () => launchUrl(Uri.parse('tel:123')),
              ),
              const SizedBox(height: 12),
              BotonContorno(
                texto: 'Compartir reporte',
                icono: TablerIcons.share,
                alto: 50,
                tamanoTexto: 18,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: 'Reporte ${r.id}: ${b.nombreVehiculo} ${b.placa} hurtada en ${b.direccion}. Alerta Vial'));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reporte copiado para compartir.')));
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PasoLinea extends StatelessWidget {
  const _PasoLinea({required this.paso, required this.ultimo});

  final PasoSeguimiento paso;
  final bool ultimo;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final gris = context.esOscuro ? const Color(0xFF2A3238) : const Color(0xFFD9D9D9);
    final (color, icono) = switch (paso.estado) {
      'hecho' => (AppColors.verdeExito, const Icon(TablerIcons.check, size: 18, color: Colors.white)),
      'actual' => (AppColors.amarillo, Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle))),
      _ => (gris, const SizedBox.shrink()),
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 52,
            child: Column(
              children: [
                Container(width: 30, height: 30, alignment: Alignment.center, decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: icono),
                if (!ultimo) Expanded(child: Container(width: 3, color: paso.estado == 'hecho' ? AppColors.verdeExito : gris)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 2, bottom: ultimo ? 0 : 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(paso.titulo, style: Txt.nb(16, color: paso.estado == 'pendiente' ? p.textoSecundario : p.texto)),
                  Text(paso.detalle, style: Txt.n(13, color: p.textoSecundario)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- Sin conexión ----------------

class SinConexionScreen extends ConsumerStatefulWidget {
  const SinConexionScreen({super.key});

  @override
  ConsumerState<SinConexionScreen> createState() => _SinConexionScreenState();
}

class _SinConexionScreenState extends ConsumerState<SinConexionScreen> {
  bool _reintentando = false;

  Future<void> _reintentar() async {
    setState(() => _reintentando = true);
    final repo = ref.read(reporteRepositoryProvider);
    final pendientes = await repo.pendientes();
    await repo.limpiarPendientes();
    String? ultimo;
    try {
      for (final b in pendientes) {
        ultimo = (await repo.enviar(b)).id;
      }
      if (mounted) context.go(ultimo == null ? '/inicio' : '/reporte/enviado/$ultimo');
    } on SinConexionException {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sigues sin conexión. Lo intentaremos de nuevo.')));
    } finally {
      if (mounted) setState(() => _reintentando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return _Marco(
      titulo: 'Sin conexión',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 50),
          Center(
            child: Container(
              width: 170,
              height: 170,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: p.suaveRojo, shape: BoxShape.circle),
              child: Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(color: AppColors.rojo, shape: BoxShape.circle),
                child: const Icon(TablerIcons.wifi_off, size: 48, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 36),
          Text('Sin conexión', textAlign: TextAlign.center, style: Txt.r(24, color: p.texto)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              'Revisa tu internet. Guardamos tu reporte y lo enviaremos cuando vuelvas a estar en línea.',
              textAlign: TextAlign.center,
              style: Txt.n(15, color: p.textoSecundario),
            ),
          ),
          const SizedBox(height: 70),
          Tarjeta(
            child: Row(
              children: [
                const Icon(TablerIcons.clock, color: AppColors.amarillo),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reporte pendiente de envío', style: Txt.nb(14, color: p.texto)),
                      Text('Se enviará automáticamente', style: Txt.n(12, color: p.textoSecundario)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          BotonPrincipal(texto: 'Reintentar', icono: TablerIcons.refresh, color: AppColors.amarillo, cargando: _reintentando, onPressed: _reintentar),
        ],
      ),
    );
  }
}
