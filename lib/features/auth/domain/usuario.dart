import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../../core/constants/app_colors.dart';

/// Roles: ciudadano (amarillo), DEV (morado) y autoridad (azul), según el diseño.
enum Rol {
  ciudadano('Ciudadano', TablerIcons.user, AppColors.amarillo),
  dev('DEV', TablerIcons.code, AppColors.moradoDev),
  autoridad('Autoridad', TablerIcons.shield_check, AppColors.azulAutoridad);

  const Rol(this.etiqueta, this.icono, this.color);
  final String etiqueta;
  final IconData icono;
  final Color color;

  /// Color de texto sobre el color del rol.
  Color get sobreColor => this == Rol.ciudadano ? Colors.black : Colors.white;

  /// Ruta de inicio propia de cada rol.
  String get rutaInicio => switch (this) {
        Rol.ciudadano => '/inicio',
        Rol.dev => '/dev',
        Rol.autoridad => '/autoridad',
      };
}

class Usuario {
  const Usuario({required this.id, required this.nombre, required this.correo, required this.rol, this.celular = ''});

  final String id;
  final String nombre;
  final String correo;
  final Rol rol;
  final String celular;

  String get inicial => nombre.isEmpty ? '?' : nombre[0].toUpperCase();
  String get primerNombre => nombre.split(' ').first;

  Map<String, String> toMap() => {'id': id, 'nombre': nombre, 'correo': correo, 'rol': rol.name, 'celular': celular};

  static Usuario? fromMap(Map<String, String> m) {
    final rol = Rol.values.where((r) => r.name == m['rol']).firstOrNull;
    if (rol == null || m['id'] == null) return null;
    return Usuario(id: m['id']!, nombre: m['nombre'] ?? '', correo: m['correo'] ?? '', rol: rol, celular: m['celular'] ?? '');
  }
}
