// ==========================================
// File: lib/core/providers/class_mixin.dart
// ==========================================
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_provider.dart';

/// Mixin for class/section management.
/// Handles loading, creating, updating, and deleting classes.
///
/// MASTER PLAN V4:
/// - Every operation filters by schoolId — tenant isolation
/// - V4: Added class_level field support (sorting, grouping)
/// - V4: Fixed null filter for section (was comparing to string 'null' instead of SQL NULL)
/// - V4: Uses supabase getter from BaseProvider (consistent pattern)
/// - V4: Uses debugPrint instead of print
/// - V4: Fixed Postgrest v2 syntax (.is_ -> .isFilter)

mixin ClassMixin on BaseProvider {
  List<Map<String, dynamic>> _classes = [];

  @override
  List<Map<String, dynamic>> get classes => _classes;

  @override
  Future<void> loadClasses() async {
    try {
      final r = await supabase
          .from('classes')
          .select()
          .eq('school_id', schoolId)
          .order('name');
      _classes = List<Map<String, dynamic>>.from(r);
    } catch (e) {
      debugPrint('Error loading classes: $e');
    }
  }

  /// Add a new class to the database.
  /// Prevents duplicates by checking name + section combination.
  /// V4: Supports class_level field for sorting/grouping.
  Future<bool> addClassToDb(Map<String, dynamic> cls) async {
    try {
      // Build duplicate check query
      var q = supabase
          .from('classes')
          .select('id')
          .eq('school_id', schoolId)
          .eq('name', cls['name']);

      if (cls['section'] != null && cls['section'].toString().isNotEmpty) {
        q = q.eq('section', cls['section']);
      } else {
        // [FIX] Postgrest v2 renamed .is_() to .isFilter() to avoid Dart keyword conflict
        q = q.isFilter('section', null);
      }

      if (await q.maybeSingle() != null) {
        throw Exception('Class already exists');
      }

      // Insert with V4 class_level support
      final insertData = <String, dynamic>{
        'school_id': schoolId,
        'name': cls['name'],
        'section': cls['section'],
        'student_count': 0,
      };
      // class_level is optional — only include if provided
      if (cls['class_level'] != null && cls['class_level'].toString().isNotEmpty) {
        insertData['class_level'] = cls['class_level'].toString().trim();
      }

      final r = await supabase
          .from('classes')
          .insert(insertData)
          .select()
          .single();

      _classes.add(Map<String, dynamic>.from(r));

      logAudit(
        action: 'create',
        tableName: 'classes',
        recordId: r['id']?.toString(),
        newData: {'name': cls['name'], 'section': cls['section']},
      );
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding class: $e');
      return false;
    }
  }

  /// Update a class in the database.
  /// Protects id, school_id, created_at, student_count from overwrite.
  Future<bool> updateClassInDb(String id, Map<String, dynamic> updates) async {
    try {
      final c = _classes.cast<Map<String, dynamic>?>().firstWhere(
            (c) => c?['id']?.toString() == id,
            orElse: () => <String, dynamic>{},
          );
      if (c == null || c.isEmpty) return false;

      // Build safe update map — remove protected fields
      final u = Map<String, dynamic>.from(updates)
        ..remove('id')
        ..remove('school_id')
        ..remove('created_at')
        ..remove('updated_at')
        ..remove('student_count');

      if (u.isEmpty) return false;

      final r = await supabase
          .from('classes')
          .update(u)
          .eq('id', id)
          .eq('school_id', schoolId)
          .select()
          .single();

      final i = _classes.indexWhere((c) => c['id']?.toString() == id);
      if (i != -1) {
        _classes[i] = Map<String, dynamic>.from(r);
        // Preserve local student_count — DB may not reflect real-time changes
        _classes[i]['student_count'] = c['student_count'];
      }

      logAudit(
        action: 'update',
        tableName: 'classes',
        recordId: id,
        newData: u,
      );
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating class: $e');
      return false;
    }
  }

  /// Delete a class from the database.
  /// V4: Relies on DB ON DELETE CASCADE for scores, students, etc.
  Future<bool> deleteClassFromDb(String id) async {
    try {
      await supabase
          .from('classes')
          .delete()
          .eq('id', id)
          .eq('school_id', schoolId);

      _classes.removeWhere((c) => c['id']?.toString() == id);

      logAudit(action: 'delete', tableName: 'classes', recordId: id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting class: $e');
      return false;
    }
  }

  /// Get a single class by ID. Returns null if not found.
  Map<String, dynamic>? getClassById(String classId) {
    try {
      return _classes.cast<Map<String, dynamic>?>().firstWhere(
            (c) => c?['id']?.toString() == classId,
            orElse: () => null,
          );
    } catch (e) {
      return null;
    }
  }

  /// Get class display name (e.g. "SS1", "SS1 - A", "SS1 A").
  String getClassName(Map<String, dynamic>? classData) {
    if (classData == null) return '';
    final name = (classData['name'] ?? '').toString();
    final section = (classData['section'] ?? '').toString();
    if (section.isNotEmpty) return '$name - $section';
    return name;
  }

  /// Get full class display with level (e.g. "SS1 - A (Secondary)").
  String getFullClassName(Map<String, dynamic>? classData) {
    if (classData == null) return '';
    final base = getClassName(classData);
    final level = (classData['class_level'] ?? '').toString();
    if (level.isNotEmpty && level != base) return '$base ($level)';
    return base;
  }

  /// Get student count for a class. Returns 0 if class not found.
  int getStudentCount(String classId) {
    final cls = getClassById(classId);
    return (cls?['student_count'] as int?) ?? 0;
  }

  /// Update student count locally (without DB write).
  /// Used by student_mixin after bulk import to avoid N+1 DB calls.
  void updateLocalStudentCount(String classId, int delta) {
    final i = _classes.indexWhere((c) => c['id']?.toString() == classId);
    if (i != -1) {
      _classes[i] = Map<String, dynamic>.from(_classes[i]);
      _classes[i]['student_count'] = ((_classes[i]['student_count'] as int?) ?? 0) + delta;
      // Don't notifyListeners here — caller handles batch notification
    }
  }

  /// Sync a single class's student count from DB.
  Future<void> syncClassCountFromDb(String classId) async {
    try {
      final r = await supabase
          .from('classes')
          .select('student_count')
          .eq('id', classId)
          .maybeSingle();

      if (r != null) {
        final i = _classes.indexWhere((c) => c['id']?.toString() == classId);
        if (i != -1) {
          _classes[i] = Map<String, dynamic>.from(_classes[i]);
          _classes[i]['student_count'] = (r['student_count'] as int?) ?? 0;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error syncing class count: $e');
    }
  }

  // ==========================================
  // LEGACY (backward compat — local state only)
  // ==========================================

  /// Add class to local list only (no DB write).
  void addClass(Map<String, dynamic> c) {
    _classes.add(Map<String, dynamic>.from(c));
    notifyListeners();
  }

  /// Remove class from local list only (no DB write).
  void deleteClass(Map<String, dynamic> c) {
    _classes.removeWhere((cl) => cl['id']?.toString() == c['id']?.toString());
    notifyListeners();
  }
}
