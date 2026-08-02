import 'package:flutter/material.dart';

class ChartTheme {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color text;
  final Color grid;
  final Color tooltipBg;
  final Color tooltipText;
  final Color pass;
  final Color fail;

  const ChartTheme({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.text,
    required this.grid,
    required this.tooltipBg,
    required this.tooltipText,
    required this.pass,
    required this.fail,
  });

  static Color _parseHex(String hex) {
    final h = hex.replaceAll('#', '');
    if (h.length == 6) {
      return Color(int.parse('FF$h', radix: 16));
    }
    return const Color(0xFF1A237E);
  }

  factory ChartTheme.fromStudentBase({
    required String primary,
    required String secondary,
    required String accent,
    required String text,
  }) {
    return ChartTheme(
      primary: _parseHex(primary),
      secondary: _parseHex(secondary),
      accent: _parseHex(accent),
      text: _parseHex(text),
      grid: const Color(0xFFE5E7EB).withOpacity(0.3),
      tooltipBg: Colors.white,
      tooltipText: const Color(0xFF111827),
      pass: const Color(0xFF2E7D32),
      fail: const Color(0xFFD32F2F),
    );
  }

  LinearGradient areaGradient(Color color) {
    return LinearGradient(
      colors: [color.withOpacity(0.3), color.withOpacity(0.02)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }
}
