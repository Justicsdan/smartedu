import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/providers/student/student_provider.dart';
import 'student_cbt_exam_page.dart';

class StudentCbtPage extends StatefulWidget {
  const StudentCbtPage({super.key});
  @override
  State<StudentCbtPage> createState() => _StudentCbtPageState();
}

class _StudentCbtPageState extends State<StudentCbtPage> {
  final Map<String, Map<String, dynamic>> _attempts = {};
  bool _loadingStatus = false;
  bool _loadedOnce = false;

  @override
  void initState() { super.initState(); _loadAttemptStatus(); }

  Future<void> _loadAttemptStatus() async {
    setState(() => _loadingStatus = true);
    try {
      final provider = context.read<StudentProvider>();
      final history = await provider.getMyCbtHistory();
      for (final attempt in history) {
        final examId = attempt['exam_id']?.toString() ?? '';
        if (examId.isNotEmpty && !_attempts.containsKey(examId)) {
          _attempts[examId] = Map<String, dynamic>.from(attempt);
        }
      }
      _loadedOnce = true;
    } catch (e) { debugPrint('Error loading CBT attempt status: $e'); }
    if (mounted) setState(() => _loadingStatus = false);
  }

  bool _isPassed(Map<String, dynamic> attempt) {
    final score = attempt['score'] as num? ?? 0;
    final total = attempt['total_marks'] as num? ?? 1;
    if (total <= 0) return false;
    final pct = (score / total) * 100;
    final examData = attempt['cbt_exams'] as Map<String, dynamic>? ?? {};
    final passMark = (examData['pass_mark'] as num?)?.toDouble();
    if (passMark != null && passMark > 0) return pct >= passMark;
    return pct >= 50;
  }

  void _showResultDetails(Map<String, dynamic> exam, Map<String, dynamic> attempt) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _CbtResultDetailPage(exam: exam, attempt: attempt)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    final exams = provider.cbtExams;
    if (!_loadedOnce && exams.isNotEmpty) _loadAttemptStatus();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF2E7D32).withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: const Row(children: [Icon(Icons.quiz_rounded, color: Color(0xFF2E7D32), size: 28), SizedBox(width: 16), Text("CBT Exams", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)))])),
        const SizedBox(height: 24),
        if (exams.isEmpty)
          Center(child: Container(padding: const EdgeInsets.all(60), child: Column(children: [Icon(Icons.quiz_outlined, size: 80, color: Colors.grey.shade300), const SizedBox(height: 16), Text("No CBT exams available", style: TextStyle(fontSize: 18, color: Colors.grey.shade500)), const SizedBox(height: 8), Text("Your exams will appear here when teachers create them", style: TextStyle(fontSize: 14, color: Colors.grey.shade400))])))
        else
          ...exams.map((exam) {
            final examId = exam['id']?.toString() ?? '';
            final isActive = exam['isActive'] == true;
            final attempt = _attempts[examId];
            final alreadyTaken = attempt != null;
            final score = attempt?['score'] as num?;
            final totalMarks = attempt?['total_marks'] as num?;
            final totalQuestions = exam['totalQuestions'] as int?;
            final passed = alreadyTaken ? _isPassed(attempt) : null;
            String? percentage;
            if (score != null && totalMarks != null && totalMarks > 0) percentage = ((score / totalMarks) * 100).toStringAsFixed(1);
            final submittedAt = attempt?['time_submitted'] as String?;
            return Container(
              margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: alreadyTaken ? (passed == true ? Colors.green.shade200 : Colors.orange.shade200) : isActive ? Colors.green.shade200 : Colors.grey.shade100, width: alreadyTaken ? 2 : (isActive ? 2 : 1))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: alreadyTaken ? (passed == true ? Colors.green.shade50 : Colors.orange.shade50) : isActive ? Colors.green.shade50 : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)), child: Icon(alreadyTaken ? (passed == true ? Icons.check_circle_rounded : Icons.remove_circle_rounded) : isActive ? Icons.play_circle_rounded : Icons.lock_clock_rounded, color: alreadyTaken ? (passed == true ? Colors.green : Colors.orange) : isActive ? Colors.green : Colors.grey, size: 32)),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Expanded(child: Text(exam['title'] ?? 'CBT Exam', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2A4A)))), if (alreadyTaken && passed != null) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: passed ? Colors.green.shade100 : Colors.orange.shade100, borderRadius: BorderRadius.circular(6)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(passed ? Icons.check : Icons.close, size: 14, color: passed ? Colors.green.shade700 : Colors.orange.shade700), const SizedBox(width: 4), Text(passed ? "Passed" : "Failed", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: passed ? Colors.green.shade700 : Colors.orange.shade700))]))]),
                    const SizedBox(height: 4),
                    Text("${exam['className'] ?? ''} \u2022 ${exam['subjectName'] ?? ''}", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Row(children: [
                      if (exam['duration'] != null) ...[Icon(Icons.timer_outlined, size: 14, color: Colors.orange.shade400), const SizedBox(width: 4), Text("${exam['duration']} min", style: TextStyle(fontSize: 12, color: Colors.orange.shade700)), const SizedBox(width: 12)],
                      if (totalQuestions != null && totalQuestions > 0) ...[Icon(Icons.help_outline, size: 14, color: Colors.grey.shade400), const SizedBox(width: 4), Text("$totalQuestions questions", style: TextStyle(fontSize: 12, color: Colors.grey.shade500))],
                      if (alreadyTaken && totalMarks != null) ...[const SizedBox(width: 12), Icon(Icons.stars_outlined, size: 14, color: Colors.blue.shade400), const SizedBox(width: 4), Text("Total: $totalMarks marks", style: TextStyle(fontSize: 12, color: Colors.blue.shade700))],
                    ]),
                  ])),
                ]),
                if (alreadyTaken) ...[
                  const SizedBox(height: 12),
                  Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12)), child: Row(children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text("Your Score", style: TextStyle(fontSize: 11, color: Colors.grey)), const SizedBox(height: 2),
                      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text("${score ?? 0}", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                        if (totalMarks != null) ...[const SizedBox(width: 4), Padding(padding: const EdgeInsets.only(bottom: 4), child: Text("/ $totalMarks", style: TextStyle(fontSize: 16, color: Colors.grey.shade500)))],
                        if (percentage != null) ...[const SizedBox(width: 10), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: double.parse(percentage) >= 50 ? Colors.green.shade100 : Colors.orange.shade100, borderRadius: BorderRadius.circular(6)), child: Text("$percentage%", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: double.parse(percentage) >= 50 ? Colors.green.shade700 : Colors.orange.shade700)))],
                      ]),
                    ]),
                    const Spacer(),
                    if (submittedAt != null) ...[Column(crossAxisAlignment: CrossAxisAlignment.end, children: [const Text("Submitted", style: TextStyle(fontSize: 11, color: Colors.grey)), const SizedBox(height: 2), Text(_fmtDate(submittedAt), style: TextStyle(fontSize: 12, color: Colors.grey.shade600))]), const SizedBox(width: 16)],
                    ElevatedButton.icon(onPressed: () => _showResultDetails(exam, attempt), icon: const Icon(Icons.visibility, size: 18), label: const Text("View Results"), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))),
                  ])),
                ],
                if (!alreadyTaken) Padding(padding: const EdgeInsets.only(top: 12), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  if (isActive) ElevatedButton.icon(onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (_) => StudentCbtExamPage(exam: exam))).then((_) => _loadAttemptStatus()); }, icon: const Icon(Icons.play_arrow), label: const Text("Start"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white))
                  else Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: const Text("Not Available", style: TextStyle(color: Colors.grey, fontSize: 12))),
                ])),
              ]),
            );
          }),
      ]),
    );
  }

  String _fmtDate(String s) { try { final d = DateTime.parse(s); return '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}'; } catch (_) { return s; } }
}

class _CbtResultDetailPage extends StatefulWidget {
  final Map<String, dynamic> exam;
  final Map<String, dynamic> attempt;
  const _CbtResultDetailPage({required this.exam, required this.attempt});
  @override
  State<_CbtResultDetailPage> createState() => _CbtResultDetailPageState();
}

class _CbtResultDetailPageState extends State<_CbtResultDetailPage> {
  List<Map<String, dynamic>> _questions = [];
  bool _loading = true;
  String? _error;
  StudentProvider get _p => context.read<StudentProvider>();
  @override
  void initState() { super.initState(); _loadQ(); }
  Future<void> _loadQ() async {
    try { final q = await _p.getCbtExamQuestions(widget.exam['id']?.toString() ?? ''); if (mounted) setState(() { _questions = q; _loading = false; }); }
    catch (_) { if (mounted) setState(() { _error = 'Failed to load'; _loading = false; }); }
  }
  String? _getAns(String qId) { final a = widget.attempt['answers']; if (a is Map<String, dynamic>) return a[qId]?.toString(); if (a is Map) return a[qId]?.toString(); return null; }
  bool _isOk(String qId) { final sa = _getAns(qId); if (sa == null || sa.isEmpty) return false; for (final q in _questions) { if (q['id']?.toString() == qId) return sa.toLowerCase() == ((q['correct_option'] as String?) ?? '').toLowerCase(); } return false; }

  @override
  Widget build(BuildContext context) {
    final score = widget.attempt['score'] as num? ?? 0;
    final total = widget.attempt['total_marks'] as num? ?? 1;
    final pct = total > 0 ? ((score / total) * 100).toStringAsFixed(1) : '0.0';
    final ed = widget.attempt['cbt_exams'] as Map<String, dynamic>? ?? {};
    final pm = (ed['pass_mark'] as num?)?.toDouble();
    final thr = (pm != null && pm > 0) ? pm : 50.0;
    final passed = double.parse(pct) >= thr;
    int cc = 0, wc = 0, sc = 0;
    for (final q in _questions) { final qId = q['id']?.toString() ?? ''; final a = _getAns(qId); if (a == null || a.isEmpty) sc++; else if (_isOk(qId)) cc++; else wc++; }
    return Scaffold(backgroundColor: Colors.white, appBar: AppBar(backgroundColor: Colors.white, elevation: 0, foregroundColor: const Color(0xFF1B2A4A), title: Text(widget.exam['title'] ?? 'CBT Results', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B2A4A))), leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF1B2A4A)), onPressed: () => Navigator.pop(context))),
      body: _loading ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D47A1))) : _error != null ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.error_outline, size: 48, color: Colors.red.shade300), const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: Colors.red)), const SizedBox(height: 16), ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back'))])) : SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(colors: passed ? [const Color(0xFF2E7D32), const Color(0xFF43A047)] : [const Color(0xFFE65100), const Color(0xFFFF8F00)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(16)), child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(passed ? Icons.emoji_events : Icons.refresh, color: Colors.white.withOpacity(0.9), size: 32), const SizedBox(width: 8), Text(passed ? 'PASSED' : 'NOT YET', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.95), letterSpacing: 2))]),
          const SizedBox(height: 16), Text('$score / $total', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)), const SizedBox(height: 4), Text('$pct%', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.85))),
          const SizedBox(height: 16), Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_sc(Icons.check_circle, '$cc', 'Correct'), _sc(Icons.cancel, '$wc', 'Wrong'), _sc(Icons.remove_circle_outline, '$sc', 'Skipped')]),
        ])),
        const SizedBox(height: 20), Text('${_questions.length} Questions', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1B2A4A))),
        const SizedBox(height: 12),
        ..._questions.asMap().entries.map((e) {
          final i = e.key; final q = e.value; final qId = q['id']?.toString() ?? '';
          final sa = _getAns(qId); final co = (q['correct_option'] as String?) ?? '';
          final ok = _isOk(qId); final skip = sa == null || sa.isEmpty; final mk = (q['marks'] as num?)?.toInt() ?? 1;
          Color bc = skip ? Colors.grey.shade300 : ok ? Colors.green.shade300 : Colors.red.shade300;
          Color ic = skip ? Colors.grey : ok ? Colors.green : Colors.red;
          IconData ii = skip ? Icons.remove_circle_outline : ok ? Icons.check_circle : Icons.cancel;
          return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: bc, width: 1.5)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 28, height: 28, decoration: BoxDecoration(color: skip ? Colors.grey.shade100 : ok ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(6)), alignment: Alignment.center, child: Text('${i+1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ic))), const SizedBox(width: 10), Expanded(child: Text(q['question_text'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF1B2A4A), height: 1.4), maxLines: 4)), const SizedBox(width: 8), Icon(ii, size: 20, color: ic)]),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: ['a','b','c','d'].map((o) {
              final ol = o.toUpperCase(); final ov = q['option_$o']?.toString() ?? '';
              if (ov.isEmpty) return const SizedBox.shrink();
              final isSt = sa?.toLowerCase() == o; final isCo = co.toLowerCase() == o;
              Color bg, bd, tc; IconData? tr;
              if (isCo && isSt) { bg = Colors.green.shade50; bd = Colors.green; tc = Colors.green.shade800; tr = Icons.check; }
              else if (isSt && !isCo) { bg = Colors.red.shade50; bd = Colors.red; tc = Colors.red.shade800; tr = Icons.close; }
              else if (isCo) { bg = Colors.green.shade50; bd = Colors.green.shade300; tc = Colors.green.shade700; tr = null; }
              else { bg = Colors.grey.shade50; bd = Colors.grey.shade200; tc = Colors.grey.shade700; tr = null; }
              return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6), border: Border.all(color: bd)), child: Row(mainAxisSize: MainAxisSize.min, children: [Text('$ol: $ov', style: TextStyle(fontSize: 11, color: tc)), if (tr != null) ...[const SizedBox(width: 4), Icon(tr, size: 12, color: bd)]]));
            }).toList()),
            const SizedBox(height: 6),
            Row(children: [
              if (skip) Text('Not answered', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic))
              else Text('Your answer: ${sa?.toUpperCase() ?? '-'}', style: TextStyle(fontSize: 11, color: ok ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.w600)),
              if (!ok && !skip) ...[const SizedBox(width: 12), Text('Correct: ${co.toUpperCase()}', style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w600))],
              const Spacer(), Text('$mk mark${mk > 1 ? 's' : ''}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ]),
          ]));
        }),
        const SizedBox(height: 20),
      ])));
  }
  Widget _sc(IconData i, String v, String l) => Column(children: [Icon(i, size: 20, color: Colors.white), const SizedBox(height: 4), Text(v, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)), Text(l, style: const TextStyle(fontSize: 11, color: Colors.white))]);
}
