// Uygulama teması: iOS sistem zeminleri + SF tipografi, iris yalnız aksan rengi.
// Açık (default) + koyu; iOS semantik renkleri ColorScheme rollerine eşlenir.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';
import 'app_typography.dart';

/// Ham renk değerleri — ColorScheme dışında doğrudan kullanılmaz. iOS sistem
/// renkleri HIG değerleridir; marka yalnız iris/menekşe aksanında yaşar.
abstract final class _Palette {
  // Marka aksanı.
  static const Color iris = Color(0xFF5457D6);
  static const Color irisBright = Color(0xFF8A8CFF);
  static const Color violet = Color(0xFF7E6BD9);
  static const Color violetBright = Color(0xFFA995F0);

  // iOS açık: systemGroupedBackground / secondarySystemGroupedBackground.
  static const Color groupedLight = Color(0xFFF2F2F7);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color labelLight = Color(0xFF000000);
  // secondaryLabel'ın erişilebilir (≥4.5:1) opak karşılığı (systemGray, AX).
  static const Color secondaryLabelLight = Color(0xFF6C6C70);
  static const Color systemGray3Light = Color(0xFFC7C7CC);
  static const Color systemGray5Light = Color(0xFFE5E5EA);
  // Dolgular (tertiary/secondary systemFill'in beyaz üstü opak karşılığı).
  static const Color fillLight = Color(0xFFEFEFF0);
  static const Color fillStrongLight = Color(0xFFE9E9EB);
  // systemRed: beyaz üstünde ~3.6:1 — HIG yıkıcı buton standardı; yalnız
  // büyük/kalın metinde (17pt semibold, AA büyük metin 3:1) kullanılır.
  static const Color redLight = Color(0xFFFF3B30);

  // iOS koyu: saf siyah zemin, kartlar #1C1C1E, yükseltilmiş #2C2C2E.
  static const Color groupedDark = Color(0xFF000000);
  static const Color cardDark = Color(0xFF1C1C1E);
  static const Color elevatedDark = Color(0xFF2C2C2E);
  static const Color fillStrongDark = Color(0xFF3A3A3C);
  static const Color labelDark = Color(0xFFFFFFFF);
  static const Color secondaryLabelDark = Color(0xFF98989E);
  static const Color systemGray3Dark = Color(0xFF48484A);
  // opaqueSeparator: yükseltilmiş (#2C2C2E) dolgudan ayrışsın diye bir ton açık.
  static const Color separatorDark = Color(0xFF38383A);
  static const Color redDark = Color(0xFFFF453A);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);
}

/// Açık ve koyu [ThemeData] üreticisi.
///
/// iOS semantik rol → ColorScheme eşlemesi (ekranlar yalnız colorScheme'i
/// kullanır):
/// - systemGroupedBackground → `surfaceContainer` (scaffold zemini)
/// - secondarySystemGroupedBackground (kart) → `surface`
/// - tertiary grouped / dolgular → `surfaceContainerHigh(est)`
/// - label / secondaryLabel → `onSurface` / `onSurfaceVariant`
/// - separator → `outlineVariant`, güçlü kenarlık → `outline`
/// - systemRed (yıkıcı) → `error`
abstract final class AppTheme {
  static ThemeData get light => _build(_lightScheme);

  static ThemeData get dark => _build(_darkScheme);

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: _Palette.iris,
    onPrimary: _Palette.white,
    primaryContainer: Color(0xFFE6E6FB),
    onPrimaryContainer: Color(0xFF24247A),
    secondary: _Palette.violet,
    onSecondary: _Palette.white,
    secondaryContainer: Color(0xFFECE7FB),
    onSecondaryContainer: Color(0xFF2E2075),
    tertiary: _Palette.violet,
    onTertiary: _Palette.white,
    tertiaryContainer: Color(0xFFE9E3FB),
    onTertiaryContainer: Color(0xFF2E2075),
    error: _Palette.redLight,
    onError: _Palette.white,
    errorContainer: Color(0xFFFFE5E3),
    onErrorContainer: Color(0xFF8A1C14),
    surface: _Palette.cardLight,
    onSurface: _Palette.labelLight,
    onSurfaceVariant: _Palette.secondaryLabelLight,
    surfaceContainerLowest: _Palette.cardLight,
    surfaceContainerLow: _Palette.groupedLight,
    surfaceContainer: _Palette.groupedLight,
    surfaceContainerHigh: _Palette.fillLight,
    surfaceContainerHighest: _Palette.fillStrongLight,
    outline: _Palette.systemGray3Light,
    outlineVariant: _Palette.systemGray5Light,
    inverseSurface: _Palette.labelLight,
    onInverseSurface: _Palette.groupedLight,
    inversePrimary: _Palette.irisBright,
    shadow: _Palette.black,
    scrim: _Palette.black,
    surfaceTint: _Palette.transparent,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: _Palette.irisBright,
    onPrimary: Color(0xFF1A1B4B),
    primaryContainer: Color(0xFF2E3070),
    onPrimaryContainer: Color(0xFFE1E1FF),
    secondary: _Palette.violetBright,
    onSecondary: Color(0xFF251A55),
    secondaryContainer: Color(0xFF3C2F79),
    onSecondaryContainer: Color(0xFFEAE3FF),
    tertiary: _Palette.violetBright,
    onTertiary: Color(0xFF251A55),
    tertiaryContainer: Color(0xFF3C2F79),
    onTertiaryContainer: Color(0xFFEAE3FF),
    error: _Palette.redDark,
    onError: _Palette.white,
    errorContainer: Color(0xFF4A1512),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: _Palette.cardDark,
    onSurface: _Palette.labelDark,
    onSurfaceVariant: _Palette.secondaryLabelDark,
    surfaceContainerLowest: _Palette.groupedDark,
    surfaceContainerLow: _Palette.groupedDark,
    surfaceContainer: _Palette.groupedDark,
    surfaceContainerHigh: _Palette.elevatedDark,
    surfaceContainerHighest: _Palette.fillStrongDark,
    outline: _Palette.systemGray3Dark,
    outlineVariant: _Palette.separatorDark,
    inverseSurface: _Palette.labelDark,
    onInverseSurface: _Palette.cardDark,
    inversePrimary: _Palette.iris,
    shadow: _Palette.black,
    scrim: _Palette.black,
    surfaceTint: _Palette.transparent,
  );

  static ThemeData _build(ColorScheme scheme) {
    final TextTheme textTheme = AppTypography.textTheme(scheme.onSurface);
    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surfaceContainer,
      // iOS'ta dokunma geri bildirimi ripple değil; basış ölçeği/opaklığıdır.
      splashFactory: NoSplash.splashFactory,
      splashColor: _Palette.transparent,
      highlightColor: _Palette.transparent,
    );

    return base.copyWith(
      // Cupertino widget'ları aynı aksan ve zemini kullansın.
      cupertinoOverrideTheme: NoDefaultCupertinoThemeData(
        primaryColor: scheme.primary,
        scaffoldBackgroundColor: scheme.surfaceContainer,
      ),
      // Not: push geçişleri iOS'ta framework default'u olan Cupertino
      // (sağdan kayma + interaktif geri swipe) ile gelir; ek ayar gerekmez.
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surfaceContainer,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        // iOS inline gezinme başlığı ortalı ve Headline (17 semibold) olur.
        centerTitle: true,
        titleTextStyle: textTheme.titleMedium,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outline),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: textTheme.bodyLarge),
      ),
      // Segment ve çip etiketleri 17pt buton stilinde taşar; Subheadline.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(textTheme.titleSmall),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        labelStyle: AppTypography.subheadline,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      // M3 varsayılanı surfaceContainerLow/High; koyuda zeminle aynı siyah
      // olurdu. iOS'ta sheet ve uyarılar kart tonunda (secondary grouped).
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        modalBackgroundColor: scheme.surface,
      ),
      dialogTheme: DialogThemeData(backgroundColor: scheme.surface),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }
}
