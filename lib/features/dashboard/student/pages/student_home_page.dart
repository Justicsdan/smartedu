import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/providers/student/student_provider.dart';
import 'package:smartedu/core/services/db_proxy.dart';
import '../widgets/student_subject_bar_chart.dart';
import '../widgets/student_session_comparison_chart.dart';
import '../widgets/student_term_pie_chart.dart';

class StudentHomePage extends StatelessWidget {
  const StudentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<StudentProvider>();
    final isAce = p.curriculumMode == 'ace';
    final passport = p.passportUrl;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _welcomeBanner(p, passport),
          const SizedBox(height: 20),
          const _MyStatusCard(),
          const SizedBox(height: 20),
          if (isAce) ...[
            _sectionTitle('ACE Progress'),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE8EAED))),
              child: Column(
                children: [
                  Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFF1A237E).withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.auto_stories_rounded, size: 28, color: Color(0xFF1A237E))),
                  const SizedBox(height: 16),
                  const Text('View your PACE scores and progress report', style: TextStyle(fontSize: 15, color: Color(0xFF111827), fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  const Text('Go to "My Progress" in the sidebar to see your report card, PACE test scores, HACS and NCE scores.', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                ],
              ),
            ),
          ] else ...[
            _sectionTitle('Quick Stats'),
            const SizedBox(height: 14),
            Row(
              children: [
                _statCard('Subjects', '${p.scores.length}', Icons.menu_book_rounded, const Color(0xFF1A237E)),
                const SizedBox(width: 12),
                _statCard('Average', '${p.getOverallAverage().toStringAsFixed(1)}%', Icons.trending_up_rounded, const Color(0xFF2E7D32)),
              ],
            ),
            const SizedBox(height: 24),
            _sectionTitle('Recent Results'),
            const SizedBox(height: 14),
            if (p.scores.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE8EAED))),
                child: const Column(
                  children: [
                    Icon(Icons.grading_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('No results available yet', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              )
            else
              ...p.scores.take(3).map((score) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8EAED))),
                child: Row(
                  children: [
                    Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.assignment_rounded, size: 18, color: Color(0xFF1A237E))),
                    const SizedBox(width: 12),
                    Expanded(child: Text(((score['subjects'] as Map?)?['name'] ?? 'Subject').toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF111827)))),
                    Text('${score['total'] ?? 0}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                  ],
                ),
              )),
          if (!isAce) ...[
            const SizedBox(height: 24),
            _sectionTitle('Performance Charts'),
            const SizedBox(height: 14),
            const SizedBox(height: 200, child: StudentSubjectBarChart()),
            const SizedBox(height: 12),
            const SizedBox(height: 200, child: StudentSessionComparisonChart()),
            const SizedBox(height: 12),
            const SizedBox(height: 200, child: StudentTermPieChart()),
          ],
          ],
        ],
      ),
    );
  }

  Widget _welcomeBanner(StudentProvider p, String passport) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A237E), Color(0xFF3949AB)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withOpacity(0.15),
            backgroundImage: passport.isNotEmpty ? NetworkImage(passport) : null,
            onBackgroundImageError: passport.isNotEmpty ? (_, __) {} : null,
            child: passport.isEmpty ? const Icon(Icons.person, size: 32, color: Colors.white70) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome Back,', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6))),
                const SizedBox(height: 4),
                Text(p.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 2),
                Text(p.classDisplay, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)));
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8EAED))),
        child: Row(
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 20, color: color)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
              Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ]),
          ],
        ),
      ),
    );
  }
}

class _MyStatusCard extends StatefulWidget {
  const _MyStatusCard();
  @override
  State<_MyStatusCard> createState() => _MyStatusCardState();
}

class _MyStatusCardState extends State<_MyStatusCard> {
  bool _loading = true;
  String _termLabel = '';
  String _curriculumMode = 'traditional';
  String _resultsStatus = 'unknown';
  int _subjectsScored = 0;
  int _totalSubjects = 0;
  int _attPresent = 0;
  int _attTotal = 0;
  int _feeOutstanding = 0;
  int _cbtTotal = 0;
  int _cbtCompleted = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = context.read<StudentProvider>();
      _curriculumMode = p.curriculumMode;
      final sessionId = p.currentSession?['id']?.toString() ?? '';
      final termId = p.currentTerm?['id']?.toString() ?? '';
      _termLabel = [p.currentTermName, p.currentSessionName].where((s) => s.isNotEmpty).join(', ');
      if (sessionId.isEmpty || termId.isEmpty) { setState(() => _loading = false); return; }
      final schoolId = p.schoolId;
      final studentId = p.studentId;
      final classId = p.classId;
      final isAce = _curriculumMode == 'ace';

      if (isAce) {
        final r = await DbProxy.instance.from('ace_term_reports').select('is_published').eq('student_id', studentId).eq('session_id', sessionId).eq('term_id', termId).maybeSingle();
        if (r == null) { _resultsStatus = 'not_ready'; } else if (r['is_published'] == true) { _resultsStatus = 'published'; } else { _resultsStatus = 'not_published'; }
      } else {
        final r = await DbProxy.instance.from('student_term_summaries').select('is_published').eq('student_id', studentId).eq('session_id', sessionId).eq('term_id', termId).maybeSingle();
        if (r == null) { _resultsStatus = 'not_ready'; } else if (r['is_published'] == true) { _resultsStatus = 'published'; } else { _resultsStatus = 'not_published'; }
      }

      final scoreTable = isAce ? 'ace_pace_scores' : 'scores';
      final scores = await DbProxy.instance.from(scoreTable).select('subject_id').eq('student_id', studentId).eq('session_id', sessionId).eq('term_id', termId).get();
      _subjectsScored = scores.map((s) => s['subject_id']?.toString()).where((s) => s != null).toSet().length;
      final cs = await DbProxy.instance.from('class_subjects').select('subject_id').eq('class_id', classId).get();
      _totalSubjects = cs.length;

      final att = await DbProxy.instance.from('attendance').select('status').eq('student_id', studentId).eq('session_id', sessionId).eq('term_id', termId).get();
      _attTotal = att.length;
      _attPresent = att.where((a) => a['status'] == 'present').length;

      final fp = await DbProxy.instance.from('fee_payments').select('fee_type_id, amount_paid').eq('student_id', studentId).eq('session_id', sessionId).eq('term_id', termId).get();
      if (fp.isNotEmpty) {
        final ftIds = fp.map((f) => f['fee_type_id']?.toString()).where((s) => s != null).toSet().toList();
        if (ftIds.isNotEmpty) {
          final fts = await DbProxy.instance.from('fee_types').select('id, amount').in_('id', ftIds).get();
          final Map<String, double> ftAmounts = {};
          for (final ft in fts) { ftAmounts[ft['id']?.toString() ?? ''] = (ft['amount'] as num?)?.toDouble() ?? 0; }
          for (final f in fp) {
            final ftId = f['fee_type_id']?.toString() ?? '';
            final expected = ftAmounts[ftId] ?? 0;
            final paid = (f['amount_paid'] as num?)?.toDouble() ?? 0;
            if (paid < expected) _feeOutstanding++;
          }
        }
      }

      if (!isAce) {
        final exams = await DbProxy.instance.from('cbt_exams').select('id').eq('class_id', classId).eq('session_id', sessionId).eq('term_id', termId).eq('is_active', true).get();
        _cbtTotal = exams.length;
        if (exams.isNotEmpty) {
          final examIds = exams.map((e) => e['id']?.toString()).where((s) => s != null).toList();
          final attempts = await DbProxy.instance.from('cbt_attempts').select('exam_id, is_submitted').eq('student_id', studentId).in_('exam_id', examIds).get();
          _cbtCompleted = attempts.where((a) => a['is_submitted'] == true).length;
        }
      }

      setState(() => _loading = false);
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _termLabel.isEmpty) return const SizedBox.shrink();
    final isAce = _curriculumMode == 'ace';
    final attPct = _attTotal > 0 ? (_attPresent / _attTotal * 100).round() : 0;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)]), borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded, size: 17, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text('MY STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.6)),
                  const Spacer(),
                  Text(_termLabel, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7))),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(children: [
                  _row(Icons.bar_chart_rounded, 'Results', _resultsLabel(), _resultsColor()),
                  const Divider(height: 20),
                  _row(Icons.menu_book_rounded, isAce ? 'PACEs Done' : 'Subjects', '$_subjectsScored of $_totalSubjects', _subjectsScored >= _totalSubjects ? const Color(0xFF2E7D32) : const Color(0xFF757575)),
                  const Divider(height: 20),
                  _row(Icons.fact_check_rounded, 'Attendance', '$_attPresent/$_attTotal days ($attPct%)', attPct >= 75 ? const Color(0xFF2E7D32) : attPct >= 50 ? const Color(0xFFF57F17) : const Color(0xFFC62828)),
                  const Divider(height: 20),
                  _row(Icons.receipt_long_rounded, 'Fees', _feeOutstanding == 0 ? 'All clear' : '$_feeOutstanding outstanding', _feeOutstanding == 0 ? const Color(0xFF2E7D32) : const Color(0xFFC62828)),
                  if (!isAce) ...[const Divider(height: 20), _row(Icons.quiz_rounded, 'CBT', _cbtTotal == 0 ? 'No exams' : '$_cbtCompleted of $_cbtTotal completed', _cbtTotal == 0 ? const Color(0xFF9E9E9E) : _cbtCompleted >= _cbtTotal ? const Color(0xFF2E7D32) : const Color(0xFFF57F17))],
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _resultsLabel() {
    if (_resultsStatus == 'published') return 'PUBLISHED';
    if (_resultsStatus == 'not_published') return 'NOT YET PUBLISHED';
    return 'NOT READY';
  }

  Color _resultsColor() {
    if (_resultsStatus == 'published') return const Color(0xFF2E7D32);
    if (_resultsStatus == 'not_published') return const Color(0xFFF57F17);
    return const Color(0xFF9E9E9E);
  }

  Widget _row(IconData icon, String label, String value, Color color) {
    return Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: color)),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF757575)))),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
    ]);
  }
}
