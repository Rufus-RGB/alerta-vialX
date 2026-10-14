import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _clave = 'theme_mode';

/// Modo de tema (sistema por defecto), persistido en SharedPreferences.
final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _cargar();
    return ThemeMode.system;
  }

  Future<void> _cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final guardado = prefs.getString(_clave);
    if (guardado == null) return;
    state = ThemeMode.values.firstWhere((m) => m.name == guardado, orElse: () => ThemeMode.system);
  }

  Future<void> cambiar(ThemeMode modo) async {
    state = modo;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, modo.name);
  }
}
