import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const String _prefKey = 'app_theme_mode';

  @override
  ThemeMode build() {
    // Default to dark mode out of the box
    AppColors.isDark = true;
    _loadPersistedTheme();
    return ThemeMode.dark;
  }

  Future<void> _loadPersistedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_prefKey);
      if (savedMode != null) {
        final mode = savedMode == 'light' ? ThemeMode.light : ThemeMode.dark;
        state = mode;
        AppColors.isDark = mode == ThemeMode.dark;
      }
    } catch (e) {
      debugPrint('[ThemeModeNotifier] Failed to load persisted theme: $e');
    }
  }

  Future<void> toggle() async {
    final nextMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = nextMode;
    AppColors.isDark = nextMode == ThemeMode.dark;
    await _saveTheme(nextMode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    AppColors.isDark = mode == ThemeMode.dark;
    await _saveTheme(mode);
  }

  Future<void> _saveTheme(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, mode == ThemeMode.dark ? 'dark' : 'light');
    } catch (e) {
      debugPrint('[ThemeModeNotifier] Failed to save theme preference: $e');
    }
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
