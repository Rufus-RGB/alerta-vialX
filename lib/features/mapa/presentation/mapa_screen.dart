import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../widgets/chips.dart';
import '../../../widgets/etiqueta_riesgo.dart';
import '../data/mapa_repository.dart';
import '../domain/modelos_mapa.dart';
import 'mapa_controller.dart';

class MapaScreen extends ConsumerStatefulWidget {
  const MapaScreen({super.key, this.foco});

  /// Punto inicial opcional (p. ej. al abrir una zona de riesgo desde Inicio).
  final LatLng? foco;

  @override
  ConsumerState<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends ConsumerState<MapaScreen> {
  final _mapController = MapController();
  LatLng? _miUbicacion;
  bool _buscandoUbicacion = false;

  @override
  void didUpdateWidget(MapaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.foco != null && widget.foco != oldWidget.foco) {
      _mapController.move(widget.foco!, 14);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _irAMiUbicacion() async {
    setState(() => _buscandoUbicacion = true);
    try {
      final punto = await obtenerUbicacionActual();
      if (!mounted) return;
      setState(() => _miUbicacion = punto);
      _mapController.move(punto, 15);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _buscandoUbicacion = false);
    }
  }

  void _verIncidente(IncidenteHurto i) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final hace = DateTime.now().difference(i.fecha);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconoIncidente(vehiculo: i.vehiculo, tamano: 44),
                    const SizedBox(width: 12),
                    Expanded(child: Text(i.titulo, style: theme.textTheme.titleLarge)),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.place_rounded),
                  title: Text(i.barrio),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule_rounded),
                  title: Text(hace.inHours < 1 ? 'Hace ${hace.inMinutes} min' : 'Hace ${hace.inHours} h'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtro = ref.watch(filtroVehiculoProvider);
    final incidentes = ref.watch(incidentesFiltradosProvider);
    final zonas = ref.watch(zonasRiesgoProvider).value ?? const <ZonaRiesgo>[];
    final cargando = incidentes.isLoading;
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final inferior = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.foco ?? AppConstants.centroBogota,
              initialZoom: widget.foco == null ? 12 : 14,
              minZoom: 9,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: AppConstants.osmTileUrl,
                userAgentPackageName: AppConstants.userAgentPackage,
                tileBuilder: oscuro ? _tileOscuro : null,
              ),
              CircleLayer(
                circles: [
                  // Zonas de calor: tres anillos concéntricos con opacidad creciente hacia el centro.
                  for (final z in zonas)
                    for (final (factor, alfa) in const [(1.0, 0.12), (0.66, 0.18), (0.33, 0.28)])
                      CircleMarker(
                        point: z.centro,
                        radius: z.radioMetros * factor,
                        useRadiusInMeter: true,
                        color: z.nivel.color.withValues(alpha: alfa),
                      ),
                ],
              ),
              MarkerLayer(
                markers: [
                  for (final i in incidentes.value ?? const <IncidenteHurto>[])
                    Marker(
                      point: i.punto,
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _verIncidente(i),
                        child: Tooltip(message: i.titulo, child: _IconoIncidente(vehiculo: i.vehiculo)),
                      ),
                    ),
                  if (_miUbicacion != null)
                    Marker(point: _miUbicacion!, width: 28, height: 28, child: const _PuntoUbicacion()),
                ],
              ),
              const RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                attributions: [TextSourceAttribution('OpenStreetMap contributors')],
              ),
            ],
          ),
          // Encabezado con filtros
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Row(
                        children: [
                          const Icon(Icons.map_rounded, color: AppColors.rojo),
                          const SizedBox(width: 10),
                          Expanded(child: Text('Mapa de hurtos', style: Theme.of(context).textTheme.titleMedium)),
                          if (cargando) const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GrupoChips<FiltroVehiculo>(
                    opciones: FiltroVehiculo.values,
                    seleccionado: filtro,
                    etiqueta: (f) => f.etiqueta,
                    icono: (f) => switch (f) {
                      FiltroVehiculo.todas => Icons.layers_rounded,
                      FiltroVehiculo.motos => Icons.two_wheeler_rounded,
                      FiltroVehiculo.autos => Icons.directions_car_rounded,
                    },
                    onChanged: ref.read(filtroVehiculoProvider.notifier).cambiar,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: inferior + 24,
            child: FloatingActionButton(
              heroTag: 'mi_ubicacion',
              tooltip: 'Mi ubicación',
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: AppColors.rojo,
              onPressed: _buscandoUbicacion ? null : _irAMiUbicacion,
              child: _buscandoUbicacion
                  ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Icon(Icons.my_location_rounded),
            ),
          ),
          Positioned(left: 16, bottom: inferior + 40, child: const _Leyenda()),
        ],
      ),
    );
  }

  /// Invierte los tiles para un mapa oscuro sencillo.
  static Widget _tileOscuro(BuildContext context, Widget tile, TileImage image) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        -0.85, 0, 0, 0, 230, //
        0, -0.85, 0, 0, 235,
        0, 0, -0.85, 0, 240,
        0, 0, 0, 1, 0,
      ]),
      child: tile,
    );
  }
}

class _IconoIncidente extends StatelessWidget {
  const _IconoIncidente({required this.vehiculo, this.tamano = 40});

  final TipoVehiculo vehiculo;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final color = vehiculo == TipoVehiculo.moto ? AppColors.rojo : AppColors.amarillo;
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Icon(
        vehiculo == TipoVehiculo.moto ? Icons.two_wheeler_rounded : Icons.directions_car_rounded,
        color: vehiculo == TipoVehiculo.moto ? Colors.white : AppColors.fondoOscuro,
        size: tamano * 0.5,
      ),
    );
  }
}

class _PuntoUbicacion extends StatelessWidget {
  const _PuntoUbicacion();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.azulAutoridad,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [BoxShadow(color: AppColors.azulAutoridad.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 4)],
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda();

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.bodySmall;
    Widget fila(Color c, String t) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(t, style: estilo),
          ]),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            fila(AppColors.rojo, 'Hurto de moto'),
            fila(AppColors.amarillo, 'Hurto de auto'),
            fila(NivelRiesgo.alto.color.withValues(alpha: 0.4), 'Zona de calor'),
          ],
        ),
      ),
    );
  }
}
