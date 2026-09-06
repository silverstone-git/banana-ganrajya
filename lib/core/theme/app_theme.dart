import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'palette/app_palette.dart';

/// Spacing scale from `DESIGN.md` ("base-8 scale", 20px outer margin).
class AppSpacing {
  AppSpacing._();

  static const marginMobile = 20.0;
  static const gutter = 16.0;
  static const stackSm = 8.0;
  static const stackMd = 24.0;
  static const stackLg = 40.0;
}

/// Corner radii — "Soft" shape language, 4px default, pill for premium chips.
class AppRadius {
  AppRadius._();

  static const sm = 2.0;
  static const md = 4.0;
  static const lg = 8.0;
  static const xl = 12.0;
  static const full = 999.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => buildTheme(AppColors.lightPalette);
  static ThemeData get dark => buildTheme(AppColors.darkPalette);

  static ThemeData buildTheme(AppPalette palette) {
    final colorScheme = ColorScheme(
      brightness: palette.brightness,
      primary: palette.primary,
      onPrimary: palette.onPrimary,
      primaryContainer: palette.primaryContainer,
      onPrimaryContainer: palette.onPrimaryContainer,
      secondary: palette.secondary,
      onSecondary: palette.onSecondary,
      secondaryContainer: palette.secondaryContainer,
      onSecondaryContainer: palette.onSecondaryContainer,
      tertiary: palette.tertiary,
      onTertiary: palette.onTertiary,
      tertiaryContainer: palette.tertiaryContainer,
      onTertiaryContainer: palette.onTertiaryContainer,
      error: palette.error,
      onError: palette.onError,
      errorContainer: palette.errorContainer,
      onErrorContainer: palette.onErrorContainer,
      surface: palette.surface,
      onSurface: palette.onSurface,
      surfaceContainerHighest: palette.surfaceContainerHighest,
      onSurfaceVariant: palette.onSurfaceVariant,
      outline: palette.outline,
      outlineVariant: palette.outlineVariant,
      inverseSurface: palette.inverseSurface,
      onInverseSurface: palette.inverseOnSurface,
      inversePrimary: palette.inversePrimary,
      surfaceTint: palette.surfaceTint,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      fontFamily: AppTypography.bodyMd.fontFamily,
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLg.copyWith(color: palette.onSurface),
        headlineLarge: AppTypography.headlineLg.copyWith(color: palette.onSurface),
        headlineMedium: AppTypography.headlineMd.copyWith(color: palette.onSurface),
        bodyLarge: AppTypography.bodyLg.copyWith(color: palette.onSurface),
        bodyMedium: AppTypography.bodyMd.copyWith(color: palette.onSurface),
        labelLarge: AppTypography.labelLg.copyWith(color: palette.onSurface),
        labelMedium: AppTypography.labelMd.copyWith(color: palette.onSurface),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.surface.withValues(alpha: 0.8),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        iconTheme: IconThemeData(color: palette.onSurfaceVariant),
      ),
      dividerColor: palette.surfaceContainer,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          textStyle: AppTypography.labelLg,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceContainerLowest,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: palette.primary, width: 1.5),
        ),
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }
}
