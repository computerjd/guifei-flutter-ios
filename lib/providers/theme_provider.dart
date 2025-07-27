import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 可选的背景颜色
enum AppBackgroundColor {
  darkGray(Color(0xFF2D2D2D), '灰黑色'),
  black(Color(0xFF000000), '纯黑色'),
  darkBlue(Color(0xFF1A1A2E), '深蓝色'),
  darkGreen(Color(0xFF0F3460), '深绿色'),
  darkPurple(Color(0xFF16213E), '深紫色');

  const AppBackgroundColor(this.color, this.name);
  final Color color;
  final String name;
}

class ThemeNotifier extends StateNotifier<AppBackgroundColor> {
  ThemeNotifier() : super(AppBackgroundColor.darkGray) {
    _loadTheme();
  }

  static const String _themeKey = 'app_background_color';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final colorIndex = prefs.getInt(_themeKey) ?? 0;
    if (colorIndex < AppBackgroundColor.values.length) {
      state = AppBackgroundColor.values[colorIndex];
    }
  }

  Future<void> setBackgroundColor(AppBackgroundColor color) async {
    state = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, color.index);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppBackgroundColor>(
  (ref) => ThemeNotifier(),
);