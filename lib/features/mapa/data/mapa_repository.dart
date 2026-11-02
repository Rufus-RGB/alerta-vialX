import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../widgets/etiqueta_riesgo.dart';
import '../domain/modelos_mapa.dart';

/// Contrato de datos geográficos. La implementación real consumirá la API.
abstract interface class MapaRepository {
  Future<List<IncidenteHurto>> incidentes();
  Future<List<ZonaRiesgo>> zonasRiesgo();
  Future<List<Cai>> cais();
}

final mapaRepositoryProvider = Provider<MapaRepository>((ref) => SupabaseConfig.habilitado ? SupabaseMapaRepository() : MockMapaRepository());

final incidentesProvider = FutureProvider<List<IncidenteHurto>>((ref) => ref.watch(mapaRepositoryProvider).incidentes());
final zonasRiesgoProvider = FutureProvider<List<ZonaRiesgo>>((ref) => ref.watch(mapaRepositoryProvider).zonasRiesgo());
final caisProvider = FutureProvider<List<Cai>>((ref) => ref.watch(mapaRepositoryProvider).cais());

/// Datos de ejemplo tomados del diseño (placas ABC12D, HGT567…; zonas Kennedy, Bosa…).
class MockMapaRepository implements MapaRepository {
  static const _latencia = Duration(milliseconds: 300);

  @override
  Future<List<IncidenteHurto>> incidentes() async {
    await Future<void>.delayed(_latencia);
    final ahora = DateTime.now();
    IncidenteHurto i(String id, String titulo, TipoVehiculo v, double lat, double lng, String barrio, int minutos, String placa,
            String desc, String dir, NivelRiesgo nivel) =>
        IncidenteHurto(
          id: id,
          titulo: titulo,
          vehiculo: v,
          punto: LatLng(lat, lng),
          barrio: barrio,
          fecha: ahora.subtract(Duration(minutes: minutos)),
          placa: placa,
          descripcionVehiculo: desc,
          direccion: dir,
          nivel: nivel,
        );
    return [
      i('AV-2048', 'Hurto de moto', TipoVehiculo.moto, 4.6683, -74.0537, 'Chapinero', 12, 'ABC12D', 'Pulsar NS200 · Negra', 'Calle 85 # 11-53', NivelRiesgo.alto),
      i('AV-2047', 'Hurto de auto', TipoVehiculo.auto, 4.7419, -74.0836, 'Suba', 40, 'HGT567', 'Mazda 3 · Gris', 'Av. Suba # 115-20', NivelRiesgo.medio),
      i('AV-2046', 'Intento de hurto', TipoVehiculo.moto, 4.6381, -74.0786, 'Teusaquillo', 60, 'XYZ98E', 'Yamaha FZ 2.0 · Azul', 'Calle 45 # 19-30', NivelRiesgo.medio),
      i('AV-2045', 'Hurto de auto', TipoVehiculo.auto, 4.6286, -74.1569, 'Kennedy', 120, 'JKL432', 'Chevrolet Spark · Rojo', 'Av. 1 de Mayo # 72-15 Sur', NivelRiesgo.alto),
      i('AV-2044', 'Hurto de moto', TipoVehiculo.moto, 4.6186, -74.1906, 'Bosa', 180, 'QWE45F', 'AKT NKD 125 · Negra', 'Calle 59 Sur # 80-11', NivelRiesgo.alto),
      i('AV-2043', 'Vehículo recuperado', TipoVehiculo.auto, 4.7069, -74.1150, 'Engativá', 300, 'KLM234', 'Renault Logan · Blanco', 'Calle 72 # 110-45', NivelRiesgo.info),
      i('AV-2042', 'Hurto de moto', TipoVehiculo.moto, 4.5120, -74.1540, 'Ciudad Bolívar', 420, 'MNB76C', 'Honda CB 160 · Roja', 'Calle 70 Sur # 17C-05', NivelRiesgo.alto),
      i('AV-2041', 'Hurto de autopartes', TipoVehiculo.auto, 4.6766, -74.0482, 'Chapinero', 540, 'PRT908', 'Kia Picanto · Negro', 'Carrera 11 # 93-40', NivelRiesgo.medio),
    ];
  }

  @override
  Future<List<ZonaRiesgo>> zonasRiesgo() async {
    await Future<void>.delayed(_latencia);
    return const [
      ZonaRiesgo(nombre: 'Kennedy', centro: LatLng(4.6286, -74.1569), radioMetros: 1500, nivel: NivelRiesgo.alto, reportesSemana: 42),
      ZonaRiesgo(nombre: 'Bosa', centro: LatLng(4.6186, -74.1906), radioMetros: 1300, nivel: NivelRiesgo.alto, reportesSemana: 35),
      ZonaRiesgo(nombre: 'Ciudad Bolívar', centro: LatLng(4.5097, -74.1522), radioMetros: 1500, nivel: NivelRiesgo.alto, reportesSemana: 31),
      ZonaRiesgo(nombre: 'Engativá', centro: LatLng(4.7069, -74.1150), radioMetros: 1200, nivel: NivelRiesgo.medio, reportesSemana: 19),
      ZonaRiesgo(nombre: 'Chapinero', centro: LatLng(4.6683, -74.0537), radioMetros: 1000, nivel: NivelRiesgo.medio, reportesSemana: 16),
    ];
  }

  @override
  Future<List<Cai>> cais() async {
    await Future<void>.delayed(_latencia);
    return const [
      Cai(nombre: 'CAI Chapinero', direccion: 'Calle 63 # 13-20', punto: LatLng(4.6490, -74.0640), telefono: '123', distanciaKm: 1.2),
      Cai(nombre: 'CAI Fontanar', direccion: 'Calle 145 # 92-50, Suba', punto: LatLng(4.7480, -74.0950), telefono: '123', distanciaKm: 2.8),
      Cai(nombre: 'CAI Kennedy Central', direccion: 'Cra. 78 # 38-20 Sur', punto: LatLng(4.6290, -74.1540), telefono: '123', distanciaKm: 6.4),
      Cai(nombre: 'CAI Bosa Piamonte', direccion: 'Cl. 65 Sur # 80-10', punto: LatLng(4.6150, -74.1900), telefono: '123', distanciaKm: 9.1),
    ];
  }
}

/// Lee la vista pública `incidentes_publicos` y las tablas `zonas_riesgo` y `cai`.
class SupabaseMapaRepository implements MapaRepository {
  static NivelRiesgo _nivel(Object? n) => NivelRiesgo.values.firstWhere((e) => e.name == n, orElse: () => NivelRiesgo.medio);

  @override
  Future<List<IncidenteHurto>> incidentes() async {
    final filas = await supa.from('incidentes_publicos').select().order('fecha', ascending: false).limit(300);
    return [
      for (final f in filas)
        IncidenteHurto(
          id: f['id'] as String,
          titulo: f['titulo'] as String,
          vehiculo: TipoVehiculo.values.byName(f['vehiculo'] as String),
          punto: LatLng((f['lat'] as num).toDouble(), (f['lng'] as num).toDouble()),
          barrio: f['barrio'] as String? ?? '',
          fecha: DateTime.parse(f['fecha'] as String).toLocal(),
          placa: f['placa'] as String? ?? '',
          descripcionVehiculo: f['descripcion_vehiculo'] as String? ?? '',
          direccion: f['direccion'] as String? ?? '',
          nivel: _nivel(f['nivel']),
        ),
    ];
  }

  @override
  Future<List<ZonaRiesgo>> zonasRiesgo() async {
    final filas = await supa.from('zonas_riesgo').select().order('reportes_semana', ascending: false);
    return [
      for (final f in filas)
        ZonaRiesgo(
          nombre: f['nombre'] as String,
          centro: LatLng((f['lat'] as num).toDouble(), (f['lng'] as num).toDouble()),
          radioMetros: (f['radio_m'] as num).toDouble(),
          nivel: _nivel(f['nivel']),
          reportesSemana: f['reportes_semana'] as int? ?? 0,
        ),
    ];
  }

  @override
  Future<List<Cai>> cais() async {
    final filas = await supa.from('cai').select().eq('estado', 'activo').order('nombre');
    return [
      for (final f in filas)
        Cai(
          nombre: f['nombre'] as String,
          direccion: '${f['direccion'] ?? ''}, ${f['localidad']}',
          punto: LatLng((f['lat'] as num).toDouble(), (f['lng'] as num).toDouble()),
          telefono: f['telefono'] as String? ?? '123',
        ),
    ];
  }
}
