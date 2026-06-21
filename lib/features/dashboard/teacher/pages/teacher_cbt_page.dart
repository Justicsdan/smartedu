import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/providers/teacher/teacher_provider.dart';

class TeacherCbtPage extends StatefulWidget {
  const TeacherCbtPage({super.key});

  @override
  State<TeacherCbtPage> createState() => _TeacherCbtPageState();
}

class _TeacherCbtPageState extends State<TeacherCbtPage> {
  final Set<String> _expandedExamIds = {};
  Map<String, List<Map<String, dynamic>>> _questions = {};

  TeacherProvider get _p => context.read<TeacherProvider>();

  Future<void> _loadQuestions(String examId) async {
    try {
      final q = await _p.loadQuestions(examId);
      if (mounted) setState(() => _questions[examId] = q);
    } catch (e) {
      debugPrint('Load questions error: $e');
    }
  }

  void _toggleExpand(String examId) {
    setState(() {
      if (_expandedExamIds.contains(examId)) {
        _expandedExamIds.remove(examId);
      } else {
        _expandedExamIds.add(examId);
        _loadQuestions(examId);
      }
    });
  }

  void _showAddQuestionDialog(String examId) {
    final qCtrl = TextEditingController();
    final optA = TextEditingController();
    final optB = TextEditingController();
    final optC = TextEditingController();
    final optD = TextEditingController();
    final explCtrl = TextEditingController();
    final marksCtrl = TextEditingController();
    String correctOpt = 'a';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Add Question'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: qCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Question Text *',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: optA,
                  decoration: const InputDecoration(
                    labelText: 'Option A *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: optB,
                  decoration: const InputDecoration(
                    labelText: 'Option B *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: optC,
                  decoration: const InputDecoration(
                    labelText: 'Option C *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: optD,
                  decoration: const InputDecoration(
                    labelText: 'Option D *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: correctOpt,
                  decoration: const InputDecoration(
                    labelText: 'Correct Answer *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'a', child: Text('A')),
                    DropdownMenuItem(value: 'b', child: Text('B')),
                    DropdownMenuItem(value: 'c', child: Text('C')),
                    DropdownMenuItem(value: 'd', child: Text('D')),
                  ],
                  onChanged: (v) => setSt(() => correctOpt = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: marksCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Marks *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: explCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Explanation (optional)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (qCtrl.text.trim().isEmpty) return;
                final marks = int.tryParse(marksCtrl.text.trim()) ?? 1;
                _p.addQuestion(
                  examId: examId,
                  questionText: qCtrl.text.trim(),
                  optionA: optA.text.trim(),
                  optionB: optB.text.trim(),
                  optionC: optC.text.trim(),
                  optionD: optD.text.trim(),
                  correctOption: correctOpt,
                  explanation: explCtrl.text.trim(),
                  marks: marks,
                ).then((ok) {
                  if (ok) {
                    Navigator.pop(ctx);
                    _loadQuestions(examId);
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Question'),
            ),
          ],
        ),
      ),
    );
  }

  static List<Map<String, dynamic>> _parsePastedQuestions(String text) {
    final results = <Map<String, dynamic>>[];
    final blocks = text.split(RegExp(r'\n\s*\n'));
    for (final block in blocks) {
      final lines = block
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();
      if (lines.isEmpty) continue;
      String? questionText;
      String? optA, optB, optC, optD;
      String correctOption = 'a';
      int marks = 1;
      for (final line in lines) {
        final trimmed = line.trim();
        final stripped = trimmed.replaceFirst(RegExp(r'[^a-zA-Z]+'), '');
        if (stripped.isNotEmpty) {
          final firstChar = stripped.substring(0, 1).toUpperCase();
          if (firstChar == 'A' ||
              firstChar == 'B' ||
              firstChar == 'C' ||
              firstChar == 'D') {
            final letter = firstChar.toLowerCase();
            final afterLetter = trimmed.replaceFirst(
              RegExp(r'[^a-zA-Z]*[a-d][^a-zA-Z0-9]*',
                  caseSensitive: false),
              '',
            );
            final value = afterLetter.trim();
            if (letter == 'a') optA = value;
            else if (letter == 'b') optB = value;
            else if (letter == 'c') optC = value;
            else if (letter == 'd') optD = value;
            continue;
          }
        }
        final ansMatch = RegExp(
          r'^(ans(?:wer)?\s*[\:\.]\s*)([a-d])',
          caseSensitive: false,
        ).firstMatch(trimmed);
        if (ansMatch != null) {
          correctOption = ansMatch.group(2)!.toLowerCase();
          continue;
        }
        final marksMatch = RegExp(
          r'^(marks?\s*[\:\.]\s*)(\d+)',
          caseSensitive: false,
        ).firstMatch(trimmed);
        if (marksMatch != null) {
          marks = int.tryParse(marksMatch.group(2)!) ?? 1;
          continue;
        }
        if (questionText == null) {
          questionText = trimmed.replaceFirst(RegExp(r'^\d+[\.\)\s]+'), '');
        } else {
          questionText = '$questionText $trimmed';
        }
      }
      if (questionText != null && questionText.isNotEmpty) {
        results.add({
          'question_text': questionText,
          'option_a': optA ?? '',
          'option_b': optB ?? '',
          'option_c': optC ?? '',
          'option_d': optD ?? '',
          'correct_option': correctOption,
          'marks': marks,
        });
      }
    }
    return results;
  }

  void _showBulkImportDialog(String examId) {
    int step = 0;
    final textCtrl = TextEditingController();
    List<Map<String, dynamic>> parsed = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(
            step == 0
                ? 'Bulk Import Questions'
                : 'Preview (${parsed.length} questions)',
          ),
          content: SizedBox(
            width: 520,
            child: step == 0
                ? SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Paste questions below. Separate each question with a blank line:',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'What is 2+2?\nA. 3\nB. 4\nC. 5\nD. 6\nAns: B\nMarks: 2\n\nCapital of Nigeria?\nA. Lagos\nB. Abuja\nC. Kano\nD. Ibadan\nAns: B',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: textCtrl,
                          maxLines: 14,
                          decoration: const InputDecoration(
                            labelText: 'Paste questions here',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${parsed.length} questions parsed.',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 320,
                        width: 480,
                        child: ListView.builder(
                          itemCount: parsed.length,
                          itemBuilder: (ctx, i) {
                            final q = parsed[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${i + 1}. ${q['question_text']}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'A. ${q['option_a'] ?? '-'}   B. ${q['option_b'] ?? '-'}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      'C. ${q['option_c'] ?? '-'}   D. ${q['option_d'] ?? '-'}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      'Answer: ${q['correct_option'].toString().toUpperCase()}  |  Marks: ${q['marks']}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF0D47A1),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
          actions: [
            if (step == 1)
              TextButton(
                onPressed: () => setSt(() => step = 0),
                child: const Text('Back'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            if (step == 0)
              ElevatedButton(
                onPressed: () {
                  final p = _parsePastedQuestions(textCtrl.text);
                  if (p.isEmpty) return;
                  setSt(() {
                    parsed = p;
                    step = 1;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Parse'),
              )
            else
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _p.bulkImportQuestions(examId, parsed).then((ok) {
                    if (ok) _loadQuestions(examId);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Import All'),
              ),
          ],
        ),
      ),
    );
  }

  String _correctOptionLabel(String? opt) {
    if (opt == null || opt.isEmpty) return '';
    return opt.toUpperCase();
  }

  Widget _optionChip(String label, String? val, String correctOpt) {
    final isSelected = val?.toLowerCase() == correctOpt.toLowerCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            isSelected ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF2E7D32)
              : Colors.grey.shade300,
        ),
      ),
      child: Text(
        val != null && val.isNotEmpty ? '$label: $val' : label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected
              ? const Color(0xFF2E7D32)
              : Colors.grey.shade700,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _p.loadMyCbtExams();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeacherProvider>();
    final exams = provider.myCbtExams;

    return Stack(
      children: [
        if (exams.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.quiz_outlined, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No CBT exams created yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to create one',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
            itemCount: exams.length,
            itemBuilder: (context, index) {
              final e = exams[index];
              final examId = e['id']?.toString() ?? '';
              final isActive = e['is_active'] == true;
              final isExpanded = _expandedExamIds.contains(examId);
              final questions = _questions[examId] ?? [];
              final subjectName = e['subjects'] is Map<String, dynamic>
                  ? (e['subjects'] as Map)['name']?.toString() ?? 'Unknown'
                  : 'Unknown';
              final className = e['classes'] is Map<String, dynamic>
                  ? (e['classes'] as Map)['name']?.toString() ?? ''
                  : '';
              final classSection = e['classes'] is Map<String, dynamic>
                  ? (e['classes'] as Map)['section']?.toString() ?? ''
                  : '';

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: isExpanded ? 0 : 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF4CAF50)
                            : Colors.grey.shade200,
                        width: isActive ? 2 : 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: () => _toggleExpand(examId),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.green.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.quiz,
                              color: isActive ? Colors.green : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e['title'] ?? 'CBT Exam',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B2A4A),
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$className${classSection.isNotEmpty ? ' $classSection' : ''} \u2022 $subjectName',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                if (e['duration_minutes'] != null)
                                  Text(
                                    '${e['duration_minutes']}min',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _p.toggleCbtExam(examId),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.green
                                    : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (questions.isNotEmpty) ...[
                            Text(
                              '${questions.length} Qs',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Icon(
                            isExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 20,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Colors.red,
                            ),
                            onPressed: () => _showDeleteConfirm(
                              examId,
                              e['title'],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                      child: Row(
                        children: [
                          Text(
                            'Questions (${questions.length})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B2A4A),
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () =>
                                _showBulkImportDialog(examId),
                            icon: const Icon(Icons.paste, size: 18),
                            label: const Text('Bulk Import'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF0D47A1),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 36,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _showAddQuestionDialog(examId),
                              icon: const Icon(
                                Icons.add,
                                color: Colors.white,
                              ),
                              label: const Text('Add Question'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF0D47A1),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (questions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.help_outline,
                                size: 48,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No questions yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Use "Bulk Import" to paste many questions at once',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...questions.asMap().entries.map((entry) {
                        final qi = entry.key;
                        final q = entry.value;
                        final qId = q['id']?.toString() ?? '';
                        final correctOpt =
                            q['correct_option']?.toString() ?? '';
                        final marks =
                            (q['marks'] as num?)?.toInt() ?? 1;
                        return Container(
                          margin:
                              const EdgeInsets.fromLTRB(24, 0, 24, 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.grey.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color:
                                          const Color(0xFF0D47A1),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${qi + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      q['question_text'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF1B2A4A),
                                      ),
                                      maxLines: 3,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Colors.red.shade400,
                                    ),
                                    onPressed: () =>
                                        _showDeleteQuestionConfirm(
                                      qId,
                                      examId,
                                      q['question_text'],
                                    ),
                                    constraints:
                                        const BoxConstraints(
                                            minWidth: 32,
                                            minHeight: 32),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _optionChip(
                                    'A',
                                    q['option_a']?.toString(),
                                    correctOpt,
                                  ),
                                  _optionChip(
                                    'B',
                                    q['option_b']?.toString(),
                                    correctOpt,
                                  ),
                                  _optionChip(
                                    'C',
                                    q['option_c']?.toString(),
                                    correctOpt,
                                  ),
                                  _optionChip(
                                    'D',
                                    q['option_d']?.toString(),
                                    correctOpt,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          const Color(0xFFF0F4FF),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Ans: ${_correctOptionLabel(correctOpt)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0D47A1),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          const Color(0xFFE8F5E9),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '$marks marks',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ],
              );
            },
          ),
        Positioned(
          bottom: 30,
          right: 30,
          child: FloatingActionButton.extended(
            onPressed: () => _showAddExamDialog(),
            backgroundColor: const Color(0xFF0D47A1),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Create CBT',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddExamDialog() {
    final provider = context.read<TeacherProvider>();
    final assignments = provider.mySubjectAssignments;
    if (assignments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No subject assignments found. Contact your admin.',
          ),
        ),
      );
      return;
    }

    final titleCtrl = TextEditingController();
    final durCtrl = TextEditingController(text: '60');
    final tqCtrl = TextEditingController(text: '50');
    String? selectedAssignmentId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSt) => AlertDialog(
          title: const Text('Create CBT Exam'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Exam Title *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedAssignmentId,
                  decoration: const InputDecoration(
                    labelText: 'Class & Subject *',
                    border: OutlineInputBorder(),
                  ),
                  items: assignments.map((a) {
                    final subj =
                        a['subjects'] as Map<String, dynamic>? ?? {};
                    final cls =
                        a['classes'] as Map<String, dynamic>? ?? {};
                    final label =
                        '${cls['name'] ?? ''} ${cls['section'] ?? ''} \u2022 ${subj['name'] ?? ''}'
                            .trim();
                    return DropdownMenuItem(
                      value: a['id']?.toString(),
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) =>
                      setSt(() => selectedAssignmentId = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: durCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Duration (min)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: tqCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Total Questions',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty ||
                    selectedAssignmentId == null) return;
                final assignment = assignments.firstWhere(
                  (a) =>
                      a['id']?.toString() == selectedAssignmentId,
                  orElse: () => {},
                );
                if (assignment.isEmpty) return;
                final classId =
                    assignment['class_id']?.toString() ?? '';
                final subjectId =
                    assignment['subject_id']?.toString() ?? '';
                final dur =
                    int.tryParse(durCtrl.text.trim()) ?? 60;
                final tq =
                    int.tryParse(tqCtrl.text.trim()) ?? 50;
                _p.createCbtExam(
                  title: titleCtrl.text.trim(),
                  subjectId: subjectId,
                  classId: classId,
                  durationMinutes: dur,
                  totalQuestions: tq,
                ).then((_) {
                  Navigator.pop(ctx);
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(String id, String? title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red, size: 24),
            SizedBox(width: 10),
            Text('Delete Exam'),
          ],
        ),
        content: Text(
          'Delete "${title ?? 'this exam'}"? This will also delete all its questions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _p.deleteCbtExam(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteQuestionConfirm(
    String qId,
    String examId,
    String? questionText,
  ) {
    final preview = questionText != null && questionText.length > 50
        ? '${questionText.substring(0, 50)}...'
        : questionText ?? 'this question';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red, size: 24),
            SizedBox(width: 10),
            Text('Delete Question'),
          ],
        ),
        content: Text('Delete "$preview"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _p.deleteQuestion(qId).then((ok) {
                if (ok) _loadQuestions(examId);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
