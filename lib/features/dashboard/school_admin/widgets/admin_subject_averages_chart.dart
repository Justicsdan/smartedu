import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/providers/school_admin_provider.dart';
import 'package:smartedu/utils/chart_theme.dart';
import 'package:smartedu/widgets/empty_chart_placeholder.dart';

class AdminSubjectAveragesChart extends StatelessWidget {
  const AdminSubjectAveragesChart({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SchoolAdminProvider>();
    final theme = ChartTheme.fromSettings(provider.schoolSettings);
    final isAce = provider.schoolSettings?['curriculum_mode'] == 'ace';
    final passMark = (provider.schoolSettings?['pass_mark'] as num?)?.toDouble() ?? 40.0;

    if (isAce) {
      return ChartTheme.card(
        title: 'Subject Performance',
        icon: Icons.bar_chart,
        child: const EmptyChartPlaceholder(message: 'No data available'),
      );
    }

    final scores = provider.scores;
    if (scores.isEmpty) {
      return ChartTheme.card(
        title: 'Subject Performance',
        icon: Icons.bar_chart,
        child: const EmptyChartPlaceholder(message: 'No score data available'),
      );
    }

    // Compute average per subject
    final Map<String, List<double>> subjectScores = {};
    for (final s in scores) {
      final subject = s['subjects'] as Map<String, dynamic>?;
      final name = subject?['name']?.toString().trim() ?? '';
      if (name.isEmpty) continue;
      final total = (s['total'] as num?)?.toDouble() ?? 0;
      if (total <= 0) continue;
      subjectScores.putIfAbsent(name, () => []);
      subjectScores[name]!.add(total);
    }

    if (subjectScores.isEmpty) {
      return ChartTheme.card(
        title: 'Subject Performance',
        icon: Icons.bar_chart,
        child: const EmptyChartPlaceholder(message: 'No score data available'),
      );
    }

    // Compute averages and sort descending
    final entries = subjectScores.entries.map((e) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return MapEntry(e.key, avg);
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final display = entries.length > 15 ? entries.sublist(0, 15) : entries;
    final maxScale = 100.0;

    return ChartTheme.card(
      title: 'Subject Performance',
      icon: Icons.bar_chart,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final labelW = 110.0;
          final scoreW = 48.0;
          final gap = 8.0;
          final barLeft = labelW + gap;
          final barRight = constraints.maxWidth - scoreW - gap;
          final barWidth = (barRight - barLeft).clamp(0.0, double.infinity);

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...display.map((e) {
                  final pct = (e.value / maxScale).clamp(0.0, 1.0);
                  final pass = e.value >= passMark;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: labelW,
                          child: Text(
                            e.key,
                            style: TextStyle(fontSize: 11, color: theme.text),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        SizedBox(width: gap),
                        SizedBox(
                          width: barWidth,
                          child: Stack(
                            children: [
                              Container(
                                height: 22,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Container(
                                height: 22,
                                width: barWidth * pct,
                                decoration: BoxDecoration(
                                  color: pass ? theme.pass : theme.fail,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: gap),
                        SizedBox(
                          width: scoreW,
                          child: Text(
                            e.value.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.text,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                // X-axis
                SizedBox(
                  height: 32,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      if (barWidth > 0)
                        ...List.generate((maxScale ~/ 20) + 1, (i) {
                          final v = i * 20.0;
                          if (v > maxScale) return const SizedBox.shrink();
                          final xPos = barLeft + barWidth * (v / maxScale);
                          return Positioned(
                            left: xPos,
                            top: 0,
                            child: Container(
                              width: 2,
                              height: 6,
                              color: theme.text.withOpacity(0.3),
                            ),
                          );
                        }),
                      if (barWidth > 0 && passMark > 0 && passMark <= maxScale)
                        Positioned(
                          left: barLeft + barWidth * (passMark / maxScale),
                          top: 0,
                          child: Container(
                            width: 2.5,
                            height: 6,
                            color: theme.fail,
                          ),
                        ),
                      if (barWidth > 0)
                        ...List.generate((maxScale ~/ 20) + 1, (i) {
                          final v = i * 20.0;
                          if (v > maxScale) return const SizedBox.shrink();
                          final xPos = barLeft + barWidth * (v / maxScale);
                          return Positioned(
                            left: xPos - 12,
                            top: 8,
                            child: SizedBox(
                              width: 24,
                              child: Text(
                                v.toInt().toString(),
                                style: TextStyle(fontSize: 10, color: theme.text),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }),
                      if (barWidth > 0 && passMark > 0 && passMark <= maxScale)
                        Positioned(
                          left: barLeft + barWidth * (passMark / maxScale) - 16,
                          top: 8,
                          child: Container(
                            width: 32,
                            height: 18,
                            decoration: BoxDecoration(
                              color: theme.fail.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Center(
                              child: Text(
                                'Pass',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: theme.fail,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
