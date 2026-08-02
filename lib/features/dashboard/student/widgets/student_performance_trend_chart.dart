import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/providers/student/student_provider.dart';
import 'package:smartedu/utils/chart_theme.dart';
import 'package:smartedu/widgets/empty_chart_placeholder.dart';

class StudentPerformanceTrendChart extends StatefulWidget {
  const StudentPerformanceTrendChart({super.key});

  @override
  State<StudentPerformanceTrendChart> createState() => _StudentPerformanceTrendChartState();
}

class _StudentPerformanceTrendChartState extends State<StudentPerformanceTrendChart> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final provider = context.read<StudentProvider>();
    if (!provider.termHistory.any((t) => t['is_published'] == true)) {
      await provider.loadTermHistory();
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    final theme = ChartTheme.fromStudentBase(
      primary: provider.primaryColor,
      secondary: provider.secondaryColor,
      accent: provider.accentColor,
      text: provider.textColor,
    );

    final published = provider.termHistory
        .where((t) => t['is_published'] == true)
        .toList();
    if (published.length > 6) {
      published.removeRange(0, published.length - 6);
    }

    if (!_loaded) {
      return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
    }

    if (published.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: const EmptyChartPlaceholder(message: 'No published results yet'),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < published.length; i++) {
      spots.add(FlSpot(i.toDouble(), (published[i]['average_score'] as num).toDouble()));
    }

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.trending_up, color: Color(0xFF1A237E), size: 20),
            SizedBox(width: 8),
            Text('Performance Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minX: -0.5,
                maxX: (published.length - 1).toDouble() + 0.5,
                minY: -5,
                maxY: 105,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.grid,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    axisNameWidget: const SizedBox.shrink(),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 20,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          '${value.toInt()}',
                          style: TextStyle(fontSize: 10, color: theme.text.withOpacity(0.6)),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const SizedBox.shrink(),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= published.length) return const SizedBox.shrink();
                        final label = '${published[idx]['term_name']}';
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label.length > 10 ? '${label.substring(0, 10)}..' : label,
                            style: TextStyle(fontSize: 10, color: theme.text.withOpacity(0.7)),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: theme.primary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: theme.primary,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: theme.areaGradient(theme.primary),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => theme.tooltipBg,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.x.toInt();
                        final term = published[idx];
                        final avg = (term['average_score'] as num).toDouble();
                        final avgStr = avg == avg.roundToDouble() ? avg.toInt().toString() : avg.toStringAsFixed(1);
                        return LineTooltipItem(
                          '${term['term_name']}: $avgStr%',
                          const TextStyle(color: Color(0xFF111827), fontSize: 12, fontWeight: FontWeight.w600),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
