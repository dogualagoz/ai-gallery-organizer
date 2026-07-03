// Uygulama teması: açık (default) + koyu. Sıcak kağıt/mürekkep paleti,
// tek canlı vurgu rengi (persimmon). Stash'ten bilinçli olarak farklı bir dil.
import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';

/// Marka renkleri — ColorScheme dışında doğrudan kullanılmaz.
abstract final class _BrandColors {
  // Açık tema: sıcak kağıt zemin + koyu mürekkep + persimmon vurgu.
  static const Color paper = Color(0xFFFAF6F0);
  static const Color surfaceLight = Color(0xFFFFFDFA);
  static const Color ink = Color(0xFF1F1B16);
  static const Color persimmon = Color(0xFFD9482B);
  static const Color sage = Color(0xFF6B7F5E);
  static const Color outlineLight = Color(0xFFE3DCD2);

  // Koyu tema: sıcak kömür zemin, aynı vurgu biraz parlatılmış.
  static const Color charcoal = Color(0xFF171410);
  static const Color surfaceDark = Color(0xFF221E19);
  static const Color cream = Color(0xFFF2EDE5);
  static const Color persimmonBright = Color(0xFFFF6B4A);
  static const Color sageBright = Color(0xFF93A886);
  static const Color outlineDark = Color(0xFF3A342C);
}

/// Açık ve koyu [ThemeData] üreticisi.
abstract final class AppTheme {
  static ThemeData get light => _build(_lightScheme);

  static ThemeData get dark => _build(_darkScheme);

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: _BrandColors.persimmon,
    onPrimary: Colors.white,
    secondary: _BrandColors.sage,
    onSecondary: Colors.white,
    error: Color(0xFFB3261E),
    onError: Colors.white,
    surface: _BrandColors.surfaceLight,
    onSurface: _BrandColors.ink,
    surfaceContainerHighest: Color(0xFFF0EAE1),
    surfaceContainer: _BrandColors.paper,
    onSurfaceVariant: Color(0xFF6F675C),
    outline: _BrandColors.outlineLight,
    outlineVariant: Color(0xFFEFE9DF),
    inverseSurface: _BrandColors.ink,
    onInverseSurface: _BrandColors.paper,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: _BrandColors.persimmonBright,
    onPrimary: Color(0xFF2B120A),
    secondary: _BrandColors.sageBright,
    onSecondary: Color(0xFF17200F),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    surface: _BrandColors.surfaceDark,
    onSurface: _BrandColors.cream,
    surfaceContainerHighest: Color(0xFF2E2922),
    surfaceContainer: _BrandColors.charcoal,
    onSurfaceVariant: Color(0xFFA89E90),
    outline: _BrandColors.outlineDark,
    outlineVariant: Color(0xFF2A251E),
    inverseSurface: _BrandColors.cream,
    onInverseSurface: _BrandColors.charcoal,
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
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surfaceContainer,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.12),
        elevation: 0,
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
