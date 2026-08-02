import 'package:flutter/material.dart';

class EmptyChartPlaceholder extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? color;

  const EmptyChartPlaceholder({
    super.key,
    this.message = 'No data available',
    this.icon = Icons.bar_chart,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clr = color ?? const Color(0xFF9CA3AF);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: clr.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(fontSize: 14, color: clr, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
