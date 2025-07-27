import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeColor {
  final Color color;
  final String name;

  const ThemeColor(this.color, this.name);
}

class ThemeNotifier extends StateNotifier<ThemeColor> {
  ThemeNotifier() : super(const ThemeColor(Color(0xFF1A1A2E), '深夜蓝'));

  void changeTheme(ThemeColor newTheme) {
    state = newTheme;
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeColor>((ref) {
  return ThemeNotifier();
});

final themeColors = [
  const ThemeColor(Color(0xFF1A1A2E), '深夜蓝'),
  const ThemeColor(Color(0xFF16213E), '午夜蓝'),
  const ThemeColor(Color(0xFF0F3460), '皇家蓝'),
  const ThemeColor(Color(0xFF533483), '紫罗兰'),
  const ThemeColor(Color(0xFF7209B7), '魅惑紫'),
  const ThemeColor(Color(0xFF2D1B69), '神秘紫'),
  const ThemeColor(Color(0xFF11001C), '深紫黑'),
  const ThemeColor(Color(0xFF19376D), '深海蓝'),
];