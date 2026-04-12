import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_base.dart';

/// Student CBT mixin.
/// Handles CBT exam taking for the logged-in student.
///
/// MASTER PLAN:
/// - Questions loaded via Postgres RPC function (RLS blocks direct reads for security)
/// - Time window enforcement — student can only start exam between start_time and end_time
/// - Shuffle controlled by exam.shuffle_questions setting
/// - Double submission prevented by is_submitted check
/// - All queries scoped by schoolId + studentId
/// - Student cannot see correct answers (RPC strips them out)
/// - [FIX] Renamed class to StudentCbtMixin to match student_provider.dart import
/// - [FIX] Postgrest v2 RPC strictly requires named `params:` argument

mixin StudentCbtMixin on StudentBase {

  // ==========================================
  // EXAM AVAILABILITY CHECKS
  // ==========================================

  /// Check if an exam is currently available for the student to take.
  Future<Map<String, dynamic>> checkExamAvailability(String examId) async {
    if (examId.isEmpty) return {'available': false, 'reason': 'Invalid exam ID'};

    try {
      final exam = await supabase
          .from('cbt_exams')
          .select('''
            id, title, duration_minutes, total_questions, pass_mark,
            is_active, start_time, end_time, shuffle_questions,
            show_result_immediately
          ''')
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

  /// Get available CBT exams for student's class.
  Future<List<Map<String, dynamic>>> getAvailableCbtExams() async {
    if (classId.isEmpty) return [];

    try {
      final allExams = await supabase
          .from('cbt_exams')
          .select('''
            id, title, subject_id, class_id, duration_minutes, total_questions,
            pass_mark, is_active, start_time, end_time, instructions,
            show_result_immediately, shuffle_questions, created_at,
            subjects(name, code)
          ''')
          .eq('school_id', schoolId)
          .eq('class_id', classId)
          .eq('is_active', true);

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

  /// Get exam details by ID.
  Future<Map<String, dynamic>?> getExamDetails(String examId) async {
    if (examId.isEmpty) return null;
    try {
      return await supabase
          .from('cbt_exams')
          .select('''
            id, title, subject_id, class_id, duration_minutes, total_questions,
            pass_mark, is_active, start_time, end_time, instructions,
            shuffle_questions, show_result_immediately, created_by
          ''')
          .eq('id', examId)
          .maybeSingle();
    } catch (e) {
      debugPrint('Error fetching exam details: $e');
      return null;
    }
  }

  // ==========================================
  // QUESTIONS LOADING
  // ==========================================

  /// Load questions for an exam via secure RPC.
  /// [FIX] Postgrest v2 requires `params:` named argument for RPC calls.
  Future<List<Map<String, dynamic>>> getCbtExamQuestions(String examId) async {
    if (examId.isEmpty) return [];

    try {
      final response = await supabase.rpc('get_cbt_questions', params: {
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
      debugPrint('Error loading CBT questions via RPC: $e');
      return [];
    }
  }

  /// Fallback: load questions directly (only works if RLS is adjusted).
  Future<List<Map<String, dynamic>>> _loadQuestionsDirect(String examId) async {
    try {
      final r = await supabase
          .from('cbt_questions')
          .select('id, question_text, option_a, option_b, option_c, option_d, marks, question_order, image_url')
          .eq('school_id', schoolId)
          .eq('exam_id', examId)
          .order('question_order', ascending: true);

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

  // ==========================================
  // EXAM SUBMISSION
  // ==========================================

  /// Submit CBT exam answers.
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

      if (exam['end_time'] != null) {
        if (DateTime.now().isAfter(DateTime.parse(exam['end_time']))) {
          return {'error': 'time_expired', 'message': 'Time is up! Your answers have been auto-submitted.'};
        }
      }

      // [FIX] Postgrest v2 requires `params:` named argument for RPC calls.
      final response = await supabase.rpc('score_cbt_attempt', params: {
        'p_exam_id': examId,
        'p_student_id': studentId,
        'p_answers': answers,
        'p_time_started': timeStarted?.toIso8601String(),
        'p_ip_address': '',
      });

      if (response == null) return null;

      Map<String, dynamic> result = {};
      if (response is Map) {
        final data = response['data'] ?? response;
        if (data is Map) {
          result = Map<String, dynamic>.from(data);
        }
      } else if (response is List && response.isNotEmpty) {
        result = Map<String, dynamic>.from(response.first as Map);
      }

      return result.isEmpty ? null : result;
    } catch (e) {
      debugPrint('Error submitting CBT: $e');
      return null;
    }
  }

  /// Check if student already attempted an exam.
  Future<bool> hasAttemptedExam(String examId) async {
    if (examId.isEmpty) return false;
    try {
      final r = await supabase.from('cbt_attempts').select('id')
          .eq('school_id', schoolId).eq('exam_id', examId).eq('student_id', studentId).maybeSingle();
      return r != null;
    } catch (_) {
      return false;
    }
  }

  /// Get previous attempt for an exam (for review if show_result_immediately is true).
  Future<Map<String, dynamic>?> getPreviousAttempt(String examId) async {
    try {
      return await supabase.from('cbt_attempts').select('''
            id, score, total_marks, time_started, time_submitted,
            is_submitted, created_at
          ''')
          .eq('school_id', schoolId).eq('exam_id', examId).eq('student_id', studentId).maybeSingle();
    } catch (_) {
      return null;
    }
  }

  /// Get all CBT attempts for the student (for history).
  Future<List<Map<String, dynamic>>> getMyCbtHistory() async {
    if (schoolId.isEmpty || studentId.isEmpty) return [];
    try {
      return List<Map<String, dynamic>>.from(
        await supabase.from('cbt_attempts').select('''
              id, exam_id, score, total_marks, time_started, time_submitted,
              is_submitted, created_at,
              cbt_exams(title, subject_id, class_id, duration_minutes, pass_mark)
            ''')
            .eq('school_id', schoolId).eq('student_id', studentId).order('created_at', ascending: false),
      );
    } catch (e) {
      debugPrint('Error loading CBT history: $e');
      return [];
    }
  }

  // ==========================================
  // EXAM TIMER
  // ==========================================

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
