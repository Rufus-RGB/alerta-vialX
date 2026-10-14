import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/paleta.dart';
import '../../../widgets/etiqueta_riesgo.dart';
import '../domain/modelos_mapa.dart';

/// Mapa OpenStreetMap con el estilo del Figma: calles en gris, zonas de calor rojas
/// con degradado radial, pines rojos de hurto y punto azul de "mi ubicación".
class MapaBase extends StatelessWidget {
  const MapaBase({
    super.key,
    this.controller,
    this.incidentes = const [],
    this.zonas = const [],
    this.miUbicacion,
    this.onIncidente,
    this.seleccionado,
    this.centro,
    this.zoom = 12,
    this.interactivo = true,
    this.onTapMapa,
  });

  final MapController? controller;
  final List<IncidenteHurto> incidentes;
  final List<ZonaRiesgo> zonas;
  final LatLng? miUbicacion;
  final ValueChanged<IncidenteHurto>? onIncidente;
  final String? seleccionado;
  final LatLng? centro;
  final double zoom;
  final bool interactivo;
  final VoidCallback? onTapMapa;

  @override
  Widget build(BuildContext context) {
    final oscuro = context.esOscuro;
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: centro ?? AppConstants.centroBogota,
        initialZoom: zoom,
        minZoom: 9,
        maxZoom: 18,
        backgroundColor: oscuro ? const Color(0xFF151D23) : const Color(0xFFECEEF0),
        interactionOptions: InteractionOptions(flags: interactivo ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none),
        onTap: onTapMapa == null ? null : (_, _) => onTapMapa!(),
      ),
      children: [
        capaTiles(context),
        CircleLayer(
          circles: [
            for (final z in zonas)
              // Degradado radial aproximado: anillos concéntricos de 28 % a 0 % de opacidad.
              for (var k = 6; k >= 1; k--)
                CircleMarker(
                  point: z.centro,
                  radius: z.radioMetros * k / 6,
                  useRadiusInMeter: true,
                  color: (z.nivel == NivelRiesgo.alto ? const Color(0xFFFF383D) : const Color(0xFFFF7A3D)).withValues(alpha: 0.07),
                ),
          ],
        ),
        MarkerLayer(
          markers: [
            for (final i in incidentes)
              Marker(
                point: i.punto,
                width: i.nivel != NivelRiesgo.info ? 40 : 40,
                height: i.nivel != NivelRiesgo.info ? 52 : 40,
                alignment: i.nivel != NivelRiesgo.info ? Alignment.topCenter : Alignment.center,
                child: GestureDetector(
                  onTap: onIncidente == null ? null : () => onIncidente!(i),
                  child: Semantics(
                    button: onIncidente != null,
                    label: '${i.titulo} en ${i.barrio}',
                    child: AnimatedScale(
                      scale: seleccionado == i.id ? 1.2 : 1,
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.bottomCenter,
                      child: i.nivel != NivelRiesgo.info ? const PinHurto() : PinVehiculo(vehiculo: i.vehiculo),
                    ),
                  ),
                ),
              ),
            if (miUbicacion != null) Marker(point: miUbicacion!, width: 20, height: 20, child: const PuntoUbicacion()),
          ],
        ),
        const RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          showFlutterMapAttribution: false,
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }

  /// Capa de tiles OSM con el filtro de color del tema actual.
  static TileLayer capaTiles(BuildContext context) {
    final oscuro = context.esOscuro;
    return TileLayer(
      urlTemplate: AppConstants.osmTileUrl,
      userAgentPackageName: AppConstants.userAgentPackage,
      tileBuilder: (context, tile, image) => ColorFiltered(colorFilter: oscuro ? _filtroOscuro : _filtroClaro, child: tile),
    );
  }

  /// Escala de grises aclarada (aspecto del mapa claro del Figma).
  static const _filtroClaro = ColorFilter.matrix([
    0.20, 0.55, 0.08, 0, 32, //
    0.20, 0.55, 0.08, 0, 34,
    0.20, 0.55, 0.08, 0, 38,
    0, 0, 0, 1, 0,
  ]);

  /// Gris invertido y oscurecido (mapa oscuro del Figma).
  static const _filtroOscuro = ColorFilter.matrix([
    -0.16, -0.45, -0.07, 0, 150, //
    -0.16, -0.45, -0.07, 0, 158,
    -0.16, -0.45, -0.07, 0, 166,
    0, 0, 0, 1, 0,
  ]);
}

/// Pin rojo de hurto con triángulo de advertencia (40×52, trazado del Figma).
class PinHurto extends StatelessWidget {
  const PinHurto({super.key, this.ancho = 40});

  final double ancho;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      height: ancho * 1.3,
      child: CustomPaint(
        painter: _PinPainter(),
        child: Align(
          alignment: const Alignment(0, -0.42),
          child: Icon(TablerIcons.alert_triangle_filled, color: Colors.white, size: ancho * 0.45),
        ),
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 40;
    final path = Path()
      ..moveTo(20 * s, 1 * s)
      ..cubicTo(9.5 * s, 1 * s, 1 * s, 9.3 * s, 1 * s, 19.6 * s)
      ..cubicTo(1 * s, 33.5 * s, 20 * s, 51 * s, 20 * s, 51 * s)
      ..cubicTo(20 * s, 51 * s, 39 * s, 33.5 * s, 39 * s, 19.6 * s)
      ..cubicTo(39 * s, 9.3 * s, 30.5 * s, 1 * s, 20 * s, 1 * s)
      ..close();
    canvas.drawShadow(path, Colors.black54, 4, false);
    canvas.drawPath(path, Paint()..color = AppColors.rojo);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * s,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Pin circular amarillo con el vehículo (moto/auto), borde blanco de 2 px.
class PinVehiculo extends StatelessWidget {
  const PinVehiculo({super.key, required this.vehiculo, this.tamano = 40});

  final TipoVehiculo vehiculo;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        color: AppColors.amarillo,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 14, offset: Offset(0, 4))],
      ),
      child: Icon(vehiculo == TipoVehiculo.moto ? TablerIcons.motorbike : TablerIcons.car, size: tamano * 0.6, color: Colors.black),
    );
  }
}

/// Punto azul de "mi ubicación".
class PuntoUbicacion extends StatelessWidget {
  const PuntoUbicacion({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Color(0x553B82F6), blurRadius: 10, spreadRadius: 4)],
      ),
    );
  }
}
