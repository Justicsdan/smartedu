// ==========================================
// File: lib/core/providers/score_mixin.dart
// ==========================================
import 'package:flutter/foundation.dart';
import 'base_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mixin for score CRUD, position calculation, and results visibility.
///
/// MASTER PLAN V4 (Global Scale Optimizations):
/// - Every query strictly filters by schoolId + session_id + term_id
/// - Position calculation OFFLOADED to PostgreSQL RPCs for maximum speed.
///   (Calculating 5000 student positions in Dart is too slow for global scale).
/// - Uses compute_subject_positions() and compute_term_summaries() SQL functions.
/// - Batch operations for DB writes.
/// - V4: Fixed onConflict removed in postgrest 2.x → uses upsert
/// - V4: Fixed 'is' keyword conflict in .not() filter
/// - V4: Added utility methods for score lookups
/// - V4: Fixed nullable map access in findScore()

mixin ScoreMixin on BaseProvider {

  List<Map<String, dynamic>> _scores = [];
  bool _resultsVisible = false;

  @override
  List<Map<String, dynamic>> get scores => _scores;

  bool get resultsVisible => _resultsVisible;

  /// Total number of scores currently loaded.
  int get scoreCount => _scores.length;

  // ==========================================
  // LOADING
  // ==========================================

  @override
  Future<void> loadScores() async {
    if (currentSession == null || currentTerm == null) {
      _scores = [];
      return;
    }

    try {
      final r = await supabase
          .from('scores')
          .select(
            '*, '
            'students(first_name, last_name, admission_no, class_id, passport_url), '
            'subjects(name, code), '
            'classes(name, section)',
          )
          .eq('school_id', schoolId)
          .eq('session_id', currentSession!['id'])
          .eq('term_id', currentTerm!['id']);

      _scores = List<Map<String, dynamic>>.from(r);
    } catch (e) {
      debugPrint('Error loading scores: $e');
    }
  }

  /// Load scores for a specific class only.
  Future<void> loadScoresForClass(String classId) async {
    if (currentSession == null || currentTerm == null) return;

    try {
      final r = await supabase
          .from('scores')
          .select(
            '*, '
            'students(first_name, last_name, admission_no, class_id, passport_url), '
            'subjects(name, code), '
            'classes(name, section)',
          )
          .eq('school_id', schoolId)
          .eq('session_id', currentSession!['id'])
          .eq('term_id', currentTerm!['id'])
          .eq('class_id', classId);

      _scores = List<Map<String, dynamic>>.from(r);
    } catch (e) {
      debugPrint('Error loading class scores: $e');
    }
  }

  /// Load scores for a specific student only.
  Future<void> loadScoresForStudent(String studentId) async {
    if (currentSession == null || currentTerm == null) return;

    try {
      final r = await supabase
          .from('scores')
          .select(
            '*, '
            'subjects(name, code), '
            'classes(name, section)',
          )
          .eq('school_id', schoolId)
          .eq('session_id', currentSession!['id'])
          .eq('term_id', currentTerm!['id'])
          .eq('student_id', studentId);

      _scores = List<Map<String, dynamic>>.from(r);
    } catch (e) {
      debugPrint('Error loading student scores: $e');
    }
  }

  // ==========================================
  // SAVE SCORES (LOCAL STATE ONLY)
  // ==========================================

  void saveScores(List<Map<String, dynamic>> newScores) {
    for (final s in newScores) {
      final sid = s['student_id']?.toString() ?? '';
      final subid = s['subject_id']?.toString() ?? '';
      if (sid.isEmpty || subid.isEmpty) continue;

      final index = _scores.indexWhere(
        (x) =>
            (x['student_id']?.toString() ?? '') == sid &&
            (x['subject_id']?.toString() ?? '') == subid &&
            (x['session_id']?.toString() ?? '') == (currentSession?['id']?.toString() ?? '') &&
            (x['term_id']?.toString() ?? '') == (currentTerm?['id']?.toString() ?? ''),
      );

      if (index != -1) {
        _scores[index] = Map<String, dynamic>.from(_scores[index])..addAll(s);
      } else {
        _scores.add(Map<String, dynamic>.from(s));
      }
    }
    notifyListeners();
  }

  void removeStudentScores(String studentId) {
    _scores.removeWhere(
      (s) => (s['student_id']?.toString() ?? '') == studentId &&
             (s['session_id']?.toString() ?? '') == (currentSession?['id']?.toString() ?? '') &&
             (s['term_id']?.toString() ?? '') == (currentTerm?['id']?.toString() ?? ''),
    );
    notifyListeners();
  }

  void clearScores() {
    _scores = [];
    notifyListeners();
  }

  // ==========================================
  // SAVE SCORES TO DATABASE (BATCH)
  // ==========================================

  Future<bool> saveScoresToDb(
    List<Map<String, dynamic>> newScores, {
    String? recordedBy,
    bool recalculatePositions = true,
  }) async {
    if (schoolId.isEmpty || currentSession == null || currentTerm == null) return false;
    if (newScores.isEmpty) return true;

    try {
      final rows = <Map<String, dynamic>>[];

      for (final s in newScores) {
        final sid = s['student_id']?.toString() ?? '';
        final subid = s['subject_id']?.toString() ?? '';
        final cid = s['class_id']?.toString() ?? '';
        if (sid.isEmpty || subid.isEmpty || cid.isEmpty) continue;

        dynamic rawJson = s['scores_json'];
        Map<String, dynamic> scoresJson;
        if (rawJson is Map<String, dynamic>) {
          scoresJson = Map<String, dynamic>.from(rawJson);
        } else if (rawJson is Map) {
          scoresJson = (rawJson as Map).map((k, v) => MapEntry(k.toString(), v.toString()));
        } else {
          scoresJson = {};
        }

        double total = 0;
        for (final entry in scoresJson.values) {
          total += (double.tryParse(entry.toString()) ?? 0);
        }

        final gradeInfo = calculateGradeWithRemark(total);

        rows.add({
          'school_id': schoolId,
          'student_id': sid,
          'class_id': cid,
          'subject_id': subid,
          'session_id': currentSession!['id'],
          'term_id': currentTerm!['id'],
          'scores_json': scoresJson,
          'total': total,
          'grade': gradeInfo['grade'],
          'recorded_by': recordedBy,
        });
      }

      if (rows.isEmpty) return true;

      // [FIX] postgrest 2.x removed onConflict from .insert()
      // Use .upsert() instead — same effect, correct API
      await supabase
          .from('scores')
          .upsert(
            rows,
            onConflict: 'student_id,subject_id,session_id,term_id',
          );

      // V4 SCALE: Offload position calculations to Postgres RPCs
      if (recalculatePositions) {
        final affectedClasses = <String>{};
        for (final s in newScores) {
          final cid = s['class_id']?.toString() ?? '';
          if (cid.isNotEmpty) affectedClasses.add(cid);
        }

        for (final cid in affectedClasses) {
          try {
            await recalculateClassAndSubjectPositions(cid);
          } catch (e) {
            debugPrint('Position calc error for class $cid: $e');
          }
        }
      }

      await loadScores();

      logAudit(
        action: 'batch_upsert',
        tableName: 'scores',
        newData: {'count': rows.length},
      );
      return true;
    } catch (e) {
      debugPrint('Error batch saving scores: $e');
      return false;
    }
  }

  Future<bool> saveSingleScore(Map<String, dynamic> scoreData, {String? recordedBy}) async {
    return saveScoresToDb([scoreData], recordedBy: recordedBy, recalculatePositions: true);
  }

  // ==========================================
  // SCORE LOOKUP UTILITIES
  // ==========================================

  /// Find a single score record in local state.
  /// Returns null if not found.
  Map<String, dynamic>? findScore(String studentId, String subjectId) {
    if (currentSession == null || currentTerm == null) return null;
    final sid = currentSession!['id'].toString();
    final tid = currentTerm!['id'].toString();

    try {
      // [FIX] s is Map<String, dynamic>? because of cast<...?>()
      // MUST use s?['key'] to avoid null crash on the map itself
      return _scores.cast<Map<String, dynamic>?>().firstWhere(
            (s) =>
                (s?['student_id']?.toString() ?? '') == studentId &&
                (s?['subject_id']?.toString() ?? '') == subjectId &&
                (s?['session_id']?.toString() ?? '') == sid &&
                (s?['term_id']?.toString() ?? '') == tid,
            orElse: () => null,
          );
    } catch (e) {
      return null;
    }
  }

  /// Backward compat alias used by teacher_enter_scores.dart
  Map<String, dynamic>? getExistingScore(String studentId, String subjectId, [String? termId]) {
    return findScore(studentId, subjectId);
  }

  /// Get scores_json map for a student+subject combo.
  /// Returns empty map if not found.
  Map<String, dynamic> getScoresJson(String studentId, String subjectId) {
    final score = findScore(studentId, subjectId);
    final raw = score?['scores_json'];
    if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
    if (raw is Map) return (raw as Map).map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  /// Get total score for a student+subject combo.
  double getScoreTotal(String studentId, String subjectId) {
    return (findScore(studentId, subjectId)?['total'] as num?)?.toDouble() ?? 0;
  }

  /// Get grade for a student+subject combo.
  String getScoreGrade(String studentId, String subjectId) {
    return (findScore(studentId, subjectId)?['grade'] ?? '').toString();
  }

  /// Check if a score exists for a student+subject combo.
  bool hasScore(String studentId, String subjectId) {
    return findScore(studentId, subjectId) != null;
  }

  // ==========================================
  // POSITION CALCULATION (V4: Database RPC Delegation)
  /// For global scale (500+ students), Dart loops are too slow.
  /// We call the native PostgreSQL functions which use DENSE_RANK().
  // ==========================================

  /// Recalculates BOTH per-subject positions AND overall class positions
  /// for a specific class using lightning-fast SQL RPCs.
  Future<bool> recalculateClassAndSubjectPositions(String classId) async {
    if (schoolId.isEmpty || currentSession == null || currentTerm == null) return false;

    try {
      // 1. Compute per-subject positions (Updates scores table natively)
      await supabase.rpc('compute_all_subject_positions', params: {
        'p_school_id': schoolId,
        'p_class_id': classId,
        'p_session_id': currentSession!['id'],
        'p_term_id': currentTerm!['id'],
      });

      // 2. Compute overall class positions & term summaries
      await supabase.rpc('compute_term_summaries', params: {
        'p_school_id': schoolId,
        'p_class_id': classId,
        'p_session_id': currentSession!['id'],
        'p_term_id': currentTerm!['id'],
      });

      return true;
    } catch (e) {
      debugPrint('RPC Position calc error for $classId: $e');
      return false;
    }
  }

  /// Get class-level positions for all current scores in memory.
  /// (Used for instant UI rendering without waiting for DB)
  Map<String, Map<String, dynamic>> getClassPositions() {
    if (currentSession == null || currentTerm == null) return {};

    final studentTotals = <String, double>{};
    final studentSubjectCount = <String, int>{};

    for (final s in _scores) {
      final sid = (s['student_id'] ?? '').toString();
      final total = (s['total'] as num?)?.toDouble() ?? 0;
      studentTotals[sid] = (studentTotals[sid] ?? 0) + total;
      studentSubjectCount[sid] = (studentSubjectCount[sid] ?? 0) + 1;
    }

    final sorted = studentTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final result = <String, Map<String, dynamic>>{};
    int pos = 1;
    for (int i = 0; i < sorted.length; i++) {
      final currentTotal = sorted[i].value;
      final prevTotal = i > 0 ? sorted[i - 1].value : -1;
      if (i > 0 && currentTotal != prevTotal) pos = i + 1;
      result[sorted[i].key] = {
        'position': pos,
        'position_out_of': sorted.length,
        'total_score': sorted[i].value,
        'subjects_taken': studentSubjectCount[sorted[i].key] ?? 0,
      };
    }

    return result;
  }

  Map<String, dynamic>? getClassPositionForStudent(String studentId) {
    return getClassPositions()[studentId];
  }

  List<Map<String, dynamic>> studentScoresForClass(String classId) {
    if (currentSession == null || currentTerm == null) return [];
    final sid = currentSession!['id'].toString();
    final tid = currentTerm!['id'].toString();
    return _scores.where((s) =>
        (s['class_id']?.toString() ?? '') == classId &&
        (s['session_id']?.toString() ?? '') == sid &&
        (s['term_id']?.toString() ?? '') == tid
    ).toList();
  }

  List<Map<String, dynamic>> studentScoresForStudent(String studentId) {
    if (currentSession == null || currentTerm == null) return [];
    final sid = currentSession!['id'].toString();
    final tid = currentTerm!['id'].toString();
    return _scores.where((s) =>
        (s['student_id']?.toString() ?? '') == studentId &&
        (s['session_id']?.toString() ?? '') == sid &&
        (s['term_id']?.toString() ?? '') == tid
    ).toList();
  }

  // ==========================================
  // RECALCULATE ALL
  // ==========================================

  Future<bool> recalculateAllPositions() async {
    if (currentSession == null || currentTerm == null) return false;

    try {
      final rawRows = await supabase
          .from('scores')
          .select('class_id')
          .eq('school_id', schoolId)
          .eq('session_id', currentSession!['id'])
          .eq('term_id', currentTerm!['id']);

      // [FIX] Was .not('class_id', is: '') — 'is' is a Dart keyword,
      // can't be used as named parameter in postgrest 2.x.
      // Filter and dedup in Dart instead — cleaner and version-safe.
      final uniqueClassIds = rawRows
          .map((r) => (r['class_id'] ?? '').toString())
          .where((cid) => cid.isNotEmpty)
          .toSet();

      int successCount = 0;
      for (final cid in uniqueClassIds) {
        final success = await recalculateClassAndSubjectPositions(cid);
        if (success) successCount++;
      }

      await loadScores();
      return successCount > 0;
    } catch (e) {
      debugPrint('Recalculate all positions error: $e');
      return false;
    }
  }

  /// Alias to maintain backward compatibility with existing UI calls
  Future<bool> recalculateAllSubjectPositions() async {
    return recalculateAllPositions();
  }

  // ==========================================
  // DELETE SCORES
  // ==========================================

  Future<bool> deleteStudentScores(String studentId) async {
    if (schoolId.isEmpty || currentSession == null || currentTerm == null) return false;

    try {
      // V4: term_comments cascade if we set up ON DELETE CASCADE,
      // but for safety we delete explicitly (RLS may block cascade from anon)
      await supabase
          .from('term_comments')
          .delete()
          .eq('school_id', schoolId)
          .eq('student_id', studentId)
          .eq('session_id', currentSession!['id'])
          .eq('term_id', currentTerm!['id']);

      await supabase
          .from('scores')
          .delete()
          .eq('school_id', schoolId)
          .eq('student_id', studentId)
          .eq('session_id', currentSession!['id'])
          .eq('term_id', currentTerm!['id']);

      await loadScores();
      logAudit(action: 'delete_student_scores', tableName: 'scores', recordId: studentId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting student scores: $e');
      return false;
    }
  }

  Future<bool> deleteClassScores(String classId) async {
    if (schoolId.isEmpty || currentSession == null || currentTerm == null) return false;

    try {
      await supabase
          .from('scores')
          .delete()
          .eq('school_id', schoolId)
          .eq('class_id', classId)
          .eq('session_id', currentSession!['id'])
          .eq('term_id', currentTerm!['id']);

      await loadScores();
      logAudit(action: 'delete_class_scores', tableName: 'scores', newData: {'class_id': classId});
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting class scores: $e');
      return false;
    }
  }

  Future<bool> deleteSubjectScores(String classId, String subjectId) async {
    if (schoolId.isEmpty || currentSession == null || currentTerm == null) return false;

    try {
      await supabase
          .from('scores')
          .delete()
          .eq('school_id', schoolId)
          .eq('class_id', classId)
          .eq('subject_id', subjectId)
          .eq('session_id', currentSession!['id'])
          .eq('term_id', currentTerm!['id']);

      await loadScores();
      logAudit(
        action: 'delete_subject_scores',
        tableName: 'scores',
        newData: {'class_id': classId, 'subject_id': subjectId},
      );
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting subject scores: $e');
      return false;
    }
  }

  // ==========================================
  // RESULTS VISIBILITY
  // ==========================================

  Future<bool> toggleResultsVisibility(bool visible) async {
    if (schoolId.isEmpty) return false;

    try {
      await supabase
          .from('school_settings')
          .update({'show_grade_only': visible})
          .eq('school_id', schoolId);

      _resultsVisible = visible;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error toggling results visibility: $e');
      return false;
    }
  }

  void toggleResults(bool val) {
    _resultsVisible = val;
    notifyListeners();
  }

  // ==========================================
  // SCORE VALIDATION
  // ==========================================

  List<String> validateScoresForSave(List<Map<String, dynamic>> scores) {
    final errors = <String>[];
    if (currentSession == null) errors.add('No session selected');
    if (currentTerm == null) errors.add('No term selected');
    if (scores.isEmpty) errors.add('No scores to save');
    if (errors.isNotEmpty) return errors;

    final maxScore = subjectMaxScore;
    final assessmentTypes = this.assessmentTypes;

    for (int idx = 0; idx < scores.length; idx++) {
      final s = scores[idx];
      final sid = s['student_id']?.toString() ?? '';
      final subid = s['subject_id']?.toString() ?? '';
      final cid = s['class_id']?.toString() ?? '';
      final studentLabel = s['student_name'] ?? 'Student #$idx';

      if (sid.isEmpty) errors.add('Missing student ID at row $idx');
      if (subid.isEmpty) errors.add('Missing subject ID at row $idx');
      if (cid.isEmpty) errors.add('Missing class ID at row $idx');

      final rawJson = s['scores_json'];
      if (rawJson != null) {
        final json = rawJson is Map<String, dynamic>
            ? Map<String, dynamic>.from(rawJson)
            : <String, dynamic>{};

        for (final at in assessmentTypes) {
          final key = (at['id'] ?? '').toString().toLowerCase();
          final val = json[key];
          if (val != null) {
            final numVal = double.tryParse(val.toString()) ?? 0;
            final max = _getMaxForAssessment(at);
            if (numVal < 0) {
              errors.add('Score cannot be negative for $key ($numVal) — $studentLabel');
            }
            if (numVal > max) {
              errors.add('$key exceeds max of $max ($numVal) — $studentLabel');
            }
          }
        }

        final total = json.values.fold<double>(
          0,
          (sum, val) => sum + (double.tryParse(val.toString()) ?? 0),
        );
        if (total > maxScore) {
          errors.add('Total $total exceeds $maxScore — $studentLabel');
        }
      }

      if (s['total'] != null) {
        final totalDirect = (s['total'] as num?)?.toDouble() ?? 0;
        if (totalDirect > maxScore) {
          final studentLabel2 = s['student_name'] ?? 'Student';
          errors.add('Total $totalDirect exceeds $maxScore — $studentLabel2');
        }
      }
    }

    return errors;
  }

  double _getMaxForAssessment(Map<String, dynamic> at) {
    return (at['max'] as num?)?.toDouble() ?? 100;
  }
}
