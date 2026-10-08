import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smartedu/utils/chart_theme.dart';
import 'package:smartedu/widgets/empty_chart_placeholder.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/providers/school_admin_provider.dart';
import 'package:smartedu/core/services/db_proxy.dart';

class AdminAttendanceTrendChart extends StatefulWidget {
  const AdminAttendanceTrendChart({super.key});

  @override
  State<AdminAttendanceTrendChart> createState() => _AdminAttendanceTrendChartState();
}

class _AdminAttendanceTrendChartState extends State<AdminAttendanceTrendChart> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<SchoolAdminProvider>();
    final sid = provider.currentSession?['id']?.toString() ?? '';
    final tid = provider.currentTerm?['id']?.toString() ?? '';
    
    if (sid.isEmpty || tid.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await DbProxy.instance
          .from('attendance')
          .select('date, status')
          .eq('school_id', provider.schoolId)
          .eq('session_id', sid)
          .eq('term_id', tid)
          .get();
      if (mounted) {
        setState(() {
          _records = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final theme = ChartTheme.fromSettings(context.read<SchoolAdminProvider>().schoolSettings);
    
    if (_records.isEmpty) {
      return const EmptyChartPlaceholder(message: 'No attendance data available for this term.');
    }

    final Map<String, int> dailyPresent = {};
    final Map<String, int> dailyTotal = {};

    for (var r in _records) {
      final date = (r['date'] as String?)?.split('T').first;
      if (date == null) continue;
      dailyTotal[date] = (dailyTotal[date] ?? 0) + 1;
      if (r['status'] == 'present' || r['status'] == 'late') {
        dailyPresent[date] = (dailyPresent[date] ?? 0) + 1;
      }
    }

    final sortedDates = dailyTotal.keys.toList()..sort();
    if (sortedDates.isEmpty) {
      return const EmptyChartPlaceholder(message: 'No attendance data available.');
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final present = dailyPresent[date] ?? 0;
      final total = dailyTotal[date] ?? 1;
      final pct = (present / total) * 100;
      spots.add(FlSpot(i.toDouble(), pct));
    }

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) => FlLine(color: theme.grid, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 25,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}%', style: TextStyle(color: theme.text, fontSize: 10));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: theme.accent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: theme.accent.withOpacity(0.1)),
            ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 75,
                color: Colors.green.withOpacity(0.5),
                strokeWidth: 2,
                dashArray: [5, 5],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(right: 8, bottom: 4),
                  style: TextStyle(color: Colors.green.shade800, fontSize: 9, fontWeight: FontWeight.bold),
                  labelResolver: (_) => 'Target: 75%',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
