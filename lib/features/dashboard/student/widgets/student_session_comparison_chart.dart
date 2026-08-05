import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/providers/student/student_provider.dart';
import 'package:smartedu/utils/chart_theme.dart';
import 'package:smartedu/widgets/empty_chart_placeholder.dart';

class StudentSessionComparisonChart extends StatefulWidget {
  const StudentSessionComparisonChart({super.key});

  @override
  State<StudentSessionComparisonChart> createState() =>
      _StudentSessionComparisonChartState();
}

class _StudentSessionComparisonChartState
    extends State<StudentSessionComparisonChart> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Load session-wide scores on first build (cached, no-op on repeat)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().loadSessionScores().then((_) {
        if (mounted) setState(() => _loading = false);
      });
    });
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

    // Build title parts
    final termNames =
        provider.sessionTerms.map((t) => t['name']?.toString() ?? '').toList();
    final titleTerms = termNames.isEmpty
        ? ''
        : termNames.map((n) => n.replaceAll(' Term', '').trim()).join(', ');
    final sessionName = provider.currentSessionName;

    if (_loading) {
      return ChartTheme.card(
        title: 'REPORT CHART',
        icon: Icons.timeline,
        subtitle: 'End of session chart',
        child: const Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final sessionScores = provider.sessionScores;
    if (sessionScores.isEmpty || termNames.isEmpty) {
      return ChartTheme.card(
        title: 'REPORT CHART',
        icon: Icons.timeline,
        subtitle: 'End of session chart for: $sessionName',
        child: const EmptyChartPlaceholder(message: 'No data available'),
      );
    }

    if (termNames.length < 2) {
      return ChartTheme.card(
        title: 'REPORT CHART',
        icon: Icons.timeline,
        subtitle: 'End of session chart for: $sessionName',
        child: const EmptyChartPlaceholder(
            message: 'Complete more terms to see comparison'),
      );
    }

    // Collect all unique subject names across all terms
    final Set<String> subjectSet = {};
    for (final termScores in sessionScores.values) {
      for (final s in termScores) {
        final name = (s['subject_name'] ?? '').toString().trim();
        if (name.isNotEmpty) subjectSet.add(name);
      }
    }
    final subjects = subjectSet.toList()..sort();
    if (subjects.isEmpty) {
      return ChartTheme.card(
        title: 'REPORT CHART',
        icon: Icons.timeline,
        subtitle: 'End of session chart for: $sessionName',
        child: const EmptyChartPlaceholder(message: 'No subject data available'),
      );
    }

    final displaySubjects = subjects.length > 12 ? subjects.sublist(0, 12) : subjects;

    // Build lookup: termId → termName, termIndex
    final termIds = termNames
        .map((name) => provider.sessionTerms
            .firstWhere((t) => t['name'] == name)['id']?.toString())
        .toList();
    final colors = theme.termColors;

    return ChartTheme.card(
      title: 'REPORT CHART FOR ${titleTerms.toUpperCase()}',
      icon: Icons.timeline,
      subtitle: 'End of session chart for: $sessionName',
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Chart rows
            ...displaySubjects.map((subject) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subject name
                    Padding(
                      padding: const EdgeInsets.only(left: 118, bottom: 2),
                      child: Text(
                        subject,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.text,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    // One bar per term
                    ...termIds.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final tid = entry.value;
                      if (tid == null) return const SizedBox.shrink();
                      final termScoreList = sessionScores[tid];
                      final scoreRow = termScoreList?.firstWhere(
                        (s) =>
                            (s['subject_name'] ?? '').toString().trim() ==
                            subject,
                        orElse: () => <String, dynamic>{},
                      );
                      final total =
                          (scoreRow?['total'] as num?)?.toDouble() ?? 0;
                      final pct = (total / 100).clamp(0.0, 1.0);
                      final color = colors[idx % colors.length];
                      final termLabel = termNames[idx]
                          .replaceAll(' Term', '')
                          .trim();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            const SizedBox(width: 118),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return Stack(
                                    children: [
                                      Container(
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3F4F6),
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                      ),
                                      Container(
                                        height: 16,
                                        width: total > 0
                                            ? constraints.maxWidth * pct
                                            : 0,
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 36,
                              child: Text(
                                total > 0
                                    ? (total % 1 == 0
                                        ? total.toInt().toString()
                                        : total.toStringAsFixed(1))
                                    : '--',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.text,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: termNames.asMap().entries.map((entry) {
                final idx = entry.key;
                final name = entry.value.replaceAll(' Term', '').trim();
                final color = colors[idx % colors.length];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      name,
                      style: TextStyle(fontSize: 11, color: theme.text),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
