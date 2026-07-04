// Uygulama teması: açık (default) + koyu. Serin sis zemin + mürekkep +
// iris (çivit) vurgu ve menekşe ikincil renk. Modern iOS diline yakın.
import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';

/// Marka renkleri — ColorScheme dışında doğrudan kullanılmaz.
abstract final class _BrandColors {
  // Açık tema: serin sis zemin + koyu mürekkep + iris vurgu.
  static const Color mist = Color(0xFFF4F4F9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF1B1B24);
  static const Color iris = Color(0xFF5457D6);
  static const Color violet = Color(0xFF7E6BD9);
  static const Color outlineLight = Color(0xFFDEDEE9);

  // Koyu tema: gece zemini, aynı vurgular parlatılmış.
  static const Color night = Color(0xFF121217);
  static const Color surfaceDark = Color(0xFF1B1B22);
  static const Color fog = Color(0xFFECECF4);
  static const Color irisBright = Color(0xFF8A8CFF);
  static const Color violetBright = Color(0xFFA995F0);
  static const Color outlineDark = Color(0xFF34343F);
}

/// Açık ve koyu [ThemeData] üreticisi.
abstract final class AppTheme {
  static ThemeData get light => _build(_lightScheme);

  static ThemeData get dark => _build(_darkScheme);

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: _BrandColors.iris,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFE3E3FB),
    onPrimaryContainer: Color(0xFF24247A),
    secondary: _BrandColors.violet,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFECE7FB),
    onSecondaryContainer: Color(0xFF2E2075),
    error: Color(0xFFB3261E),
    onError: Colors.white,
    surface: _BrandColors.surfaceLight,
    onSurface: _BrandColors.ink,
    surfaceContainerHighest: Color(0xFFEBEBF4),
    surfaceContainer: _BrandColors.mist,
    onSurfaceVariant: Color(0xFF6E6E80),
    outline: _BrandColors.outlineLight,
    outlineVariant: Color(0xFFEAEAF2),
    inverseSurface: _BrandColors.ink,
    onInverseSurface: _BrandColors.mist,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: _BrandColors.irisBright,
    onPrimary: Color(0xFF1A1B4B),
    primaryContainer: Color(0xFF34367F),
    onPrimaryContainer: Color(0xFFE1E1FF),
    secondary: _BrandColors.violetBright,
    onSecondary: Color(0xFF251A55),
    secondaryContainer: Color(0xFF3C2F79),
    onSecondaryContainer: Color(0xFFEAE3FF),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    surface: _BrandColors.surfaceDark,
    onSurface: _BrandColors.fog,
    surfaceContainerHighest: Color(0xFF26262F),
    surfaceContainer: _BrandColors.night,
    onSurfaceVariant: Color(0xFF9A9AAB),
    outline: _BrandColors.outlineDark,
    outlineVariant: Color(0xFF28282F),
    inverseSurface: _BrandColors.fog,
    onInverseSurface: _BrandColors.night,
  );

  static ThemeData _build(ColorScheme scheme) {
    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surfaceContainer,
    );

    return base.copyWith(
      // iOS'ta San Francisco tipografisini kullan (Material default Roboto'yu ezer).
      textTheme: Typography.material2021(platform: TargetPlatform.iOS)
          .englishLike
          .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
      // Not: push geçişleri iOS'ta framework default'u olan Cupertino
      // (sağdan kayma + interaktif geri swipe) ile gelir; ek ayar gerekmez.
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surfaceContainer,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
