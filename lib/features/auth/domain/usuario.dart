import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

enum Rol {
  ciudadano('Ciudadano', Icons.person_rounded, AppColors.rojo),
  dev('DEV', Icons.code_rounded, AppColors.moradoDev),
  autoridad('Autoridad', Icons.local_police_rounded, AppColors.azulAutoridad);

  const Rol(this.etiqueta, this.icono, this.color);
  final String etiqueta;
  final IconData icono;
  final Color color;

  /// Ruta de inicio propia de cada rol.
  String get rutaInicio => switch (this) {
        Rol.ciudadano => '/inicio',
        Rol.dev => '/dev',
        Rol.autoridad => '/autoridad',
      };
}

class Usuario {
  const Usuario({required this.id, required this.nombre, required this.correo, required this.rol});

  final String id;
  final String nombre;
  final String correo;
  final Rol rol;

  Map<String, String> toMap() => {'id': id, 'nombre': nombre, 'correo': correo, 'rol': rol.name};

  static Usuario? fromMap(Map<String, String> m) {
    final rol = Rol.values.where((r) => r.name == m['rol']).firstOrNull;
    if (rol == null || m['id'] == null) return null;
    return Usuario(id: m['id']!, nombre: m['nombre'] ?? '', correo: m['correo'] ?? '', rol: rol);
  }
}
