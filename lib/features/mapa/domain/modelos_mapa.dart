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
