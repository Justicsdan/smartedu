// ==========================================
// File: lib/core/providers/student/student_results_mixin.dart
// ==========================================
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_base.dart';

mixin StudentResultsMixin on StudentBase {

  List<Map<String, dynamic>> _myScores = [];

  List<Map<String, dynamic>> get myScores => _myScores;

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

  /// UI pages use this — returns flattened scores WITH subject_name
  @override
  List<Map<String, dynamic>> get scores => myScoresFlat;

  Map<String, dynamic>? _myTermSummary;
  Map<String, dynamic>? get myTermSummary => _myTermSummary;

  bool get areResultsPublished {
    if (_myTermSummary == null) return false;
    return _myTermSummary!['is_published'] == true;
  }

  double get totalScore => (_myTermSummary?['total_score'] as num?)?.toDouble() ?? 0;
  int get subjectsTaken => (_myTermSummary?['subjects_taken'] as int?) ?? 0;
  double get termAverage => (_myTermSummary?['average_score'] as num?)?.toDouble() ?? 0;
  int get termPosition => (_myTermSummary?['position'] as int?) ?? 0;
  int get positionOutOf => (_myTermSummary?['position_out_of'] as int?) ?? 0;

  String get positionDisplay {
    if (termPosition == 0 || positionOutOf == 0) return '—';
    return '${_ordinal(termPosition)} out of $positionOutOf';
  }

  int get daysPresent => (_myTermSummary?['days_present'] as int?) ?? 0;
  int get daysAbsent => (_myTermSummary?['days_absent'] as num?)?.toInt() ?? 0;
  String get termGrade => (_myTermSummary?['grade'] as String?) ?? '';

  @override
  double getOverallAverage() {
    if (_myScores.isEmpty) return 0.0;
    double total = 0;
    for (final s in _myScores) {
      total += (s['total'] as num?)?.toDouble() ?? 0;
    }
    return total / _myScores.length;
  }

  double get totalScoresSum {
    double total = 0;
    for (final s in _myScores) {
      total += (s['total'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  @override
  Future<void> loadStudentData() async {
    await loadAllResults();
  }

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
            id, subject_id, scores_json, total, grade, position, position_out_of,
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

  Future<void> loadMyTermSummary() async {
    if (currentSessionId == null || currentTermId == null) {
      _myTermSummary = null;
      debugPrint("STUDENT RESULTS DEBUG: schoolId=$schoolId studentId=$studentId sessionId=$currentSessionId termId=$currentTermId");
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

  Future<void> loadAllResults() async {
    _myScores = [];
    debugPrint("STUDENT RESULTS: loadStudentData() called");
    _myTermSummary = null;
    notifyListeners();
    debugPrint("STUDENT RESULTS: loadAllResults() called");

    await loadMyTermSummary();

    if (areResultsPublished) {
      await loadMyScores();
    }
  }

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

  List<Map<String, dynamic>> getScoresBySubject() => myScoresFlat;

  Map<String, dynamic> getAssessmentBreakdown(String subjectId) {
    final score = getScoreForSubject(subjectId);
    if (score == null) return {};
    return (score['scores_json'] as Map<String, dynamic>?) ?? {};
  }

  double getSubjectTotal(String subjectId) {
    final score = getScoreForSubject(subjectId);
    return (score?['total'] as num?)?.toDouble() ?? 0;
  }

  String getSubjectGrade(String subjectId) {
    return calculateGrade(getSubjectTotal(subjectId));
  }

  String getSubjectRemark(String subjectId) {
    return getGradeRemark(getSubjectTotal(subjectId));
  }

  Map<String, dynamic>? getBestSubject() {
    if (_myScores.isEmpty) return null;
    final sorted = List<Map<String, dynamic>>.from(_myScores);
    sorted.sort((a, b) => ((b['total'] as num?)?.toDouble() ?? 0)
        .compareTo((a['total'] as num?)?.toDouble() ?? 0));
    return sorted.first;
  }

  Map<String, dynamic>? getWorstSubject() {
    if (_myScores.isEmpty) return null;
    final sorted = List<Map<String, dynamic>>.from(_myScores);
    sorted.sort((a, b) => ((a['total'] as num?)?.toDouble() ?? 0)
        .compareTo((b['total'] as num?)?.toDouble() ?? 0));
    return sorted.first;
  }

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

    return {'passed': passed, 'failed': failed, 'total': total, 'pass_rate': '$rate%'};
  }

  bool passedAllSubjects() {
    if (_myScores.isEmpty) return false;
    final threshold = passMark;
    for (final score in _myScores) {
      final total = (score['total'] as num?)?.toDouble() ?? 0;
      if (total < threshold) return false;
    }
    return true;
  }

  void clearResults() {
    _myScores = [];
    _myTermSummary = null;
    notifyListeners();
  }

  String _ordinal(int n) {
    if (n < 1 || n > 1000) return '$n';
    if (n >= 11 && n <= 20) return '${n}th';
    if (n == 1) return '1st';
    if (n == 2) return '2nd';
    if (n == 3) return '3rd';
    return '${n}th';
  }
}
