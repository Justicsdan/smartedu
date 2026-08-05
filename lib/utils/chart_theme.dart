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

  /// Parse hex color from dynamic value (String or null).
  static Color? _parseDynamic(dynamic value) {
    if (value == null || value is! String || value.isEmpty) return null;
    return _parseHex(value);
  }

  /// Build from school_settings map. Used by all admin/teacher/general charts.
  factory ChartTheme.fromSettings(Map<String, dynamic>? settings) {
    return ChartTheme(
      primary: _parseDynamic(settings?['primary_color']) ?? const Color(0xFF3B82F6),
      secondary: _parseDynamic(settings?['secondary_color']) ?? const Color(0xFF6366F1),
      accent: _parseDynamic(settings?['accent_color']) ?? const Color(0xFFF59E0B),
      text: _parseDynamic(settings?['text_color']) ?? const Color(0xFF6B7280),
      grid: const Color(0xFFE5E7EB).withOpacity(0.3),
      tooltipBg: Colors.white,
      tooltipText: const Color(0xFF111827),
      pass: const Color(0xFF2E7D32),
      fail: const Color(0xFFD32F2F),
    );
  }

  /// Build from raw hex strings. Used by existing student radar chart.
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

  /// Default theme when no settings available.
  static ChartTheme get fallback => ChartTheme.fromSettings(null);

  /// Term colors for multi-term charts (cycles if more than 3 terms).
  List<Color> get termColors => [primary, secondary, accent];

  /// Area gradient for line charts.
  LinearGradient areaGradient(Color color) {
    return LinearGradient(
      colors: [color.withOpacity(0.3), color.withOpacity(0.02)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  /// Standard chart card wrapper — white container with border.
  static Widget card({
    required Widget child,
    required String title,
    required IconData icon,
    Widget? trailing,
    String? subtitle,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200, maxHeight: 300),
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF6B7280)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}
