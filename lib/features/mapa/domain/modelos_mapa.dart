import 'package:latlong2/latlong.dart';

import '../../../widgets/etiqueta_riesgo.dart';

enum TipoVehiculo { moto, auto }

/// Filtro del mapa (Todas/Motos/Autos).
enum FiltroVehiculo {
  todas('Todas', 'Todos'),
  motos('Motos', 'Hurto Motos'),
  autos('Autos', 'Hurto Autos');

  const FiltroVehiculo(this.etiqueta, this.etiquetaMapa);
  final String etiqueta;

  /// Texto de los chips flotantes del mapa de celular.
  final String etiquetaMapa;

  bool incluye(TipoVehiculo v) => switch (this) {
        FiltroVehiculo.todas => true,
        FiltroVehiculo.motos => v == TipoVehiculo.moto,
        FiltroVehiculo.autos => v == TipoVehiculo.auto,
      };
}

class IncidenteHurto {
  const IncidenteHurto({
    required this.id,
    required this.titulo,
    required this.vehiculo,
    required this.punto,
    required this.barrio,
    required this.fecha,
    required this.placa,
    required this.descripcionVehiculo,
    required this.direccion,
    this.nivel = NivelRiesgo.alto,
  });

  final String id;
  final String titulo;
  final TipoVehiculo vehiculo;
  final LatLng punto;
  final String barrio;
  final DateTime fecha;
  final String placa;
  final String descripcionVehiculo;
  final String direccion;
  final NivelRiesgo nivel;

  bool coincide(String q) {
    final t = q.toLowerCase().trim();
    return t.isEmpty || placa.toLowerCase().contains(t) || barrio.toLowerCase().contains(t) || direccion.toLowerCase().contains(t);
  }
}

class ZonaRiesgo {
  const ZonaRiesgo({
    required this.nombre,
    required this.centro,
    required this.radioMetros,
    required this.nivel,
    required this.reportesSemana,
  });

  final String nombre;
  final LatLng centro;
  final double radioMetros;
  final NivelRiesgo nivel;
  final int reportesSemana;
}

class Cai {
  const Cai({required this.nombre, required this.direccion, required this.punto, required this.telefono, this.distanciaKm = 0});

  final String nombre;
  final String direccion;
  final LatLng punto;
  final String telefono;
  final double distanciaKm;
}

/// "hace 12 min", "hace 2 h".
String haceTiempo(DateTime fecha, {bool mayuscula = false}) {
  final d = DateTime.now().difference(fecha);
  final texto = d.inMinutes < 1
      ? 'ahora'
      : d.inMinutes < 60
          ? 'hace ${d.inMinutes} min'
          : d.inHours < 24
              ? 'hace ${d.inHours} h'
              : 'hace ${d.inDays} d';
  return mayuscula ? '${texto[0].toUpperCase()}${texto.substring(1)}' : texto;
}

/// Centros aproximados de las localidades de Bogotá (para nombrar un punto del mapa).
const localidadesBogota = <String, LatLng>{
  'Usaquén': LatLng(4.7030, -74.0300),
  'Chapinero': LatLng(4.6483, -74.0630),
  'Santa Fe': LatLng(4.6090, -74.0710),
  'San Cristóbal': LatLng(4.5700, -74.0850),
  'Usme': LatLng(4.4750, -74.1260),
  'Tunjuelito': LatLng(4.5760, -74.1300),
  'Bosa': LatLng(4.6186, -74.1906),
  'Kennedy': LatLng(4.6286, -74.1569),
  'Fontibón': LatLng(4.6780, -74.1430),
  'Engativá': LatLng(4.7069, -74.1150),
  'Suba': LatLng(4.7420, -74.0830),
  'Barrios Unidos': LatLng(4.6680, -74.0750),
  'Teusaquillo': LatLng(4.6380, -74.0780),
  'Los Mártires': LatLng(4.6040, -74.0880),
  'Antonio Nariño': LatLng(4.5890, -74.0990),
  'Puente Aranda': LatLng(4.6170, -74.1110),
  'La Candelaria': LatLng(4.5960, -74.0730),
  'Rafael Uribe Uribe': LatLng(4.5700, -74.1150),
  'Ciudad Bolívar': LatLng(4.5097, -74.1522),
};

/// Nombre de la localidad más cercana a [punto].
String localidadCercana(LatLng punto) {
  const d = Distance();
  return localidadesBogota.entries.reduce((a, b) => d(punto, a.value) <= d(punto, b.value) ? a : b).key;
}
