// ==========================================
// File: lib/core/providers/school_admin_provider.dart
// ==========================================
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:smartedu/utils/grading_utils.dart';
import '../services/db_proxy.dart';
import 'base_provider.dart';
import 'session_mixin.dart';
import 'comment_mixin.dart';
import 'student_mixin.dart';
import 'teacher_mixin.dart';
import 'class_mixin.dart';
import 'subject_mixin.dart';
import 'assignment_mixin.dart';
import 'score_mixin.dart';
import 'cbt_mixin.dart';
import 'attendance_mixin.dart';
import 'fee_mixin.dart';
import 'cbt_question_mixin.dart';

class SchoolAdminProvider extends BaseProvider
    with
        SessionMixin,
        CommentMixin,
        StudentMixin,
        TeacherMixin,
        ClassMixin,
        SubjectMixin,
        AssignmentMixin,
        ScoreMixin,
        CbtMixin,
        AttendanceMixin,
        FeeMixin,
        CbtQuestionMixin {

  // ==========================================
  // TIER-AWARE GRADING & ASSESSMENT
  // All tier methods now use BaseProvider's schoolSettings getter
  // instead of a shadowed local _schoolSettings map.
  // ==========================================

  String _defaultTemplateForTier(String tier) {
    switch (tier) {
      case 'JSS': return 'BECE';
      case 'PRIMARY': return 'PRIMARY';
      default: return examTemplate;
    }
  }

  String _gradingKey(String tier) {
    switch (tier) {
      case 'JSS': return 'grading_system_jss';
      case 'PRIMARY': return 'grading_system_primary';
      default: return 'grading_system';
    }
  }

  String _assessmentKey(String tier) {
    switch (tier) {
      case 'JSS': return 'assessment_types_jss';
      case 'PRIMARY': return 'assessment_types_primary';
      default: return 'assessment_types';
    }
  }

  List<Map<String, dynamic>> getTierGradingOverride(String tier) {
    final raw = schoolSettings?[_gradingKey(tier)];
    if (raw == null) return [];
    if (raw is List) return List<Map<String, dynamic>>.from(raw);
    return [];
  }

  List<Map<String, dynamic>> getTierAssessmentOverride(String tier) {
    final raw = schoolSettings?[_assessmentKey(tier)];
    if (raw == null) return [];
    if (raw is List) return List<Map<String, dynamic>>.from(raw);
    return [];
  }

  List<Map<String, dynamic>> getEffectiveGradingForTier(String tier) {
    // American standard overrides everything
    final standard = (schoolSettings?['grading_standard'] ?? '').toString().toLowerCase();
    if (standard == 'american') return GradingUtils.getDefaultGradingSystem('AMERICAN');
    final override = getTierGradingOverride(tier);
    if (override.isNotEmpty) return override;
    return GradingUtils.getGradingSystemForTier(tier, schoolSettings ?? {});
  }

  List<Map<String, dynamic>> getEffectiveAssessmentForTier(String tier) {
    // American standard overrides everything
    final standard = (schoolSettings?['grading_standard'] ?? '').toString().toLowerCase();
    if (standard == 'american') return GradingUtils.getDefaultAssessmentTypes('AMERICAN');
    final override = getTierAssessmentOverride(tier);
    if (override.isNotEmpty) return override;
    return GradingUtils.getAssessmentTypesForTier(tier, schoolSettings ?? {});
  }

  bool hasTierGradingOverride(String tier) => schoolSettings?[_gradingKey(tier)] != null;
  bool hasTierAssessmentOverride(String tier) => schoolSettings?[_assessmentKey(tier)] != null;

  Future<bool> updateTierGrading(String tier, List<Map<String, dynamic>> grading) async {
    if (schoolId.isEmpty) return false;
    try {
      final key = _gradingKey(tier);
      await supabase
          .from('school_settings')
          .update({key: grading, 'updated_at': DateTime.now().toIso8601String()})
          .eq('school_id', schoolId);
      logAudit(action: 'update', tableName: 'school_settings', newData: {key: '${grading.length} grades'});
      await refreshSchoolInfo();
      return true;
    } catch (e) {
      debugPrint('Error updating tier grading: $e');
      return false;
    }
  }

  Future<bool> updateTierAssessment(String tier, List<Map<String, dynamic>> assessment) async {
    if (schoolId.isEmpty) return false;
    try {
      final key = _assessmentKey(tier);
      await supabase
          .from('school_settings')
          .update({key: assessment, 'updated_at': DateTime.now().toIso8601String()})
          .eq('school_id', schoolId);
      logAudit(action: 'update', tableName: 'school_settings', newData: {key: '${assessment.length} types'});
      await refreshSchoolInfo();
      return true;
    } catch (e) {
      debugPrint('Error updating tier assessment: $e');
      return false;
    }
  }

  Future<bool> resetTierToDefault(String tier) async {
    if (schoolId.isEmpty) return false;
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
        _gradingKey(tier): null,
        _assessmentKey(tier): null,
      };
      await DbProxy.instance.from('school_settings').eq('school_id', schoolId).update(updates);
      logAudit(action: 'update', tableName: 'school_settings', newData: {'reset_tier': tier});
      await refreshSchoolInfo();
      return true;
    } catch (e) {
      debugPrint('Error resetting tier: $e');
      return false;
    }
  }

  Future<bool> updateGradingStandard(String standard) async {
    if (schoolId.isEmpty) return false;
    try {
      await DbProxy.instance.from('school_settings').eq('school_id', schoolId).update({
        'grading_standard': standard,
        'updated_at': DateTime.now().toIso8601String(),
      });
      logAudit(action: 'update', tableName: 'school_settings', newData: {'grading_standard': standard});
      if (schoolSettings != null) {
        schoolSettings!['grading_standard'] = standard;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating grading standard: $e');
      return false;
    }
  }

  // ==========================================
  // BEHAVIORAL RATINGS (11 Nigerian Standard)
  // ==========================================

  /// Save behavioral ratings for a student for a session/term.
  /// ratingsMap keys must match GradingUtils.behavioralFieldKeys.
  Future<bool> saveBehavioralRatings({
    required String studentId,
    required String classId,
    required String sessionId,
    required String termId,
    required Map<String, String> ratingsMap,
  }) async {
    if (schoolId.isEmpty) return false;
    try {
      // Upsert: check if exists
      final existing = await supabase
          .from('student_behavioural_ratings')
          .select('id')
          .eq('school_id', schoolId)
          .eq('student_id', studentId)
          .eq('class_id', classId)
          .eq('session_id', sessionId)
          .eq('term_id', termId)
          .maybeSingle();

      final data = <String, dynamic>{
        'school_id': schoolId,
        'student_id': studentId,
        'class_id': classId,
        'session_id': sessionId,
        'term_id': termId,
        'recorded_by': currentUserId,
        'updated_at': DateTime.now().toIso8601String(),
      };
      data.addAll(ratingsMap);

      if (existing != null) {
        await supabase
            .from('student_behavioural_ratings')
            .update(data)
            .eq('id', existing['id']);
      } else {
        await supabase
            .from('student_behavioural_ratings')
            .insert(data);
      }
      return true;
    } catch (e) {
      debugPrint('Error saving behavioral ratings: $e');
      return false;
    }
  }

  /// Load behavioral ratings for a student for a session/term.
  /// Returns a map of field_key -> rating value, or empty map if none.
  Future<Map<String, String>> loadBehavioralRatings({
    required String studentId,
    required String sessionId,
    required String termId,
  }) async {
    if (schoolId.isEmpty) return {};
    try {
      final row = await supabase
          .from('student_behavioural_ratings')
          .select()
          .eq('school_id', schoolId)
          .eq('student_id', studentId)
          .eq('session_id', sessionId)
          .eq('term_id', termId)
          .maybeSingle();

      if (row == null) return {};

      final result = <String, String>{};
      for (final key in GradingUtils.behavioralFieldKeys) {
        final val = row[key];
        if (val != null && val.toString().isNotEmpty) {
          result[key] = val.toString();
        }
      }
      return result;
    } catch (e) {
      debugPrint('Error loading behavioral ratings: $e');
      return {};
    }
  }

  /// Get current custom behavioral labels from school_settings.
  /// Returns null if no custom labels set (uses defaults).
  Map<String, dynamic>? get behavioralLabels {
    final raw = schoolSettings?['behavioral_labels'];
    if (raw == null) return null;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  /// Save custom behavioral labels to school_settings.behavioral_labels.
  /// labels map: {"punctuality": "Punctuality", "neatness": "Personal Hygiene", ...}
  /// Only non-empty values are saved. Empty values are removed (revert to default).
  Future<bool> updateBehavioralLabels(Map<String, String> labels) async {
    if (schoolId.isEmpty) return false;
    try {
      // Remove empty entries — they should fall back to defaults
      final cleaned = <String, String>{};
      for (final entry in labels.entries) {
        if (entry.value.trim().isNotEmpty) {
          cleaned[entry.key] = entry.value.trim();
        }
      }
      // If all empty, store null to clear custom labels
      final value = cleaned.isEmpty ? null : cleaned;
      await DbProxy.instance.from('school_settings').eq('school_id', schoolId).update({
        'behavioral_labels': value,
        'updated_at': DateTime.now().toIso8601String(),
      });
      // Update local state immediately
      if (schoolSettings != null) {
        schoolSettings!['behavioral_labels'] = value;
        notifyListeners();
      }
      logAudit(action: 'update', tableName: 'school_settings', newData: {'behavioral_labels': '${cleaned.length} custom labels'});
      return true;
    } catch (e) {
      debugPrint('Error updating behavioral labels: $e');
      return false;
    }
  }

  // ==========================================
  // SCHOOL SETTINGS (thin wrappers around BaseProvider)
  // All shadowed fields removed — uses BaseProvider's getters.
  // ==========================================

  /// Thin wrapper for page_settings.dart backward compat.
  Future<bool> updateSchoolSettings(String name, String address, String phone, String email) async {
    return updateSchoolSettingsInDb(
      name: name,
      address: address,
      officialPhone: phone,
      email: email,
    );
  }

  @override
  Future<bool> updateSchoolBranding({
    String? motto,
    String? principalName,
    String? examTemplate,
    List<Map<String, dynamic>>? gradingSystem,
    List<Map<String, dynamic>>? assessmentTypes,
    int? subjectMaxScore,
    bool? showPosition,
    bool? showGradeOnly,
  }) async {
    if (schoolId.isEmpty) return false;
    try {
      final settingsUpdates = <String, dynamic>{};
      if (principalName != null) settingsUpdates['principal_name'] = principalName;
      if (examTemplate != null) settingsUpdates['exam_template'] = examTemplate;
      if (gradingSystem != null) settingsUpdates['grading_system'] = gradingSystem;
      if (assessmentTypes != null) settingsUpdates['assessment_types'] = assessmentTypes;
      if (subjectMaxScore != null) settingsUpdates['subject_max_score'] = subjectMaxScore;
      if (showPosition != null) settingsUpdates['show_position'] = showPosition;
      if (showGradeOnly != null) settingsUpdates['show_grade_only'] = showGradeOnly;

      if (settingsUpdates.isNotEmpty) {
        settingsUpdates['updated_at'] = DateTime.now().toIso8601String();
        await DbProxy.instance.from('school_settings').eq('school_id', schoolId).update(settingsUpdates);
      }

      if (motto != null) {
        await DbProxy.instance.from('schools').eq('id', schoolId).update({'motto': motto});
      }

      logAudit(action: 'update_school_branding', tableName: 'school_settings', newData: settingsUpdates);
      await refreshSchoolInfo();
      return true;
    } catch (e) {
      debugPrint('Error updating school branding: $e');
      return false;
    }
  }

  Future<bool> updateSchoolLogo(String filePath) async {
    try {
      final publicUrl = supabase.storage.from('school-logos').getPublicUrl(filePath);
      await DbProxy.instance.from('schools').eq('id', schoolId).update({'logo_url': publicUrl});
      logAudit(action: 'update_school_logo', tableName: 'schools', newData: {'logo_url': publicUrl});
      await refreshSchoolInfo();
      return true;
    } catch (e) {
      debugPrint('Error updating school logo: $e');
      return false;
    }
  }

  // ==========================================
  // SESSIONS & COMMENTS
  // ==========================================

  List<Map<String, dynamic>> get sessions {
    try {
      return sessionsList;
    } catch (_) {
      return [];
    }
  }

  Map<String, Map<String, dynamic>> _termCommentsCache = {};

  Future<void> loadTermCommentsForClass(String classId) async {
    final comments = await getTermCommentsForClass(classId: classId);
    _termCommentsCache.clear();
    for (final c in comments) {
      final sid = c['student_id']?.toString() ?? '';
      if (sid.isNotEmpty) _termCommentsCache[sid] = c;
    }
    notifyListeners();
  }

  @override
  Map<String, dynamic>? getBehavioralForStudent(String studentId, String? termId) {
    return _termCommentsCache[studentId];
  }

  void clearBehavioralCache() {
    _termCommentsCache.clear();
  }

  // ==========================================
  // INITIALIZATION
  // ==========================================

  Future<void> initializeWithSchool({
    required Map<String, dynamic> loginData,
    required String schoolId,
    required String adminId,
  }) async {
    await initializeFromLoginData(loginData);
  }

  Future<void> refreshSettings() async {
    await refreshSchoolInfo();
  }
}
