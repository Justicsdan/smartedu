// ==========================================
// File: lib/core/providers/cbt_mixin.dart
// ==========================================
import 'package:flutter/foundation.dart';
import 'base_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mixin for CBT exam management.
/// Handles loading, creating, updating, toggling, and deleting exams.
///
/// MASTER PLAN V4:
/// - Every operation filters by schoolId — tenant isolation
/// - V4: Uses supabase getter from BaseProvider (consistent pattern)
/// - V4: Uses debugPrint instead of print
/// - V4: Fixed orElse type mismatch
/// - V4: Added all schema fields (pass_mark, timing, shuffle, retake, etc.)
/// - V4: Fixed local toggleCbt using wrong key name
/// - V4: Added utility methods for lookups
/// - V4: Made getCbtExamById accept String? to prevent upstream crashes

mixin CbtMixin on BaseProvider {
  List<Map<String, dynamic>> _cbtExams = [];

  @override
  List<Map<String, dynamic>> get cbtExams => _cbtExams;

  /// Total number of exams.
  int get cbtExamCount => _cbtExams.length;

  /// Count of active (visible to students) exams.
  int get activeExamCount => _cbtExams.where((e) => e['is_active'] == true).length;

  // ==========================================
  // LOADING
  // ==========================================

  @override
  Future<void> loadCbtExams() async {
    try {
      final r = await supabase
          .from('cbt_exams')
          .select('*, subjects(name, code), classes(name, section)')
          .eq('school_id', schoolId)
          .order('created_at', ascending: false);
      _cbtExams = List<Map<String, dynamic>>.from(r);
    } catch (e) {
      debugPrint('Error loading CBT exams: $e');
    }
  }

  // ==========================================
  // CRUD
  // ==========================================

  /// Add a new CBT exam to the database.
  /// V4: Supports all schema fields including retake settings.
  Future<Map<String, dynamic>?> addCbtExamToDb({
    required String title,
    required String subjectId,
    required String classId,
    int durationMinutes = 60,
    int totalQuestions = 50,
    double passMark = 40,
    bool isActive = false,
    DateTime? startTime,
    DateTime? endTime,
    String instructions = '',
    bool shuffleQuestions = false,
    bool showResultImmediately = true,
    bool allowRetake = false,
    int maxAttempts = 1,
  }) async {
    try {
      final insertData = <String, dynamic>{
        'school_id': schoolId,
        'title': title.trim(),
        'subject_id': subjectId,
        'class_id': classId,
        'duration_minutes': durationMinutes,
        'total_questions': totalQuestions,
        'pass_mark': passMark,
        'is_active': isActive,
        'instructions': instructions,
        'shuffle_questions': shuffleQuestions,
        'show_result_immediately': showResultImmediately,
        'allow_retake': allowRetake,
        'max_attempts': maxAttempts,
      };

      if (startTime != null) insertData['start_time'] = startTime.toUtc().toIso8601String();
      if (endTime != null) insertData['end_time'] = endTime.toUtc().toIso8601String();

      final r = await supabase
          .from('cbt_exams')
          .insert(insertData)
          .select('*, subjects(name, code), classes(name, section)')
          .single();

      _cbtExams.insert(0, Map<String, dynamic>.from(r));

      logAudit(
        action: 'create',
        tableName: 'cbt_exams',
        recordId: r['id']?.toString(),
        newData: {'title': title, 'subject_id': subjectId, 'class_id': classId},
      );
      notifyListeners();
      return r;
    } catch (e) {
      debugPrint('Error adding CBT exam: $e');
      return null;
    }
  }

  /// Update a CBT exam in the database.
  Future<bool> updateCbtExamInDb(String id, Map<String, dynamic> updates) async {
    try {
      final u = Map<String, dynamic>.from(updates)
        ..remove('id')
        ..remove('school_id')
        ..remove('created_at')
        ..remove('updated_at');

      if (u.isEmpty) return false;

      final r = await supabase
          .from('cbt_exams')
          .update(u)
          .eq('id', id)
          .eq('school_id', schoolId)
          .select('*, subjects(name, code), classes(name, section)')
          .single();

      final i = _cbtExams.indexWhere((e) => e['id']?.toString() == id);
      if (i != -1) {
        _cbtExams[i] = Map<String, dynamic>.from(r);
      }

      logAudit(action: 'update', tableName: 'cbt_exams', recordId: id, newData: u);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating CBT exam: $e');
      return false;
    }
  }

  /// Toggle exam active/inactive status in the database.
  Future<bool> toggleCbtInDb(String id) async {
    try {
      final e = _cbtExams.cast<Map<String, dynamic>?>().firstWhere(
            (e) => e?['id']?.toString() == id,
            orElse: () => <String, dynamic>{},
          );
      if (e == null || e.isEmpty) return false;

      final newState = !(e['is_active'] as bool? ?? false);

      await supabase
          .from('cbt_exams')
          .update({'is_active': newState})
          .eq('id', id)
          .eq('school_id', schoolId);

      final i = _cbtExams.indexWhere((e) => e['id']?.toString() == id);
      if (i != -1) {
        _cbtExams[i] = Map<String, dynamic>.from(_cbtExams[i]);
        _cbtExams[i]['is_active'] = newState;
      }

      logAudit(
        action: 'toggle_active',
        tableName: 'cbt_exams',
        recordId: id,
        newData: {'is_active': newState},
      );
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error toggling CBT: $e');
      return false;
    }
  }

  /// Delete a CBT exam from the database.
  /// V4: Questions and attempts cascade via ON DELETE CASCADE.
  Future<bool> deleteCbtExamFromDb(String id) async {
    try {
      await supabase
          .from('cbt_exams')
          .delete()
          .eq('id', id)
          .eq('school_id', schoolId);

      _cbtExams.removeWhere((e) => e['id']?.toString() == id);

      logAudit(action: 'delete', tableName: 'cbt_exams', recordId: id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting CBT exam: $e');
      return false;
    }
  }

  // ==========================================
  // UTILITY METHODS
  // ==========================================

  /// Get a single exam by ID. Returns null if not found.
  /// [FIX] Accepts String? to prevent upstream null crashes in CBT score mixins.
  Map<String, dynamic>? getCbtExamById(String? examId) {
    if (examId == null || examId.isEmpty) return null;
    try {
      return _cbtExams.cast<Map<String, dynamic>?>().firstWhere(
            (e) => e?['id']?.toString() == examId,
            orElse: () => null,
          );
    } catch (e) {
      return null;
    }
  }

  /// Get exam title by ID, safely.
  String getCbtExamTitle(String? examId) {
    if (examId == null || examId.isEmpty) return '';
    final exam = getCbtExamById(examId);
    return (exam?['title'] ?? '').toString();
  }

  /// Get exams for a specific class.
  List<Map<String, dynamic>> getExamsForClass(String classId) {
    return _cbtExams
        .where((e) => e['class_id']?.toString() == classId)
        .toList();
  }

  /// Get active exams for a specific class (visible to students).
  List<Map<String, dynamic>> getActiveExamsForClass(String classId) {
    return _cbtExams
        .where((e) =>
            e['class_id']?.toString() == classId &&
            e['is_active'] == true)
        .toList();
  }

  /// Get exams for a specific subject.
  List<Map<String, dynamic>> getExamsForSubject(String subjectId) {
    return _cbtExams
        .where((e) => e['subject_id']?.toString() == subjectId)
        .toList();
  }

  /// Get exams created by a specific teacher.
  List<Map<String, dynamic>> getExamsByTeacher(String teacherId) {
    return _cbtExams
        .where((e) => e['created_by']?.toString() == teacherId)
        .toList();
  }

  /// Check if an exam is currently active (visible to students).
  bool isExamActive(String? examId) {
    final exam = getCbtExamById(examId);
    return exam?['is_active'] == true;
  }

  /// Check if an exam's time window is currently open.
  /// Returns true if no start/end time set, or if current time is within window.
  bool isExamTimeOpen(String? examId) {
    final exam = getCbtExamById(examId);
    if (exam == null) return false;

    final startTimeStr = exam['start_time']?.toString();
    final endTimeStr = exam['end_time']?.toString();

    // No time constraints — always open
    if (startTimeStr == null || startTimeStr.isEmpty) return true;

    final now = DateTime.now().toUtc();
    final startTime = DateTime.tryParse(startTimeStr);
    final endTime = endTimeStr != null && endTimeStr.isNotEmpty
        ? DateTime.tryParse(endTimeStr)
        : null;

    if (startTime == null) return true;
    if (now.isBefore(startTime)) return false;
    if (endTime != null && now.isAfter(endTime)) return false;
    return true;
  }

  /// Get formatted duration string (e.g. "1h 30m").
  String getFormattedDuration(String? examId) {
    final exam = getCbtExamById(examId);
    if (exam == null) return '';
    final mins = (exam['duration_minutes'] as int?) ?? 60;
    if (mins < 60) return '${mins}m';
    final hours = mins ~/ 60;
    final remainingMins = mins % 60;
    if (remainingMins == 0) return '${hours}h';
    return '${hours}h ${remainingMins}m';
  }

  /// Check if an exam allows retakes.
  bool allowsRetake(String? examId) {
    final exam = getCbtExamById(examId);
    return exam?['allow_retake'] == true;
  }

  /// Get max attempts for an exam.
  int getMaxAttempts(String? examId) {
    final exam = getCbtExamById(examId);
    return (exam?['max_attempts'] as int?) ?? 1;
  }

  // ==========================================
  // LEGACY (backward compat — local state only)
  // ==========================================

  /// Add exam to local list only (no DB write).
  void addCbtExam(Map<String, dynamic> e) {
    _cbtExams.add(Map<String, dynamic>.from(e));
    notifyListeners();
  }

  /// Toggle exam active state locally (no DB write).
  /// [FIX] Was using wrong key 'isActive' — correct DB key is 'is_active'.
  void toggleCbt(String id) {
    final i = _cbtExams.indexWhere((e) => e['id']?.toString() == id);
    if (i != -1) {
      _cbtExams[i] = Map<String, dynamic>.from(_cbtExams[i]);
      _cbtExams[i]['is_active'] = !(_cbtExams[i]['is_active'] as bool? ?? false);
      notifyListeners();
    }
  }

  /// Remove exam from local list by ID only (no DB write).
  void deleteCbtExam(String id) {
    _cbtExams.removeWhere((e) => e['id']?.toString() == id);
    notifyListeners();
  }
}
