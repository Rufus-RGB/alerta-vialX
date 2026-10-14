import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/paleta.dart';
import '../../../widgets/app_shell.dart';
import '../../../widgets/botones.dart';
import '../../../widgets/encabezado_escritorio.dart';
import '../../../widgets/menu_lateral.dart';
import '../../../widgets/tarjeta.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../mapa/data/mapa_repository.dart';
import '../../mapa/presentation/mapa_base.dart';
import '../data/clima_repository.dart';
import 'inicio_widgets.dart';

/// Inicio del ciudadano. Celular: "Home Screen"; tablet/PC: panel con KPIs y mapa en vivo.
class InicioScreen extends ConsumerWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return context.esCelular ? const _InicioCelular() : const _InicioAncho();
  }
}

/// Hero de Bogotá recortado como en el Figma (imagen al 118,5 % del ancho).
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => ClipRect(
        child: OverflowBox(
          maxWidth: c.maxWidth * 1.1852,
          minWidth: c.maxWidth * 1.1852,
          alignment: const Alignment(-0.13, 0.4),
          child: Image.asset('assets/images/hero_bogota.png', fit: BoxFit.fitWidth),
        ),
      ),
    );
  }
}

class _InicioCelular extends ConsumerWidget {
  const _InicioCelular();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.paleta;
    final usuario = ref.watch(authControllerProvider).usuario;
    final inferior = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      drawer: const MenuLateral(),
      body: Builder(
        builder: (context) => ListView(
          padding: EdgeInsets.only(bottom: inferior + 16),
          children: [
            SizedBox(
              height: 412,
              child: Stack(
                children: [
                  const Positioned(left: 0, right: 0, top: 111, height: 226, child: _Hero()),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 16, 6, 0),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Menú',
                            onPressed: () => Scaffold.of(context).openDrawer(),
                            icon: Icon(TablerIcons.menu_2, size: 28, color: p.texto),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Notificaciones',
                            onPressed: () => context.push('/notificaciones'),
                            icon: Badge(
                              smallSize: 9,
                              backgroundColor: AppColors.rojo,
                              child: Icon(TablerIcons.bell, size: 24, color: p.texto),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 17,
                    top: MediaQuery.paddingOf(context).top + 52,
                    right: 17,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hola, ${usuario?.primerNombre ?? 'User'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: Txt.display(40, color: p.texto)),
                        Text('Conduce informado, llega seguro', style: Txt.n(12, color: p.textoTenue, spacing: -0.12)),
                      ],
                    ),
                  ),
                  const Positioned(left: 17, right: 17, top: 322, child: TarjetaClima()),
                ],
              ),
            ),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 17), child: BannerPublicidad()),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17),
              child: Row(
                children: [
                  Expanded(
                    child: _BotonAccion(
                      icono: TablerIcons.urgent,
                      texto: 'Reportar\nIncidente',
                      fondo: AppColors.rojo,
                      color: Colors.white,
                      onTap: () => context.go('/reporte'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _BotonAccion(
                      icono: TablerIcons.map_pin_filled,
                      texto: 'Ver Mapa',
                      fondo: AppColors.amarillo,
                      color: Colors.black,
                      onTap: () => context.go('/mapa'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _BotonAccion(
                      icono: TablerIcons.shield_filled,
                      texto: 'CAI Cercanos',
                      fondo: p.botonNegro,
                      color: Colors.white,
                      borde: context.esOscuro ? const Color(0xFF2C363E) : null,
                      onTap: () => mostrarCaisCercanos(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 17), child: ListaZonas()),
          ],
        ),
      ),
    );
  }
}

class _BotonAccion extends StatelessWidget {
  const _BotonAccion({required this.icono, required this.texto, required this.fondo, required this.color, required this.onTap, this.borde});

  final IconData icono;
  final String texto;
  final Color fondo;
  final Color color;
  final Color? borde;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fondo,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: borde == null ? BorderSide.none : BorderSide(color: borde!)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 86,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icono == TablerIcons.urgent
                  ? SvgPicture.asset('assets/icons/siren.svg', width: 30, height: 30)
                  : Icon(icono, size: 30, color: color),
              const SizedBox(height: 6),
              Text(texto, textAlign: TextAlign.center, style: Txt.r(13, color: color, height: 15 / 13)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- Tablet / PC ----------------

class _InicioAncho extends ConsumerWidget {
  const _InicioAncho();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.paleta;
    final usuario = ref.watch(authControllerProvider).usuario;
    final resumen = ref.watch(resumenInicioProvider).value;
    final esPc = context.pantalla == TipoPantalla.escritorio;

    final kpis = resumen == null
        ? const <Widget>[]
        : [
            _Kpi(titulo: 'Reportes hoy', valor: '${resumen.reportesHoy}', nota: '+${resumen.variacion} vs ayer', colorNota: AppColors.verdeExito, icono: TablerIcons.file_text, fondoIcono: p.suaveAmarillo, colorIcono: const Color(0xFFB88600)),
            _Kpi(titulo: 'Zona actual', valor: resumen.zonaActual, nota: resumen.riesgoZona, colorNota: p.textoMedio, icono: TablerIcons.map_pin, fondoIcono: p.suaveAmarillo, colorIcono: const Color(0xFFB88600)),
            _Kpi(titulo: 'Alertas cerca', valor: '${resumen.alertasCerca}', nota: 'En 1 km', colorNota: p.textoAlto, icono: TablerIcons.bell, fondoIcono: p.suaveRojo, colorIcono: AppColors.rojo),
            _Kpi(titulo: 'CAI más cercano', valor: resumen.caiDistancia, nota: resumen.caiNombre, colorNota: p.textoSecundario, icono: TablerIcons.shield, fondoIcono: p.suaveAzul, colorIcono: AppColors.azulAutoridad),
          ];

    return SingleChildScrollView(
      padding: paddingEscritorio,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EncabezadoEscritorio(titulo: 'Inicio', subtitulo: fechaLarga(DateTime.now())),
          // Banner de bienvenida
          Tarjeta(
            padding: EdgeInsets.zero,
            radio: 20,
            child: SizedBox(
              height: esPc ? 200 : 176,
              child: Stack(
                children: [
                  Positioned(
                    right: -8,
                    top: -10,
                    bottom: -6,
                    width: esPc ? 509 : 420,
                    child: Image.asset('assets/images/hero_bogota.png', fit: BoxFit.cover, alignment: Alignment.centerLeft),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [p.tarjeta, p.tarjeta, p.tarjeta.withValues(alpha: 0)],
                          stops: const [0, 0.42, 0.62],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(31, 26, 31, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hola, ${usuario?.primerNombre ?? 'User'}', style: Txt.r(40, color: p.texto)),
                        Text('Conduce informado, llega seguro', style: Txt.n(15, color: p.textoSecundario)),
                        const Spacer(),
                        const PildoraClima(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              for (var i = 0; i < kpis.length; i++) ...[if (i > 0) const SizedBox(width: 20), Expanded(child: kpis[i])],
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 448,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(flex: 699, child: _MapaEnVivo()),
                const SizedBox(width: 20),
                Expanded(
                  flex: 409,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Tarjeta(
                        padding: const EdgeInsets.fromLTRB(15, 13, 15, 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Acciones rápidas', style: Txt.nb(15, color: p.texto)),
                            const SizedBox(height: 12),
                            _AccionAncha(texto: 'Reportar incidente', icono: TablerIcons.urgent, fondo: AppColors.rojo, color: Colors.white, onTap: () => context.go('/reporte')),
                            const SizedBox(height: 8),
                            _AccionAncha(texto: 'Ver mapa', icono: TablerIcons.map, fondo: AppColors.amarillo, color: Colors.black, onTap: () => context.go('/mapa')),
                            const SizedBox(height: 8),
                            _AccionAncha(texto: 'CAI cercanos', icono: TablerIcons.shield, fondo: p.botonNegro, color: Colors.white, onTap: () => mostrarCaisCercanos(context)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Expanded(child: SingleChildScrollView(child: ListaZonas(compacta: true, titulo: 'Zonas de riesgo'))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.titulo,
    required this.valor,
    required this.nota,
    required this.colorNota,
    required this.icono,
    required this.fondoIcono,
    required this.colorIcono,
  });

  final String titulo;
  final String valor;
  final String nota;
  final Color colorNota;
  final IconData icono;
  final Color fondoIcono;
  final Color colorIcono;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Tarjeta(
      padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: Txt.n(12, color: p.textoSecundario)),
                const SizedBox(height: 4),
                Text(valor, maxLines: 1, overflow: TextOverflow.ellipsis, style: Txt.r(22, color: p.texto)),
                const SizedBox(height: 2),
                Text(nota, maxLines: 1, overflow: TextOverflow.ellipsis, style: Txt.nb(11, color: colorNota)),
              ],
            ),
          ),
          IconoCirculo(icono: icono, fondo: fondoIcono, color: colorIcono, tamano: 40, tamanoIcono: 20),
        ],
      ),
    );
  }
}

class _AccionAncha extends StatelessWidget {
  const _AccionAncha({required this.texto, required this.icono, required this.fondo, required this.color, required this.onTap});

  final String texto;
  final IconData icono;
  final Color fondo;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fondo,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 42,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, size: 18, color: color),
              const SizedBox(width: 8),
              Text(texto, style: Txt.r(13, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Mapa en vivo" del inicio de tablet/PC.
class _MapaEnVivo extends ConsumerWidget {
  const _MapaEnVivo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.paleta;
    final incidentes = ref.watch(incidentesProvider).value ?? const [];
    final zonas = ref.watch(zonasRiesgoProvider).value ?? const [];
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: p.borde)),
        child: Stack(
          children: [
            Positioned.fill(
              child: MapaBase(
                incidentes: incidentes,
                zonas: zonas,
                zoom: 12,
                centro: const LatLng(4.655, -74.095),
                onIncidente: (i) => context.go('/mapa?incidente=${i.id}'),
              ),
            ),
            Positioned(
              left: 15,
              top: 15,
              child: Material(
                color: p.tarjeta,
                elevation: 3,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => context.go('/mapa'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(TablerIcons.map, size: 18, color: p.texto),
                        const SizedBox(width: 8),
                        Text('Mapa en vivo', style: Txt.nb(13, color: p.texto)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: BotonCircular(icono: TablerIcons.arrows_maximize, tooltip: 'Abrir mapa', radio: 12, sombra: true, onPressed: () => context.go('/mapa')),
            ),
          ],
        ),
      ),
    );
  }
}
