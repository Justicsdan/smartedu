import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/providers/student/student_provider.dart';

class StudentCbtExamPage extends StatefulWidget {
  final Map<String, dynamic> exam;

  const StudentCbtExamPage({super.key, required this.exam});

  @override
  State<StudentCbtExamPage> createState() => _StudentCbtExamPageState();
}

class _StudentCbtExamPageState extends State<StudentCbtExamPage> {
  List<Map<String, dynamic>> _questions = [];
  final Map<String, String> _answers = {};
  int _currentIndex = 0;
  bool _loading = true;
  bool _submitting = false;
  bool _submitted = false;
  Map<String, dynamic>? _result;
  String? _error;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _showNavGrid = false;
  DateTime? _startTime;

  StudentProvider get _p => context.read<StudentProvider>();

  @override
  void initState() {
    super.initState();
    _startExam();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _p.stopExamTimer();
    super.dispose();
  }

  Future<void> _startExam() async {
    final examId = widget.exam['id']?.toString() ?? '';

    final check = await _p.checkExamAvailability(examId);
    if (check['available'] != true) {
      if (mounted) {
        setState(() {
          _error = check['reason']?.toString() ?? 'Exam not available';
          _loading = false;
        });
      }
      return;
    }

    _startTime = DateTime.now();
    final duration = (widget.exam['duration_minutes'] as num?)?.toInt() ?? 60;
    _p.startExamTimer(durationMinutes: duration);
    if (mounted) {
      setState(() {
        _remainingSeconds = duration * 60;
      });
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = _p.getRemainingSeconds();
      setState(() {
        _remainingSeconds = remaining;
      });
      if (remaining <= 0) {
        _timer?.cancel();
        _autoSubmit();
      }
    });

    final questions = await _p.getCbtExamQuestions(examId);
    if (mounted) {
      setState(() {
        _questions = questions;
        _loading = false;
      });
    }
  }

  Future<void> _autoSubmit() async {
    if (_submitted || _submitting) return;
    if (_answers.isNotEmpty) {
      await _submitExam(autoSubmitted: true);
    } else {
      if (mounted) {
        setState(() {
          _submitted = true;
          _error = 'Time expired with no answers submitted.';
        });
      }
    }
  }

  Future<void> _submitExam({bool autoSubmitted = false}) async {
    if (_submitting || _submitted) return;
    setState(() {
      _submitting = true;
    });

    final examId = widget.exam['id']?.toString() ?? '';
    final result = await _p.submitCbtExam(
      examId: examId,
      answers: _answers,
      timeStarted: _startTime,
    );

    _timer?.cancel();
    _p.stopExamTimer();

    if (mounted) {
      setState(() {
        _submitting = false;
        _submitted = true;
        _result = result;
      });
    }
  }

  String _formatTime(int totalSeconds) {
    if (totalSeconds <= 0) return "00:00";
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _selectOption(String questionId, String option) {
    if (_submitted) return;
    setState(() {
      _answers[questionId] = option;
    });
  }

  void _goToQuestion(int index) {
    if (index < 0 || index >= _questions.length) return;
    setState(() {
      _currentIndex = index;
      _showNavGrid = false;
    });
  }

  int get _answeredCount => _answers.length;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading exam...',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null && !_submitted) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_submitted) return _buildResultScreen();

    return WillPopScope(
      onWillPop: () async {
        final leave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Leave Exam?'),
            content: const Text(
              'Your progress will be lost if you leave.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Stay'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Leave'),
              ),
            ],
          ),
        );
        return leave ?? false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(child: _buildQuestionArea()),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final isLow = _remainingSeconds > 0 && _remainingSeconds <= 60;
    final isExpired = _remainingSeconds <= 0;
    final timerColor = isExpired
        ? Colors.red
        : isLow
            ? Colors.orange
            : const Color(0xFF1B2A4A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: timerColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 18,
                  color: timerColor,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatTime(_remainingSeconds),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: timerColor,
                    fontFeatures: const [
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            'Question ${_currentIndex + 1} of ${_questions.length}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B2A4A),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '$_answeredCount answered',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionArea() {
    if (_questions.isEmpty) {
      return Center(
        child: Text(
          'No questions found for this exam.',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    final q = _questions[_currentIndex];
    final qId = q['id']?.toString() ?? '';
    final selectedOpt = _answers[qId] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q['question_text'] ?? '',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B2A4A),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          if (q['marks'] != null)
            Text(
              '${q['marks']} mark${(q['marks'] as int) > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          const SizedBox(height: 24),
          _buildOptionCard('A', q['option_a']?.toString() ?? '', qId, selectedOpt),
          const SizedBox(height: 12),
          _buildOptionCard('B', q['option_b']?.toString() ?? '', qId, selectedOpt),
          const SizedBox(height: 12),
          _buildOptionCard('C', q['option_c']?.toString() ?? '', qId, selectedOpt),
          const SizedBox(height: 12),
          _buildOptionCard('D', q['option_d']?.toString() ?? '', qId, selectedOpt),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    String label,
    String value,
    String questionId,
    String selectedOpt,
  ) {
    final isSelected = selectedOpt.toLowerCase() == label.toLowerCase();
    final hasValue = value.isNotEmpty;

    return InkWell(
      onTap: hasValue
          ? () => _selectOption(questionId, label.toLowerCase())
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0D47A1).withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0D47A1)
                : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0D47A1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                hasValue ? value : '$label - (no option provided)',
                style: TextStyle(
                  fontSize: 15,
                  color: hasValue
                      ? const Color(0xFF1B2A4A)
                      : Colors.grey.shade400,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF0D47A1),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showNavGrid) _buildNavGrid(),
          Row(
            children: [
              TextButton.icon(
                onPressed: _currentIndex > 0
                    ? () => _goToQuestion(_currentIndex - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
                label: const Text('Prev'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0D47A1),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showNavGrid = !_showNavGrid;
                  });
                },
                icon: const Icon(Icons.grid_view, size: 18),
                label: Text('$_answeredCount/${_questions.length}'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _submitting ? null : () => _showSubmitConfirm(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _currentIndex < _questions.length - 1
                    ? () => _goToQuestion(_currentIndex + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
                label: const Text('Next'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0D47A1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavGrid() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(_questions.length, (i) {
          final q = _questions[i];
          final qId = q['id']?.toString() ?? '';
          final isAnswered = _answers.containsKey(qId);
          final isCurrent = i == _currentIndex;

          return InkWell(
            onTap: () => _goToQuestion(i),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCurrent
                    ? const Color(0xFF0D47A1)
                    : isAnswered
                        ? const Color(0xFF2E7D32)
                        : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCurrent
                      ? const Color(0xFF0D47A1)
                      : isAnswered
                          ? const Color(0xFF2E7D32)
                          : Colors.grey.shade300,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isCurrent || isAnswered
                      ? Colors.white
                      : Colors.grey.shade600,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _showSubmitConfirm() {
    final unanswered = _questions.length - _answeredCount;
    final warning = unanswered > 0
        ? '\n\nYou have $unanswered unanswered question${unanswered > 1 ? 's' : ''}.'
        : '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Submit Exam?'),
        content: Text(
          'Are you sure you want to submit?$warning',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitExam();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    final isError = _result != null && _result!.containsKey('error');
    final score = _result?['score'] as num?;
    final total = _result?['total_marks'] as num?;
    final percentage = (score != null && total != null && total > 0)
        ? ((score / total) * 100).toStringAsFixed(1)
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isError)
                Icon(
                  Icons.error_outline,
                  size: 72,
                  color: Colors.orange.shade300,
                )
              else if (percentage != null &&
                  double.parse(percentage) >= 50)
                const Icon(
                  Icons.check_circle_outline,
                  size: 72,
                  color: Color(0xFF2E7D32),
                )
              else
                Icon(
                  Icons.sentiment_neutral,
                  size: 72,
                  color: Colors.orange.shade300,
                ),
              const SizedBox(height: 20),
              Text(
                isError
                    ? (_result?['message'] ?? 'Submission failed').toString()
                    : 'Exam Submitted!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2A4A),
                ),
              ),
              if (!isError && score != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$score / $total',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                      if (percentage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '$percentage%',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        '$_answeredCount of ${_questions.length} questions answered',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                ),
                child: const Text('Back to Exams'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
