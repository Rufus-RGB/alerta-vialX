import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../widgets/etiqueta_riesgo.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../mapa/domain/modelos_mapa.dart';

// ---------------- Modelos ----------------

enum EstadoVehiculo {
  protegida('Protegida'),
  recuperado('Recuperado'),
  reportado('Reportado');

  const EstadoVehiculo(this.etiqueta);
  final String etiqueta;
}

class Vehiculo {
  const Vehiculo({
    required this.id,
    required this.tipo,
    required this.marca,
    required this.modelo,
    required this.anio,
    required this.placa,
    required this.color,
    this.reportes = 0,
    this.estado = EstadoVehiculo.protegida,
    this.foto,
  });

  final String id;
  final TipoVehiculo tipo;
  final String marca;
  final String modelo;
  final int anio;
  final String placa;
  final String color;
  final int reportes;
  final EstadoVehiculo estado;
  final String? foto;

  String get nombreTipo => tipo == TipoVehiculo.moto ? 'Motocicleta' : 'Automóvil';

  Map<String, Object?> toJson() => {
        'id': id,
        'tipo': tipo.name,
        'marca': marca,
        'modelo': modelo,
        'anio': anio,
        'placa': placa,
        'color': color,
        'reportes': reportes,
        'estado': estado.name,
        'foto': foto,
      };

  static Vehiculo fromJson(Map<String, Object?> j) => Vehiculo(
        id: j['id']! as String,
        tipo: TipoVehiculo.values.byName(j['tipo']! as String),
        marca: j['marca']! as String,
        modelo: j['modelo']! as String,
        anio: (j['anio']! as num).toInt(),
        placa: j['placa']! as String,
        color: j['color']! as String,
        reportes: (j['reportes'] as num?)?.toInt() ?? 0,
        estado: EstadoVehiculo.values.byName(j['estado'] as String? ?? 'protegida'),
        foto: j['foto'] as String?,
      );
}

enum TipoZona {
  casa('Casa', TablerIcons.home),
  trabajo('Trabajo', TablerIcons.briefcase),
  estudio('Estudio', TablerIcons.school),
  otro('Otro', TablerIcons.map_pin);

  const TipoZona(this.etiqueta, this.icono);
  final String etiqueta;
  final IconData icono;
}

class ZonaFavorita {
  const ZonaFavorita({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.tipo,
    required this.punto,
    this.radioKm = 1,
    this.avisar = true,
    this.nivel = NivelRiesgo.bajo,
  });

  final String id;
  final String nombre;
  final String direccion;
  final TipoZona tipo;
  final LatLng punto;
  final double radioKm;
  final bool avisar;
  final NivelRiesgo nivel;

  ZonaFavorita copyWith({bool? avisar}) =>
      ZonaFavorita(id: id, nombre: nombre, direccion: direccion, tipo: tipo, punto: punto, radioKm: radioKm, avisar: avisar ?? this.avisar, nivel: nivel);

  Map<String, Object?> toJson() => {
        'id': id,
        'nombre': nombre,
        'direccion': direccion,
        'tipo': tipo.name,
        'lat': punto.latitude,
        'lng': punto.longitude,
        'radio': radioKm,
        'avisar': avisar,
        'nivel': nivel.name,
      };

  static ZonaFavorita fromJson(Map<String, Object?> j) => ZonaFavorita(
        id: j['id']! as String,
        nombre: j['nombre']! as String,
        direccion: j['direccion']! as String,
        tipo: TipoZona.values.byName(j['tipo']! as String),
        punto: LatLng((j['lat']! as num).toDouble(), (j['lng']! as num).toDouble()),
        radioKm: (j['radio'] as num?)?.toDouble() ?? 1,
        avisar: j['avisar'] as bool? ?? true,
        nivel: NivelRiesgo.values.byName(j['nivel'] as String? ?? 'bajo'),
      );
}

class Privacidad {
  const Privacidad({this.anonimo = true, this.compartirUbicacion = true, this.mostrarNombre = false});

  final bool anonimo;
  final bool compartirUbicacion;
  final bool mostrarNombre;

  Privacidad copyWith({bool? anonimo, bool? compartirUbicacion, bool? mostrarNombre}) => Privacidad(
        anonimo: anonimo ?? this.anonimo,
        compartirUbicacion: compartirUbicacion ?? this.compartirUbicacion,
        mostrarNombre: mostrarNombre ?? this.mostrarNombre,
      );
}

class EstadisticasPerfil {
  const EstadisticasPerfil({this.reportes = 12, this.alertasUtiles = 27, this.mesesActivo = 8});
  final int reportes;
  final int alertasUtiles;
  final int mesesActivo;
}

const preguntasFrecuentes = <(String, String)>[
  ('¿Cómo reporto un hurto?', 'Toca "Reportar incidente" en el inicio o el botón SOS si estás en peligro. Completa los 3 pasos: vehículo, ubicación y confirmación.'),
  ('¿Quién puede ver mis reportes?', 'La autoridad ve el reporte completo. Los demás ciudadanos solo ven el punto en el mapa; si reportas de forma anónima, tu nombre no aparece.'),
  ('¿Cómo funciona el mapa de calor?', 'Las zonas rojas se calculan con los reportes de los últimos 30 días: mientras más reportes, más intenso el color.'),
  ('¿Qué hago si recupero mi vehículo?', 'Entra a Mis vehículos y márcalo como recuperado, o avisa en el CAI más cercano para cerrar el caso.'),
  ('¿Cómo cambio mi tipo de usuario?', 'Las cuentas de autoridad se solicitan desde "¿Eres Policía o SIJIN?" al crear la cuenta y las aprueba un administrador.'),
];

// ---------------- Persistencia ----------------
// Sin Supabase: SharedPreferences (datos de ejemplo del diseño).
// Con Supabase: tablas `vehiculos` y `zonas_favoritas` del usuario con sesión (RLS).

abstract class _ListaPersistida<T> extends Notifier<List<T>> {
  String get clave;
  String get tabla;
  List<T> get iniciales;
  Map<String, Object?> aJson(T v);
  T deJson(Map<String, Object?> j);
  Map<String, Object?> aFila(T v);
  T deFila(Map<String, dynamic> f);

  bool get _remoto => SupabaseConfig.habilitado;

  @override
  List<T> build() {
    // Se recarga al cambiar de usuario.
    final uid = ref.watch(authControllerProvider.select((s) => s.usuario?.id));
    if (_remoto) {
      if (uid != null) _cargarRemoto();
      return const [];
    }
    _cargar();
    return iniciales;
  }

  Future<void> _cargarRemoto() async {
    try {
      final filas = await supa.from(tabla).select().order('creado_en');
      state = [for (final f in filas) deFila(f)];
    } catch (_) {
      // Sin conexión: se mantiene la lista vacía.
    }
  }

  Future<void> _cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(clave);
    if (texto == null) return;
    state = (jsonDecode(texto) as List).map((e) => deJson((e as Map).cast<String, Object?>())).toList();
  }

  Future<void> guardar(List<T> lista) async {
    state = lista;
    if (_remoto) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(clave, jsonEncode(lista.map(aJson).toList()));
  }

  Future<void> _insertar(T v) async {
    if (!_remoto) return guardar([...state, v]);
    final fila = await supa.from(tabla).insert(aFila(v)).select().single();
    state = [...state, deFila(fila)];
  }

  Future<void> _borrar(String id, bool Function(T) donde) async {
    final antes = state;
    state = state.where((e) => !donde(e)).toList();
    if (!_remoto) return guardar(state);
    try {
      await supa.from(tabla).delete().eq('id', id);
    } catch (e) {
      state = antes;
      rethrow;
    }
  }
}

final vehiculosProvider = NotifierProvider<VehiculosController, List<Vehiculo>>(VehiculosController.new);

class VehiculosController extends _ListaPersistida<Vehiculo> {
  @override
  String get clave => 'perfil_vehiculos';

  @override
  String get tabla => 'vehiculos';

  @override
  List<Vehiculo> get iniciales => const [
        Vehiculo(id: 'v1', tipo: TipoVehiculo.moto, marca: 'Bajaj', modelo: 'Pulsar NS200', anio: 2022, placa: 'ABC12D', color: 'Negra'),
        Vehiculo(
          id: 'v2',
          tipo: TipoVehiculo.auto,
          marca: 'Chevrolet',
          modelo: 'Onix',
          anio: 2021,
          placa: 'HGT567',
          color: 'Gris',
          reportes: 1,
          estado: EstadoVehiculo.recuperado,
        ),
      ];

  @override
  Map<String, Object?> aJson(Vehiculo v) => v.toJson();

  @override
  Vehiculo deJson(Map<String, Object?> j) => Vehiculo.fromJson(j);

  @override
  Map<String, Object?> aFila(Vehiculo v) => {
        'tipo': v.tipo.name,
        'marca': v.marca,
        'modelo': v.modelo,
        'anio': v.anio,
        'placa': v.placa,
        'color': v.color,
        'foto': v.foto,
      };

  @override
  Vehiculo deFila(Map<String, dynamic> f) => Vehiculo.fromJson({...f, 'id': f['id'].toString()});

  /// Sube la foto (si hay) al bucket `vehiculos` y guarda el vehículo.
  Future<void> agregar(Vehiculo v) async {
    final foto = v.foto != null && _remoto ? await ArchivosLocales.subir('vehiculos', v.foto!) : v.foto;
    await _insertar(Vehiculo(
      id: v.id,
      tipo: v.tipo,
      marca: v.marca,
      modelo: v.modelo,
      anio: v.anio,
      placa: v.placa,
      color: v.color,
      reportes: v.reportes,
      estado: v.estado,
      foto: foto,
    ));
  }

  Future<void> eliminar(String id) => _borrar(id, (v) => v.id == id);
}

final zonasFavoritasProvider = NotifierProvider<ZonasFavoritasController, List<ZonaFavorita>>(ZonasFavoritasController.new);

class ZonasFavoritasController extends _ListaPersistida<ZonaFavorita> {
  @override
  String get clave => 'perfil_zonas';

  @override
  String get tabla => 'zonas_favoritas';

  @override
  List<ZonaFavorita> get iniciales => const [
        ZonaFavorita(id: 'z1', nombre: 'Casa', direccion: 'Calle 140 # 12-30, Usaquén', tipo: TipoZona.casa, punto: LatLng(4.7215, -74.0360)),
        ZonaFavorita(
          id: 'z2',
          nombre: 'Trabajo',
          direccion: 'Cra. 7 # 72-41, Chapinero',
          tipo: TipoZona.trabajo,
          punto: LatLng(4.6560, -74.0560),
          nivel: NivelRiesgo.medio,
        ),
        ZonaFavorita(
          id: 'z3',
          nombre: 'Universidad',
          direccion: 'Cra. 4 # 22-61, Santa Fe',
          tipo: TipoZona.estudio,
          punto: LatLng(4.6020, -74.0660),
          nivel: NivelRiesgo.alto,
        ),
      ];

  @override
  Map<String, Object?> aJson(ZonaFavorita v) => v.toJson();

  @override
  ZonaFavorita deJson(Map<String, Object?> j) => ZonaFavorita.fromJson(j);

  @override
  Map<String, Object?> aFila(ZonaFavorita z) => {
        'nombre': z.nombre,
        'direccion': z.direccion,
        'tipo': z.tipo.name,
        'lat': z.punto.latitude,
        'lng': z.punto.longitude,
        'radio_km': z.radioKm,
        'avisar': z.avisar,
        'nivel': z.nivel.name,
      };

  @override
  ZonaFavorita deFila(Map<String, dynamic> f) => ZonaFavorita.fromJson({...f, 'id': f['id'].toString(), 'radio': f['radio_km']});

  Future<void> agregar(ZonaFavorita z) => _insertar(z);

  Future<void> alternarAviso(String id) async {
    final zona = state.firstWhere((z) => z.id == id);
    state = [for (final z in state) z.id == id ? z.copyWith(avisar: !z.avisar) : z];
    if (!_remoto) return guardar(state);
    await supa.from(tabla).update({'avisar': !zona.avisar}).eq('id', id);
  }

  Future<void> eliminar(String id) => _borrar(id, (z) => z.id == id);
}

final privacidadProvider = NotifierProvider<PrivacidadController, Privacidad>(PrivacidadController.new);

class PrivacidadController extends Notifier<Privacidad> {
  @override
  Privacidad build() {
    _cargar();
    return const Privacidad();
  }

  Future<void> _cargar() async {
    final s = await SharedPreferences.getInstance();
    state = Privacidad(
      anonimo: s.getBool('priv_anonimo') ?? true,
      compartirUbicacion: s.getBool('priv_ubicacion') ?? true,
      mostrarNombre: s.getBool('priv_nombre') ?? false,
    );
  }

  Future<void> cambiar(Privacidad p) async {
    state = p;
    final s = await SharedPreferences.getInstance();
    await s.setBool('priv_anonimo', p.anonimo);
    await s.setBool('priv_ubicacion', p.compartirUbicacion);
    await s.setBool('priv_nombre', p.mostrarNombre);
  }
}

final estadisticasPerfilProvider = Provider<EstadisticasPerfil>((ref) => const EstadisticasPerfil());

/// Localidad guardada en el perfil (Editar perfil).
final localidadPerfilProvider = NotifierProvider<LocalidadPerfil, String>(LocalidadPerfil.new);

class LocalidadPerfil extends Notifier<String> {
  @override
  String build() {
    SharedPreferences.getInstance().then((s) => state = s.getString('perfil_localidad') ?? state);
    return 'Chapinero';
  }

  Future<void> cambiar(String v) async {
    state = v;
    final s = await SharedPreferences.getInstance();
    await s.setString('perfil_localidad', v);
  }
}
