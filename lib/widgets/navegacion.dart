import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../features/auth/domain/usuario.dart';

class DestinoNav {
  const DestinoNav(this.etiqueta, this.icono, this.ruta, {this.iconoActivo, this.etiquetaCorta});
  final String etiqueta;
  final IconData icono;
  final IconData? iconoActivo;
  final String ruta;

  /// Etiqueta para el riel de tablet (11 px) cuando la normal es larga.
  final String? etiquetaCorta;
}

/// Destinos del HUD inferior (celular). El SOS va aparte, al centro.
List<DestinoNav> destinosHud(Rol rol) => [
      DestinoNav('Inicio', TablerIcons.home, rol.rutaInicio, iconoActivo: TablerIcons.home_filled),
      const DestinoNav('Mapa', TablerIcons.map_pin, '/mapa', iconoActivo: TablerIcons.map_pin_filled),
      const DestinoNav('Alertas', TablerIcons.bell, '/alertas', iconoActivo: TablerIcons.bell_filled),
      const DestinoNav('Perfil', TablerIcons.user, '/perfil', iconoActivo: TablerIcons.user_filled),
    ];

/// Destinos de la barra lateral (PC) y del riel (tablet), según el rol.
List<DestinoNav> destinosLaterales(Rol rol) => switch (rol) {
      Rol.ciudadano => const [
          DestinoNav('Inicio', TablerIcons.home, '/inicio'),
          DestinoNav('Mapa', TablerIcons.map, '/mapa'),
          DestinoNav('Reportar', TablerIcons.urgent, '/reporte'),
          DestinoNav('Alertas', TablerIcons.bell, '/alertas'),
          DestinoNav('Mis reportes', TablerIcons.file_text, '/mis-reportes'),
          DestinoNav('Perfil', TablerIcons.user, '/perfil'),
        ],
      Rol.dev => const [
          DestinoNav('Panel', TablerIcons.home, '/dev'),
          DestinoNav('Usuarios', TablerIcons.users, '/dev/usuarios'),
          DestinoNav('Moderación', TablerIcons.flag, '/dev/moderacion'),
          DestinoNav('Autoridades', TablerIcons.user_shield, '/dev/autoridades'),
          DestinoNav('Zonas de riesgo', TablerIcons.flame, '/dev/zonas', etiquetaCorta: 'Zonas'),
          DestinoNav('Notificaciones', TablerIcons.send, '/dev/notificaciones', etiquetaCorta: 'Avisos'),
          DestinoNav('CAI y puntos', TablerIcons.building, '/dev/cai', etiquetaCorta: 'CAI'),
          DestinoNav('Analítica', TablerIcons.chart_bar, '/dev/analitica'),
          DestinoNav('Registros', TablerIcons.terminal_2, '/dev/registros'),
          DestinoNav('Estado del servicio', TablerIcons.activity, '/dev/estado', etiquetaCorta: 'Estado'),
          DestinoNav('Roles y permisos', TablerIcons.key, '/dev/roles', etiquetaCorta: 'Roles'),
          DestinoNav('Exportar datos', TablerIcons.download, '/dev/exportar', etiquetaCorta: 'Exportar'),
          DestinoNav('Sistema', TablerIcons.settings, '/dev/sistema'),
        ],
      Rol.autoridad => const [
          DestinoNav('Panel', TablerIcons.layout_dashboard, '/autoridad'),
          DestinoNav('Mapa de incidencias', TablerIcons.map, '/autoridad/mapa', etiquetaCorta: 'Mapa'),
          DestinoNav('Casos', TablerIcons.layout_kanban, '/autoridad/casos'),
          DestinoNav('Consulta de placas', TablerIcons.id, '/autoridad/placas', etiquetaCorta: 'Placas'),
          DestinoNav('Actuaciones', TablerIcons.gavel, '/autoridad/actuaciones'),
          DestinoNav('Reportes oficiales', TablerIcons.file_certificate, '/autoridad/reportes', etiquetaCorta: 'Reportes'),
        ],
    };

/// Índice del destino activo según la ruta actual (o -1). Gana la coincidencia más larga.
int indiceActivo(List<DestinoNav> destinos, String ubicacion) {
  var mejor = -1;
  var largo = -1;
  for (var i = 0; i < destinos.length; i++) {
    final r = destinos[i].ruta;
    if ((ubicacion == r || ubicacion.startsWith('$r/')) && r.length > largo) {
      mejor = i;
      largo = r.length;
    }
  }
  return mejor;
}
