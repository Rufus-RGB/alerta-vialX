import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../widgets/etiqueta_riesgo.dart';
import '../domain/modelos_mapa.dart';

/// Contrato de datos geográficos. La implementación real consumirá la API.
abstract interface class MapaRepository {
  Future<List<IncidenteHurto>> incidentes();
  Future<List<ZonaRiesgo>> zonasRiesgo();
  Future<List<Cai>> cais();
}

final mapaRepositoryProvider = Provider<MapaRepository>((ref) => MockMapaRepository());

final incidentesProvider = FutureProvider<List<IncidenteHurto>>((ref) => ref.watch(mapaRepositoryProvider).incidentes());
final zonasRiesgoProvider = FutureProvider<List<ZonaRiesgo>>((ref) => ref.watch(mapaRepositoryProvider).zonasRiesgo());
final caisProvider = FutureProvider<List<Cai>>((ref) => ref.watch(mapaRepositoryProvider).cais());

class MockMapaRepository implements MapaRepository {
  static const _latencia = Duration(milliseconds: 350);

  @override
  Future<List<IncidenteHurto>> incidentes() async {
    await Future<void>.delayed(_latencia);
    final ahora = DateTime.now();
    IncidenteHurto i(String id, String titulo, TipoVehiculo v, double lat, double lng, String barrio, int horas) =>
        IncidenteHurto(
          id: id,
          titulo: titulo,
          vehiculo: v,
          punto: LatLng(lat, lng),
          barrio: barrio,
          fecha: ahora.subtract(Duration(hours: horas)),
        );
    return [
      i('h1', 'Hurto de moto', TipoVehiculo.moto, 4.6301, -74.1552, 'Kennedy Central', 2),
      i('h2', 'Hurto de autopartes', TipoVehiculo.auto, 4.6252, -74.1610, 'Timiza', 5),
      i('h3', 'Hurto de moto', TipoVehiculo.moto, 4.6362, -74.1489, 'Castilla', 9),
      i('h4', 'Hurto de moto', TipoVehiculo.moto, 4.6170, -74.1925, 'Bosa Centro', 3),
      i('h5', 'Hurto de vehículo', TipoVehiculo.auto, 4.6228, -74.1868, 'El Recreo', 14),
      i('h6', 'Hurto de moto', TipoVehiculo.moto, 4.5120, -74.1540, 'Lucero', 1),
      i('h7', 'Hurto de autopartes', TipoVehiculo.auto, 4.5065, -74.1480, 'Meissen', 20),
      i('h8', 'Hurto de vehículo', TipoVehiculo.auto, 4.7081, -74.1132, 'Engativá Centro', 6),
      i('h9', 'Hurto de moto', TipoVehiculo.moto, 4.7015, -74.1190, 'Boyacá Real', 11),
      i('h10', 'Hurto de autopartes', TipoVehiculo.auto, 4.6533, -74.0836, 'Teusaquillo', 26),
      i('h11', 'Hurto de moto', TipoVehiculo.moto, 4.6097, -74.0817, 'Santa Fe', 30),
    ];
  }

  @override
  Future<List<ZonaRiesgo>> zonasRiesgo() async {
    await Future<void>.delayed(_latencia);
    return const [
      ZonaRiesgo(nombre: 'Kennedy', centro: LatLng(4.6286, -74.1569), radioMetros: 1400, nivel: NivelRiesgo.alto, reportesSemana: 42),
      ZonaRiesgo(nombre: 'Bosa', centro: LatLng(4.6186, -74.1906), radioMetros: 1200, nivel: NivelRiesgo.alto, reportesSemana: 35),
      ZonaRiesgo(nombre: 'Ciudad Bolívar', centro: LatLng(4.5097, -74.1522), radioMetros: 1500, nivel: NivelRiesgo.medio, reportesSemana: 28),
      ZonaRiesgo(nombre: 'Engativá', centro: LatLng(4.7069, -74.1150), radioMetros: 1100, nivel: NivelRiesgo.medio, reportesSemana: 19),
    ];
  }

  @override
  Future<List<Cai>> cais() async {
    await Future<void>.delayed(_latencia);
    return const [
      Cai(nombre: 'CAI Kennedy Central', direccion: 'Cra. 78 #38-20 Sur', punto: LatLng(4.6290, -74.1540), telefono: '123'),
      Cai(nombre: 'CAI Bosa Piamonte', direccion: 'Cl. 65 Sur #80-10', punto: LatLng(4.6150, -74.1900), telefono: '123'),
      Cai(nombre: 'CAI Lucero', direccion: 'Cl. 70 Sur #17C-05', punto: LatLng(4.5130, -74.1500), telefono: '123'),
      Cai(nombre: 'CAI Engativá Pueblo', direccion: 'Cl. 64 #120-50', punto: LatLng(4.7090, -74.1160), telefono: '123'),
    ];
  }
}
