import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/providers/student/student_provider.dart';
import 'package:smartedu/utils/chart_theme.dart';
import 'package:smartedu/widgets/empty_chart_placeholder.dart';

class StudentTermPieChart extends StatelessWidget {
  const StudentTermPieChart({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    final theme = ChartTheme.fromStudentBase(
      primary: provider.primaryColor,
      secondary: provider.secondaryColor,
      accent: provider.accentColor,
      text: provider.textColor,
    );

    final sessionScores = provider.sessionScores;
    final termNames = provider.sessionTerms
        .map((t) => t['name']?.toString() ?? '')
        .toList();
    final sessionName = provider.currentSessionName;
    final lastTerm = termNames.isNotEmpty ? termNames.last : '';
    final colors = theme.termColors;

    if (sessionScores.isEmpty || termNames.isEmpty) {
      return ChartTheme.card(
        title: 'PIE CHART',
        icon: Icons.pie_chart,
        subtitle: 'End of $lastTerm Summary Chart',
        child: const EmptyChartPlaceholder(message: 'No data available'),
      );
    }

    if (termNames.length < 2) {
      return ChartTheme.card(
        title: 'PIE CHART',
        icon: Icons.pie_chart,
        subtitle: 'End of $lastTerm Summary Chart',
        child: const EmptyChartPlaceholder(
            message: 'Need at least 2 terms for comparison'),
      );
    }

    // Compute total score per term
    final List<_TermSlice> slices = [];
    for (int i = 0; i < termNames.length; i++) {
      final tid = provider.sessionTerms[i]['id']?.toString();
      if (tid == null) continue;
      final scores = sessionScores[tid];
      double total = 0;
      if (scores != null) {
        for (final s in scores) {
          total += (s['total'] as num?)?.toDouble() ?? 0;
        }
      }
      if (total <= 0) continue;
      slices.add(_TermSlice(
        label: termNames[i].replaceAll(' Term', '').trim(),
        total: total,
        color: colors[i % colors.length],
      ));
    }

    if (slices.isEmpty) {
      return ChartTheme.card(
        title: 'PIE CHART',
        icon: Icons.pie_chart,
        subtitle: 'End of $lastTerm Summary Chart',
        child: const EmptyChartPlaceholder(message: 'No score data available'),
      );
    }

    final grandTotal = slices.fold<double>(0, (sum, s) => sum + s.total);

    return ChartTheme.card(
      title:
          'PIE CHART FOR ${termNames.map((n) => n.replaceAll(' Term', '').trim()).join(', ').toUpperCase()}',
      icon: Icons.pie_chart,
      subtitle: 'End of $lastTerm Summary Chart',
      child: Column(
        children: [
          // Pie — NO text inside slices
          Expanded(
            child: PieChart(
              PieChartData(
                sections: slices.asMap().entries.map((entry) {
                  final i = entry.key;
                  final slice = entry.value;
                  final pct = grandTotal > 0 ? (slice.total / grandTotal * 100) : 0;
                  return PieChartSectionData(
                    value: slice.total,
                    title: '${pct.toStringAsFixed(1)}%',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
                    ),
                    titlePositionPercentageOffset: 0.5,
                    color: slice.color,
                    radius: 70,
                    borderSide: const BorderSide(color: Colors.white, width: 3),
                  );
                }).toList(),
                sectionsSpace: 3,
                centerSpaceRadius: 0,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend — all info here, clean and readable
          ...slices.map((slice) {
            final pct =
                grandTotal > 0 ? (slice.total / grandTotal * 100) : 0.0;
            final totalStr = slice.total % 1 == 0
                ? slice.total.toInt().toString()
                : slice.total.toStringAsFixed(1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: slice.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${slice.label}: $totalStr (${pct.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TermSlice {
  final String label;
  final double total;
  final Color color;
  _TermSlice(
      {required this.label, required this.total, required this.color});
}
