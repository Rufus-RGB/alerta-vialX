import 'package:flutter/material.dart';

import '../features/auth/domain/usuario.dart';

class DestinoNav {
  const DestinoNav(this.etiqueta, this.icono, this.ruta);
  final String etiqueta;
  final IconData icono;
  final String ruta;
}

/// Destinos del HUD inferior (móvil). El SOS se dibuja aparte, al centro.
List<DestinoNav> destinosHud(Rol rol) => [
      DestinoNav('Inicio', Icons.home_rounded, rol.rutaInicio),
      const DestinoNav('Mapa', Icons.map_rounded, '/mapa'),
      const DestinoNav('Alertas', Icons.notifications_rounded, '/alertas'),
      const DestinoNav('Perfil', Icons.person_rounded, '/perfil'),
    ];

/// Destinos de la barra lateral (escritorio), según el rol.
List<DestinoNav> destinosLaterales(Rol rol) => switch (rol) {
      Rol.ciudadano => const [
          DestinoNav('Inicio', Icons.home_rounded, '/inicio'),
          DestinoNav('Mapa', Icons.map_rounded, '/mapa'),
          DestinoNav('Reportar', Icons.add_location_alt_rounded, '/reporte'),
          DestinoNav('Alertas', Icons.notifications_rounded, '/alertas'),
          DestinoNav('Perfil', Icons.person_rounded, '/perfil'),
        ],
      Rol.dev => const [
          DestinoNav('Panel DEV', Icons.code_rounded, '/dev'),
          DestinoNav('Mapa', Icons.map_rounded, '/mapa'),
          DestinoNav('Alertas', Icons.notifications_rounded, '/alertas'),
          DestinoNav('Perfil', Icons.person_rounded, '/perfil'),
        ],
      Rol.autoridad => const [
          DestinoNav('Panel', Icons.local_police_rounded, '/autoridad'),
          DestinoNav('Mapa', Icons.map_rounded, '/mapa'),
          DestinoNav('Alertas', Icons.notifications_rounded, '/alertas'),
          DestinoNav('Perfil', Icons.person_rounded, '/perfil'),
        ],
    };

/// Índice del destino activo según la ruta actual (o -1).
int indiceActivo(List<DestinoNav> destinos, String ubicacion) =>
    destinos.indexWhere((d) => ubicacion == d.ruta || ubicacion.startsWith('${d.ruta}/'));
