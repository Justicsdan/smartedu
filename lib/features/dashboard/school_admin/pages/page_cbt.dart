import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:smartedu/core/providers/school_admin_provider.dart";

class PageCbt extends StatefulWidget {
  final List<Map<String, dynamic>> classes, subjects;
  final void Function(Map<String, dynamic>) onAdd;
  final void Function(String) onToggle;
  final void Function(String) onDelete;

  const PageCbt({
    super.key,
    required this.classes,
    required this.subjects,
    required this.onAdd,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  State<PageCbt> createState() => _PageCbtState();
}

class _PageCbtState extends State<PageCbt> {
  final Set<String> _expandedExamIds = {};
  Map<String, List<Map<String, dynamic>>> _questions = {};

  SchoolAdminProvider get _p => context.read<SchoolAdminProvider>();

  Future<void> _loadQuestions(String examId) async {
    try {
      final q = await _p.loadCbtQuestions(examId);
      if (mounted) setState(() => _questions[examId] = q);
    } catch (e) {
      debugPrint("Load questions error: $e");
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
    String correctOpt = "a";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text("Add Question"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: qCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Question Text *",
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: optA,
                  decoration: const InputDecoration(
                    labelText: "Option A *",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: optB,
                  decoration: const InputDecoration(
                    labelText: "Option B *",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: optC,
                  decoration: const InputDecoration(
                    labelText: "Option C *",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: optD,
                  decoration: const InputDecoration(
                    labelText: "Option D *",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: correctOpt,
                  decoration: const InputDecoration(
                    labelText: "Correct Answer *",
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: "a", child: Text("A")),
                    DropdownMenuItem(value: "b", child: Text("B")),
                    DropdownMenuItem(value: "c", child: Text("C")),
                    DropdownMenuItem(value: "d", child: Text("D")),
                  ],
                  onChanged: (v) => setSt(() => correctOpt = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: marksCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Marks *",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: explCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: "Explanation (optional)",
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
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (qCtrl.text.trim().isEmpty) return;
                final marks = int.tryParse(marksCtrl.text.trim()) ?? 1;
                _p.addCbtQuestion(
                  examId: examId,
                  questionText: qCtrl.text.trim(),
                  optionA: optA.text.trim(),
                  optionB: optB.text.trim(),
                  optionC: optC.text.trim(),
                  optionD: optD.text.trim(),
                  correctOption: correctOpt,
                  explanation: explCtrl.text.trim(),
                  marks: marks,
                ).then((_) {
                  Navigator.pop(ctx);
                  _loadQuestions(examId);
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
              ),
              child: const Text("Add Question"),
            ),
          ],
        ),
      ),
    );
  }

  static List<Map<String, dynamic>> _parsePastedQuestions(String text) {
    final results = <Map<String, dynamic>>[];
    final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n').where((l) => l.trim().isNotEmpty).toList();
    String? questionText;
    String? optA, optB, optC, optD;
    String correctOption = 'a';
    void saveCurrent() {
      if (questionText != null && questionText!.isNotEmpty) {
        results.add({
          'question_text': questionText,
          'option_a': optA ?? '',
          'option_b': optB ?? '',
          'option_c': optC ?? '',
          'option_d': optD ?? '',
          'correct_option': correctOption,
          'marks': 0,
        });
      }
      questionText = null;
      optA = optB = optC = optD = null;
      correctOption = 'a';
    }
    for (final line in lines) {
      final trimmed = line.trim();
      final upper = trimmed.toUpperCase();
      if (upper.startsWith('A.') || upper.startsWith('A)')) { optA = trimmed.substring(2).trim(); continue; }
      if (upper.startsWith('B.') || upper.startsWith('B)')) { optB = trimmed.substring(2).trim(); continue; }
      if (upper.startsWith('C.') || upper.startsWith('C)')) { optC = trimmed.substring(2).trim(); continue; }
      if (upper.startsWith('D.') || upper.startsWith('D)')) { optD = trimmed.substring(2).trim(); continue; }
      if (upper.startsWith('ANS')) {
        for (int i = 0; i < trimmed.length; i++) {
          final ch = trimmed[i].toUpperCase();
          if (ch == 'A' || ch == 'B' || ch == 'C' || ch == 'D') { correctOption = ch.toLowerCase(); break; }
        }
        saveCurrent();
        continue;
      }
      String qPart = trimmed;
      if (qPart.isNotEmpty && qPart.codeUnitAt(0) >= 48 && qPart.codeUnitAt(0) <= 57) {
        qPart = qPart.replaceFirst(RegExp(r'^\d+[.)\s]+'), '');
      }
      if (questionText == null) { questionText = qPart; } else { questionText = questionText! + ' ' + qPart; }
    }
    saveCurrent();
    return results;
  }

  void _showBulkImportDialog(String examId) {
    int step = 0;
    final textCtrl = TextEditingController();
    final marksCtrl = TextEditingController(text: '2');
    List<Map<String, dynamic>> parsed = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(
            step == 0
                ? "Bulk Import Questions"
                : "Preview (" + parsed.length.toString() + " questions)",
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
                          "Paste questions below. Separate each question with a blank line.",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: marksCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "Marks per question *",
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "What is 2+2?\nA. 3\nB. 4\nC. 5\nD. 6\nAns: B\n\nCapital of Nigeria?\nA. Lagos\nB. Abuja\nC. Kano\nD. Ibadan\nAns: B",
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: "monospace",
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: textCtrl,
                          maxLines: 12,
                          decoration: const InputDecoration(
                            labelText: "Paste questions here",
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
                        parsed.length.toString() +
                            " questions parsed. Each worth " +
                            marksCtrl.text.trim() +
                            " marks.",
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
                            final aText = "A. " + (q["option_a"] ?? "-");
                            final bText = "B. " + (q["option_b"] ?? "-");
                            final cText = "C. " + (q["option_c"] ?? "-");
                            final dText = "D. " + (q["option_d"] ?? "-");
                            final ansText =
                                "Answer: " +
                                (q["correct_option"] ?? "")
                                    .toString()
                                    .toUpperCase();
                            final marksText =
                                "  |  Marks: " + (q["marks"] ?? 1).toString();
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (i + 1).toString() +
                                          ". " +
                                          (q["question_text"] ?? ""),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      aText + "   " + bText,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      cText + "   " + dText,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      ansText + marksText,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF1A237E),
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
                child: const Text("Back"),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            if (step == 0)
              ElevatedButton(
                onPressed: () {
                  final marksVal =
                      int.tryParse(marksCtrl.text.trim()) ?? 1;
                  if (marksVal < 1) return;
                  final raw = textCtrl.text;
                  final p = _parsePastedQuestions(raw);
                  if (p.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text(
                        "No questions found. Use blank lines between questions.",
                      ),
                    ));
                    return;
                  }
                  for (final q in p) {
                    q['marks'] = marksVal;
                  }
                  setSt(() {
                    parsed = p;
                    step = 1;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                ),
                child: const Text("Parse"),
              )
            else
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _p.bulkImportCbtQuestions(examId, parsed).then(
                    (_) => _loadQuestions(examId),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
                child: const Text("Import All"),
              ),
          ],
        ),
      ),
    );
  }

  String _correctOptionLabel(String? opt) {
    if (opt == null || opt.isEmpty) return "";
    return opt.toUpperCase();
  }

  Widget _optionChip(String label, String? val, String correctOpt) {
    final isSelected = val?.toLowerCase() == correctOpt.toLowerCase();
    final displayText =
        (val != null && val.isNotEmpty) ? "$label: $val" : label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF2E7D32)
              : Colors.grey.shade300,
        ),
      ),
      child: Text(
        displayText,
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
  Widget build(BuildContext context) {
    final exams = context.watch<SchoolAdminProvider>().cbtExams;

    final Widget body;
    if (exams.isEmpty) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.quiz_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "No CBT exams created yet",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              "Tap the + button to create one",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        itemCount: exams.length,
        itemBuilder: (context, index) {
          final e = exams[index];
          final examId = e["id"]?.toString() ?? "";
          final isActive = e["is_active"] == true;
          final isExpanded = _expandedExamIds.contains(examId);
          final questions = _questions[examId] ?? [];
          final subjMap = e["subjects"] is Map<String, dynamic>
              ? e["subjects"] as Map<String, dynamic>
              : {};
          final clsMap = e["classes"] is Map<String, dynamic>
              ? e["classes"] as Map<String, dynamic>
              : {};
          final subjectName = subjMap["name"]?.toString() ?? "Unknown";
          final className = clsMap["name"]?.toString() ?? "";
          final classSection = clsMap["section"]?.toString() ?? "";
          final sec = classSection.isNotEmpty ? " $classSection" : "";
          final classLabel = className + sec;
          final durText = (e["duration_minutes"] ?? "").toString();
          final durShow =
              durText.isNotEmpty ? durText + "min" : null;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildExamCard(e, examId, isActive, isExpanded,
                  questions, subjectName, classLabel, durShow),
              if (isExpanded) ...[
                _buildQuestionsHeader(examId, questions),
                if (questions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.help_outline,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            "No questions yet",
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Use Bulk Import to paste many questions at once",
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...questions.asMap().entries.map((entry) {
                    final qi = entry.key;
                    final q = entry.value;
                    final qId = q["id"]?.toString() ?? "";
                    final correctOpt =
                        q["correct_option"]?.toString() ?? "";
                    final marks =
                        (q["marks"] as num?)?.toInt() ?? 1;
                    return _buildQuestionCard(
                        qi, q, qId, correctOpt, marks, examId);
                  }),
              ],
            ],
          );
        },
      );
    }

    return Stack(
      children: [
        body,
        Positioned(
          bottom: 30,
          right: 30,
          child: FloatingActionButton.extended(
            onPressed: () => _showAddExamDialog(),
            backgroundColor: const Color(0xFF1A237E),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              "Create CBT",
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

  Widget _buildExamCard(
    Map<String, dynamic> e,
    String examId,
    bool isActive,
    bool isExpanded,
    List<Map<String, dynamic>> questions,
    String subjectName,
    String classLabel,
    String? durShow,
  ) {
    return Container(
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
              child: Icon(Icons.quiz,
                  color: isActive ? Colors.green : Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e["title"] ?? "CBT Exam",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B2A4A),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$classLabel \u2022 $subjectName",
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                  if (durShow != null)
                    Text(
                      durShow,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => widget.onToggle(examId),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? "Active" : "Inactive",
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
                questions.length.toString() + " Qs",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 20,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: Colors.red),
              onPressed: () =>
                  _showDeleteConfirm(examId, e["title"]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsHeader(
      String examId, List<Map<String, dynamic>> questions) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Row(
        children: [
          Text(
            "Questions (" + questions.length.toString() + ")",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B2A4A),
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _showBulkImportDialog(examId),
            icon: const Icon(Icons.paste, size: 18),
            label: const Text("Bulk Import"),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1A237E),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: () => _showAddQuestionDialog(examId),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Add Question"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
    int qi,
    Map<String, dynamic> q,
    String qId,
    String correctOpt,
    int marks,
    String examId,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  (qi + 1).toString(),
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
                  q["question_text"] ?? "",
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF1B2A4A)),
                  maxLines: 3,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Colors.red),
                onPressed: () => _showDeleteQuestionConfirm(
                  qId,
                  examId,
                  q["question_text"],
                ),
                constraints: const BoxConstraints(
                    minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _optionChip("A", q["option_a"]?.toString(), correctOpt),
              _optionChip("B", q["option_b"]?.toString(), correctOpt),
              _optionChip("C", q["option_c"]?.toString(), correctOpt),
              _optionChip("D", q["option_d"]?.toString(), correctOpt),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "Ans: " + _correctOptionLabel(correctOpt),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  marks.toString() + " marks",
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
  }

  void _showAddExamDialog() {
    final titleCtrl = TextEditingController();
    String? classId, subjectId;
    final durCtrl = TextEditingController(text: '60');
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSt) => AlertDialog(
          title: const Text("Create CBT Exam"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: "Exam Title *",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: classId,
                decoration: const InputDecoration(
                  labelText: "Class *",
                  border: OutlineInputBorder(),
                ),
                items: widget.classes.map((c) {
                  final n = c["name"] ?? "";
                  final s = c["section"] ?? "";
                  return DropdownMenuItem(
                    value: c["id"].toString(),
                    child: Text(n + (s.isNotEmpty ? " " + s : "")),
                  );
                }).toList(),
                onChanged: (v) => setSt(() => classId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: subjectId,
                decoration: const InputDecoration(
                  labelText: "Subject *",
                  border: OutlineInputBorder(),
                ),
                items: widget.subjects.map((s) {
                  return DropdownMenuItem(
                    value: s["id"].toString(),
                    child: Text(s["name"] ?? ""),
                  );
                }).toList(),
                onChanged: (v) => setSt(() => subjectId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Duration (minutes)",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isNotEmpty &&
                    classId != null &&
                    subjectId != null) {
                  widget.onAdd({
                    "title": titleCtrl.text.trim(),
                    "classId": classId,
                    "subjectId": subjectId,
                    "duration":
                        int.tryParse(durCtrl.text.trim()) ?? 60,
                    "isActive": false,
                  });
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
              ),
              child: const Text("Create"),
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
            borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red, size: 24),
            SizedBox(width: 10),
            Text("Delete Exam"),
          ],
        ),
        content: Text(
          'Delete "' +
              (title ?? "this exam") +
              '"? This will also delete all its questions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDelete(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
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
        ? questionText.substring(0, 50) + "..."
        : questionText ?? "this question";
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red, size: 24),
            SizedBox(width: 10),
            Text("Delete Question"),
          ],
        ),
        content: Text('Delete "' + preview + '"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _p.deleteCbtQuestion(qId)
                  .then((_) => _loadQuestions(examId));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
