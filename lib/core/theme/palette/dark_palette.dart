import 'package:flutter/material.dart';
import 'app_palette.dart';

/// Dark theme palette for Banana Ganrajya.
///
/// Features (flipped accent roles for optimal contrast):
/// - Primary accent: Yellow (#FFE135)
/// - Secondary accent: Lighter Green (#16805B)
class DarkPalette extends AppPalette {
  const DarkPalette();

  @override
  Brightness get brightness => Brightness.dark;

  // Primary Accent: Yellow (#FFE135) - Flipped for vibrant dark mode contrast
  @override
  Color get primary => const Color(0xFFFFE135);

  @override
  Color get onPrimary => const Color(0xFF121313);

  @override
  Color get primaryContainer => const Color(0xFF3D3500);

  @override
  Color get onPrimaryContainer => const Color(0xFFFFF085);

  @override
  Color get inversePrimary => const Color(0xFF0A3B2A);

  @override
  Color get primaryFixed => const Color(0xFFFFF085);

  @override
  Color get primaryFixedDim => const Color(0xFFFFE135);

  @override
  Color get onPrimaryFixed => const Color(0xFF221B00);

  @override
  Color get onPrimaryFixedVariant => const Color(0xFF534600);

  @override
  Color get surfaceTint => const Color(0xFFFFE135);

  // Secondary Accent: Lighter Green (#16805B)
  @override
  Color get secondary => const Color(0xFF16805B);

  @override
  Color get onSecondary => const Color(0xFFFFFFFF);

  @override
  Color get secondaryContainer => const Color(0xFF07291D);

  @override
  Color get onSecondaryContainer => const Color(0xFFA3F2CD);

  @override
  Color get secondaryFixed => const Color(0xFFA3F2CD);

  @override
  Color get secondaryFixedDim => const Color(0xFF16805B);

  @override
  Color get onSecondaryFixed => const Color(0xFF002114);

  @override
  Color get onSecondaryFixedVariant => const Color(0xFF07291D);

  // Tertiary: Warm Gold
  @override
  Color get tertiary => const Color(0xFFF2BF41);

  @override
  Color get onTertiary => const Color(0xFF251A00);

  @override
  Color get tertiaryContainer => const Color(0xFF5B4300);

  @override
  Color get onTertiaryContainer => const Color(0xFFFFDF9C);

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
  Color get surface => const Color(0xFF121313);

  @override
  Color get surfaceDim => const Color(0xFF101010);

  @override
  Color get surfaceBright => const Color(0xFF1F2121);

  @override
  Color get surfaceContainerLowest => const Color(0xFF0F1010);

  @override
  Color get surfaceContainerLow => const Color(0xFF181A1A);

  @override
  Color get surfaceContainer => const Color(0xFF202222);

  @override
  Color get surfaceContainerHigh => const Color(0xFF282B2B);

  @override
  Color get surfaceContainerHighest => const Color(0xFF303434);

  @override
  Color get surfaceVariant => const Color(0xFF202222);

  @override
  Color get onSurface => const Color(0xFFF1F1F1);

  @override
  Color get onSurfaceVariant => const Color(0xFFC2C8C3);

  @override
  Color get inverseSurface => const Color(0xFFF1F1F1);

  @override
  Color get inverseOnSurface => const Color(0xFF1A1C1C);

  // Outline
  @override
  Color get outline => const Color(0xFF8A938D);

  @override
  Color get outlineVariant => const Color(0xFF424944);

  // Error
  @override
  Color get error => const Color(0xFFFFB4AB);

  @override
  Color get onError => const Color(0xFF690005);

  @override
  Color get errorContainer => const Color(0xFF93000A);

  @override
  Color get onErrorContainer => const Color(0xFFFFDAD6);

  // Background
  @override
  Color get background => const Color(0xFF121313);

  @override
  Color get onBackground => const Color(0xFFF1F1F1);
}
