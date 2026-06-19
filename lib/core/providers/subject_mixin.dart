// ==========================================
// File: lib/core/providers/subject_mixin.dart
// ==========================================
import 'package:flutter/foundation.dart';
import 'base_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mixin for subject management.
/// Handles loading, creating, updating, and deleting subjects.
/// Also loads class_subjects for per-class subject filtering.
///
/// GLOBAL SCALE FIX:
/// - Every operation filters by schoolId — tenant isolation
/// - Removed is_active references to match actual DB schema (subjects table has no is_active column)

mixin SubjectMixin on BaseProvider {
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _classSubjects = [];

  @override
  List<Map<String, dynamic>> get subjects => _subjects;

  /// Class-subject link records (which subjects belong to which class).
  /// Used by page_result.dart to filter subjects by selected class.
  List<Map<String, dynamic>> get classSubjects => _classSubjects;

  /// All subjects — for dropdowns and assignments
  List<Map<String, dynamic>> get activeSubjects => _subjects;

  @override
  Future<void> loadSubjects() async {
    if (schoolId.isEmpty) {
      _subjects = [];
      notifyListeners();
      return;
    }

    try {
      final r = await supabase
          .from('subjects')
          .select()
          .eq('school_id', schoolId)
          .order('name');
      _subjects = List<Map<String, dynamic>>.from(r);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading subjects: $e');
      _subjects = [];
      notifyListeners();
    }
  }

  /// Load class_subjects for the school.
  /// Called during core data loading alongside loadSubjects().
  Future<void> loadClassSubjects() async {
    if (schoolId.isEmpty) {
      _classSubjects = [];
      notifyListeners();
      return;
    }

    try {
      final r = await supabase
          .from('class_subjects')
          .select('id, school_id, class_id, subject_id, is_compulsory, teacher_id')
          .eq('school_id', schoolId);
      _classSubjects = List<Map<String, dynamic>>.from(r);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading class subjects: $e');
      _classSubjects = [];
      notifyListeners();
    }
  }

  /// Add a subject to a class (creates a class_subjects row).
  /// Returns true on success.
  Future<bool> addClassSubjectToDb({
    required String classId,
    required String subjectId,
    bool isCompulsory = true,
    String? teacherId,
  }) async {
    if (schoolId.isEmpty || classId.isEmpty || subjectId.isEmpty) return false;

    try {
      // Check if already linked
      final existing = _classSubjects.any((cs) =>
          cs['class_id']?.toString() == classId &&
          cs['subject_id']?.toString() == subjectId);
      if (existing) return true; // Already linked, no error

      final insertData = <String, dynamic>{
        'school_id': schoolId,
        'class_id': classId,
        'subject_id': subjectId,
        'is_compulsory': isCompulsory,
        'teacher_id': teacherId,
      };

      final r = await supabase
          .from('class_subjects')
          .insert(insertData)
          .select()
          .single();

      _classSubjects.add(Map<String, dynamic>.from(r));

      logAudit(
        action: 'create',
        tableName: 'class_subjects',
        recordId: r['id']?.toString(),
        newData: {'class_id': classId, 'subject_id': subjectId},
      );
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding class subject: $e');
      return false;
    }
  }

  /// Remove a subject from a class (deletes the class_subjects row by its id).
  Future<bool> removeClassSubjectFromDb(String classSubjectId) async {
    if (schoolId.isEmpty || classSubjectId.isEmpty) return false;

    try {
      await supabase
          .from('class_subjects')
          .delete()
          .eq('id', classSubjectId)
          .eq('school_id', schoolId);

      _classSubjects.removeWhere(
          (cs) => cs['id']?.toString() == classSubjectId);

      logAudit(
        action: 'delete',
        tableName: 'class_subjects',
        recordId: classSubjectId,
      );
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error removing class subject: $e');
      return false;
    }
  }

  /// Update teacher_id on a class_subjects row.
  Future<bool> updateClassSubjectTeacher(String classSubjectId, String? teacherId) async {
    if (schoolId.isEmpty || classSubjectId.isEmpty) return false;

    try {
      final r = await supabase
          .from('class_subjects')
          .update({'teacher_id': teacherId})
          .eq('id', classSubjectId)
          .eq('school_id', schoolId)
          .select()
          .single();

      final i = _classSubjects.indexWhere(
          (cs) => cs['id']?.toString() == classSubjectId);
      if (i != -1) {
        _classSubjects[i] = Map<String, dynamic>.from(r);
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating class subject teacher: $e');
      return false;
    }
  }

  /// Get subject IDs linked to a specific class.
  Set<String> getSubjectIdsForClass(String? classId) {
    if (classId == null || classId.isEmpty) return {};
    return _classSubjects
        .where((cs) => cs['class_id']?.toString() == classId)
        .map((cs) => cs['subject_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  /// Get full class_subjects records for a specific class.
  List<Map<String, dynamic>> getClassSubjectsForClass(String? classId) {
    if (classId == null || classId.isEmpty) return [];
    return _classSubjects
        .where((cs) => cs['class_id']?.toString() == classId)
        .toList();
  }

  /// Check if a subject is linked to a class.
  bool isSubjectInClass(String? subjectId, String? classId) {
    if (subjectId == null || classId == null) return false;
    return _classSubjects.any((cs) =>
        cs['subject_id']?.toString() == subjectId &&
        cs['class_id']?.toString() == classId);
  }

  /// Add a new subject to the database.
  /// Prevents duplicate subject names and codes within the same school.
  Future<bool> addSubjectToDb(Map<String, dynamic> subj) async {
    if (schoolId.isEmpty) return false;

    try {
      final name = (subj['name'] ?? '').toString().trim();
      if (name.isEmpty) return false;

      // Check duplicate NAME within school
      final existingName = await supabase
          .from('subjects')
          .select('id')
          .eq('school_id', schoolId)
          .eq('name', name)
          .maybeSingle();
      if (existingName != null) throw Exception('Subject already exists');

      // Check duplicate CODE within school
      if (subj['code'] != null && subj['code'].toString().trim().isNotEmpty) {
        final code = subj['code'].toString().trim();
        final existingCode = await supabase
            .from('subjects')
            .select('id')
            .eq('school_id', schoolId)
            .eq('code', code)
            .maybeSingle();
        if (existingCode != null) throw Exception('Subject code already exists');
      }

      final insertData = <String, dynamic>{
        'school_id': schoolId,
        'name': name,
        'code': subj['code'] != null && subj['code'].toString().trim().isNotEmpty
            ? subj['code'].toString().trim()
            : null,
        'is_elective': subj['is_elective'] ?? false,
        'description': subj['description'] ?? '',
      };

      final r = await supabase
          .from('subjects')
          .insert(insertData)
          .select()
          .single();

      _subjects.add(Map<String, dynamic>.from(r));

      logAudit(
        action: 'create',
        tableName: 'subjects',
        recordId: r['id']?.toString(),
        newData: {'name': insertData['name'], 'code': insertData['code']},
      );
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding subject: $e');
      return false;
    }
  }

  /// Update a subject in the database.
  Future<bool> updateSubjectInDb(String id, Map<String, dynamic> updates) async {
    if (id.isEmpty || schoolId.isEmpty) return false;

    try {
      final s = _subjects.cast<Map<String, dynamic>?>().firstWhere(
            (s) => s?['id']?.toString() == id,
            orElse: () => <String, dynamic>{},
          );
      if (s == null || s.isEmpty) return false;

      final u = Map<String, dynamic>.from(updates)
        ..remove('id')
        ..remove('school_id')
        ..remove('created_at')
        ..remove('updated_at');

      if (u.isEmpty) return false;

      final r = await supabase
          .from('subjects')
          .update(u)
          .eq('id', id)
          .eq('school_id', schoolId)
          .select()
          .single();

      final i = _subjects.indexWhere((s) => s['id']?.toString() == id);
      if (i != -1) {
        _subjects[i] = Map<String, dynamic>.from(r);
      }

      logAudit(
        action: 'update',
        tableName: 'subjects',
        recordId: id,
        newData: u,
      );
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating subject: $e');
      return false;
    }
  }

  /// Hard delete a subject.
  Future<bool> deleteSubjectFromDb(String id) async {
    if (id.isEmpty || schoolId.isEmpty) return false;

    try {
      await supabase
          .from('subjects')
          .delete()
          .eq('id', id)
          .eq('school_id', schoolId);

      _subjects.removeWhere((s) => s['id']?.toString() == id);

      logAudit(action: 'delete', tableName: 'subjects', recordId: id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting subject: $e');
      return false;
    }
  }

  // ==========================================
  // UTILITY METHODS
  // ==========================================

  /// Get a single subject by ID. Returns null if not found.
  Map<String, dynamic>? getSubjectById(String? subjectId) {
    if (subjectId == null || subjectId.isEmpty) return null;
    try {
      return _subjects.cast<Map<String, dynamic>?>().firstWhere(
            (s) => s?['id']?.toString() == subjectId,
            orElse: () => null,
          );
    } catch (e) {
      return null;
    }
  }

  /// Get a single subject by code. Returns null if not found.
  Map<String, dynamic>? getSubjectByCode(String code) {
    if (code.isEmpty) return null;
    try {
      return _subjects.cast<Map<String, dynamic>?>().firstWhere(
            (s) => s?['code']?.toString().toLowerCase() == code.toLowerCase(),
            orElse: () => null,
          );
    } catch (e) {
      return null;
    }
  }

  /// Get subject display name with code (e.g. "Mathematics (MTH)").
  String getSubjectDisplayName(Map<String, dynamic>? subjectData) {
    if (subjectData == null) return '';
    final name = (subjectData['name'] ?? '').toString();
    final code = (subjectData['code'] ?? '').toString();
    if (code.isNotEmpty) return '$name ($code)';
    return name;
  }

  /// Get just the subject name, safely.
  String getSubjectName(String? subjectId) {
    if (subjectId == null || subjectId.isEmpty) return '';
    final subj = getSubjectById(subjectId);
    return (subj?['name'] ?? '').toString();
  }

  /// Get just the subject code, safely.
  String getSubjectCode(String? subjectId) {
    if (subjectId == null || subjectId.isEmpty) return '';
    final subj = getSubjectById(subjectId);
    return (subj?['code'] ?? '').toString();
  }

  /// Check if a subject is elective.
  bool isElective(String? subjectId) {
    final subj = getSubjectById(subjectId);
    return subj?['is_elective'] == true;
  }

  /// Get all compulsory (non-elective) subjects.
  List<Map<String, dynamic>> get compulsorySubjects =>
      _subjects.where((s) => s['is_elective'] != true).toList();

  /// Get all elective subjects.
  List<Map<String, dynamic>> get electiveSubjects =>
      _subjects.where((s) => s['is_elective'] == true).toList();

  /// Check if a subject name already exists (for UI validation).
  bool subjectNameExists(String name) {
    if (name.isEmpty) return false;
    return _subjects.any((s) =>
        s['name']?.toString().trim().toLowerCase() == name.trim().toLowerCase());
  }

  /// Check if a subject code already exists (for UI validation).
  bool subjectCodeExists(String code) {
    if (code.isEmpty) return false;
    return _subjects.any((s) =>
        s['code']?.toString().trim().toLowerCase() == code.trim().toLowerCase());
  }

  /// Get subjects that are NOT yet assigned to a given teacher.
  List<Map<String, dynamic>> getUnassignedSubjects(List<Map<String, dynamic>> assignedSubjects) {
    final assignedIds = assignedSubjects
        .map((a) => a['subject_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    return activeSubjects.where((s) => !assignedIds.contains(s['id']?.toString())).toList();
  }

  /// Get total active subject count.
  int get subjectCount => _subjects.length;

  // ==========================================
  // LEGACY (backward compat — local state only)
  // ==========================================

  void addSubject(Map<String, dynamic> s) {
    _subjects.add(Map<String, dynamic>.from(s));
    notifyListeners();
  }

  void deleteSubject(Map<String, dynamic> s) {
    _subjects.removeWhere((su) => su['id']?.toString() == s['id']?.toString());
    notifyListeners();
  }
}
