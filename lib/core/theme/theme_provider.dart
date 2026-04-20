import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_theme.dart';

/// Persisted theme selection.
///
/// Stores the theme key ('dark', 'light', 'midnight', 'solana', 'system')
/// in SharedPreferences. Defaults to 'system' which follows platform brightness.
class ThemeNotifier extends Notifier<ThemeState> {
  static const _prefKey = 'aura_theme';

  @override
  ThemeState build() {
    _load();
    return const ThemeState(mode: 'system');
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_prefKey) ?? 'system';
    state = ThemeState(mode: key);
  }

  Future<void> setTheme(String key) async {
    state = ThemeState(mode: key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, key);
  }
}

class ThemeState {
  final String mode; // 'system', 'dark', 'light', 'midnight', 'solana'

  const ThemeState({required this.mode});

  bool get isSystem => mode == 'system';

  /// Resolve to a concrete theme, using platform brightness for 'system'.
  ThemeData resolveTheme(Brightness platformBrightness) {
    if (isSystem) {
      return platformBrightness == Brightness.dark
          ? AppTheme.darkTheme
          : AppTheme.lightTheme;
    }
    final colors = AuraColors.themes[mode] ?? AuraColors.dark;
    return AppTheme.fromColors(colors);
  }

  /// For MaterialApp: when mode is 'system', we use both theme + darkTheme.
  /// When explicit, we only set theme.
  ThemeMode get themeMode {
    if (isSystem) return ThemeMode.system;
    final colors = AuraColors.themes[mode];
    if (colors == null) return ThemeMode.dark;
    return colors.brightness == Brightness.dark
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  ThemeData get lightTheme => AppTheme.lightTheme;
  ThemeData get darkTheme {
    if (isSystem) return AppTheme.darkTheme;
    final colors = AuraColors.themes[mode] ?? AuraColors.dark;
    return AppTheme.fromColors(colors);
  }

  /// The explicit theme (used when not 'system').
  ThemeData get explicitTheme {
    final colors = AuraColors.themes[mode] ?? AuraColors.dark;
    return AppTheme.fromColors(colors);
  }
}

final themeNotifierProvider = NotifierProvider<ThemeNotifier, ThemeState>(
  ThemeNotifier.new,
);
