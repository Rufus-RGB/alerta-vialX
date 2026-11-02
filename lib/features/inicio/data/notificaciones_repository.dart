import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/supabase/supabase_config.dart';

class Notificacion {
  const Notificacion({
    required this.titulo,
    required this.detalle,
    required this.cuando,
    required this.icono,
    required this.color,
    required this.grupo,
    this.leida = false,
    this.ruta,
  });

  final String titulo;
  final String detalle;
  final String cuando;
  final IconData icono;
  final Color color;
  final String grupo; // "Hoy" / "Esta semana"
  final bool leida;
  final String? ruta;
}

abstract interface class NotificacionesRepository {
  Future<List<Notificacion>> todas();
}

final notificacionesRepositoryProvider = Provider<NotificacionesRepository>(
  (ref) => SupabaseConfig.habilitado ? SupabaseNotificacionesRepository() : MockNotificacionesRepository(),
);
final notificacionesProvider = FutureProvider<List<Notificacion>>((ref) => ref.watch(notificacionesRepositoryProvider).todas());

class MockNotificacionesRepository implements NotificacionesRepository {
  @override
  Future<List<Notificacion>> todas() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return const [
      Notificacion(titulo: 'Hurto a 500 m de ti', detalle: 'Moto · Chapinero', cuando: '5 min', icono: TablerIcons.urgent, color: AppColors.rojo, grupo: 'Hoy', ruta: '/mapa?incidente=AV-2048'),
      Notificacion(titulo: 'Reporte AV-2048 en atención', detalle: 'La Policía va en camino', cuando: '20 min', icono: TablerIcons.check, color: AppColors.verdeExito, grupo: 'Hoy', ruta: '/mis-reportes'),
      Notificacion(titulo: 'Aumento de reportes en Kennedy', detalle: '+35 % esta semana', cuando: '2 h', icono: TablerIcons.trending_up, color: AppColors.amarillo, grupo: 'Hoy', leida: true, ruta: '/mapa?zona=Kennedy'),
      Notificacion(titulo: 'Nuevo CAI cerca de tu zona', detalle: 'CAI Fontanar · Suba', cuando: 'Lun', icono: TablerIcons.shield, color: AppColors.azulAutoridad, grupo: 'Esta semana', leida: true),
      Notificacion(titulo: 'Tu zona Trabajo subió a medio', detalle: 'Chapinero', cuando: 'Dom', icono: TablerIcons.heart, color: AppColors.rojo, grupo: 'Esta semana', leida: true),
      Notificacion(titulo: '¡Gracias por reportar!', detalle: 'Ayudaste a 120 conductores', cuando: 'Sáb', icono: TablerIcons.star, color: AppColors.amarillo, grupo: 'Esta semana', leida: true),
    ];
  }
}

/// Tabla `notificaciones` (propias y generales). El tipo define ícono y color.
class SupabaseNotificacionesRepository implements NotificacionesRepository {
  static const _estilos = <String, (IconData, Color)>{
    'hurto': (TablerIcons.urgent, AppColors.rojo),
    'atencion': (TablerIcons.check, AppColors.verdeExito),
    'aumento': (TablerIcons.trending_up, AppColors.amarillo),
    'cai': (TablerIcons.shield, AppColors.azulAutoridad),
    'zona': (TablerIcons.heart, AppColors.rojo),
    'gracias': (TablerIcons.star, AppColors.amarillo),
  };

  static String _cuando(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    if (d.inHours < 24) return '${d.inHours} h';
    const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return dias[t.weekday - 1];
  }

  @override
  Future<List<Notificacion>> todas() async {
    final filas = await supa.from('notificaciones').select().order('creado_en', ascending: false).limit(40);
    return [
      for (final f in filas)
        () {
          final creado = DateTime.parse(f['creado_en'] as String).toLocal();
          final (icono, color) = _estilos[f['tipo']] ?? _estilos['hurto']!;
          return Notificacion(
            titulo: f['titulo'] as String,
            detalle: f['detalle'] as String? ?? '',
            cuando: _cuando(creado),
            icono: icono,
            color: color,
            grupo: DateTime.now().difference(creado).inHours < 24 ? 'Hoy' : 'Esta semana',
            leida: f['leida'] as bool? ?? false,
            ruta: f['ruta'] as String?,
          );
        }(),
    ];
  }
}
