// ==========================================
// File: lib/core/providers/assignment_mixin.dart
// ==========================================
import 'package:flutter/foundation.dart';
import '../services/db_proxy.dart';
import 'base_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

mixin AssignmentMixin on BaseProvider {

  List<Map<String, dynamic>> _assignments = [];
  List<Map<String, dynamic>> _formTeacherAssignments = [];
  List<Map<String, dynamic>> _subjectTeacherAssignments = [];

  @override
  List<Map<String, dynamic>> get assignments => _assignments;

  List<Map<String, dynamic>> get formTeacherAssignments => _formTeacherAssignments;
  List<Map<String, dynamic>> get subjectTeacherAssignments => _subjectTeacherAssignments;

  // ==========================================
  // LOADING
  // ==========================================

  @override
  Future<void> loadAssignments() async {
    try {
      final r = await supabase
          .from('assignments')
          .select('*, '
              'teachers(first_name, last_name), '
              'subjects(name, code), '
              'classes(name, section)')
          .eq('school_id', schoolId);

      _assignments = List<Map<String, dynamic>>.from(r);
    } catch (e) {
      debugPrint('Error loading assignments: $e');
    }
  }

  Future<void> loadSubjectTeacherAssignments() async {
    try {
      final r = await supabase
          .from('subject_teacher_assignments')
          .select('*, '
              'teachers(first_name, last_name, staff_id), '
              'subjects(name, code), '
              'classes(name, section)')
          .eq('school_id', schoolId);

      _subjectTeacherAssignments = List<Map<String, dynamic>>.from(r);
    } catch (e) {
      debugPrint('Error loading subject teacher assignments: $e');
    }
  }

  Future<void> loadFormTeacherAssignments() async {
    try {
      final r = await supabase
          .from('form_teacher_assignments')
          .select('*, '
              'teachers(first_name, last_name, staff_id), '
              'classes(name, section)')
          .eq('school_id', schoolId);

      _formTeacherAssignments = List<Map<String, dynamic>>.from(r);
    } catch (e) {
      debugPrint('Error loading form teacher assignments: $e');
    }
  }

  Future<void> loadAllAssignments() async {
    await Future.wait([
      loadAssignments(),
      loadSubjectTeacherAssignments(),
      loadFormTeacherAssignments(),
    ]);
  }

  // ==========================================
  // HOMEWORK ASSIGNMENTS CRUD
  // ==========================================

  Future<Map<String, dynamic>?> addHomeworkToDb({
    required String teacherId,
    required String subjectId,
    required String classId,
    required String title,
    String description = '',
    required DateTime dueDate,
    int totalMarks = 20,
    String? attachmentUrl,
  }) async {
    if (currentSession == null) return null;

    try {
      final insertData = <String, dynamic>{
        'school_id': schoolId,
        'teacher_id': teacherId,
        'subject_id': subjectId,
        'class_id': classId,
        'session_id': currentSession!['id'],
        'term_id': currentTerm?['id'],
        'title': title.trim(),
        'description': description,
        'due_date': dueDate.toUtc().toIso8601String(),
        'total_marks': totalMarks,
        'attachment_url': attachmentUrl ?? '',
        'is_published': false,
      };

      final r = await supabase
          .from('assignments')
          .insert(insertData)
          .select('*, teachers(first_name, last_name), subjects(name, code), classes(name, section)')
          .single();

      _assignments.insert(0, Map<String, dynamic>.from(r));

      logAudit(
        action: 'create',
        tableName: 'assignments',
        recordId: r['id']?.toString(),
        newData: {'title': title, 'class_id': classId, 'subject_id': subjectId},
      );
      notifyListeners();
      return r;
    } catch (e) {
      debugPrint('Error adding homework: $e');
      return null;
    }
  }

  Future<bool> toggleHomeworkPublished(String id, bool published) async {
    try {
      await supabase
          .from('assignments')
          .update({'is_published': published})
          .eq('id', id)
          .eq('school_id', schoolId);

      final i = _assignments.indexWhere((a) => a['id']?.toString() == id);
      if (i != -1) {
        _assignments[i] = Map<String, dynamic>.from(_assignments[i]);
        _assignments[i]['is_published'] = published;
      }

      logAudit(action: published ? 'publish' : 'unpublish', tableName: 'assignments', recordId: id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error toggling homework published: $e');
      return false;
    }
  }

  Future<bool> deleteHomeworkFromDb(String id) async {
    try {
      await DbProxy.instance.from('assignments').eq('id', id).eq('school_id', schoolId).delete();
      _assignments.removeWhere((a) => a['id']?.toString() == id);
      logAudit(action: 'delete', tableName: 'assignments', recordId: id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting homework: $e');
      return false;
    }
  }

  List<Map<String, dynamic>> getHomeworkForClass(String classId) {
    return _assignments.where((a) => a['class_id']?.toString() == classId).toList();
  }

  List<Map<String, dynamic>> getPublishedHomeworkForClass(String classId) {
    return _assignments.where((a) => a['class_id']?.toString() == classId && a['is_published'] == true).toList();
  }

  List<Map<String, dynamic>> getHomeworkByTeacher(String teacherId) {
    return _assignments.where((a) => a['teacher_id']?.toString() == teacherId).toList();
  }

  // ==========================================
  // SUBJECT-TEACHER ASSIGNMENTS
  // ==========================================

  Future<bool> addSubjectTeacherToDb(Map<String, dynamic> assign) async {
    if (currentSession == null) return false;

    try {
      final r = await supabase
          .from('subject_teacher_assignments')
          .insert({
            'school_id': schoolId,
            'class_id': assign['class_id'],
            'subject_id': assign['subject_id'],
            'teacher_id': assign['teacher_id'],
            'session_id': currentSession!['id'],
          })
          .select('*, teachers(first_name, last_name), subjects(name, code), classes(name, section)')
          .single();

      _subjectTeacherAssignments.add(Map<String, dynamic>.from(r));

      logAudit(
        action: 'create',
        tableName: 'subject_teacher_assignments',
        recordId: r['id']?.toString(),
        newData: {'class_id': assign['class_id'], 'subject_id': assign['subject_id'], 'teacher_id': assign['teacher_id']},
      );
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding subject teacher: $e');
      return false;
    }
  }

  Future<bool> deleteSubjectTeacherFromDb(String id) async {
    try {
      await supabase.from('subject_teacher_assignments').delete().eq('id', id).eq('school_id', schoolId);
      _subjectTeacherAssignments.removeWhere((a) => a['id']?.toString() == id);
      logAudit(action: 'delete', tableName: 'subject_teacher_assignments', recordId: id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting subject teacher: $e');
      return false;
    }
  }

  Future<bool> saveSubjectTeacherAssignmentsToDb(Map<String, Map<String, String?>> selections) async {
    if (currentSession == null) return false;

    try {
      await supabase
          .from('subject_teacher_assignments')
          .delete()
          .eq('school_id', schoolId)
          .eq('session_id', currentSession!['id']);

      final rows = <Map<String, dynamic>>[];
      for (final classEntry in selections.entries) {
        for (final subjectEntry in classEntry.value.entries) {
          if (subjectEntry.value != null && subjectEntry.value!.isNotEmpty) {
            rows.add({
              'school_id': schoolId,
              'class_id': classEntry.key,
              'subject_id': subjectEntry.key,
              'teacher_id': subjectEntry.value,
              'session_id': currentSession!['id'],
            });
          }
        }
      }

      if (rows.isNotEmpty) {
        await supabase.from('subject_teacher_assignments').insert(rows);
      }

      logAudit(action: 'bulk_replace', tableName: 'subject_teacher_assignments', newData: {'count': rows.length});
      await loadSubjectTeacherAssignments();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving subject teacher assignments: $e');
      return false;
    }
  }

  List<Map<String, dynamic>> getSubjectTeachersForClass(String classId) {
    return _subjectTeacherAssignments.where((a) => a['class_id']?.toString() == classId).toList();
  }

  List<Map<String, dynamic>> getSubjectTeachersForTeacher(String teacherId) {
    return _subjectTeacherAssignments.where((a) => a['teacher_id']?.toString() == teacherId).toList();
  }

  List<Map<String, dynamic>> getSubjectsForTeacher(String teacherId) {
    final seen = <String>{};
    final result = <Map<String, dynamic>>[];
    for (final a in _subjectTeacherAssignments) {
      if (a['teacher_id']?.toString() == teacherId) {
        final subId = a['subject_id']?.toString() ?? '';
        if (subId.isNotEmpty && !seen.contains(subId)) {
          seen.add(subId);
          final subData = a['subjects'];
          result.add(subData is Map<String, dynamic> ? Map<String, dynamic>.from(subData) : {'id': subId, 'name': 'Unknown', 'code': ''});
        }
      }
    }
    return result;
  }

  // ==========================================
  // FORM TEACHER ASSIGNMENTS
  // ==========================================

  Future<bool> saveFormTeacherAssignmentsToDb(Map<String, String?> selections) async {
    if (currentSession == null) return false;

    try {
      await supabase
          .from('form_teacher_assignments')
          .delete()
          .eq('school_id', schoolId)
          .eq('session_id', currentSession!['id']);

      final rows = <Map<String, dynamic>>[];
      for (final entry in selections.entries) {
        if (entry.value != null && entry.value!.isNotEmpty) {
          rows.add({
            'school_id': schoolId,
            'class_id': entry.key,
            'teacher_id': entry.value,
            'session_id': currentSession!['id'],
          });
        }
      }

      if (rows.isNotEmpty) {
        await supabase.from('form_teacher_assignments').insert(rows);
      }

      logAudit(action: 'bulk_replace', tableName: 'form_teacher_assignments', newData: {'count': rows.length});
      await loadFormTeacherAssignments();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving form teacher assignments: $e');
      return false;
    }
  }

  Map<String, dynamic>? getFormTeacherForClass(String classId) {
    if (classId.isEmpty) return null;

    try {
      final a = _formTeacherAssignments.cast<Map<String, dynamic>?>().firstWhere(
            (a) => a?['class_id']?.toString() == classId,
            orElse: () => null,
          );

      if (a == null) return null;

      final teacherData = a['teachers'];
      if (teacherData is Map<String, dynamic>) {
        return Map<String, dynamic>.from(teacherData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String getFormTeacherName(String classId) {
    final ft = getFormTeacherForClass(classId);
    if (ft == null) return 'Not Assigned';
    final first = (ft['first_name'] ?? '').toString();
    final last = (ft['last_name'] ?? '').toString();
    if (first.isEmpty && last.isEmpty) return 'Not Assigned';
    return '$first $last'.trim();
  }

  List<Map<String, dynamic>> getFormTeacherClasses(String teacherId) {
    return _formTeacherAssignments.where((a) => a['teacher_id']?.toString() == teacherId).toList();
  }

  // ==========================================
  // UTILITY
  // ==========================================

  String getAssignmentDisplay(Map<String, dynamic>? assignment) {
    if (assignment == null) return '';
    final subject = assignment['subjects'];
    final cls = assignment['classes'];
    final teacher = assignment['teachers'];

    final subName = subject is Map ? (subject['name'] ?? '').toString() : '';
    final className = cls is Map ? (cls['name'] ?? '').toString() : '';
    final section = cls is Map ? (cls['section'] ?? '').toString() : '';
    final teacherName = teacher is Map
        ? '${(teacher['first_name'] ?? '').toString()} ${(teacher['last_name'] ?? '').toString()}'.trim()
        : '';

    final parts = <String>[
      if (subName.isNotEmpty) subName,
      if (className.isNotEmpty) className,
      if (section.isNotEmpty) '($section)',
    ].join(' - ');

    if (teacherName.isNotEmpty) return '$parts — $teacherName';
    return parts;
  }

  String getHomeworkDisplay(Map<String, dynamic>? homework) {
    if (homework == null) return '';
    final title = (homework['title'] ?? '').toString();
    final dueDateStr = (homework['due_date'] ?? '').toString();
    if (dueDateStr.isEmpty) return title;
    final dueDate = DateTime.tryParse(dueDateStr);
    if (dueDate == null) return title;
    final now = DateTime.now();
    final isOverdue = dueDate.isBefore(now);
    final daysLeft = dueDate.difference(now).inDays;
    final dueLabel = isOverdue
        ? 'Overdue'
        : daysLeft == 0
            ? 'Due today'
            : '$daysLeft day${daysLeft == 1 ? '' : 's'} left';
    return '$title ($dueLabel)';
  }

  // ==========================================
  // LOCAL STATE
  // ==========================================

  void addAssignment(Map<String, dynamic> a) {
    _assignments.add(Map<String, dynamic>.from(a));
    notifyListeners();
  }

  void deleteAssignment(Map<String, dynamic> a) {
    _assignments.removeWhere((x) => x['id']?.toString() == a['id']?.toString());
    notifyListeners();
  }
}
