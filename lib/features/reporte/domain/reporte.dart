import 'package:latlong2/latlong.dart';

import '../../mapa/domain/modelos_mapa.dart';

/// Datos que el ciudadano llena en "Reportar hurto".
class BorradorReporte {
  const BorradorReporte({
    this.vehiculo = TipoVehiculo.moto,
    this.marca,
    this.modelo,
    this.placa = '',
    this.color,
    required this.fecha,
    this.punto = const LatLng(4.6683, -74.0537),
    this.barrio = 'Chapinero',
    this.direccion = 'Calle 85 # 11-53, Chapinero',
    this.referencia = '',
    this.descripcion = '',
    this.fotos = const [],
  });

  final TipoVehiculo vehiculo;
  final String? marca;
  final String? modelo;
  final String placa;
  final String? color;
  final DateTime fecha;
  final LatLng punto;
  final String barrio;
  final String direccion;
  final String referencia;
  final String descripcion;

  /// Rutas o nombres de las fotos seleccionadas (máx. 3).
  final List<String> fotos;

  bool get vehiculoCompleto => marca != null && modelo != null && placaValida(placa) && color != null;
  bool get ubicacionCompleta => direccion.trim().isNotEmpty;

  String get nombreVehiculo => vehiculo == TipoVehiculo.moto ? 'Motocicleta' : 'Automóvil';

  BorradorReporte copyWith({
    TipoVehiculo? vehiculo,
    String? marca,
    String? modelo,
    String? placa,
    String? color,
    DateTime? fecha,
    LatLng? punto,
    String? barrio,
    String? direccion,
    String? referencia,
    String? descripcion,
    List<String>? fotos,
    bool limpiarModelo = false,
  }) =>
      BorradorReporte(
        vehiculo: vehiculo ?? this.vehiculo,
        marca: marca ?? this.marca,
        modelo: limpiarModelo ? null : (modelo ?? this.modelo),
        placa: placa ?? this.placa,
        color: color ?? this.color,
        fecha: fecha ?? this.fecha,
        punto: punto ?? this.punto,
        barrio: barrio ?? this.barrio,
        direccion: direccion ?? this.direccion,
        referencia: referencia ?? this.referencia,
        descripcion: descripcion ?? this.descripcion,
        fotos: fotos ?? this.fotos,
      );

  Map<String, Object?> toJson() => {
        'vehiculo': vehiculo.name,
        'marca': marca,
        'modelo': modelo,
        'placa': placa,
        'color': color,
        'fecha': fecha.toIso8601String(),
        'lat': punto.latitude,
        'lng': punto.longitude,
        'barrio': barrio,
        'direccion': direccion,
        'referencia': referencia,
        'descripcion': descripcion,
        'fotos': fotos,
      };

  static BorradorReporte fromJson(Map<String, Object?> j) => BorradorReporte(
        vehiculo: TipoVehiculo.values.byName(j['vehiculo']! as String),
        marca: j['marca'] as String?,
        modelo: j['modelo'] as String?,
        placa: j['placa'] as String? ?? '',
        color: j['color'] as String?,
        fecha: DateTime.parse(j['fecha']! as String),
        punto: LatLng((j['lat']! as num).toDouble(), (j['lng']! as num).toDouble()),
        barrio: j['barrio'] as String? ?? '',
        direccion: j['direccion'] as String? ?? '',
        referencia: j['referencia'] as String? ?? '',
        descripcion: j['descripcion'] as String? ?? '',
        fotos: (j['fotos'] as List?)?.cast<String>() ?? const [],
      );
}

/// Placa colombiana: autos ABC123, motos ABC12D.
bool placaValida(String placa) => RegExp(r'^[A-Z]{3}[0-9]{2}[0-9A-Z]$').hasMatch(placa.toUpperCase().replaceAll(' ', ''));

enum EstadoReporte {
  enviado('Enviado'),
  recibido('Recibido'),
  enAtencion('En atención'),
  cerrado('Caso cerrado');

  const EstadoReporte(this.etiqueta);
  final String etiqueta;
}

class PasoSeguimiento {
  const PasoSeguimiento({required this.titulo, required this.detalle, required this.estado});
  final String titulo;
  final String detalle;

  /// 'hecho', 'actual' o 'pendiente'.
  final String estado;
}

class Reporte {
  const Reporte({
    required this.id,
    required this.borrador,
    required this.estado,
    required this.seguimiento,
    this.notificadoA = 'CAI Chapinero · 1,2 km',
    this.conductoresAlertados = 120,
    this.agente = 'Pt. Ramírez',
    this.unidadAgente = 'Policía Nacional · CAI Chapinero',
  });

  final String id;
  final BorradorReporte borrador;
  final EstadoReporte estado;
  final List<PasoSeguimiento> seguimiento;
  final String notificadoA;
  final int conductoresAlertados;
  final String agente;
  final String unidadAgente;
}

/// Catálogo para los selectores del formulario.
const marcasPorVehiculo = <TipoVehiculo, Map<String, List<String>>>{
  TipoVehiculo.moto: {
    'Bajaj': ['Pulsar NS200', 'Pulsar 180', 'Boxer CT100'],
    'Yamaha': ['FZ 2.0', 'XTZ 150', 'NMAX'],
    'Honda': ['CB 160', 'XR 150', 'Navi'],
    'AKT': ['NKD 125', 'TTR 200', 'Dynamic'],
    'Suzuki': ['GN 125', 'Gixxer 150'],
  },
  TipoVehiculo.auto: {
    'Chevrolet': ['Spark', 'Onix', 'Sail'],
    'Renault': ['Logan', 'Sandero', 'Duster'],
    'Mazda': ['Mazda 2', 'Mazda 3', 'CX-30'],
    'Kia': ['Picanto', 'Rio'],
    'Toyota': ['Corolla', 'Hilux'],
  },
};

const coloresVehiculo = ['Negra', 'Blanca', 'Gris', 'Plateada', 'Roja', 'Azul', 'Verde', 'Amarilla'];
