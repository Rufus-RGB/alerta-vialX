import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/paleta.dart';
import '../../../widgets/app_shell.dart';
import '../../../widgets/botones.dart';
import '../../../widgets/campos.dart';
import '../../../widgets/chips.dart';
import '../../../widgets/encabezado_escritorio.dart';
import '../../../widgets/etiqueta_riesgo.dart';
import '../../../widgets/tarjeta.dart';
import '../data/mapa_repository.dart';
import '../domain/modelos_mapa.dart';
import 'detalle_incidente.dart';
import 'mapa_base.dart';
import 'mapa_controller.dart';

/// Mapa principal del ciudadano. Celular: mapa a pantalla completa con buscador,
/// filtros y tarjeta de zona. Tablet/PC: lista de recientes + mapa con ventana emergente.
class MapaScreen extends ConsumerStatefulWidget {
  const MapaScreen({super.key, this.foco, this.incidenteId, this.zona, this.busqueda});

  final LatLng? foco;
  final String? incidenteId;
  final String? zona;
  final String? busqueda;

  @override
  ConsumerState<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends ConsumerState<MapaScreen> {
  final _mapa = MapController();
  final _buscar = TextEditingController();
  LatLng? _miUbicacion;
  bool _buscandoUbicacion = false;
  String? _seleccionado;
  bool _listo = false;

  @override
  void initState() {
    super.initState();
    if (widget.busqueda != null) {
      _buscar.text = widget.busqueda!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(busquedaMapaProvider.notifier).cambiar(widget.busqueda!);
      });
    }
  }

  @override
  void didUpdateWidget(MapaScreen old) {
    super.didUpdateWidget(old);
    if (widget.foco != old.foco || widget.incidenteId != old.incidenteId || widget.zona != old.zona) _aplicarFoco();
    if (widget.busqueda != null && widget.busqueda != old.busqueda) {
      _buscar.text = widget.busqueda!;
      ref.read(busquedaMapaProvider.notifier).cambiar(widget.busqueda!);
    }
  }

  @override
  void dispose() {
    _mapa.dispose();
    _buscar.dispose();
    super.dispose();
  }

  /// Centra el mapa según los parámetros de la ruta (lat/lng, incidente o zona).
  void _aplicarFoco() {
    if (!_listo || !mounted) return;
    if (widget.foco != null) {
      _mapa.move(widget.foco!, 14);
    } else if (widget.incidenteId != null) {
      final i = ref.read(incidentesProvider).value?.where((e) => e.id == widget.incidenteId).firstOrNull;
      if (i != null) _seleccionar(i);
    } else if (widget.zona != null) {
      final z = ref.read(zonasRiesgoProvider).value?.where((e) => e.nombre == widget.zona).firstOrNull;
      if (z != null) _mapa.move(z.centro, 14);
    }
  }

  void _seleccionar(IncidenteHurto i, {bool abrirDetalle = false}) {
    setState(() => _seleccionado = i.id);
    _mapa.move(i.punto, 14);
    if (abrirDetalle || context.esCelular) {
      mostrarDetalleIncidente(context, i, hoja: context.esCelular).then((_) {
        if (mounted && context.esCelular) setState(() => _seleccionado = null);
      });
    }
  }

  Future<void> _irAMiUbicacion() async {
    setState(() => _buscandoUbicacion = true);
    try {
      final punto = await obtenerUbicacionActual();
      if (!mounted) return;
      setState(() => _miUbicacion = punto);
      _mapa.move(punto, 15);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _buscandoUbicacion = false);
    }
  }

  void _buscarTexto(String q) {
    ref.read(busquedaMapaProvider.notifier).cambiar(q);
    final t = q.toLowerCase().trim();
    if (t.isEmpty) return;
    final zona = ref.read(zonasRiesgoProvider).value?.where((z) => z.nombre.toLowerCase().contains(t)).firstOrNull;
    final inc = ref.read(incidentesProvider).value?.where((i) => i.coincide(t)).firstOrNull;
    if (inc != null) {
      _mapa.move(inc.punto, 14);
    } else if (zona != null) {
      _mapa.move(zona.centro, 14);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sin resultados para "$q"')));
    }
  }

  void _zoom(double delta) => _mapa.move(_mapa.camera.center, (_mapa.camera.zoom + delta).clamp(9, 18));

  MapaBase _mapaBase(List<IncidenteHurto> incidentes, List<ZonaRiesgo> zonas) => MapaBase(
        controller: _mapa,
        incidentes: incidentes,
        zonas: zonas,
        miUbicacion: _miUbicacion,
        seleccionado: _seleccionado,
        centro: widget.foco,
        zoom: widget.foco == null ? 12 : 14,
        onIncidente: _seleccionar,
      );

  @override
  Widget build(BuildContext context) {
    final incidentes = ref.watch(incidentesFiltradosProvider).value ?? const <IncidenteHurto>[];
    final zonas = ref.watch(zonasRiesgoProvider).value ?? const <ZonaRiesgo>[];
    if (!_listo && ref.watch(incidentesProvider).hasValue && zonas.isNotEmpty) {
      _listo = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _aplicarFoco());
    }
    return context.esCelular ? _celular(context, incidentes, zonas) : _ancho(context, incidentes, zonas);
  }

  // ---------- Celular ----------
  Widget _celular(BuildContext context, List<IncidenteHurto> incidentes, List<ZonaRiesgo> zonas) {
    final filtro = ref.watch(filtroVehiculoProvider);
    final inferior = MediaQuery.paddingOf(context).bottom;
    final zona = zonas.where((z) => z.nivel == NivelRiesgo.alto).firstOrNull ?? zonas.firstOrNull;
    final ultimo = incidentes.where((i) => zona != null && i.barrio == zona.nombre).firstOrNull;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _mapaBase(incidentes, zonas)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(19, 12, 19, 0),
              child: Column(
                children: [
                  Buscador(hint: 'Buscar dirección o zona', controller: _buscar, onSubmitted: _buscarTexto, alto: 40, radio: 14, sombra: true),
                  const SizedBox(height: 12),
                  GrupoChips<FiltroVehiculo>(
                    opciones: FiltroVehiculo.values,
                    seleccionado: filtro,
                    etiqueta: (f) => f.etiquetaMapa,
                    icono: (f) => switch (f) {
                      FiltroVehiculo.todas => null,
                      FiltroVehiculo.motos => TablerIcons.motorbike,
                      FiltroVehiculo.autos => TablerIcons.car,
                    },
                    sombra: true,
                    expandir: true,
                    onChanged: ref.read(filtroVehiculoProvider.notifier).cambiar,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: inferior + 112,
            child: Column(
              children: [
                _botonMapa(
                  _buscandoUbicacion ? null : TablerIcons.current_location,
                  'Mi ubicación',
                  _buscandoUbicacion ? null : _irAMiUbicacion,
                ),
                const SizedBox(height: 12),
                _botonMapa(TablerIcons.navigation, 'Centrar en Bogotá', () => _mapa.move(AppConstants.centroBogota, 12)),
              ],
            ),
          ),
          if (zona != null)
            Positioned(
              left: 19,
              right: 16,
              bottom: inferior + 14,
              child: _TarjetaZona(zona: zona, ultimo: ultimo, onTap: () => _mapa.move(zona.centro, 14)),
            ),
        ],
      ),
    );
  }

  Widget _botonMapa(IconData? icono, String tooltip, VoidCallback? onPressed) {
    if (icono == null) {
      return Container(
        width: 50,
        height: 50,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: context.paleta.tarjeta, shape: BoxShape.circle),
        child: const CircularProgressIndicator(strokeWidth: 2.5),
      );
    }
    return BotonCircular(icono: icono, tooltip: tooltip, onPressed: onPressed, tamano: 50, sombra: true);
  }

  // ---------- Tablet / PC ----------
  Widget _ancho(BuildContext context, List<IncidenteHurto> incidentes, List<ZonaRiesgo> zonas) {
    final p = context.paleta;
    final filtro = ref.watch(filtroVehiculoProvider);
    final sel = incidentes.where((i) => i.id == _seleccionado).firstOrNull;
    final esPc = context.pantalla == TipoPantalla.escritorio;

    final lista = Tarjeta(
      padding: const EdgeInsets.fromLTRB(8, 15, 8, 8),
      sombra: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: Buscador(hint: 'Buscar dirección o zona', controller: _buscar, onSubmitted: _buscarTexto, radio: 12),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: GrupoChips<FiltroVehiculo>(
              opciones: FiltroVehiculo.values,
              seleccionado: filtro,
              etiqueta: (f) => f.etiqueta,
              alto: 34,
              onChanged: ref.read(filtroVehiculoProvider.notifier).cambiar,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 18, 7, 6),
            child: Text('Recientes', style: Txt.nb(14, color: p.textoSecundario)),
          ),
          Expanded(
            child: incidentes.isEmpty
                ? Center(child: Text('Sin reportes con este filtro', style: Txt.n(13, color: p.textoSecundario)))
                : ListView.builder(
                    itemCount: incidentes.length,
                    itemBuilder: (context, n) => _FilaReciente(
                      incidente: incidentes[n],
                      activo: incidentes[n].id == _seleccionado,
                      onTap: () => _seleccionar(incidentes[n]),
                    ),
                  ),
          ),
        ],
      ),
    );

    final mapa = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: p.borde)),
        child: Stack(
          children: [
            Positioned.fill(child: _mapaBase(incidentes, zonas)),
            if (sel != null)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(child: _Emergente(incidente: sel, onVer: () => mostrarDetalleIncidente(context, sel, hoja: false), onCerrar: () => setState(() => _seleccionado = null))),
              ),
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                children: [
                  BotonCircular(icono: TablerIcons.plus, tooltip: 'Acercar', onPressed: () => _zoom(1), radio: 12, sombra: true),
                  const SizedBox(height: 6),
                  BotonCircular(icono: TablerIcons.minus, tooltip: 'Alejar', onPressed: () => _zoom(-1), radio: 12, sombra: true),
                  const SizedBox(height: 10),
                  BotonCircular(icono: TablerIcons.current_location, tooltip: 'Mi ubicación', onPressed: _buscandoUbicacion ? null : _irAMiUbicacion, sombra: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: paddingEscritorio,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EncabezadoEscritorio(titulo: 'Mapa', subtitulo: 'Incidentes en tiempo real'),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: esPc ? 380 : 320, child: lista),
                const SizedBox(width: 20),
                Expanded(child: mapa),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaZona extends StatelessWidget {
  const _TarjetaZona({required this.zona, required this.ultimo, required this.onTap});

  final ZonaRiesgo zona;
  final IncidenteHurto? ultimo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final alto = zona.nivel == NivelRiesgo.alto;
    return Tarjeta(
      radio: 18,
      borde: false,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
      child: Row(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(color: alto ? AppColors.rojo : AppColors.amarillo, shape: BoxShape.circle),
            child: Icon(TablerIcons.alert_triangle_filled, size: 36, color: alto ? Colors.white : Colors.black),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alto ? 'Zona De Alto Riesgo' : 'Zona De Riesgo Medio', style: Txt.nb(20, color: p.texto)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: Text('Localidad ${zona.nombre}', overflow: TextOverflow.ellipsis, style: Txt.n(14, color: p.textoSecundario))),
                    if (ultimo != null) Text(haceTiempo(ultimo!.fecha, mayuscula: true), style: Txt.n(14, color: p.textoSecundario)),
                  ],
                ),
              ],
            ),
          ),
          Icon(TablerIcons.chevron_right, color: p.textoSecundario),
        ],
      ),
    );
  }
}

class _FilaReciente extends StatelessWidget {
  const _FilaReciente({required this.incidente, required this.activo, required this.onTap});

  final IncidenteHurto incidente;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final i = incidente;
    final moto = i.vehiculo == TipoVehiculo.moto;
    return Material(
      color: activo ? p.suaveAmarillo : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            children: [
              IconoCirculo(
                icono: moto ? TablerIcons.motorbike : TablerIcons.car,
                fondo: moto ? AppColors.amarillo : AppColors.rojo,
                color: moto ? Colors.black : Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${i.titulo} · ${i.placa}', overflow: TextOverflow.ellipsis, style: Txt.nb(13, color: p.texto)),
                    const SizedBox(height: 3),
                    Text('${i.barrio} · ${haceTiempo(i.fecha)}', style: Txt.n(12, color: p.textoSecundario)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              EtiquetaRiesgo(i.nivel, corta: true),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ventana emergente sobre el mapa (PC): título, lugar y botón "Ver detalle".
class _Emergente extends StatelessWidget {
  const _Emergente({required this.incidente, required this.onVer, required this.onCerrar});

  final IncidenteHurto incidente;
  final VoidCallback onVer;
  final VoidCallback onCerrar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final i = incidente;
    return SizedBox(
      width: 280,
      child: Tarjeta(
        borde: false,
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconoCirculo(icono: i.vehiculo == TipoVehiculo.moto ? TablerIcons.motorbike : TablerIcons.car, fondo: AppColors.amarillo, color: Colors.black, tamano: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(i.titulo, style: Txt.r(15, color: p.texto)),
                      Text('${i.barrio} · ${haceTiempo(i.fecha)}', style: Txt.n(12, color: p.textoSecundario)),
                    ],
                  ),
                ),
                EtiquetaRiesgo(i.nivel, corta: true),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: BotonPrincipal(texto: 'Ver detalle', icono: TablerIcons.arrow_right, color: AppColors.amarillo, alto: 40, tamanoTexto: 13, onPressed: onVer)),
                const SizedBox(width: 6),
                IconButton(tooltip: 'Cerrar', onPressed: onCerrar, icon: const Icon(TablerIcons.x, size: 18)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
