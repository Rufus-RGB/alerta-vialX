import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Colores semánticos que cambian entre modo claro y oscuro (según Figma).
@immutable
class Paleta extends ThemeExtension<Paleta> {
  const Paleta({
    required this.fondo,
    required this.fondoPanel,
    required this.tarjeta,
    required this.borde,
    required this.divisor,
    required this.texto,
    required this.textoSecundario,
    required this.textoTenue,
    required this.inputBorde,
    required this.inputFondo,
    required this.placeholder,
    required this.hud,
    required this.hudInactivo,
    required this.numero,
    required this.chip,
    required this.suaveRojo,
    required this.suaveAmarillo,
    required this.suaveAzul,
    required this.suaveVerde,
    required this.suaveMorado,
    required this.textoAlto,
    required this.textoMedio,
    required this.enlace,
    required this.botonNegro,
    required this.sombra,
  });

  final Color fondo;
  final Color fondoPanel; // fondo del área de contenido en tablet/PC
  final Color tarjeta;
  final Color borde;
  final Color divisor;
  final Color texto;
  final Color textoSecundario;
  final Color textoTenue;
  final Color inputBorde;
  final Color inputFondo;
  final Color placeholder;
  final Color hud;
  final Color hudInactivo;
  final Color numero;
  final Color chip;
  final Color suaveRojo;
  final Color suaveAmarillo;
  final Color suaveAzul;
  final Color suaveVerde;
  final Color suaveMorado;
  final Color textoAlto;
  final Color textoMedio;
  final Color enlace;
  final Color botonNegro;
  final Color sombra;

  static const claro = Paleta(
    fondo: Colors.white,
    fondoPanel: AppColors.fondoClaro,
    tarjeta: Colors.white,
    borde: Color(0xFFE6E6E6),
    divisor: Color(0xFFEEEEEE),
    texto: Colors.black,
    textoSecundario: AppColors.grisTexto,
    textoTenue: Color(0xFF898989),
    inputBorde: Color(0xFF555555),
    inputFondo: Colors.white,
    placeholder: Color(0xFF9A9A9A),
    hud: Colors.white,
    hudInactivo: Color(0xFF555B61),
    numero: AppColors.negro,
    chip: Color(0xFFEEF0F2),
    suaveRojo: Color(0xFFFFE1E1),
    suaveAmarillo: Color(0xFFFFF1C2),
    suaveAzul: Color(0xFFE6F1FB),
    suaveVerde: Color(0xFFDDF3EA),
    suaveMorado: Color(0xFFEDEBFA),
    textoAlto: Color(0xFFE5262B),
    textoMedio: Color(0xFFB88600),
    enlace: AppColors.azulEnlace,
    botonNegro: AppColors.negro,
    sombra: Color(0x14000000),
  );

  static const oscuro = Paleta(
    fondo: AppColors.fondoOscuro,
    fondoPanel: AppColors.fondoOscuro,
    tarjeta: AppColors.tarjetaOscura,
    borde: AppColors.bordeOscuro,
    divisor: AppColors.bordeOscuro,
    texto: Colors.white,
    textoSecundario: AppColors.grisTextoOscuro,
    textoTenue: Color(0xFF898989),
    inputBorde: Color(0xFF3A4752),
    inputFondo: Color(0xFF0F1419),
    placeholder: Color(0xFF7D868D),
    hud: Color(0xFF161D22),
    hudInactivo: Color(0xFFB9BEC3),
    numero: Color(0xFF2A3238),
    chip: Color(0xFF1B252C),
    suaveRojo: Color(0xFF361115),
    suaveAmarillo: Color(0xFF3D3417),
    suaveAzul: Color(0xFF13283B),
    suaveVerde: Color(0xFF12302A),
    suaveMorado: Color(0xFF221F42),
    textoAlto: Color(0xFFFF4D52),
    textoMedio: AppColors.amarillo,
    enlace: AppColors.amarillo,
    botonNegro: Colors.black,
    sombra: Color(0x40000000),
  );

  @override
  Paleta copyWith() => this;

  @override
  Paleta lerp(ThemeExtension<Paleta>? other, double t) => t < 0.5 || other is! Paleta ? this : other;
}

extension PaletaContext on BuildContext {
  Paleta get paleta => Theme.of(this).extension<Paleta>()!;
  bool get esOscuro => Theme.of(this).brightness == Brightness.dark;
}
