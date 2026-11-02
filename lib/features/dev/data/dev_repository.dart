import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/domain/usuario.dart';
import '../../mapa/domain/modelos_mapa.dart';

// Datos del panel DEV (administrador).
// Sin Supabase: datos de ejemplo del Figma en memoria. Con Supabase: cada lista se carga de su tabla
// y las acciones (aprobar, bloquear, permisos…) se guardan en la base de datos.

/// Iniciales seguras para el avatar ("LG", "SC").
String inicialesDe(String nombre) {
  final partes = nombre.replaceAll('.', '').split(' ').where((p) => p.isNotEmpty).toList();
  if (partes.isEmpty) return '?';
  if (partes.length == 1) return partes.first.substring(0, partes.first.length.clamp(1, 2)).toUpperCase();
  return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
}

enum EstadoCuenta { activo, pendiente, bloqueado }

class UsuarioAdmin {
  const UsuarioAdmin({this.id = '', required this.nombre, required this.correo, required this.rol, this.estado = EstadoCuenta.activo, this.colorAvatar});

  final String id;
  final String nombre;
  final String correo;
  final Rol rol;
  final EstadoCuenta estado;
  final Color? colorAvatar;

  String get iniciales => inicialesDe(nombre);

  Color get color => colorAvatar ?? (estado == EstadoCuenta.bloqueado ? const Color(0xFF6F767C) : rol.color);

  UsuarioAdmin copyWith({EstadoCuenta? estado, Rol? rol}) =>
      UsuarioAdmin(id: id, nombre: nombre, correo: correo, rol: rol ?? this.rol, estado: estado ?? this.estado, colorAvatar: colorAvatar);
}

enum EstadoRevision { pendiente, aprobado, rechazado }

class SolicitudAutoridad {
  const SolicitudAutoridad({
    this.id = '',
    required this.nombre,
    required this.correo,
    required this.detalle,
    this.estado = EstadoRevision.pendiente,
    this.carneRuta,
  });
  final String id;
  final String nombre;
  final String correo;
  final String detalle;
  final EstadoRevision estado;

  /// Ruta del carné en el bucket `carnes` (solo con Supabase).
  final String? carneRuta;

  String get iniciales => inicialesDe(nombre);

  SolicitudAutoridad copyWith(EstadoRevision e) =>
      SolicitudAutoridad(id: id, nombre: nombre, correo: correo, detalle: detalle, estado: e, carneRuta: carneRuta);
}

enum Evidencia {
  conFotos('Con fotos'),
  posibleFalso('Posible falso'),
  sinFotos('Sin fotos');

  const Evidencia(this.etiqueta);
  final String etiqueta;
}

class ReporteModeracion {
  const ReporteModeracion({
    required this.id,
    required this.titulo,
    required this.placa,
    required this.autor,
    required this.barrio,
    required this.hora,
    required this.vehiculo,
    required this.evidencia,
    required this.nota,
    this.estado = EstadoRevision.pendiente,
  });

  final String id;
  final String titulo;
  final String placa;
  final String autor;
  final String barrio;
  final String hora;
  final TipoVehiculo vehiculo;
  final Evidencia evidencia;
  final String nota;
  final EstadoRevision estado;

  ReporteModeracion copyWith(EstadoRevision e) => ReporteModeracion(
        id: id,
        titulo: titulo,
        placa: placa,
        autor: autor,
        barrio: barrio,
        hora: hora,
        vehiculo: vehiculo,
        evidencia: evidencia,
        nota: nota,
        estado: e,
      );
}

class RegistroActividad {
  const RegistroActividad(this.texto, this.hora, this.categoria, this.color);
  final String texto;
  final String hora;
  final String categoria;
  final Color color;
}

enum EstadoCai {
  activo('Activo'),
  refuerzo('Refuerzo'),
  inactivo('Inactivo');

  const EstadoCai(this.etiqueta);
  final String etiqueta;
}

class CaiAdmin {
  const CaiAdmin(this.nombre, this.localidad, this.telefono, this.patrullas, this.estado, this.punto, {this.tipo = 'CAI'});
  final String nombre;
  final String localidad;
  final String telefono;
  final int? patrullas;
  final EstadoCai estado;
  final LatLng punto;

  /// 'CAI', 'Punto seguro' o 'Estación'.
  final String tipo;
}

class EnvioMasivo {
  const EnvioMasivo(this.titulo, this.detalle, this.apertura, {this.mensaje = '', this.tipo = 'Alerta de hurto', this.audiencia = const [], this.alcance = 0, this.canales = const []});
  final String titulo;
  final String detalle;
  final int apertura;
  final String mensaje;
  final String tipo;
  final List<String> audiencia;
  final int alcance;
  final List<String> canales;
}

enum EstadoServicio { operativo, degradado, caido }

class Servicio {
  const Servicio(this.nombre, this.latencia, this.estado, this.disponibilidad, this.icono, {this.fallas = const {}});
  final String nombre;
  final String latencia;
  final EstadoServicio estado;
  final String disponibilidad;
  final IconData icono;

  /// Días (0–29) con falla: valor 1 = degradado, 2 = caído.
  final Map<int, int> fallas;
}

class Exportacion {
  const Exportacion(this.archivo, this.detalle, this.estado);
  final String archivo;
  final String detalle;

  /// 'listo', 'procesando' o 'vencido'.
  final String estado;
}

class ConfigSistema {
  const ConfigSistema({
    this.mapaCalor = true,
    this.zonasAutomaticas = true,
    this.exigirFoto = false,
    this.moderacionAutomatica = true,
    this.cierreHoras = 72,
    this.mantenimiento = false,
  });

  final bool mapaCalor;
  final bool zonasAutomaticas;
  final bool exigirFoto;
  final bool moderacionAutomatica;
  final int cierreHoras;
  final bool mantenimiento;

  ConfigSistema copyWith({bool? mapaCalor, bool? zonasAutomaticas, bool? exigirFoto, bool? moderacionAutomatica, int? cierreHoras, bool? mantenimiento}) =>
      ConfigSistema(
        mapaCalor: mapaCalor ?? this.mapaCalor,
        zonasAutomaticas: zonasAutomaticas ?? this.zonasAutomaticas,
        exigirFoto: exigirFoto ?? this.exigirFoto,
        moderacionAutomatica: moderacionAutomatica ?? this.moderacionAutomatica,
        cierreHoras: cierreHoras ?? this.cierreHoras,
        mantenimiento: mantenimiento ?? this.mantenimiento,
      );
}

/// Reportes por localidad (Analítica y Panel).
const reportesPorLocalidad = <(String, int)>[
  ('Kennedy', 64),
  ('Bosa', 48),
  ('Suba', 39),
  ('Engativá', 31),
  ('Ciudad Bolívar', 28),
  ('Chapinero', 22),
];

/// Métricas de Analítica por periodo: (valor, variación) para reportes, recuperados, respuesta y usuarios.
const metricasPorPeriodo = <String, List<(String, String, String)>>{
  'Hoy': [('36', '+4 %', 'Reportes'), ('5', '+1 %', 'Recuperados'), ('16 min', '−2 min', 'Tiempo de respuesta'), ('980', '+3 %', 'Usuarios activos')],
  'Semana': [('248', '+12 %', 'Reportes'), ('41', '+5 %', 'Recuperados'), ('18 min', '−3 min', 'Tiempo de respuesta'), ('1.2K', '+8 %', 'Usuarios activos')],
  'Mes': [('1.031', '+9 %', 'Reportes'), ('162', '+7 %', 'Recuperados'), ('19 min', '−1 min', 'Tiempo de respuesta'), ('4.8K', '+15 %', 'Usuarios activos')],
};

/// Permisos por rol (Roles y permisos).
const permisosSistema = [
  'Crear reportes',
  'Ver mapa y alertas',
  'Ver datos personales del denunciante',
  'Atender y cerrar casos',
  'Consultar placas',
  'Moderar reportes',
  'Aprobar autoridades',
  'Gestionar usuarios',
  'Enviar notificaciones masivas',
  'Configurar sistema',
  'Exportar datos',
];

// ---------------- Notifiers ----------------

/// Origen remoto (Supabase) de una lista del panel DEV.
class _Remota<T> {
  const _Remota({required this.cargar, this.actualizar, this.insertar});
  final Future<List<T>> Function() cargar;
  final Future<void> Function(T anterior, T nuevo)? actualizar;
  final Future<T> Function(T nuevo)? insertar;
}

/// Lista del panel DEV: datos de ejemplo en memoria o, con Supabase, la tabla correspondiente.
class _ListaMemoria<T> extends Notifier<List<T>> {
  _ListaMemoria(this._inicial, {this.remota});
  final List<T> _inicial;
  final _Remota<T>? remota;

  bool get _remoto => remota != null && SupabaseConfig.habilitado;

  @override
  List<T> build() {
    if (!_remoto) return _inicial;
    final uid = ref.watch(authControllerProvider.select((s) => s.usuario?.id));
    if (uid != null) recargar();
    return const [];
  }

  Future<void> recargar() async {
    try {
      state = await remota!.cargar();
    } catch (e) {
      debugPrint('No se pudo cargar la lista DEV: $e');
    }
  }

  /// Cambia los elementos que cumplen [donde]; con Supabase guarda el cambio y lo revierte si falla.
  Future<void> reemplazar(bool Function(T) donde, T Function(T) cambio) async {
    final antes = state;
    final cambios = <(T, T)>[];
    final nueva = <T>[];
    for (final e in state) {
      if (donde(e)) {
        final n = cambio(e);
        cambios.add((e, n));
        nueva.add(n);
      } else {
        nueva.add(e);
      }
    }
    state = nueva;
    if (!_remoto || remota!.actualizar == null) return;
    try {
      for (final (a, n) in cambios) {
        await remota!.actualizar!(a, n);
      }
    } catch (e) {
      state = antes;
      rethrow;
    }
  }

  Future<void> agregar(T e) async {
    state = [e, ...state];
    if (!_remoto || remota!.insertar == null) return;
    try {
      final guardado = await remota!.insertar!(e);
      state = [guardado, ...state.skip(1)];
    } catch (err) {
      state = state.skip(1).toList();
      rethrow;
    }
  }
}

String _horaCorta(String iso) {
  final t = DateTime.parse(iso).toLocal();
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'a. m.' : 'p. m.'}';
}

String _fechaCorta(String iso) {
  final t = DateTime.parse(iso).toLocal();
  final ahora = DateTime.now();
  if (t.year == ahora.year && t.month == ahora.month && t.day == ahora.day) return 'Hoy ${_horaCorta(iso)}';
  if (ahora.difference(t).inDays < 2) return 'Ayer';
  const m = ['ene.', 'feb.', 'mar.', 'abr.', 'may.', 'jun.', 'jul.', 'ago.', 'sep.', 'oct.', 'nov.', 'dic.'];
  return '${t.day} ${m[t.month - 1]}';
}

String _miles(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return b.toString();
}

Future<void> _registrar(String texto, String categoria) async {
  try {
    await supa.from('registros_actividad').insert({'texto': texto, 'categoria': categoria});
  } catch (_) {}
}

final usuariosAdminProvider = NotifierProvider<_ListaMemoria<UsuarioAdmin>, List<UsuarioAdmin>>(
  () => _ListaMemoria(
    const [
      UsuarioAdmin(nombre: 'Laura Gómez', correo: 'laura@correo.com', rol: Rol.ciudadano),
      UsuarioAdmin(nombre: 'Pt. Ramírez', correo: 'p.ramirez@policia.gov.co', rol: Rol.autoridad),
      UsuarioAdmin(nombre: 'Andrés Mora', correo: 'andres@correo.com', rol: Rol.ciudadano),
      UsuarioAdmin(nombre: 'Sgto. Castro', correo: 's.castro@policia.gov.co', rol: Rol.autoridad, estado: EstadoCuenta.pendiente),
      UsuarioAdmin(nombre: 'Dev User', correo: 'dev@alertavial.co', rol: Rol.dev),
      UsuarioAdmin(nombre: 'Juan Ríos', correo: 'juan@correo.com', rol: Rol.ciudadano, estado: EstadoCuenta.bloqueado),
      UsuarioAdmin(nombre: 'Camila Pardo', correo: 'camila@correo.com', rol: Rol.ciudadano),
      UsuarioAdmin(nombre: 'Cabo Ríos', correo: 'l.rios@policia.gov.co', rol: Rol.autoridad, estado: EstadoCuenta.pendiente),
    ],
    remota: _Remota(
      cargar: () async {
        final filas = await supa.from('perfiles').select().order('creado_en', ascending: false);
        return [
          for (final f in filas)
            UsuarioAdmin(
              id: f['id'] as String,
              nombre: f['nombre'] as String? ?? '',
              correo: f['correo'] as String? ?? '',
              rol: Rol.values.byName(f['rol'] as String),
              estado: EstadoCuenta.values.byName(f['estado'] as String),
            ),
        ];
      },
      actualizar: (a, n) async {
        await supa.from('perfiles').update({'rol': n.rol.name, 'estado': n.estado.name}).eq('id', n.id);
        await _registrar('${n.nombre}: ${n.rol.etiqueta} · ${n.estado.name}', 'Usuarios');
      },
    ),
  ),
);

final solicitudesAutoridadProvider = NotifierProvider<_ListaMemoria<SolicitudAutoridad>, List<SolicitudAutoridad>>(
  () => _ListaMemoria(
    const [
      SolicitudAutoridad(nombre: 'Sgto. Castro', correo: 's.castro@policia.gov.co', detalle: 'SIJIN · Bogotá · Placa 012345'),
      SolicitudAutoridad(nombre: 'Pt. Torres', correo: 'm.torres@policia.gov.co', detalle: 'Policía Nacional · Suba · Placa 045821'),
      SolicitudAutoridad(nombre: 'Cabo Ríos', correo: 'l.rios@policia.gov.co', detalle: 'Tránsito · Kennedy · Placa 078214'),
      SolicitudAutoridad(nombre: 'Pt. Ramírez', correo: 'p.ramirez@policia.gov.co', detalle: 'Policía Nacional · Chapinero · Placa 033190', estado: EstadoRevision.aprobado),
      SolicitudAutoridad(nombre: 'Juan Pérez', correo: 'juanp@gmail.com', detalle: 'Correo no institucional', estado: EstadoRevision.rechazado),
    ],
    remota: _Remota(
      cargar: () async {
        final filas = await supa.from('solicitudes_autoridad').select().order('creado_en', ascending: false);
        return [
          for (final f in filas)
            SolicitudAutoridad(
              id: f['id'] as String,
              nombre: f['nombre'] as String? ?? '',
              correo: f['correo'] as String,
              detalle: '${f['unidad']} · Placa ${f['placa']}',
              estado: EstadoRevision.values.byName(f['estado'] as String),
              carneRuta: f['carne_ruta'] as String?,
            ),
        ];
      },
      actualizar: (a, n) async {
        // El trigger `al_decidir_solicitud` activa o bloquea el perfil.
        await supa.from('solicitudes_autoridad').update({'estado': n.estado.name}).eq('id', n.id);
        await _registrar('Solicitud de ${n.nombre}: ${n.estado.name}', 'Usuarios');
      },
    ),
  ),
);

/// Enlace temporal (10 min) para ver el carné de una solicitud.
Future<String?> urlCarne(String? ruta) async {
  if (ruta == null || !SupabaseConfig.habilitado) return null;
  return supa.storage.from('carnes').createSignedUrl(ruta, 600);
}

ReporteModeracion _moderacionDesdeFila(Map<String, dynamic> f) {
  final fotos = (f['fotos'] as List?)?.length ?? 0;
  final anonimo = f['anonimo'] as bool? ?? true;
  final perfil = f['perfiles'] as Map?;
  return ReporteModeracion(
    id: f['id'] as String,
    titulo: f['titulo'] as String,
    placa: f['placa'] as String,
    autor: anonimo ? 'Usuario anónimo' : (perfil?['nombre'] as String? ?? 'Ciudadano'),
    barrio: f['barrio'] as String? ?? '',
    hora: _horaCorta(f['creado_en'] as String),
    vehiculo: TipoVehiculo.values.byName(f['vehiculo'] as String),
    evidencia: (f['posible_falso'] as bool? ?? false) ? Evidencia.posibleFalso : (fotos > 0 ? Evidencia.conFotos : Evidencia.sinFotos),
    nota: fotos > 0 ? '$fotos ${fotos == 1 ? 'foto' : 'fotos'} · ${f['direccion']}' : 'Sin evidencia adjunta',
    estado: EstadoRevision.values.byName(f['moderacion'] as String),
  );
}

final moderacionProvider = NotifierProvider<_ListaMemoria<ReporteModeracion>, List<ReporteModeracion>>(
  () => _ListaMemoria(
    const [
      ReporteModeracion(id: 'AV-2052', titulo: 'Hurto de moto', placa: 'XYZ98E', autor: 'Laura Gómez', barrio: 'Bosa', hora: '6:15 p. m.', vehiculo: TipoVehiculo.moto, evidencia: Evidencia.conFotos, nota: '2 fotos · ubicación verificada'),
      ReporteModeracion(id: 'AV-2050', titulo: 'Hurto de auto', placa: 'KLM234', autor: 'Usuario anónimo', barrio: 'Suba', hora: '5:40 p. m.', vehiculo: TipoVehiculo.auto, evidencia: Evidencia.posibleFalso, nota: '2 fotos · ubicación verificada'),
      ReporteModeracion(id: 'AV-2049', titulo: 'Intento de hurto', placa: 'ABC12D', autor: 'Andrés Mora', barrio: 'Teusaquillo', hora: '3:20 p. m.', vehiculo: TipoVehiculo.moto, evidencia: Evidencia.sinFotos, nota: 'Sin evidencia adjunta'),
      ReporteModeracion(id: 'AV-2047', titulo: 'Hurto de autopartes', placa: 'PRT908', autor: 'Camila Pardo', barrio: 'Chapinero', hora: '1:05 p. m.', vehiculo: TipoVehiculo.auto, evidencia: Evidencia.conFotos, nota: '1 foto · ubicación verificada'),
      ReporteModeracion(id: 'AV-2046', titulo: 'Hurto de moto', placa: 'QWE45F', autor: 'Usuario anónimo', barrio: 'Kennedy', hora: '11:40 a. m.', vehiculo: TipoVehiculo.moto, evidencia: Evidencia.sinFotos, nota: 'Sin evidencia adjunta'),
    ],
    remota: _Remota(
      cargar: () async {
        final filas = await supa.from('reportes').select('*, perfiles(nombre)').order('creado_en', ascending: false).limit(100);
        return [for (final f in filas) _moderacionDesdeFila(f)];
      },
      actualizar: (a, n) async {
        // Aprobado: se publica en el mapa (vista incidentes_publicos) y pasa a "recibido".
        await supa
            .from('reportes')
            .update({'moderacion': n.estado.name, if (n.estado == EstadoRevision.aprobado) 'estado': 'recibido'})
            .eq('id', n.id);
        await _registrar('${n.placa} ${n.estado == EstadoRevision.aprobado ? 'aprobado' : 'rechazado'} en moderación', 'Moderación');
      },
    ),
  ),
);

final configSistemaProvider = NotifierProvider<_ConfigSistema, ConfigSistema>(_ConfigSistema.new);

class _ConfigSistema extends Notifier<ConfigSistema> {
  @override
  ConfigSistema build() {
    if (SupabaseConfig.habilitado && ref.watch(authControllerProvider.select((s) => s.usuario?.id)) != null) _cargar();
    return const ConfigSistema();
  }

  Future<void> _cargar() async {
    try {
      final f = await supa.from('configuracion_sistema').select().eq('id', 1).maybeSingle();
      final v = (f?['valores'] as Map?)?.cast<String, dynamic>();
      if (v == null) return;
      state = ConfigSistema(
        mapaCalor: v['mapaCalor'] as bool? ?? true,
        zonasAutomaticas: v['zonasAutomaticas'] as bool? ?? true,
        exigirFoto: v['exigirFoto'] as bool? ?? false,
        moderacionAutomatica: v['moderacionAutomatica'] as bool? ?? true,
        cierreHoras: v['cierreHoras'] as int? ?? 72,
        mantenimiento: v['mantenimiento'] as bool? ?? false,
      );
    } catch (_) {}
  }

  Future<void> cambiar(ConfigSistema c) async {
    state = c;
    if (!SupabaseConfig.habilitado) return;
    await supa.from('configuracion_sistema').upsert({
      'id': 1,
      'valores': {
        'mapaCalor': c.mapaCalor,
        'zonasAutomaticas': c.zonasAutomaticas,
        'exigirFoto': c.exigirFoto,
        'moderacionAutomatica': c.moderacionAutomatica,
        'cierreHoras': c.cierreHoras,
        'mantenimiento': c.mantenimiento,
      },
      'actualizado_en': DateTime.now().toUtc().toIso8601String(),
    });
    await _registrar('Configuración del sistema actualizada', 'Sistema');
  }
}

const _registrosEjemplo = [
  RegistroActividad('Laura Gómez creó el reporte AV-2051', '6:15 p. m.', 'Reportes', Color(0xFF3B82F6)),
  RegistroActividad('Sgto. Castro solicitó acceso', '6:02 p. m.', 'Usuarios', AppColors.amarillo),
  RegistroActividad('KLM234 marcado como posible falso', '5:41 p. m.', 'Moderación', AppColors.rojo),
  RegistroActividad('Copia de seguridad completada', '5:00 p. m.', 'Sistema', AppColors.verdeExito),
  RegistroActividad('Error 502 en el servicio de mapas', '4:37 p. m.', 'Errores', AppColors.rojo),
  RegistroActividad('Dev User cambió la configuración', '3:15 p. m.', 'Sistema', Color(0xFF8B7FE0)),
  RegistroActividad('Pt. Ramírez cerró el caso AV-2040', '2:50 p. m.', 'Casos', AppColors.verdeExito),
  RegistroActividad('Nuevo usuario registrado', '2:12 p. m.', 'Usuarios', Color(0xFF3B82F6)),
];

const _coloresCategoria = {
  'Reportes': Color(0xFF3B82F6),
  'Usuarios': AppColors.amarillo,
  'Moderación': AppColors.rojo,
  'Sistema': AppColors.verdeExito,
  'Errores': AppColors.rojo,
  'Casos': Color(0xFF8B7FE0),
};

final registrosActividadProvider = FutureProvider<List<RegistroActividad>>((ref) async {
  if (!SupabaseConfig.habilitado) return _registrosEjemplo;
  ref.watch(authControllerProvider.select((s) => s.usuario?.id));
  final filas = await supa.from('registros_actividad').select().order('creado_en', ascending: false).limit(100);
  return [
    for (final f in filas)
      RegistroActividad(
        f['texto'] as String,
        _horaCorta(f['creado_en'] as String),
        f['categoria'] as String,
        _coloresCategoria[f['categoria']] ?? AppColors.grisTexto,
      ),
  ];
});

const _caisEjemplo = [
  CaiAdmin('CAI Chapinero', 'Chapinero', '601 235 0000', 3, EstadoCai.activo, LatLng(4.6490, -74.0640)),
  CaiAdmin('CAI Fontanar', 'Suba', '601 680 1111', 2, EstadoCai.activo, LatLng(4.7480, -74.0950)),
  CaiAdmin('CAI Patio Bonito', 'Kennedy', '601 451 2222', 4, EstadoCai.activo, LatLng(4.6330, -74.1640)),
  CaiAdmin('CAI Bosa Centro', 'Bosa', '601 775 3333', 2, EstadoCai.activo, LatLng(4.6170, -74.1930)),
  CaiAdmin('CAI Lucero', 'Ciudad Bolívar', '601 731 4444', 1, EstadoCai.refuerzo, LatLng(4.5130, -74.1500)),
  CaiAdmin('CAI Galerías', 'Teusaquillo', '601 288 5555', 2, EstadoCai.activo, LatLng(4.6440, -74.0770)),
  CaiAdmin('CAI Unicentro', 'Usaquén', '601 213 6666', 3, EstadoCai.activo, LatLng(4.7020, -74.0420)),
  CaiAdmin('CAI Álamos', 'Engativá', '601 547 7777', 0, EstadoCai.inactivo, LatLng(4.6970, -74.1140)),
  CaiAdmin('Punto seguro Calle 72', 'Chapinero', '—', null, EstadoCai.activo, LatLng(4.6580, -74.0580), tipo: 'Punto seguro'),
  CaiAdmin('CAI Tintal', 'Kennedy', '601 452 8888', 2, EstadoCai.activo, LatLng(4.6420, -74.1560)),
  CaiAdmin('Estación Kennedy', 'Kennedy', '601 450 0000', 12, EstadoCai.activo, LatLng(4.6240, -74.1500), tipo: 'Estación'),
];

final caisAdminProvider = FutureProvider<List<CaiAdmin>>((ref) async {
  if (!SupabaseConfig.habilitado) return _caisEjemplo;
  final filas = await supa.from('cai').select().order('nombre');
  return [
    for (final f in filas)
      CaiAdmin(
        f['nombre'] as String,
        f['localidad'] as String,
        f['telefono'] as String? ?? '—',
        f['patrullas'] as int?,
        EstadoCai.values.byName(f['estado'] as String),
        LatLng((f['lat'] as num).toDouble(), (f['lng'] as num).toDouble()),
        tipo: f['tipo'] as String? ?? 'CAI',
      ),
  ];
});

final enviosMasivosProvider = NotifierProvider<_ListaMemoria<EnvioMasivo>, List<EnvioMasivo>>(
  () => _ListaMemoria(
    const [
      EnvioMasivo('Zona de riesgo · Bosa', 'Hoy 5:00 p. m. · 12.300 personas', 64),
      EnvioMasivo('Hurtos en Chapinero', 'Ayer · 8.900 personas', 58),
      EnvioMasivo('Mantenimiento programado', '10 oct. · Todos personas', 41),
      EnvioMasivo('Alerta Kennedy', '8 oct. · 15.100 personas', 71),
    ],
    remota: _Remota(
      cargar: () async {
        final filas = await supa.from('envios_masivos').select().order('creado_en', ascending: false).limit(20);
        return [
          for (final f in filas)
            EnvioMasivo(
              f['titulo'] as String,
              '${_fechaCorta(f['creado_en'] as String)} · ${_miles(f['alcance'] as int? ?? 0)} personas',
              f['apertura'] as int? ?? 0,
            ),
        ];
      },
      insertar: (e) async {
        await supa.from('envios_masivos').insert({
          'titulo': e.titulo,
          'mensaje': e.mensaje,
          'tipo': e.tipo,
          'audiencia': e.audiencia,
          'alcance': e.alcance,
          'canales': e.canales,
        });
        // La notificación llega a todos los ciudadanos (usuario_id nulo).
        await supa.from('notificaciones').insert({
          'tipo': switch (e.tipo) {
            'Zona de riesgo' => 'zona',
            'Aviso general' => 'cai',
            _ => 'hurto',
          },
          'titulo': e.titulo,
          'detalle': e.mensaje,
        });
        await _registrar('Notificación masiva enviada: ${e.titulo}', 'Sistema');
        return EnvioMasivo(e.titulo, 'Ahora · ${_miles(e.alcance)} personas', 0);
      },
    ),
  ),
);

/// Exportaciones: en memoria hasta que exista una función de exportación en el servidor.
final exportacionesProvider = NotifierProvider<_ListaMemoria<Exportacion>, List<Exportacion>>(
  () => _ListaMemoria(const [
    Exportacion('Reportes_sep_2026.xlsx', 'Hoy 5:10 p. m. · 1,4 MB', 'listo'),
    Exportacion('Casos_Q3.csv', 'Ayer · 860 KB', 'listo'),
    Exportacion('Usuarios_activos.pdf', '10 oct. · 2,1 MB', 'listo'),
    Exportacion('Zonas_riesgo_2026.xlsx', 'Ahora', 'procesando'),
    Exportacion('Notificaciones_oct.csv', '8 oct. · 320 KB', 'listo'),
    Exportacion('Reportes_ago_2026.xlsx', '1 sep. · 1,2 MB', 'vencido'),
  ]),
);

/// Matriz de permisos: permiso → roles que lo tienen (tabla `permisos_roles` con Supabase).
final permisosProvider = NotifierProvider<_Permisos, Map<String, Set<Rol>>>(_Permisos.new);

class _Permisos extends Notifier<Map<String, Set<Rol>>> {
  @override
  Map<String, Set<Rol>> build() {
    if (SupabaseConfig.habilitado && ref.watch(authControllerProvider.select((s) => s.usuario?.id)) != null) _cargar();
    return {
      'Crear reportes': {Rol.ciudadano, Rol.autoridad, Rol.dev},
      'Ver mapa y alertas': {Rol.ciudadano, Rol.autoridad, Rol.dev},
      'Ver datos personales del denunciante': {Rol.autoridad, Rol.dev},
      'Atender y cerrar casos': {Rol.autoridad},
      'Consultar placas': {Rol.autoridad, Rol.dev},
      'Moderar reportes': {Rol.dev},
      'Aprobar autoridades': {Rol.dev},
      'Gestionar usuarios': {Rol.dev},
      'Enviar notificaciones masivas': {Rol.dev},
      'Configurar sistema': {Rol.dev},
      'Exportar datos': {Rol.autoridad, Rol.dev},
    };
  }

  Future<void> _cargar() async {
    try {
      final filas = await supa.from('permisos_roles').select();
      final mapa = <String, Set<Rol>>{for (final p in permisosSistema) p: <Rol>{}};
      for (final f in filas) {
        mapa.putIfAbsent(f['permiso'] as String, () => <Rol>{}).add(Rol.values.byName(f['rol'] as String));
      }
      state = mapa;
    } catch (_) {}
  }

  Future<void> alternar(String permiso, Rol rol) async {
    final actual = {...state[permiso] ?? <Rol>{}};
    final quitar = actual.contains(rol);
    quitar ? actual.remove(rol) : actual.add(rol);
    state = {...state, permiso: actual};
    if (!SupabaseConfig.habilitado) return;
    if (quitar) {
      await supa.from('permisos_roles').delete().eq('permiso', permiso).eq('rol', rol.name);
    } else {
      await supa.from('permisos_roles').insert({'permiso': permiso, 'rol': rol.name});
    }
  }
}
