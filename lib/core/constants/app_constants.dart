import 'package:latlong2/latlong.dart';

abstract final class AppConstants {
  static const appName = 'Alerta Vial';

  /// Ancho a partir del cual se usa barra lateral en lugar del HUD inferior.
  static const breakpointEscritorio = 840.0;

  /// Centro por defecto del mapa (Bogotá).
  static const centroBogota = LatLng(4.6280, -74.1100);

  static const osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const userAgentPackage = 'co.alertavial.alerta_vial';
}
