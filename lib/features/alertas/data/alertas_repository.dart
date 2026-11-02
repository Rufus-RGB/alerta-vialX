import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../widgets/etiqueta_riesgo.dart';
import '../../mapa/domain/modelos_mapa.dart';

enum TipoAlerta {
  hurto(TablerIcons.urgent, AppColors.rojo),
  aumento(TablerIcons.bell, AppColors.amarillo),
  cai(TablerIcons.shield, Color(0xFF2E6B4F)),
  zona(TablerIcons.alert_triangle, AppColors.rojo);

  const TipoAlerta(this.icono, this.color);
  final IconData icono;
  final Color color;
}

class Alerta {
  const Alerta({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.lugar,
    required this.hora,
    required this.nivel,
    required this.punto,
    this.vehiculo,
    this.placa,
    this.descripcionVehiculo,
    this.direccion,
    this.distancia,
    this.consejo,
    this.minutos = 0,
  });

  final String id;
  final TipoAlerta tipo;
  final String titulo;
  final String lugar;
  final String hora;
  final NivelRiesgo nivel;
  final LatLng punto;
  final TipoVehiculo? vehiculo;
  final String? placa;
  final String? descripcionVehiculo;
  final String? direccion;
  final String? distancia;
  final String? consejo;

  /// Minutos desde que llegó la alerta.
  final int minutos;
}

/// Preferencias de "Configurar alertas".
class ConfigAlertas {
  const ConfigAlertas({
    this.hurtos = true,
    this.aumento = true,
    this.zonas = true,
    this.cai = false,
    this.radioKm = 3,
    this.sonido = true,
    this.vibracion = true,
    this.noMolestar = false,
  });

  final bool hurtos;
  final bool aumento;
  final bool zonas;
  final bool cai;
  final double radioKm;
  final bool sonido;
  final bool vibracion;
  final bool noMolestar;

  ConfigAlertas copyWith({bool? hurtos, bool? aumento, bool? zonas, bool? cai, double? radioKm, bool? sonido, bool? vibracion, bool? noMolestar}) =>
      ConfigAlertas(
        hurtos: hurtos ?? this.hurtos,
        aumento: aumento ?? this.aumento,
        zonas: zonas ?? this.zonas,
        cai: cai ?? this.cai,
        radioKm: radioKm ?? this.radioKm,
        sonido: sonido ?? this.sonido,
        vibracion: vibracion ?? this.vibracion,
        noMolestar: noMolestar ?? this.noMolestar,
      );

  bool permite(TipoAlerta t) => switch (t) {
        TipoAlerta.hurto => hurtos,
        TipoAlerta.aumento => aumento,
        TipoAlerta.zona => zonas,
        TipoAlerta.cai => cai,
      };
}

abstract interface class AlertasRepository {
  Future<List<Alerta>> alertas();
}

final alertasRepositoryProvider = Provider<AlertasRepository>((ref) => SupabaseConfig.habilitado ? SupabaseAlertasRepository() : MockAlertasRepository());
final alertasProvider = FutureProvider<List<Alerta>>((ref) => ref.watch(alertasRepositoryProvider).alertas());

/// Configuración persistida en SharedPreferences.
final configAlertasProvider = NotifierProvider<ConfigAlertasController, ConfigAlertas>(ConfigAlertasController.new);

class ConfigAlertasController extends Notifier<ConfigAlertas> {
  static const _p = 'alertas_';

  @override
  ConfigAlertas build() {
    _cargar();
    return const ConfigAlertas();
  }

  Future<void> _cargar() async {
    final s = await SharedPreferences.getInstance();
    const d = ConfigAlertas();
    state = ConfigAlertas(
      hurtos: s.getBool('${_p}hurtos') ?? d.hurtos,
      aumento: s.getBool('${_p}aumento') ?? d.aumento,
      zonas: s.getBool('${_p}zonas') ?? d.zonas,
      cai: s.getBool('${_p}cai') ?? d.cai,
      radioKm: s.getDouble('${_p}radio') ?? d.radioKm,
      sonido: s.getBool('${_p}sonido') ?? d.sonido,
      vibracion: s.getBool('${_p}vibracion') ?? d.vibracion,
      noMolestar: s.getBool('${_p}noMolestar') ?? d.noMolestar,
    );
  }

  Future<void> cambiar(ConfigAlertas c) async {
    state = c;
    final s = await SharedPreferences.getInstance();
    await s.setBool('${_p}hurtos', c.hurtos);
    await s.setBool('${_p}aumento', c.aumento);
    await s.setBool('${_p}zonas', c.zonas);
    await s.setBool('${_p}cai', c.cai);
    await s.setDouble('${_p}radio', c.radioKm);
    await s.setBool('${_p}sonido', c.sonido);
    await s.setBool('${_p}vibracion', c.vibracion);
    await s.setBool('${_p}noMolestar', c.noMolestar);
  }
}

class MockAlertasRepository implements AlertasRepository {
  @override
  Future<List<Alerta>> alertas() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return const [
      Alerta(
        id: 'AL-301',
        tipo: TipoAlerta.hurto,
        titulo: 'Hurto reportado cerca',
        lugar: 'Kennedy',
        hora: '9:15 p. m.',
        nivel: NivelRiesgo.alto,
        punto: LatLng(4.6265, -74.1480),
        vehiculo: TipoVehiculo.moto,
        placa: 'HGT56Y',
        descripcionVehiculo: 'Motocicleta · Pulsar NS200',
        direccion: 'Av. Boyacá con Calle 38 sur',
        distancia: 'A 800 m de tu ubicación',
        consejo: 'Evita la zona y asegura tu vehículo con candado.',
        minutos: 3,
      ),
      Alerta(
        id: 'AL-300',
        tipo: TipoAlerta.aumento,
        titulo: 'Aumento de reportes',
        lugar: 'Teusaquillo',
        hora: '6:30 p. m.',
        nivel: NivelRiesgo.medio,
        punto: LatLng(4.6381, -74.0786),
        distancia: 'A 3,1 km de tu ubicación',
        consejo: 'Parquea en lugares vigilados y con buena iluminación.',
        minutos: 165,
      ),
      Alerta(
        id: 'AL-299',
        tipo: TipoAlerta.cai,
        titulo: 'CAI cercano',
        lugar: 'CAI Fontanar',
        hora: '7:00 p. m.',
        nivel: NivelRiesgo.info,
        punto: LatLng(4.7480, -74.0950),
        direccion: 'Calle 145 # 92-50, Suba',
        distancia: 'A 1,2 km de tu ubicación',
        consejo: 'Guarda el número del CAI para emergencias.',
        minutos: 135,
      ),
      Alerta(
        id: 'AL-298',
        tipo: TipoAlerta.zona,
        titulo: 'Zona de alto riesgo',
        lugar: 'Kennedy',
        hora: '6:30 p. m.',
        nivel: NivelRiesgo.alto,
        punto: LatLng(4.6286, -74.1569),
        distancia: 'A 1,5 km de tu ubicación',
        consejo: 'Evita detenerte en semáforos solitarios en la noche.',
        minutos: 165,
      ),
      Alerta(
        id: 'AL-297',
        tipo: TipoAlerta.hurto,
        titulo: 'Hurto reportado cerca',
        lugar: 'Suba',
        hora: '5:40 p. m.',
        nivel: NivelRiesgo.medio,
        punto: LatLng(4.7419, -74.0836),
        vehiculo: TipoVehiculo.auto,
        placa: 'HGT567',
        descripcionVehiculo: 'Automóvil · Mazda 3',
        direccion: 'Av. Suba # 115-20',
        distancia: 'A 4 km de tu ubicación',
        consejo: 'No dejes objetos de valor a la vista dentro del vehículo.',
        minutos: 215,
      ),
    ];
  }
}

/// Tabla `alertas` de Supabase (las más recientes primero).
class SupabaseAlertasRepository implements AlertasRepository {
  static String _hora(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'a. m.' : 'p. m.'}';
  }

  @override
  Future<List<Alerta>> alertas() async {
    final filas = await supa.from('alertas').select().order('creado_en', ascending: false).limit(50);
    return [
      for (final f in filas)
        () {
          final creado = DateTime.parse(f['creado_en'] as String).toLocal();
          return Alerta(
            id: f['id'] as String,
            tipo: TipoAlerta.values.byName(f['tipo'] as String),
            titulo: f['titulo'] as String,
            lugar: f['lugar'] as String,
            hora: _hora(creado),
            nivel: NivelRiesgo.values.firstWhere((n) => n.name == f['nivel'], orElse: () => NivelRiesgo.medio),
            punto: LatLng((f['lat'] as num).toDouble(), (f['lng'] as num).toDouble()),
            vehiculo: f['vehiculo'] == null ? null : TipoVehiculo.values.byName(f['vehiculo'] as String),
            placa: f['placa'] as String?,
            descripcionVehiculo: f['descripcion_vehiculo'] as String?,
            direccion: f['direccion'] as String?,
            distancia: f['distancia'] as String?,
            consejo: f['consejo'] as String?,
            minutos: DateTime.now().difference(creado).inMinutes,
          );
        }(),
    ];
  }
}
