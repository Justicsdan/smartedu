// ==========================================
// File: lib/core/providers/comment_mixin.dart
// ==========================================
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_provider.dart';

/// Mixin for term_comments CRUD operations.
/// Handles behavioral ratings (conduct, attitude, interest, punctuality)
/// and teacher/principal comments per student per term.
///
/// MASTER PLAN V4:
/// - Every query filters by school_id from BaseProvider — tenant isolation
/// - V4: Uses supabase getter from BaseProvider (consistent pattern)
/// - V4: Uses debugPrint instead of print
/// - V4: FIXED upsert conflict to include class_id (V4 schema changed the
///   UNIQUE constraint from (student_id, session_id, term_id) to
///   (student_id, session_id, term_id, class_id) — mid-term class changes
///   would crash without class_id in the conflict target
/// - V4: Added attendance_remark field from schema
/// - V4: Fixed duplicate key access bug in batchSaveBehavioralRatings
/// - V4: Added getExistingBehavioral alias for teacher score entry UI
/// - V4: Fixed termId parameter type to String? to match BaseProvider override

mixin CommentMixin on BaseProvider {

  // =========================================================
  // SAVE OPERATIONS
  // =========================================================

  /// Save or update term comments for a single student.
  /// Uses upsert with V4 unique constraint: (student_id, session_id, term_id, class_id).
  Future<bool> saveTermComments({
    required String studentId,
    required String classId,
    String? teacherComment,
    String? principalComment,
    String? conduct,
    String? attitude,
    String? interest,
    String? punctuality,
    String? attendanceRemark,
  }) async {
    if (currentSession == null || currentTerm == null) {
      debugPrint('Error saving term comments: no session or term selected');
      return false;
    }

    try {
      final payload = <String, dynamic>{
        'school_id': schoolId,
        'student_id': studentId,
        'session_id': currentSession!['id'],
        'term_id': currentTerm!['id'],
        'class_id': classId,
        'teacher_comment': teacherComment ?? '',
        'principal_comment': principalComment ?? '',
        'conduct': conduct ?? '',
        'attitude': attitude ?? '',
        'interest': interest ?? '',
        'punctuality': punctuality ?? '',
        'attendance_remark': attendanceRemark ?? '',
      };

      await supabase
          .from('term_comments')
          .upsert(payload, onConflict: 'student_id,session_id,term_id,class_id');

      logAudit(
        action: 'upsert',
        tableName: 'term_comments',
        recordId: studentId,
        newData: payload,
      );
      return true;
    } catch (e) {
      debugPrint('Error saving term comments: $e');
      return false;
    }
  }

  /// Save behavioral ratings only (no comments).
  Future<bool> saveBehavioralRating({
    required String studentId,
    required String classId,
    required String termId,
    String? sessionId,
    Map<String, dynamic>? behavioralData,
  }) async {
    final sid = sessionId ?? currentSession?['id']?.toString();
    if (sid == null || sid.isEmpty || termId.isEmpty) {
      debugPrint('Error saving behavioral rating: no session or term provided');
      return false;
    }

    try {
      final payload = <String, dynamic>{
        'school_id': schoolId,
        'student_id': studentId,
        'session_id': sid,
        'term_id': termId,
        'class_id': classId,
      };

      if (behavioralData != null) {
        if (behavioralData.containsKey('conduct')) payload['conduct'] = behavioralData['conduct'] ?? '';
        if (behavioralData.containsKey('attitude')) payload['attitude'] = behavioralData['attitude'] ?? '';
        if (behavioralData.containsKey('interest')) payload['interest'] = behavioralData['interest'] ?? '';
        if (behavioralData.containsKey('punctuality')) payload['punctuality'] = behavioralData['punctuality'] ?? '';
        if (behavioralData.containsKey('attendance_remark')) payload['attendance_remark'] = behavioralData['attendance_remark'] ?? '';
        if (behavioralData.containsKey('teacher_comment')) payload['teacher_comment'] = behavioralData['teacher_comment'] ?? '';
        if (behavioralData.containsKey('principal_comment')) payload['principal_comment'] = behavioralData['principal_comment'] ?? '';
      }

      await supabase
          .from('term_comments')
          .upsert(payload, onConflict: 'student_id,session_id,term_id,class_id');

      logAudit(
        action: 'upsert_behavioral',
        tableName: 'term_comments',
        recordId: studentId,
        newData: payload,
      );
      return true;
    } catch (e) {
      debugPrint('Error saving behavioral rating: $e');
      return false;
    }
  }

  /// Batch save behavioral ratings for multiple students.
  Future<int> batchSaveBehavioralRatings({
    required String classId,
    required String termId,
    String? sessionId,
    required List<Map<String, dynamic>> studentRatings,
  }) async {
    final sid = sessionId ?? currentSession?['id']?.toString();
    if (sid == null || sid.isEmpty || termId.isEmpty || studentRatings.isEmpty) return 0;

    int successCount = 0;

    for (final rating in studentRatings) {
      final studentId = (rating['studentId'] ?? rating['student_id'])?.toString() ?? '';
      if (studentId.isEmpty) continue;

      final data = Map<String, dynamic>.from(rating)
        ..remove('studentId')
        ..remove('student_id');

      final success = await saveBehavioralRating(
        studentId: studentId,
        classId: classId,
        termId: termId,
        sessionId: sid,
        behavioralData: data,
      );
      if (success) successCount++;
    }

    return successCount;
  }

  /// Save principal comment for a single student.
  Future<bool> savePrincipalComment({
    required String studentId,
    required String classId,
    required String comment,
  }) async {
    if (currentSession == null || currentTerm == null) return false;

    try {
      final existing = await getTermComments(studentId: studentId);

      if (existing != null) {
        await supabase
            .from('term_comments')
            .update({'principal_comment': comment})
            .eq('id', existing['id'])
            .eq('school_id', schoolId);
      } else {
        await supabase
            .from('term_comments')
            .insert({
              'school_id': schoolId,
              'student_id': studentId,
              'session_id': currentSession!['id'],
              'term_id': currentTerm!['id'],
              'class_id': classId,
              'principal_comment': comment,
              'teacher_comment': '',
              'conduct': '',
              'attitude': '',
              'interest': '',
              'punctuality': '',
              'attendance_remark': '',
            });
      }

      logAudit(
        action: 'update_principal_comment',
        tableName: 'term_comments',
        recordId: studentId,
        newData: {'principal_comment': comment},
      );
      return true;
    } catch (e) {
      debugPrint('Error saving principal comment: $e');
      return false;
    }
  }

  // =========================================================
  // READ OPERATIONS
  // =========================================================

  Future<Map<String, dynamic>?> getTermComments({required String studentId}) async {
    if (currentSession == null || currentTerm == null) return null;
    try {
      return await supabase
          .from('term_comments')
          .select()
          .eq('school_id', schoolId)
          .eq('student_id', studentId)
          .eq('session_id', currentSession!['id'])
          .eq('term_id', currentTerm!['id'])
          .maybeSingle();
    } catch (e) {
      debugPrint('Error fetching term comments: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getTermCommentsForTerm({
    required String studentId,
    required String termId,
    String? sessionId,
  }) async {
    final sid = sessionId ?? currentSession?['id']?.toString();
    if (sid == null || sid.isEmpty) return null;
    try {
      return await supabase
          .from('term_comments')
          .select()
          .eq('school_id', schoolId)
          .eq('student_id', studentId)
          .eq('session_id', sid)
          .eq('term_id', termId)
          .maybeSingle();
    } catch (e) {
      debugPrint('Error fetching term comments for term: $e');
      return null;
    }
  }

  Map<String, dynamic>? getBehavioralForStudent(String studentId, String? termId) {
    return null;
  }

  /// Alias for teacher_enter_scores.dart — fetches behavioral data for UI pre-fill.
  /// [FIX] Changed termId from String to String? to match BaseProvider's abstract
  /// signature. StudentMixin also overrides with String?. Without this fix,
  /// SchoolAdminProvider (which applies both mixins) gets a conflicting override error.
  Future<Map<String, dynamic>?> getExistingBehavioral(String studentId, String? termId) async {
    if (termId == null || termId.isEmpty) return null;
    return await getTermCommentsForTerm(studentId: studentId, termId: termId);
  }

  Future<List<Map<String, dynamic>>> getTermCommentsForClass({required String classId}) async {
    if (currentSession == null || currentTerm == null) return [];
    try {
      final result = await supabase
          .from('term_comments')
          .select('*, students(first_name, last_name, admission_no, passport_url)')
          .eq('school_id', schoolId)
          .eq('class_id', classId)
          .eq('session_id', currentSession!['id'])
          .eq('term_id', currentTerm!['id']);
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('Error fetching class term comments: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTermCommentsForClassWithTerm({
    required String classId,
    required String termId,
    String? sessionId,
  }) async {
    final sid = sessionId ?? currentSession?['id']?.toString();
    if (sid == null || sid.isEmpty) return [];
    try {
      final result = await supabase
          .from('term_comments')
          .select('*, students(first_name, last_name, admission_no, passport_url)')
          .eq('school_id', schoolId)
          .eq('class_id', classId)
          .eq('session_id', sid)
          .eq('term_id', termId);
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('Error fetching class term comments with term: $e');
      return [];
    }
  }

  Future<Map<String, Map<String, dynamic>>> getTermCommentsForStudents({
    required List<String> studentIds,
    String? termId,
    String? sessionId,
  }) async {
    final sid = sessionId ?? currentSession?['id']?.toString();
    final tid = termId ?? currentTerm?['id']?.toString();
    if (sid == null || tid == null || sid.isEmpty || tid.isEmpty || studentIds.isEmpty) return {};

    try {
      final result = await supabase
          .from('term_comments')
          .select()
          .eq('school_id', schoolId)
          .eq('session_id', sid)
          .eq('term_id', tid)
          .inFilter('student_id', studentIds);

      final map = <String, Map<String, dynamic>>{};
      for (final row in result) {
        final rowStudentId = row['student_id']?.toString() ?? '';
        if (rowStudentId.isNotEmpty) {
          map[rowStudentId] = Map<String, dynamic>.from(row);
        }
      }
      return map;
    } catch (e) {
      debugPrint('Error fetching batch term comments: $e');
      return {};
    }
  }

  // =========================================================
  // DELETE OPERATIONS
  // =========================================================

  Future<bool> deleteTermComments({required String studentId}) async {
    if (currentSession == null || currentTerm == null) return false;
    try {
      await supabase
          .from('term_comments')
          .delete()
          .eq('school_id', schoolId)
          .eq('student_id', studentId)
          .eq('session_id', currentSession!['id'])
          .eq('term_id', currentTerm!['id']);

      logAudit(
        action: 'delete',
        tableName: 'term_comments',
        recordId: studentId,
      );
      return true;
    } catch (e) {
      debugPrint('Error deleting term comments: $e');
      return false;
    }
  }

  Future<bool> deleteTermCommentsForClass({required String classId}) async {
    if (currentSession == null || currentTerm == null) return false;
    try {
      await supabase
          .from('term_comments')
          .delete()
          .eq('school_id', schoolId)
          .eq('class_id', classId)
          .eq('session_id', currentSession!['id'])
          .eq('term_id', currentTerm!['id']);

      logAudit(
        action: 'delete_class_comments',
        tableName: 'term_comments',
        newData: {'class_id': classId},
      );
      return true;
    } catch (e) {
      debugPrint('Error deleting class term comments: $e');
      return false;
    }
  }

  // =========================================================
  // VALIDATION
  // =========================================================

  List<String> validateBehavioralData(Map<String, dynamic> data) {
    const allowedValues = ['Excellent', 'Very Good', 'Good', 'Fair', 'Poor', ''];
    final errors = <String>[];

    for (final field in ['conduct', 'attitude', 'interest', 'punctuality']) {
      final value = (data[field] ?? '').toString().trim();
      if (value.isNotEmpty && !allowedValues.contains(value)) {
        errors.add('$field: "$value" is not a valid rating');
      }
    }

    if (data.containsKey('teacher_comment')) {
      final tc = (data['teacher_comment'] ?? '').toString();
      if (tc.length > 500) {
        errors.add('Teacher comment exceeds 500 characters (${tc.length})');
      }
    }
    if (data.containsKey('principal_comment')) {
      final pc = (data['principal_comment'] ?? '').toString();
      if (pc.length > 500) {
        errors.add('Principal comment exceeds 500 characters (${pc.length})');
      }
    }
    if (data.containsKey('attendance_remark')) {
      final ar = (data['attendance_remark'] ?? '').toString();
      if (ar.length > 200) {
        errors.add('Attendance remark exceeds 200 characters (${ar.length})');
      }
    }

    return errors;
  }

  Map<String, dynamic> sanitizeBehavioralData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};

    for (final field in data.keys) {
      final value = data[field];
      if (value == null) continue;

      final strValue = value.toString().trim();
      if (strValue.isEmpty) continue;

      int maxLen;
      if (field.contains('comment')) {
        maxLen = 500;
      } else if (field == 'attendance_remark') {
        maxLen = 200;
      } else {
        maxLen = 50;
      }

      sanitized[field] = strValue.length > maxLen ? strValue.substring(0, maxLen) : strValue;
    }

    return sanitized;
  }

  // =========================================================
  // DISPLAY UTILITIES
  // =========================================================

  List<Map<String, dynamic>> getBehavioralDisplayList(Map<String, dynamic>? comments) {
    if (comments == null) return [];

    const fieldLabels = {
      'conduct': 'Conduct',
      'attitude': 'Attitude',
      'interest': 'Interest',
      'punctuality': 'Punctuality',
    };

    final list = <Map<String, dynamic>>[];
    for (final entry in fieldLabels.entries) {
      final value = (comments[entry.key] ?? '').toString().trim();
      list.add({
        'key': entry.key,
        'label': entry.value,
        'value': value,
        'isEmpty': value.isEmpty,
        'color': _getRatingColor(value),
      });
    }
    return list;
  }

  String _getRatingColor(String value) {
    switch (value.toLowerCase()) {
      case 'excellent': return '#4CAF50';
      case 'very good': return '#8BC34A';
      case 'good': return '#2196F3';
      case 'fair': return '#FF9800';
      case 'poor': return '#F44336';
      default: return '#9E9E9E';
    }
  }

  bool hasBehavioralData(Map<String, dynamic>? comments) {
    if (comments == null) return false;
    return ['conduct', 'attitude', 'interest', 'punctuality'].any(
      (f) => (comments[f] ?? '').toString().trim().isNotEmpty,
    );
  }

  bool hasComments(Map<String, dynamic>? comments) {
    if (comments == null) return false;
    return ['teacher_comment', 'principal_comment', 'attendance_remark'].any(
      (f) => (comments[f] ?? '').toString().trim().isNotEmpty,
    );
  }
}
