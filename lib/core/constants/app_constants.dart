import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

abstract final class AppConstants {
  static const appName = 'Alerta Vial';
  static const version = 'v1.0';

  /// < 840 px: celular/Android con HUD inferior.
  static const breakpointTablet = 840.0;

  /// >= 1280 px: PC/Web con barra lateral completa. Entre ambos: tablet con riel.
  static const breakpointEscritorio = 1280.0;

  /// Centro por defecto del mapa (Bogotá).
  static const centroBogota = LatLng(4.6480, -74.1000);

  static const osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const userAgentPackage = 'co.alertavial.alerta_vial';
}

enum TipoPantalla { celular, tablet, escritorio }

TipoPantalla tipoPantalla(double ancho) {
  if (ancho >= AppConstants.breakpointEscritorio) return TipoPantalla.escritorio;
  if (ancho >= AppConstants.breakpointTablet) return TipoPantalla.tablet;
  return TipoPantalla.celular;
}

extension TipoPantallaContext on BuildContext {
  TipoPantalla get pantalla => tipoPantalla(MediaQuery.sizeOf(this).width);
  bool get esCelular => pantalla == TipoPantalla.celular;
}
