import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import 'paleta.dart';

/// Atajos tipográficos del diseño: "M PLUS Rounded 1c" (títulos/botones)
/// y "Noto Sans" (textos y datos).
abstract final class Txt {
  static TextStyle r(double size, {Color? color, FontWeight weight = FontWeight.w700, double? height}) =>
      GoogleFonts.mPlusRounded1c(fontSize: size, fontWeight: weight, color: color, height: height);

  static TextStyle n(double size, {Color? color, FontWeight weight = FontWeight.w500, double? height, double? spacing}) =>
      GoogleFonts.notoSans(fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: spacing);

  static TextStyle nb(double size, {Color? color, double? height}) => n(size, color: color, weight: FontWeight.w700, height: height);

  /// Titulares grandes ("Hola, User", "Tu ciudad más segura").
  static TextStyle display(double size, {Color? color}) =>
      GoogleFonts.notoSans(fontSize: size, fontWeight: FontWeight.w800, color: color, letterSpacing: -size * 0.01, height: 1.15);
}

/// Tema claro y oscuro.
abstract final class AppTheme {
  static ThemeData get claro => _build(Brightness.light);
  static ThemeData get oscuro => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final oscuro = brightness == Brightness.dark;
    final p = oscuro ? Paleta.oscuro : Paleta.claro;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.rojo,
      onPrimary: Colors.white,
      secondary: AppColors.amarillo,
      onSecondary: Colors.black,
      tertiary: AppColors.azulAutoridad,
      onTertiary: Colors.white,
      error: AppColors.rojo,
      onError: Colors.white,
      surface: p.tarjeta,
      onSurface: p.texto,
      surfaceContainerLowest: p.fondo,
      surfaceContainerLow: p.fondo,
      surfaceContainer: p.tarjeta,
      surfaceContainerHigh: p.chip,
      surfaceContainerHighest: p.chip,
      onSurfaceVariant: p.textoSecundario,
      outline: p.inputBorde,
      outlineVariant: p.borde,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: brightness);
    final t = base.textTheme.apply(bodyColor: p.texto, displayColor: p.texto);
    // Se usan los helpers de TextStyle: los de TextTheme de google_fonts 9 devuelven
    // el TextTheme de package:material_ui, incompatible con el de Flutter.
    TextStyle? noto(TextStyle? s) => s == null ? null : GoogleFonts.notoSans(textStyle: s);
    TextStyle? redondeada(TextStyle? s) =>
        s == null ? null : GoogleFonts.mPlusRounded1c(textStyle: s, fontWeight: FontWeight.w700);

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
    final estiloBoton = Txt.r(18);
    final forma = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    OutlineInputBorder borde(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c, width: w));

    return base.copyWith(
      scaffoldBackgroundColor: p.fondo,
      textTheme: textTheme,
      extensions: [p],
      appBarTheme: AppBarTheme(
        backgroundColor: p.fondo,
        foregroundColor: p.texto,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: Txt.r(22, color: p.texto),
      ),
      cardTheme: CardThemeData(
        color: p.tarjeta,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: p.borde)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(0, 52), textStyle: estiloBoton, shape: forma),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          textStyle: estiloBoton,
          foregroundColor: p.texto,
          side: BorderSide(color: p.inputBorde, width: 1.5),
          shape: forma,
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(textStyle: Txt.nb(14))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.inputFondo,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        hintStyle: Txt.n(14, color: p.placeholder),
        prefixIconColor: p.textoSecundario,
        suffixIconColor: p.textoSecundario,
        border: borde(p.inputBorde),
        enabledBorder: borde(p.inputBorde),
        focusedBorder: borde(AppColors.amarillo, 2),
        errorBorder: borde(AppColors.rojo),
        focusedErrorBorder: borde(AppColors.rojo, 2),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.verdeExito : p.chip),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.amarillo : Colors.transparent),
        checkColor: const WidgetStatePropertyAll(Colors.black),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide(color: p.inputBorde, width: 1.5),
      ),
      chipTheme: base.chipTheme.copyWith(labelStyle: Txt.r(12), shape: const StadiumBorder()),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.tarjeta,
        dragHandleColor: const Color(0xFFD0D4D8),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      dialogTheme: DialogThemeData(backgroundColor: p.tarjeta),
      drawerTheme: DrawerThemeData(
        backgroundColor: p.tarjeta,
        width: 320,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(24))),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      dividerTheme: DividerThemeData(color: p.divisor, space: 1, thickness: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.amarillo),
    );
  }
}
