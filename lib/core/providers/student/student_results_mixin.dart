// ==========================================
// File: lib/core/providers/student/student_results_mixin.dart
// ==========================================
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_base.dart';

/// Student results mixin.
/// Provides score data and term summaries for the logged-in student.
/// All queries are scoped by schoolId + studentId + session + term.
///
/// MASTER PLAN:
/// - Scores joined with subjects for readable display (not just subject_id)
/// - Term summaries only loaded if is_published = true (RLS enforces this)
/// - Grades computed locally using school's grading system for consistency
/// - Position comes from pre-computed student_term_summaries table
/// - Student CANNOT see unpublished results

mixin StudentResultsMixin on StudentBase {

  // ==========================================
  // SCORES STATE
  // ==========================================
  List<Map<String, dynamic>> _myScores = [];

  /// Raw scores with nested subject data.
  List<Map<String, dynamic>> get myScores => _myScores;

  /// Flattened scores with subject name injected for easy UI binding.
  List<Map<String, dynamic>> get myScoresFlat {
    return _myScores.map((score) {
      final subject = score['subjects'] as Map<String, dynamic>?;
      return {
        ...score,
        'subject_name': subject?['name'] ?? '',
        'subject_code': subject?['code'] ?? '',
        'computed_grade': calculateGrade((score['total'] as num?)?.toDouble() ?? 0),
      };
    }).toList();
  }

  /// Dashboard stub (required by cross-mixin abstract getters).
  @override
  List<Map<String, dynamic>> get scores => _myScores;

  // ==========================================
  // TERM SUMMARY STATE
  // From student_term_summaries (only if is_published = true).
  // ==========================================
  Map<String, dynamic>? _myTermSummary;
  Map<String, dynamic>? get myTermSummary => _myTermSummary;

  /// Whether the student's results have been published by school admin.
  bool get areResultsPublished {
    if (_myTermSummary == null) return false;
    return _myTermSummary!['is_published'] == true;
  }

  /// Total score across all subjects this term.
  double get totalScore => (_myTermSummary?['total_score'] as num?)?.toDouble() ?? 0;

  /// Number of subjects with scores this term.
  int get subjectsTaken => (_myTermSummary?['subjects_taken'] as int?) ?? 0;

  /// Overall average score this term.
  double get termAverage => (_myTermSummary?['average_score'] as num?)?.toDouble() ?? 0;

  /// Student's position in class this term.
  int get termPosition => (_myTermSummary?['position'] as int?) ?? 0;

  /// Total students in class this term (for "X out of Y" display).
  int get positionOutOf => (_myTermSummary?['position_out_of'] as int?) ?? 0;

  /// Formatted position string: "3rd out of 45" or "—" if no position.
  String get positionDisplay {
    if (termPosition == 0 || positionOutOf == 0) return '—';
    return '${_ordinal(termPosition)} out of $positionOutOf';
  }

  /// Attendance days from term summary.
  int get daysPresent => (_myTermSummary?['days_present'] as int?) ?? 0;
  int get daysAbsent => (_myTermSummary?['days_absent'] as num?)?.toInt() ?? 0;

  /// Grade from term summary.
  String get termGrade => (_myTermSummary?['grade'] as String?) ?? '';

  // ==========================================
  // OVERALL AVERAGE (from scores — fallback if no summary)
  // ==========================================
  @override
  double getOverallAverage() {
    if (_myScores.isEmpty) return 0.0;
    double total = 0;
    for (final s in _myScores) {
      total += (s['total'] as num?)?.toDouble() ?? 0;
    }
    return total / _myScores.length;
  }

  /// Total score across all subjects (from scores — fallback).
  double get totalScoresSum {
    double total = 0;
    for (final s in _myScores) {
      total += (s['total'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  // ==========================================
  // AUTO-LOAD ON INITIALIZATION
  // Overrides StudentBase._loadStudentData() stub.
  // Called during initialize() and setCurrentTerm().
  // ==========================================
  @override
  Future<void> _loadStudentData() async {
    await loadAllResults();
  }

  // ==========================================
  // LOAD SCORES
  // Joins subjects table for subject names.
  // ==========================================
  Future<void> loadMyScores() async {
    if (currentSessionId == null || currentTermId == null) {
      _myScores = [];
      notifyListeners();
      return;
    }

    try {
      final response = await supabase
          .from('scores')
          .select('''
            id, scores_json, total, grade, position, position_out_of,
            recorded_by, created_at,
            subjects(name, code)
          ''')
          .eq('school_id', schoolId)
          .eq('student_id', studentId)
          .eq('session_id', currentSessionId!)
          .eq('term_id', currentTermId!);

      _myScores = List<Map<String, dynamic>>.from(response);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading student scores: $e');
      _myScores = [];
      notifyListeners();
    }
  }

  // ==========================================
  // LOAD TERM SUMMARY
  // Only loads if is_published = true (RLS enforces this).
  // ==========================================
  Future<void> loadMyTermSummary() async {
    if (currentSessionId == null || currentTermId == null) {
      _myTermSummary = null;
      notifyListeners();
      return;
    }

    try {
      final response = await supabase
          .from('student_term_summaries')
          .select()
          .eq('school_id', schoolId)
          .eq('student_id', studentId)
          .eq('session_id', currentSessionId!)
          .eq('term_id', currentTermId!)
          .eq('is_published', true)
          .maybeSingle();

      _myTermSummary = response != null ? Map<String, dynamic>.from(response) : null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading term summary: $e');
      _myTermSummary = null;
      notifyListeners();
    }
  }

  /// Load both scores and term summary in parallel.
  Future<void> loadAllResults() async {
    await Future.wait([
      loadMyScores(),
      loadMyTermSummary(),
    ]);
  }

  // ==========================================
  // SCORE HELPERS
  // ==========================================

  /// Get score for a specific subject by subject_id.
  Map<String, dynamic>? getScoreForSubject(String subjectId) {
    if (subjectId.isEmpty) return null;
    try {
      return _myScores.cast<Map<String, dynamic>?>().firstWhere(
        (s) => s?['subject_id']?.toString() == subjectId,
        orElse: () => null,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get score for a specific subject by subject name (case-insensitive).
  Map<String, dynamic>? getScoreBySubjectName(String subjectName) {
    if (subjectName.isEmpty) return null;
    final lowerName = subjectName.toLowerCase();
    try {
      return _myScores.cast<Map<String, dynamic>?>().firstWhere(
        (s) {
          final subj = s?['subjects'] as Map<String, dynamic>?;
          return subj?['name']?.toString().toLowerCase() == lowerName;
        },
        orElse: () => null,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get scores grouped by subject for display.
  List<Map<String, dynamic>> getScoresBySubject() {
    return myScoresFlat;
  }

  /// Get breakdown of assessment scores for a specific subject.
  Map<String, dynamic> getAssessmentBreakdown(String subjectId) {
    final score = getScoreForSubject(subjectId);
    if (score == null) return {};
    return (score['scores_json'] as Map<String, dynamic>?) ?? {};
  }

  /// Get total for a specific subject.
  double getSubjectTotal(String subjectId) {
    final score = getScoreForSubject(subjectId);
    return (score?['total'] as num?)?.toDouble() ?? 0;
  }

  /// Get grade for a specific subject using school grading system.
  String getSubjectGrade(String subjectId) {
    final total = getSubjectTotal(subjectId);
    return calculateGrade(total);
  }

  /// Get remark for a specific subject using school grading system.
  String getSubjectRemark(String subjectId) {
    final total = getSubjectTotal(subjectId);
    return getGradeRemark(total);
  }

  /// Get best subject (highest total).
  Map<String, dynamic>? getBestSubject() {
    if (_myScores.isEmpty) return null;
    final sorted = List<Map<String, dynamic>>.from(_myScores);
    sorted.sort((a, b) => ((b['total'] as num?)?.toDouble() ?? 0)
        .compareTo((a['total'] as num?)?.toDouble() ?? 0));
    return sorted.first;
  }

  /// Get worst subject (lowest total).
  Map<String, dynamic>? getWorstSubject() {
    if (_myScores.isEmpty) return null;
    final sorted = List<Map<String, dynamic>>.from(_myScores);
    sorted.sort((a, b) => ((a['total'] as num?)?.toDouble() ?? 0)
        .compareTo((b['total'] as num?)?.toDouble() ?? 0));
    return sorted.first;
  }

  /// Get pass/fail summary.
  Map<String, dynamic> getPassFailSummary() {
    if (_myScores.isEmpty) return {'passed': 0, 'failed': 0, 'total': 0, 'pass_rate': '0%'};

    int passed = 0;
    int failed = 0;
    final threshold = passMark;

    for (final score in _myScores) {
      final total = (score['total'] as num?)?.toDouble() ?? 0;
      if (total >= threshold) {
        passed++;
      } else {
        failed++;
      }
    }

    final total = passed + failed;
    final rate = total > 0 ? ((passed / total) * 100).toStringAsFixed(0) : '0';

    return {
      'passed': passed,
      'failed': failed,
      'total': total,
      'pass_rate': '$rate%',
    };
  }

  /// Check if student passed all subjects.
  bool passedAllSubjects() {
    if (_myScores.isEmpty) return false;
    final threshold = passMark;
    for (final score in _myScores) {
      final total = (score['total'] as num?)?.toDouble() ?? 0;
      if (total < threshold) return false;
    }
    return true;
  }

  // ==========================================
  // RESET
  // ==========================================
  void clearResults() {
    _myScores = [];
    _myTermSummary = null;
    notifyListeners();
  }

  // ==========================================
  // PRIVATE HELPERS
  // ==========================================

  /// Convert number to ordinal: 1st, 2nd, 3rd, 4th, etc.
  String _ordinal(int n) {
    if (n < 1 || n > 1000) return '$n';
    if (n >= 11 && n <= 20) return '${n}th';
    if (n == 1) return '1st';
    if (n == 2) return '2nd';
    if (n == 3) return '3rd';
    return '${n}th';
  }
}
