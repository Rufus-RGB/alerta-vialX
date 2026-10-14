import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/paleta.dart';
import '../../../widgets/app_shell.dart';
import '../../../widgets/botones.dart';
import '../../../widgets/chips.dart';
import '../../../widgets/encabezado_escritorio.dart';
import '../../../widgets/etiqueta_riesgo.dart';
import '../../../widgets/menu_lateral.dart';
import '../../../widgets/tarjeta.dart';
import '../../mapa/domain/modelos_mapa.dart';
import '../../mapa/presentation/mapa_base.dart';
import '../../reporte/presentation/reporte_widgets.dart';
import '../data/alertas_repository.dart';

final _filtroAlertasProvider = NotifierProvider<_FiltroAlertas, FiltroVehiculo>(_FiltroAlertas.new);

class _FiltroAlertas extends Notifier<FiltroVehiculo> {
  @override
  FiltroVehiculo build() => FiltroVehiculo.todas;
  void cambiar(FiltroVehiculo f) => state = f;
}

/// Alertas filtradas por vehículo y por los tipos activados en "Configurar alertas".
final alertasVisiblesProvider = Provider<AsyncValue<List<Alerta>>>((ref) {
  final filtro = ref.watch(_filtroAlertasProvider);
  final config = ref.watch(configAlertasProvider);
  return ref.watch(alertasProvider).whenData(
        (l) => l.where((a) => config.permite(a.tipo) && (filtro == FiltroVehiculo.todas || (a.vehiculo != null && filtro.incluye(a.vehiculo!)))).toList(),
      );
});

Widget _pildoraNivel(BuildContext context, NivelRiesgo n) {
  final p = context.paleta;
  return Pildora(n == NivelRiesgo.info ? n.etiqueta : n.corta, fondo: n.fondo(p), color: n.texto(p));
}

/// Alertas del ciudadano. Celular: lista con alerta destacada. Tablet/PC: lista + panel de detalle.
class AlertasScreen extends ConsumerStatefulWidget {
  const AlertasScreen({super.key});

  @override
  ConsumerState<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends ConsumerState<AlertasScreen> {
  String? _seleccionada;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final alertas = ref.watch(alertasVisiblesProvider);
    final filtro = ref.watch(_filtroAlertasProvider);
    final celular = context.esCelular;
    final chips = GrupoChips<FiltroVehiculo>(
      opciones: FiltroVehiculo.values,
      seleccionado: filtro,
      etiqueta: (f) => f.etiqueta,
      alto: 36,
      onChanged: ref.read(_filtroAlertasProvider.notifier).cambiar,
    );

    Widget lista(List<Alerta> l) {
      final principal = l.where((a) => a.nivel == NivelRiesgo.alto && a.tipo == TipoAlerta.hurto).firstOrNull;
      final sel = _seleccionada ?? l.firstOrNull?.id;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (principal != null) ...[
            _AlertaPrincipal(alerta: principal, compacta: !celular),
            SizedBox(height: celular ? 6 : 24),
          ],
          Row(
            children: [
              Expanded(child: Text('Alertas recientes', style: celular ? Txt.r(20, color: p.texto) : Txt.nb(16, color: p.texto))),
              if (celular) TextButton(onPressed: () {}, child: Text('Ver todas ›', style: Txt.nb(12, color: p.enlace))),
            ],
          ),
          const SizedBox(height: 8),
          if (l.isEmpty)
            Padding(
              padding: const EdgeInsets.all(30),
              child: Text('No hay alertas con estos filtros.', textAlign: TextAlign.center, style: Txt.n(14, color: p.textoSecundario)),
            ),
          for (final a in l)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TarjetaAlerta(
                alerta: a,
                compacta: !celular,
                seleccionada: !celular && a.id == sel,
                onTap: () => celular ? context.push('/alertas/${a.id}') : setState(() => _seleccionada = a.id),
              ),
            ),
        ],
      );
    }

    if (celular) {
      final inferior = MediaQuery.paddingOf(context).bottom;
      return Scaffold(
        drawer: const MenuLateral(rutaActiva: '/alertas'),
        appBar: AppBar(
          toolbarHeight: 72,
          leading: Builder(
            builder: (context) => IconButton(tooltip: 'Menú', onPressed: () => Scaffold.of(context).openDrawer(), icon: Icon(TablerIcons.menu_2, size: 28, color: p.texto)),
          ),
          title: Text('Alertas', style: Txt.r(24, color: p.texto)),
          actions: [
            IconButton(tooltip: 'Configurar alertas', onPressed: () => context.push('/alertas/configurar'), icon: Icon(TablerIcons.settings, size: 30, color: p.texto)),
            const SizedBox(width: 10),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(20, 4, 20, inferior + 20),
          children: [chips, const SizedBox(height: 14), alertas.when(data: lista, loading: () => const Center(child: CircularProgressIndicator()), error: (e, _) => Text('$e'))],
        ),
      );
    }

    final datos = alertas.value ?? const <Alerta>[];
    final sel = datos.where((a) => a.id == (_seleccionada ?? datos.firstOrNull?.id)).firstOrNull;
    return Padding(
      padding: paddingEscritorio,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EncabezadoEscritorio(
            titulo: 'Alertas',
            subtitulo: '${datos.length} alertas nuevas hoy',
            acciones: [
              BotonCircular(icono: TablerIcons.settings, tooltip: 'Configurar alertas', onPressed: () => context.push('/alertas/configurar')),
            ],
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: context.pantalla == TipoPantalla.escritorio ? 440 : 380,
                  child: ListView(children: [chips, const SizedBox(height: 18), lista(datos)]),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Tarjeta(
                    padding: const EdgeInsets.all(20),
                    child: sel == null
                        ? Center(child: Text('Selecciona una alerta', style: Txt.n(14, color: p.textoSecundario)))
                        : SingleChildScrollView(child: DetalleAlertaContenido(alerta: sel, ancho: true)),
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

class _AlertaPrincipal extends StatelessWidget {
  const _AlertaPrincipal({required this.alerta, required this.compacta});

  final Alerta alerta;
  final bool compacta;

  @override
  Widget build(BuildContext context) {
    final a = alerta;
    final detalle = a.descripcionVehiculo?.replaceAll(' · ', ' ') ?? '';
    final etiquetaTiempo = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(10)),
      child: Text('Hace ${a.minutos} min', style: Txt.nb(11, color: Colors.white)),
    );
    final decoracion = BoxDecoration(
      color: AppColors.rojo,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 14, offset: Offset(0, 4))],
    );
    if (compacta) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
        decoration: decoracion,
        child: Row(
          children: [
            SvgPicture.asset('assets/icons/siren.svg', width: 52, height: 52),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Alerta de hurto', style: Txt.r(20, color: Colors.white)),
                  Text('Placa ${a.placa} · ${a.descripcionVehiculo?.split(' · ').last ?? ''}', style: Txt.nb(14, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('${a.lugar} · Zona de alto riesgo', style: Txt.n(13, color: Colors.white)),
                  const SizedBox(height: 4),
                  etiquetaTiempo,
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 24, 12),
      decoration: decoracion,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            children: [
              SvgPicture.asset('assets/icons/siren.svg', width: 103, height: 103),
              const SizedBox(height: 16),
              etiquetaTiempo,
              const SizedBox(height: 14),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Alerta de hurto\nPlaca ${a.placa}\n$detalle', style: Txt.r(16, color: Colors.white, weight: FontWeight.w800, height: 1.4)),
                const SizedBox(height: 10),
                Text('${a.lugar} · Zona de alto riesgo', style: Txt.r(16, color: Colors.white, weight: FontWeight.w500)),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: Txt.r(16, weight: FontWeight.w800),
                    ),
                    onPressed: () => context.go('/mapa?lat=${a.punto.latitude}&lng=${a.punto.longitude}'),
                    child: const Text('Ver en el mapa'),
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

class _TarjetaAlerta extends StatelessWidget {
  const _TarjetaAlerta({required this.alerta, required this.onTap, this.compacta = false, this.seleccionada = false});

  final Alerta alerta;
  final VoidCallback onTap;
  final bool compacta;
  final bool seleccionada;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final a = alerta;
    final titulo = compacta ? a.titulo : a.titulo.split(' ').map((w) => w.length > 2 ? '${w[0].toUpperCase()}${w.substring(1)}' : w).join(' ');
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: seleccionada ? Border.all(color: AppColors.amarillo, width: 2) : null,
      ),
      child: Tarjeta(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconoCirculo(
              icono: a.tipo.icono,
              fondo: a.tipo.color,
              color: a.tipo == TipoAlerta.aumento ? Colors.black : Colors.white,
              tamano: compacta ? 48 : 52,
              tamanoIcono: compacta ? 24 : 30,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(titulo, style: Txt.nb(compacta ? 15 : 16, color: p.texto))),
                      _pildoraNivel(context, a.nivel),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(child: Text('${a.lugar} · ${a.hora}', style: Txt.n(compacta ? 13 : 14, color: p.textoSecundario))),
                      if (!compacta) Text('Detalles ›', style: Txt.nb(14, color: p.enlace)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Contenido del detalle de una alerta (mapa, tarjeta, datos, consejo y acciones).
class DetalleAlertaContenido extends StatelessWidget {
  const DetalleAlertaContenido({super.key, required this.alerta, this.ancho = false});

  final Alerta alerta;
  final bool ancho;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final a = alerta;
    final filas = <(IconData, String, String)>[
      if (a.descripcionVehiculo != null)
        (a.vehiculo == TipoVehiculo.auto ? TablerIcons.car : TablerIcons.motorbike, 'Vehículo', a.descripcionVehiculo!),
      if (a.placa != null) (TablerIcons.id, 'Placa', a.placa!),
      (TablerIcons.map_pin, 'Ubicación', a.direccion ?? a.lugar),
      if (a.distancia != null) (TablerIcons.route, 'Distancia', ancho ? a.distancia!.replaceAll('tu ubicación', 'ti') : a.distancia!),
    ];
    final mapa = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: p.borde)),
        child: SizedBox(
          height: ancho ? 276 : 180,
          child: FlutterMap(
            options: MapOptions(initialCenter: a.punto, initialZoom: 15, interactionOptions: const InteractionOptions(flags: InteractiveFlag.none)),
            children: [
              MapaBase.capaTiles(context),
              CircleLayer(circles: [
                for (var k = 5; k >= 1; k--)
                  CircleMarker(point: a.punto, radius: 90.0 * k, useRadiusInMeter: true, color: AppColors.rojo.withValues(alpha: 0.06)),
              ]),
              MarkerLayer(markers: [
                Marker(point: a.punto, width: 120, height: 92, alignment: const Alignment(0, -0.25), child: PinConEtiqueta(etiqueta: a.lugar)),
              ]),
            ],
          ),
        ),
      ),
    );
    final encabezado = Row(
      children: [
        IconoCirculo(icono: a.tipo.icono, fondo: a.tipo.color, color: a.tipo == TipoAlerta.aumento ? Colors.black : Colors.white, tamano: 56, tamanoIcono: 30),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.titulo, style: Txt.r(20, color: p.texto)),
              Text('${a.lugar} · Hoy, ${a.hora}', style: Txt.n(13, color: p.textoSecundario)),
            ],
          ),
        ),
        _pildoraNivel(context, a.nivel),
      ],
    );
    final consejo = a.consejo == null
        ? null
        : Container(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
            decoration: BoxDecoration(
              color: p.suaveAmarillo,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.amarillo),
            ),
            child: Row(
              children: [
                const Icon(TablerIcons.bulb, size: 22, color: AppColors.amarillo),
                const SizedBox(width: 10),
                Expanded(child: Text(a.consejo!, style: Txt.n(13, color: p.texto))),
              ],
            ),
          );
    void verMapa() => context.go('/mapa?lat=${a.punto.latitude}&lng=${a.punto.longitude}');
    void compartir() {
      Clipboard.setData(ClipboardData(text: '${a.titulo} en ${a.lugar} (${a.hora}). ${a.consejo ?? ''} — Alerta Vial'));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alerta copiada para compartir.')));
    }

    if (ancho) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          encabezado,
          const SizedBox(height: 16),
          mapa,
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              final w = (c.maxWidth - 16) / 2;
              return Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  for (final (icono, etiqueta, valor) in filas)
                    Container(
                      width: w,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Icon(icono, size: 22, color: p.texto),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(etiqueta, style: Txt.n(12, color: p.textoSecundario)),
                                Text(valor, overflow: TextOverflow.ellipsis, style: Txt.nb(14, color: p.texto)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          if (consejo != null) ...[const SizedBox(height: 24), consejo],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: BotonPrincipal(texto: 'Ver en el mapa', icono: TablerIcons.arrow_right, color: AppColors.amarillo, alto: 48, tamanoTexto: 16, onPressed: verMapa)),
              const SizedBox(width: 16),
              Expanded(child: BotonContorno(texto: 'Compartir', icono: TablerIcons.share, alto: 48, tamanoTexto: 16, onPressed: compartir)),
            ],
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        mapa,
        const SizedBox(height: 14),
        Tarjeta(padding: const EdgeInsets.all(16), child: encabezado),
        const SizedBox(height: 12),
        Tarjeta(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, (icono, etiqueta, valor)) in filas.indexed)
                FilaLista(
                  subtituloArriba: true,
                  subtitulo: etiqueta,
                  titulo: valor,
                  divisor: i < filas.length - 1,
                  leading: Icon(icono, size: 24, color: p.texto),
                ),
            ],
          ),
        ),
        if (consejo != null) ...[const SizedBox(height: 12), consejo],
        const SizedBox(height: 12),
        BotonPrincipal(texto: 'Ver en el mapa', icono: TablerIcons.arrow_right, iconoDerecha: true, color: AppColors.amarillo, alto: 50, tamanoTexto: 20, onPressed: verMapa),
      ],
    );
  }
}

/// Pantalla de detalle de alerta en celular (/alertas/:id).
class DetalleAlertaScreen extends ConsumerWidget {
  const DetalleAlertaScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerta = ref.watch(alertasProvider).value?.where((a) => a.id == id).firstOrNull;
    final inferior = MediaQuery.paddingOf(context).bottom;
    final contenido = alerta == null ? const Center(child: CircularProgressIndicator()) : DetalleAlertaContenido(alerta: alerta, ancho: !context.esCelular);
    if (!context.esCelular) {
      return SingleChildScrollView(
        padding: paddingEscritorio,
        child: Column(children: [const EncabezadoEscritorio(titulo: 'Detalle de alerta'), Tarjeta(padding: const EdgeInsets.all(20), child: contenido)]),
      );
    }
    return Scaffold(
      appBar: const EncabezadoPantalla(titulo: 'Detalle de alerta'),
      body: ListView(padding: EdgeInsets.fromLTRB(19, 8, 19, inferior + 24), children: [contenido]),
    );
  }
}
