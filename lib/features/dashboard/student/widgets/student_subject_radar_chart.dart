import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/providers/student/student_provider.dart';
import 'package:smartedu/utils/chart_theme.dart';
import 'package:smartedu/widgets/empty_chart_placeholder.dart';

class StudentSubjectRadarChart extends StatelessWidget {
  const StudentSubjectRadarChart({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    final theme = ChartTheme.fromStudentBase(
      primary: provider.primaryColor,
      secondary: provider.secondaryColor,
      accent: provider.accentColor,
      text: provider.textColor,
    );
    final scores = provider.scores;
    final maxScore = provider.subjectMaxScore.toDouble();

    if (scores.length < 3) {
      return Container(
        height: 260,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: const EmptyChartPlaceholder(message: 'Need at least 3 subjects for radar chart'),
      );
    }

    final maxSubjects = scores.length > 12 ? 12 : scores.length;
    final dataEntries = <RadarEntry>[];
    final titlesList = <RadarChartTitle>[];

    for (int i = 0; i < maxSubjects; i++) {
      final score = (scores[i]['total'] ?? 0).toDouble();
      final pct = maxScore > 0 ? (score / maxScore * 100).clamp(0, 100) : 0;
      String label = (scores[i]['subject_name'] ?? 'Subject ${i + 1}').toString();
      if (label.length > 12) label = '${label.substring(0, 12)}..';
      titlesList.add(RadarChartTitle(text: label));
      dataEntries.add(RadarEntry(value: pct));
    }

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.radar, color: Color(0xFF1A237E), size: 20),
            SizedBox(width: 8),
            Text('Subject Strengths', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    dataEntries: dataEntries,
                    fillColor: theme.primary.withOpacity(0.15),
                    borderColor: theme.primary.withOpacity(0.7),
                    borderWidth: 2,
                    entryRadius: 4,
                  ),
                ],
                getTitle: (index, angle) => titlesList[index],
                tickCount: 5,
                gridBorderData: BorderSide(color: theme.primary.withOpacity(0.15), width: 1),
                radarBorderData: BorderSide(color: theme.primary.withOpacity(0.2), width: 1),
                radarBackgroundColor: theme.primary.withOpacity(0.03),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
