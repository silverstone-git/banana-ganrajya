import 'package:flutter/material.dart';
import 'app_palette.dart';

/// Light theme palette for Banana Ganrajya.
///
/// Features:
/// - Primary accent: Dark Green (#0A3B2A)
/// - Secondary accent: Yellow (#E6C925)
class LightPalette extends AppPalette {
  const LightPalette();

  @override
  Brightness get brightness => Brightness.light;

  // Primary Accent: Dark Green (#0A3B2A)
  @override
  Color get primary => const Color(0xFF0A3B2A);

  @override
  Color get onPrimary => const Color(0xFFFFFFFF);

  @override
  Color get primaryContainer => const Color(0xFFE0EFE8);

  @override
  Color get onPrimaryContainer => const Color(0xFF032117);

  @override
  Color get inversePrimary => const Color(0xFF8FD7B8);

  @override
  Color get primaryFixed => const Color(0xFFE0EFE8);

  @override
  Color get primaryFixedDim => const Color(0xFF8FD7B8);

  @override
  Color get onPrimaryFixed => const Color(0xFF032117);

  @override
  Color get onPrimaryFixedVariant => const Color(0xFF0A3B2A);

  @override
  Color get surfaceTint => const Color(0xFF0A3B2A);

  // Secondary Accent: Yellow (#E6C925)
  @override
  Color get secondary => const Color(0xFFE6C925);

  @override
  Color get onSecondary => const Color(0xFF1A1C1C);

  @override
  Color get secondaryContainer => const Color(0xFFFFF6C5);

  @override
  Color get onSecondaryContainer => const Color(0xFF423800);

  @override
  Color get secondaryFixed => const Color(0xFFFFF6C5);

  @override
  Color get secondaryFixedDim => const Color(0xFFE6C925);

  @override
  Color get onSecondaryFixed => const Color(0xFF1A1C1C);

  @override
  Color get onSecondaryFixedVariant => const Color(0xFF594B00);

  // Tertiary: Warm Gold/Olive
  @override
  Color get tertiary => const Color(0xFF755800);

  @override
  Color get onTertiary => const Color(0xFFFFFFFF);

  @override
  Color get tertiaryContainer => const Color(0xFF946F00);

  @override
  Color get onTertiaryContainer => const Color(0xFFFFFCFF);

  @override
  Color get tertiaryFixed => const Color(0xFFFFDF9C);

  @override
  Color get tertiaryFixedDim => const Color(0xFFF2BF41);

  @override
  Color get onTertiaryFixed => const Color(0xFF251A00);

  @override
  Color get onTertiaryFixedVariant => const Color(0xFF5B4300);

  // Surfaces & Containers
  @override
  Color get surface => const Color(0xFFF9F9F9);

  @override
  Color get surfaceDim => const Color(0xFFDADADA);

  @override
  Color get surfaceBright => const Color(0xFFF9F9F9);

  @override
  Color get surfaceContainerLowest => const Color(0xFFFFFFFF);

  @override
  Color get surfaceContainerLow => const Color(0xFFF3F3F3);

  @override
  Color get surfaceContainer => const Color(0xFFEEEEEE);

  @override
  Color get surfaceContainerHigh => const Color(0xFFE8E8E8);

  @override
  Color get surfaceContainerHighest => const Color(0xFFE2E2E2);

  @override
  Color get surfaceVariant => const Color(0xFFE2E2E2);

  @override
  Color get onSurface => const Color(0xFF1A1C1C);

  @override
  Color get onSurfaceVariant => const Color(0xFF424944);

  @override
  Color get inverseSurface => const Color(0xFF2F3131);

  @override
  Color get inverseOnSurface => const Color(0xFFF1F1F1);

  // Outline
  @override
  Color get outline => const Color(0xFF707973);

  @override
  Color get outlineVariant => const Color(0xFFC2C8C3);

  // Error
  @override
  Color get error => const Color(0xFFBA1A1A);

  @override
  Color get onError => const Color(0xFFFFFFFF);

  @override
  Color get errorContainer => const Color(0xFFFFDAD6);

  @override
  Color get onErrorContainer => const Color(0xFF93000A);

  // Background
  @override
  Color get background => const Color(0xFFF9F9F9);

  @override
  Color get onBackground => const Color(0xFF1A1C1C);
}
