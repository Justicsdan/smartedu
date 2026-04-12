import 'package:supabase_flutter/supabase_flutter.dart';
import 'teacher_base.dart';

mixin TeacherClassesMixin on TeacherBase {
  List<Map<String, dynamic>> _myClasses = [];
  List<Map<String, dynamic>> _mySubjectAssignments = [];
  List<Map<String, dynamic>> _studentsInMyClasses = [];

  bool _isFormMaster = false;
  bool _isSubjectTeacher = false;
  String? _formTeacherClassId;
  Map<String, dynamic>? _formTeacherClass;

  bool get isFormMaster => _isFormMaster;
  bool get isSubjectTeacher => _isSubjectTeacher;

  List<Map<String, dynamic>> get myClasses => _myClasses;
  List<Map<String, dynamic>> get mySubjectAssignments => _mySubjectAssignments;
  List<Map<String, dynamic>> get studentsInMyClasses => _studentsInMyClasses;

  @override
  String? get formTeacherClassId => _formTeacherClassId;

  @override
  Map<String, dynamic>? get formTeacherAssignment => _formTeacherClass;

  @override
  List<String> get assignedClassIds =>
      _myClasses.map((c) => c['id']?.toString() ?? '').where((id) => id.isNotEmpty).toSet().toList();

  @override
  List<Map<String, dynamic>> get assignedSubjects => _mySubjectAssignments;

  @override
  List<Map<String, dynamic>> get students => _studentsInMyClasses;

  @override
  Future<void> loadTeacherData() async {
    await _detectRoles();
    await _loadMyStudents();
    await loadMyAssignments();
  }

  Future<void> _detectRoles() async {
    try {
      final formR = await Supabase.instance.client
          .from('classes')
          .select('id, name, section, student_count, class_level, tier')
          .eq('school_id', schoolId)
          .eq('class_teacher_id', teacherId);

      if (formR.isNotEmpty) {
        _isFormMaster = true;
        _formTeacherClass = Map<String, dynamic>.from(formR.first);
        _formTeacherClass!['role'] = 'form_master';
        _formTeacherClassId = formR.first['id']?.toString();
      } else {
        _isFormMaster = false;
        _formTeacherClass = null;
        _formTeacherClassId = null;
      }

      final subR = await Supabase.instance.client
          .from('class_subjects')
          .select('id, class_id, subject_id, is_compulsory, subjects(name, code), classes(name, section, class_level, tier)')
          .eq('school_id', schoolId)
          .eq('teacher_id', teacherId);

      _mySubjectAssignments = List<Map<String, dynamic>>.from(subR);
      _isSubjectTeacher = _mySubjectAssignments.isNotEmpty;

      final classMap = <String, Map<String, dynamic>>{};

      if (_formTeacherClass != null) {
        final cid = _formTeacherClass!['id']?.toString() ?? '';
        if (cid.isNotEmpty) {
          classMap[cid] = Map<String, dynamic>.from(_formTeacherClass!);
        }
      }

      for (final a in _mySubjectAssignments) {
        final cid = a['class_id']?.toString() ?? '';
        if (cid.isEmpty) continue;
        if (!classMap.containsKey(cid)) {
          final cls = a['classes'] as Map<String, dynamic>? ?? {};
          classMap[cid] = {
            'id': cid,
            'name': cls['name'],
            'section': cls['section'],
            'student_count': cls['student_count'],
            'class_level': cls['class_level'],
            'tier': cls['tier'],
            'role': 'subject_teacher',
          };
        }
      }

      _myClasses = classMap.values.toList();
    } catch (e) {
      print('Error detecting roles: $e');
      _isFormMaster = false;
      _isSubjectTeacher = false;
      _formTeacherClass = null;
      _formTeacherClassId = null;
      _myClasses = [];
      _mySubjectAssignments = [];
    }
  }

  Future<void> _loadMyStudents() async {
    try {
      final classIds = assignedClassIds;
      if (classIds.isEmpty) {
        _studentsInMyClasses = [];
        return;
      }
      final r = await Supabase.instance.client
          .from('students')
          .select('*, classes(name, section)')
          .eq('school_id', schoolId)
          .eq('is_active', true)
          .inFilter('class_id', classIds)
          .order('first_name');
      _studentsInMyClasses = List<Map<String, dynamic>>.from(r);
    } catch (e) {
      print('Error loading my students: $e');
      _studentsInMyClasses = [];
    }
  }

  @override
  List<Map<String, dynamic>> getStudentsInClass(String classId) {
    return _studentsInMyClasses.where((s) => s['class_id']?.toString() == classId).toList();
  }

  List<Map<String, dynamic>> getMySubjectsForClass(String classId) {
    return _mySubjectAssignments.where((a) => a['class_id']?.toString() == classId).toList();
  }

  int getSubjectCountForClass(String classId) {
    return getMySubjectsForClass(classId).length;
  }

  @override
  String getClassName(String? id) {
    if (id == null) return 'Unknown';
    try {
      final c = _myClasses.firstWhere((c) => c['id']?.toString() == id);
      final name = c['name'] ?? '';
      final section = c['section'] ?? '';
      return section.isNotEmpty ? '$name $section' : name;
    } catch (_) {
      return 'Unknown';
    }
  }

  @override
  String getSubjectName(dynamic id) {
    if (id == null) return 'Unknown';
    try {
      final a = _mySubjectAssignments.firstWhere((a) => a['subject_id']?.toString() == id.toString());
      final subj = a['subjects'] as Map<String, dynamic>? ?? {};
      return subj['name']?.toString() ?? 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  @override
  Map<String, dynamic>? getFormTeacherClass() => _formTeacherClass;
}
