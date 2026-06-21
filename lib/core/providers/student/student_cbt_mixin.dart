import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:smartedu/core/services/db_proxy.dart';
import 'student_base.dart';

mixin StudentCbtMixin on StudentBase {

  List<Map<String, dynamic>> _cbtExams = [];
  List<Map<String, dynamic>> get cbtExams => _cbtExams;

  @override
  Future<void> loadStudentData() async {
    await super.loadStudentData();
    await _loadCbtExams();
  }

  Future<void> _loadCbtExams() async {
    try {
      final raw = await getAvailableCbtExams();
      _cbtExams = raw.map((e) {
        final subjects = e['subjects'] as Map<String, dynamic>? ?? {};
        return {
          'id': e['id'],
          'title': e['title'],
          'isActive': e['is_active'] == true,
          'duration': e['duration_minutes'],
          'className': className,
          'subjectName': subjects['name']?.toString() ?? '',
          'totalQuestions': e['total_questions'],
          'passMark': e['pass_mark'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error loading CBT exams: \$e');
      _cbtExams = [];
    }
  }


  Future<Map<String, dynamic>> checkExamAvailability(String examId) async {
    if (examId.isEmpty) return {'available': false, 'reason': 'Invalid exam ID'};

    try {
      final exam = await DbProxy.instance
          .from('cbt_exams')
          .select('id, title, duration_minutes, total_questions, pass_mark, is_active, start_time, end_time, shuffle_questions, show_result_immediately')
          .eq('id', examId)
          .maybeSingle();

      if (exam == null) return {'available': false, 'reason': 'Exam not found'};
      if (exam['is_active'] != true) return {'available': false, 'reason': 'This exam is not currently active'};

      if (exam['start_time'] != null) {
        if (DateTime.now().isBefore(DateTime.parse(exam['start_time']))) {
          return {'available': false, 'reason': 'Exam has not started yet'};
        }
      }
      if (exam['end_time'] != null) {
        if (DateTime.now().isAfter(DateTime.parse(exam['end_time']))) {
          return {'available': false, 'reason': 'Exam has ended'};
        }
      }

      if (await hasAttemptedExam(examId)) {
        return {'available': false, 'reason': 'You have already submitted this exam'};
      }

      return {'available': true, 'reason': '', 'exam': exam};
    } catch (e) {
      debugPrint('Error checking exam availability: $e');
      return {'available': false, 'reason': 'Failed to check exam availability'};
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableCbtExams() async {
    if (classId.isEmpty) return [];

    try {
      final allExams = await DbProxy.instance
          .from('cbt_exams')
          .select('id, title, subject_id, class_id, duration_minutes, total_questions, pass_mark, is_active, start_time, end_time, instructions, show_result_immediately, shuffle_questions, created_at, subjects(name, code)')
          .eq('class_id', classId)
          .eq('is_active', true)
          .get();

      final now = DateTime.now();
      final available = allExams.where((exam) {
        if (exam['is_active'] != true) return false;
        if (exam['start_time'] != null) {
          final start = DateTime.tryParse(exam['start_time']);
          if (start != null && now.isBefore(start)) return false;
        }
        if (exam['end_time'] != null) {
          final end = DateTime.tryParse(exam['end_time']);
          if (end != null && now.isAfter(end)) return false;
        }
        return true;
      }).toList();

      available.sort((a, b) {
        final aDate = a['created_at'] as String? ?? '';
        final bDate = b['created_at'] as String? ?? '';
        return bDate.compareTo(aDate);
      });

      return available;
    } catch (e) {
      debugPrint('Error fetching available CBT exams: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getExamDetails(String examId) async {
    if (examId.isEmpty) return null;
    try {
      return await DbProxy.instance
          .from('cbt_exams')
          .select('id, title, subject_id, class_id, duration_minutes, total_questions, pass_mark, is_active, start_time, end_time, instructions, shuffle_questions, show_result_immediately, created_by')
          .eq('id', examId)
          .maybeSingle();
    } catch (e) {
      debugPrint('Error fetching exam details: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getCbtExamQuestions(String examId) async {
    if (examId.isEmpty) return [];

    try {
      final response = await DbProxy.instance.rpc('get_cbt_questions', params: {
        'p_exam_id': examId,
        'p_student_id': studentId,
      });

      if (response == null) return [];

      List<Map<String, dynamic>> questions = [];

      if (response is List) {
        questions = response.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else if (response is Map) {
        final data = response['data'];
        if (data is List) {
          questions = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }

      final exam = await getExamDetails(examId);
      if (exam != null && exam['shuffle_questions'] == true) {
        questions.shuffle();
      }

      return questions;
    } catch (e) {
      debugPrint('Error loading CBT questions via RPC, falling back to direct: $e');
      return await _loadQuestionsDirect(examId);
    }
  }

  Future<List<Map<String, dynamic>>> _loadQuestionsDirect(String examId) async {
    try {
      final r = await DbProxy.instance
          .from('cbt_questions')
          .select('id, question_text, option_a, option_b, option_c, option_d, marks, question_order, image_url')
          .eq('exam_id', examId)
          .order('question_order', ascending: true)
          .get();

      final questions = List<Map<String, dynamic>>.from(r);

      final exam = await getExamDetails(examId);
      if (exam != null && exam['shuffle_questions'] == true) {
        questions.shuffle();
      }

      return questions;
    } catch (e) {
      debugPrint('Error loading questions directly: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> submitCbtExam({
    required String examId,
    required Map<String, String> answers,
    DateTime? timeStarted,
  }) async {
    if (examId.isEmpty || answers.isEmpty) return null;

    try {
      if (await hasAttemptedExam(examId)) {
        return {'error': 'already_submitted', 'message': 'You have already submitted this exam.'};
      }

      final exam = await getExamDetails(examId);
      if (exam == null) return null;
      if (exam['is_active'] != true) {
        return {'error': 'exam_inactive', 'message': 'This exam is no longer active.'};
      }

      final questions = await _loadQuestionsDirect(examId);
      int score = 0;
      int totalMarks = 0;
      for (final q in questions) {
        final qId = q['id'].toString();
        final correct = (q['correct_option'] as String?) ?? '';
        final marks = (q['marks'] as num?)?.toInt() ?? 1;
        totalMarks += marks;
        final submitted = answers[qId] ?? '';
        if (submitted.toLowerCase() == correct.toLowerCase()) {
          score += marks;
        }
      }

      final now = DateTime.now().toUtc().toIso8601String();
      final startStr = timeStarted?.toUtc().toIso8601String() ?? now;

      await DbProxy.instance.from('cbt_attempts').insert({
        'school_id': schoolId,
        'exam_id': examId,
        'student_id': studentId,
        'attempt_number': 1,
        'answers': answers,
        'score': score,
        'total_marks': totalMarks,
        'time_started': startStr,
        'time_submitted': now,
        'is_submitted': true,
        'ip_address': '',
      });

      return {
        'score': score,
        'total_marks': totalMarks,
        'total_questions': questions.length,
        'correct': answers.entries.where((e) {
          final q = questions.firstWhere((q) => q['id'].toString() == e.key, orElse: () => {});
          return (e.value.toLowerCase() == ((q['correct_option'] as String?) ?? '').toLowerCase());
        }).length,
      };
    } catch (e) {
      debugPrint('Error submitting CBT: $e');
      return null;
    }
  }


  Future<bool> hasAttemptedExam(String examId) async {
    if (examId.isEmpty) return false;
    try {
      final r = await DbProxy.instance
          .from('cbt_attempts')
          .select('id')
          .eq('exam_id', examId)
          .eq('student_id', studentId)
          .maybeSingle();
      return r != null;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getPreviousAttempt(String examId) async {
    try {
      return await DbProxy.instance
          .from('cbt_attempts')
          .select('id, score, total_marks, time_started, time_submitted, is_submitted, created_at')
          .eq('exam_id', examId)
          .eq('student_id', studentId)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getMyCbtHistory() async {
    if (schoolId.isEmpty || studentId.isEmpty) return [];
    try {
      return List<Map<String, dynamic>>.from(
        await DbProxy.instance
            .from('cbt_attempts')
            .select('id, exam_id, score, total_marks, time_started, time_submitted, is_submitted, created_at, cbt_exams(title, subject_id, class_id, duration_minutes, pass_mark)')
            .eq('student_id', studentId)
            .order('created_at', ascending: false)
            .get(),
      );
    } catch (e) {
      debugPrint('Error loading CBT history: $e');
      return [];
    }
  }

  DateTime? _examStartTime;
  int _cachedExamDurationMinutes = 60;

  void startExamTimer({required int durationMinutes}) {
    _examStartTime = DateTime.now();
    _cachedExamDurationMinutes = durationMinutes;
  }

  int getRemainingSeconds() {
    if (_examStartTime == null) return 0;
    final endTime = _examStartTime!.add(Duration(minutes: _cachedExamDurationMinutes));
    final remaining = endTime.difference(DateTime.now()).inSeconds;
    return remaining < 0 ? 0 : remaining;
  }

  String getFormattedRemainingTime() {
    final seconds = getRemainingSeconds();
    if (seconds <= 0) return "Time's up!";
    if (seconds >= 3600) {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      final secs = seconds % 60;
      return '${hours}h ${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  bool isTimeRunningOut() {
    final remaining = getRemainingSeconds();
    return remaining > 0 && remaining <= 60;
  }

  bool isTimeExpired() => getRemainingSeconds() == 0;

  void stopExamTimer() {
    _examStartTime = null;
  }

  void clearCbtData() {
    _examStartTime = null;
    _cachedExamDurationMinutes = 60;
  }
}
