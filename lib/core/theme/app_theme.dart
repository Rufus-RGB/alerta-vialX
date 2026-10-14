import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Tema claro y oscuro. Títulos y botones con "M PLUS Rounded 1c",
/// textos con "Noto Sans".
abstract final class AppTheme {
  static ThemeData get claro => _build(Brightness.light);
  static ThemeData get oscuro => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final oscuro = brightness == Brightness.dark;
    final fondo = oscuro ? AppColors.fondoOscuro : AppColors.fondoClaro;
    final tarjeta = oscuro ? AppColors.tarjetaOscura : AppColors.tarjetaClara;
    final texto = oscuro ? Colors.white : AppColors.fondoOscuro;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.rojo,
      onPrimary: Colors.white,
      secondary: AppColors.amarillo,
      onSecondary: AppColors.fondoOscuro,
      tertiary: AppColors.azulAutoridad,
      onTertiary: Colors.white,
      error: AppColors.rojo,
      onError: Colors.white,
      surface: tarjeta,
      onSurface: texto,
      surfaceContainerLowest: fondo,
      surfaceContainerLow: fondo,
      surfaceContainer: tarjeta,
      surfaceContainerHigh: oscuro ? const Color(0xFF1A252C) : const Color(0xFFECEEF2),
      onSurfaceVariant: texto.withValues(alpha: 0.65),
      outline: texto.withValues(alpha: 0.18),
      outlineVariant: texto.withValues(alpha: 0.08),
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: brightness);
    // Se construye con los helpers de TextStyle: los de TextTheme de google_fonts 9
    // devuelven el TextTheme de package:material_ui, incompatible con el de Flutter.
    final t = base.textTheme.apply(bodyColor: texto, displayColor: texto);
    TextStyle? noto(TextStyle? s) => s == null ? null : GoogleFonts.notoSans(textStyle: s);
    TextStyle? redondeada(TextStyle? s) =>
        s == null ? null : GoogleFonts.mPlusRounded1c(textStyle: s, fontWeight: FontWeight.w800);

    final textTheme = TextTheme(
      displayLarge: redondeada(t.displayLarge),
      displayMedium: redondeada(t.displayMedium),
      displaySmall: redondeada(t.displaySmall),
      headlineLarge: redondeada(t.headlineLarge),
      headlineMedium: redondeada(t.headlineMedium),
      headlineSmall: redondeada(t.headlineSmall),
      titleLarge: redondeada(t.titleLarge),
      titleMedium: redondeada(t.titleMedium),
      titleSmall: redondeada(t.titleSmall),
      labelLarge: redondeada(t.labelLarge),
      bodyLarge: noto(t.bodyLarge),
      bodyMedium: noto(t.bodyMedium),
      bodySmall: noto(t.bodySmall),
      labelMedium: noto(t.labelMedium),
      labelSmall: noto(t.labelSmall),
    );
    final estiloBoton = GoogleFonts.mPlusRounded1c(fontWeight: FontWeight.w800, fontSize: 16);
    final forma = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

    return base.copyWith(
      scaffoldBackgroundColor: fondo,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: fondo,
        foregroundColor: texto,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: tarjeta,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          textStyle: estiloBoton,
          shape: forma,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          textStyle: estiloBoton,
          foregroundColor: texto,
          side: BorderSide(color: scheme.outline),
          shape: forma,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: estiloBoton.copyWith(fontSize: 14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tarjeta,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.rojo, width: 2),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        labelStyle: GoogleFonts.mPlusRounded1c(fontWeight: FontWeight.w700),
        shape: const StadiumBorder(),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }
}
