import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../data/mapa_repository.dart';
import '../domain/modelos_mapa.dart';

final filtroVehiculoProvider = NotifierProvider<FiltroVehiculoController, FiltroVehiculo>(FiltroVehiculoController.new);

class FiltroVehiculoController extends Notifier<FiltroVehiculo> {
  @override
  FiltroVehiculo build() => FiltroVehiculo.todas;

  void cambiar(FiltroVehiculo f) => state = f;
}

/// Texto de búsqueda del mapa (placa, barrio o dirección).
final busquedaMapaProvider = NotifierProvider<BusquedaMapaController, String>(BusquedaMapaController.new);

class BusquedaMapaController extends Notifier<String> {
  @override
  String build() => '';

  void cambiar(String q) => state = q;
}

/// Incidentes filtrados por tipo de vehículo y búsqueda.
final incidentesFiltradosProvider = Provider<AsyncValue<List<IncidenteHurto>>>((ref) {
  final filtro = ref.watch(filtroVehiculoProvider);
  final q = ref.watch(busquedaMapaProvider);
  return ref.watch(incidentesProvider).whenData((l) => l.where((i) => filtro.incluye(i.vehiculo) && i.coincide(q)).toList());
});

/// Obtiene la ubicación actual pidiendo permiso (solo en primer plano).
Future<LatLng> obtenerUbicacionActual() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw const UbicacionException('Activa los servicios de ubicación del dispositivo.');
  }
  var permiso = await Geolocator.checkPermission();
  if (permiso == LocationPermission.denied) {
    permiso = await Geolocator.requestPermission();
  }
  if (permiso == LocationPermission.denied) {
    throw const UbicacionException('Permiso de ubicación denegado.');
  }
  if (permiso == LocationPermission.deniedForever) {
    throw const UbicacionException('Permiso de ubicación bloqueado. Habilítalo en los ajustes.');
  }
  final pos = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
  );
  return LatLng(pos.latitude, pos.longitude);
}

class UbicacionException implements Exception {
  const UbicacionException(this.mensaje);
  final String mensaje;
  @override
  String toString() => mensaje;
}
