import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/domain/usuario.dart';
import '../../mapa/domain/modelos_mapa.dart';

// Datos de ejemplo del panel DEV (administrador), tomados del Figma.
// Cada lista vive en un Notifier en memoria para que las acciones (aprobar, bloquear…)
// se vean en la interfaz; la API real reemplazará estas clases.

enum EstadoCuenta { activo, pendiente, bloqueado }

class UsuarioAdmin {
  const UsuarioAdmin({required this.nombre, required this.correo, required this.rol, this.estado = EstadoCuenta.activo, this.colorAvatar});

  final String nombre;
  final String correo;
  final Rol rol;
  final EstadoCuenta estado;
  final Color? colorAvatar;

  String get iniciales {
    final partes = nombre.replaceAll('.', '').split(' ').where((p) => p.isNotEmpty).toList();
    if (partes.length == 1) return partes.first.substring(0, 2).toUpperCase();
    return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
  }

  Color get color => colorAvatar ?? (estado == EstadoCuenta.bloqueado ? const Color(0xFF6F767C) : rol.color);

  UsuarioAdmin copyWith({EstadoCuenta? estado, Rol? rol}) =>
      UsuarioAdmin(nombre: nombre, correo: correo, rol: rol ?? this.rol, estado: estado ?? this.estado, colorAvatar: colorAvatar);
}

enum EstadoRevision { pendiente, aprobado, rechazado }

class SolicitudAutoridad {
  const SolicitudAutoridad({required this.nombre, required this.correo, required this.detalle, this.estado = EstadoRevision.pendiente});
  final String nombre;
  final String correo;
  final String detalle;
  final EstadoRevision estado;

  String get iniciales {
    final p = nombre.replaceAll('.', '').split(' ');
    return '${p[0][0]}${p.last[0]}'.toUpperCase();
  }

  SolicitudAutoridad copyWith(EstadoRevision e) => SolicitudAutoridad(nombre: nombre, correo: correo, detalle: detalle, estado: e);
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
  const EnvioMasivo(this.titulo, this.detalle, this.apertura);
  final String titulo;
  final String detalle;
  final int apertura;
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

class _ListaMemoria<T> extends Notifier<List<T>> {
  _ListaMemoria(this._inicial);
  final List<T> _inicial;

  @override
  List<T> build() => _inicial;

  void reemplazar(bool Function(T) donde, T Function(T) cambio) => state = [for (final e in state) donde(e) ? cambio(e) : e];
  void agregar(T e) => state = [e, ...state];
}

final usuariosAdminProvider = NotifierProvider<_ListaMemoria<UsuarioAdmin>, List<UsuarioAdmin>>(
  () => _ListaMemoria(const [
    UsuarioAdmin(nombre: 'Laura Gómez', correo: 'laura@correo.com', rol: Rol.ciudadano),
    UsuarioAdmin(nombre: 'Pt. Ramírez', correo: 'p.ramirez@policia.gov.co', rol: Rol.autoridad),
    UsuarioAdmin(nombre: 'Andrés Mora', correo: 'andres@correo.com', rol: Rol.ciudadano),
    UsuarioAdmin(nombre: 'Sgto. Castro', correo: 's.castro@policia.gov.co', rol: Rol.autoridad, estado: EstadoCuenta.pendiente),
    UsuarioAdmin(nombre: 'Dev User', correo: 'dev@alertavial.co', rol: Rol.dev),
    UsuarioAdmin(nombre: 'Juan Ríos', correo: 'juan@correo.com', rol: Rol.ciudadano, estado: EstadoCuenta.bloqueado),
    UsuarioAdmin(nombre: 'Camila Pardo', correo: 'camila@correo.com', rol: Rol.ciudadano),
    UsuarioAdmin(nombre: 'Cabo Ríos', correo: 'l.rios@policia.gov.co', rol: Rol.autoridad, estado: EstadoCuenta.pendiente),
  ]),
);

final solicitudesAutoridadProvider = NotifierProvider<_ListaMemoria<SolicitudAutoridad>, List<SolicitudAutoridad>>(
  () => _ListaMemoria(const [
    SolicitudAutoridad(nombre: 'Sgto. Castro', correo: 's.castro@policia.gov.co', detalle: 'SIJIN · Bogotá · Placa 012345'),
    SolicitudAutoridad(nombre: 'Pt. Torres', correo: 'm.torres@policia.gov.co', detalle: 'Policía Nacional · Suba · Placa 045821'),
    SolicitudAutoridad(nombre: 'Cabo Ríos', correo: 'l.rios@policia.gov.co', detalle: 'Tránsito · Kennedy · Placa 078214'),
    SolicitudAutoridad(nombre: 'Pt. Ramírez', correo: 'p.ramirez@policia.gov.co', detalle: 'Policía Nacional · Chapinero · Placa 033190', estado: EstadoRevision.aprobado),
    SolicitudAutoridad(nombre: 'Juan Pérez', correo: 'juanp@gmail.com', detalle: 'Correo no institucional', estado: EstadoRevision.rechazado),
  ]),
);

final moderacionProvider = NotifierProvider<_ListaMemoria<ReporteModeracion>, List<ReporteModeracion>>(
  () => _ListaMemoria(const [
    ReporteModeracion(id: 'AV-2052', titulo: 'Hurto de moto', placa: 'XYZ98E', autor: 'Laura Gómez', barrio: 'Bosa', hora: '6:15 p. m.', vehiculo: TipoVehiculo.moto, evidencia: Evidencia.conFotos, nota: '2 fotos · ubicación verificada'),
    ReporteModeracion(id: 'AV-2050', titulo: 'Hurto de auto', placa: 'KLM234', autor: 'Usuario anónimo', barrio: 'Suba', hora: '5:40 p. m.', vehiculo: TipoVehiculo.auto, evidencia: Evidencia.posibleFalso, nota: '2 fotos · ubicación verificada'),
    ReporteModeracion(id: 'AV-2049', titulo: 'Intento de hurto', placa: 'ABC12D', autor: 'Andrés Mora', barrio: 'Teusaquillo', hora: '3:20 p. m.', vehiculo: TipoVehiculo.moto, evidencia: Evidencia.sinFotos, nota: 'Sin evidencia adjunta'),
    ReporteModeracion(id: 'AV-2047', titulo: 'Hurto de autopartes', placa: 'PRT908', autor: 'Camila Pardo', barrio: 'Chapinero', hora: '1:05 p. m.', vehiculo: TipoVehiculo.auto, evidencia: Evidencia.conFotos, nota: '1 foto · ubicación verificada'),
    ReporteModeracion(id: 'AV-2046', titulo: 'Hurto de moto', placa: 'QWE45F', autor: 'Usuario anónimo', barrio: 'Kennedy', hora: '11:40 a. m.', vehiculo: TipoVehiculo.moto, evidencia: Evidencia.sinFotos, nota: 'Sin evidencia adjunta'),
  ]),
);

final configSistemaProvider = NotifierProvider<_ConfigSistema, ConfigSistema>(_ConfigSistema.new);

class _ConfigSistema extends Notifier<ConfigSistema> {
  @override
  ConfigSistema build() => const ConfigSistema();
  void cambiar(ConfigSistema c) => state = c;
}

const registrosActividad = [
  RegistroActividad('Laura Gómez creó el reporte AV-2051', '6:15 p. m.', 'Reportes', Color(0xFF3B82F6)),
  RegistroActividad('Sgto. Castro solicitó acceso', '6:02 p. m.', 'Usuarios', AppColors.amarillo),
  RegistroActividad('KLM234 marcado como posible falso', '5:41 p. m.', 'Moderación', AppColors.rojo),
  RegistroActividad('Copia de seguridad completada', '5:00 p. m.', 'Sistema', AppColors.verdeExito),
  RegistroActividad('Error 502 en el servicio de mapas', '4:37 p. m.', 'Errores', AppColors.rojo),
  RegistroActividad('Dev User cambió la configuración', '3:15 p. m.', 'Sistema', Color(0xFF8B7FE0)),
  RegistroActividad('Pt. Ramírez cerró el caso AV-2040', '2:50 p. m.', 'Casos', AppColors.verdeExito),
  RegistroActividad('Nuevo usuario registrado', '2:12 p. m.', 'Usuarios', Color(0xFF3B82F6)),
];

const caisAdmin = [
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

final enviosMasivosProvider = NotifierProvider<_ListaMemoria<EnvioMasivo>, List<EnvioMasivo>>(
  () => _ListaMemoria(const [
    EnvioMasivo('Zona de riesgo · Bosa', 'Hoy 5:00 p. m. · 12.300 personas', 64),
    EnvioMasivo('Hurtos en Chapinero', 'Ayer · 8.900 personas', 58),
    EnvioMasivo('Mantenimiento programado', '10 oct. · Todos personas', 41),
    EnvioMasivo('Alerta Kennedy', '8 oct. · 15.100 personas', 71),
  ]),
);

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

/// Matriz de permisos: permiso → roles que lo tienen.
final permisosProvider = NotifierProvider<_Permisos, Map<String, Set<Rol>>>(_Permisos.new);

class _Permisos extends Notifier<Map<String, Set<Rol>>> {
  @override
  Map<String, Set<Rol>> build() => {
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

  void alternar(String permiso, Rol rol) {
    final actual = {...state[permiso] ?? <Rol>{}};
    actual.contains(rol) ? actual.remove(rol) : actual.add(rol);
    state = {...state, permiso: actual};
  }
}
