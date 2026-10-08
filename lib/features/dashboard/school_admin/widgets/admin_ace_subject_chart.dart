import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/providers/school_admin_provider.dart';
import 'package:smartedu/core/services/db_proxy.dart';
import 'package:smartedu/utils/chart_theme.dart';
import 'package:smartedu/widgets/empty_chart_placeholder.dart';

class AdminAceSubjectChart extends StatefulWidget {
  const AdminAceSubjectChart({super.key});

  @override
  State<AdminAceSubjectChart> createState() => _AdminAceSubjectChartState();
}

class _AdminAceSubjectChartState extends State<AdminAceSubjectChart> {
  bool _isLoading = true;
  Map<String, double> _subjectAverages = {}; 
  Map<String, String> _subjectNames = {};

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
      for (var s in provider.subjects) {
        _subjectNames[s['id'] as String] = s['name'] as String? ?? 'Unknown';
      }

      final res = await DbProxy.instance
          .from('ace_pace_scores')
          .select('subject_id, pt_score')
          .eq('school_id', provider.schoolId)
          .eq('session_id', sid)
          .eq('term_id', tid)
          .get();
          
      final Map<String, List<double>> tempScores = {};
      
      for (var row in res) {
        final subId = row['subject_id'] as String?;
        final pt = (row['pt_score'] as num?)?.toDouble();
        
        if (subId != null && pt != null) {
          tempScores.putIfAbsent(subId, () => []);
          tempScores[subId]!.add(pt);
        }
      }
      
      final averages = <String, double>{};
      tempScores.forEach((id, scores) {
        if (scores.isNotEmpty) {
          averages[id] = scores.reduce((a, b) => a + b) / scores.length;
        }
      });

      if (mounted) {
        setState(() {
          _subjectAverages = averages;
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
    
    if (_subjectAverages.isEmpty) {
      return const EmptyChartPlaceholder(message: 'No PACE scores recorded yet for this term.');
    }

    final sortedSubjects = _subjectAverages.keys.toList()
      ..sort((a, b) => _subjectAverages[b]!.compareTo(_subjectAverages[a]!));

    return SizedBox(
      height: (sortedSubjects.length * 48.0) + 40, 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend/Header
          Padding(
            padding: const EdgeInsets.only(left: 170, bottom: 12.0),
            child: Row(
              children: [
                Text('0%', style: TextStyle(fontSize: 11, color: theme.text.withOpacity(0.6))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('80% Mastery', style: TextStyle(fontSize: 10, color: Colors.orange.shade800, fontWeight: FontWeight.w800)),
                ),
                const Spacer(),
                Text('100%', style: TextStyle(fontSize: 11, color: theme.text.withOpacity(0.6))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedSubjects.length,
              itemBuilder: (context, index) {
                final subId = sortedSubjects[index];
                final avg = _subjectAverages[subId]!;
                final name = _subjectNames[subId] ?? 'Unknown';
                final isMastery = avg >= 80;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 160, // Fixed label width
                        child: Text(
                          name,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.text),
                          maxLines: 2, // NOW WRAPS TO 2 LINES
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Responsive Bar Area
                      Expanded(
                        child: Stack(
                          children: [
                            // Grid Lines (5 columns)
                            Row(
                              children: List.generate(5, (i) => Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(right: i == 4 ? BorderSide.none : BorderSide(color: theme.grid.withOpacity(0.5), width: 1)),
                                  ),
                                ),
                              )),
                            ),
                            // 80% Mastery Line
                            const Align(
                              alignment: Alignment(0.6, 0),
                              child: SizedBox(height: 24, child: VerticalDivider(color: Colors.orange, width: 2, thickness: 2)),
                            ),
                            // Background Track
                            Container(
                              height: 22,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: theme.grid.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            // Gradient Bar
                            FractionallySizedBox(
                              widthFactor: (avg / 100).clamp(0.0, 1.0), 
                              child: Container(
                                height: 22,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isMastery 
                                        ? [theme.primary, theme.primary.withOpacity(0.7)]
                                        : [theme.fail, theme.fail.withOpacity(0.7)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isMastery ? theme.primary : theme.fail).withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Fixed percentage text at the end
                      SizedBox(
                        width: 50,
                        child: Text(
                          avg.toStringAsFixed(1) + '%',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.text),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
