import 'package:latlong2/latlong.dart';

import '../../../widgets/etiqueta_riesgo.dart';

enum TipoVehiculo { moto, auto }

/// Filtro del mapa (Todas/Motos/Autos).
enum FiltroVehiculo {
  todas('Todas'),
  motos('Motos'),
  autos('Autos');

  const FiltroVehiculo(this.etiqueta);
  final String etiqueta;

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
  });

  final String id;
  final String titulo;
  final TipoVehiculo vehiculo;
  final LatLng punto;
  final String barrio;
  final DateTime fecha;
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
  const Cai({required this.nombre, required this.direccion, required this.punto, required this.telefono});

  final String nombre;
  final String direccion;
  final LatLng punto;
  final String telefono;
}
