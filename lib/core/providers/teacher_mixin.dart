// ==========================================
// File: lib/core/providers/teacher_mixin.dart
// ==========================================
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_provider.dart';

mixin TeacherMixin on BaseProvider {
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _teacherCredentials = [];

  @override
  List<Map<String, dynamic>> get teachers => _teachers;

  @override
  List<Map<String, dynamic>> get teacherCredentials => _teacherCredentials;

  @override
  Future<void> loadTeachers() async {
    try {
      final r = await supabase
          .from('teachers')
          .select()
          .eq('school_id', schoolId)
          .eq('is_active', true)
          .order('first_name');
      _teachers = List<Map<String, dynamic>>.from(r);
    } catch (e) {
      debugPrint('Error loading teachers: $e');
    }
  }

  Future<bool> addTeacherToDb(Map<String, dynamic> teacher) async {
    try {
      if (teacher['staff_id'] != null && teacher['staff_id'].toString().trim().isNotEmpty) {
        final existing = await supabase
            .from('teachers')
            .select('id')
            .eq('school_id', schoolId)
            .eq('staff_id', teacher['staff_id'].toString().trim())
            .maybeSingle();
        if (existing != null) throw Exception('Staff ID already exists');
      }

      final insertData = <String, dynamic>{
        'school_id': schoolId,
        'first_name': (teacher['first_name'] ?? '').toString().trim(),
        'last_name': (teacher['last_name'] ?? '').toString().trim(),
        'gender': teacher['gender'] ?? 'Male',
        'email': teacher['email'] != null && teacher['email'].toString().trim().isNotEmpty
            ? teacher['email'].toString().trim()
            : null,
        'phone': teacher['phone'] != null && teacher['phone'].toString().trim().isNotEmpty
            ? teacher['phone'].toString().trim()
            : null,
        'staff_id': teacher['staff_id'] != null && teacher['staff_id'].toString().trim().isNotEmpty
            ? teacher['staff_id'].toString().trim()
            : null,
        'home_address': teacher['home_address'] ?? '',
        'department': teacher['department'] ?? '',
        'qualification': teacher['qualification'] ?? '',
        'passport_url': teacher['passport_url'] ?? '',
        'is_active': true,
      };

      final r = await supabase
          .from('teachers')
          .insert(insertData)
          .select()
          .single();

      _teachers.add(Map<String, dynamic>.from(r));

      logAudit(
        action: 'create',
        tableName: 'teachers',
        recordId: r['id']?.toString(),
        newData: {
          'first_name': insertData['first_name'],
          'last_name': insertData['last_name'],
          'staff_id': insertData['staff_id'],
        },
      );
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding teacher: $e');
      return false;
    }
  }

  Future<bool> updateTeacherInDb(String id, Map<String, dynamic> updates) async {
    try {
      final t = _teachers.cast<Map<String, dynamic>?>().firstWhere(
            (t) => t?['id']?.toString() == id,
            orElse: () => <String, dynamic>{},
          );
      if (t == null || t.isEmpty) return false;

      final u = Map<String, dynamic>.from(updates)
        ..remove('id')
        ..remove('school_id')
        ..remove('created_at')
        ..remove('updated_at')
        ..remove('username')
        ..remove('password')
        ..remove('last_login')
        ..remove('auth_user_id')
        ..remove('name')
        ..remove('full_name')
        ..remove('formTeacherClassId')
        ..remove('assignedSubjects');

      if (u.isEmpty) return false;

      final r = await supabase
          .from('teachers')
          .update(u)
          .eq('id', id)
          .eq('school_id', schoolId)
          .select()
          .single();

      final i = _teachers.indexWhere((t) => t['id']?.toString() == id);
      if (i != -1) {
        _teachers[i] = Map<String, dynamic>.from(r);
      }

      logAudit(action: 'update', tableName: 'teachers', recordId: id, newData: u);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating teacher: $e');
      return false;
    }
  }

  Future<bool> deleteTeacherFromDb(String id) async {
    try {
      await supabase.from('teachers').delete().eq('id', id).eq('school_id', schoolId);
      _teachers.removeWhere((t) => t['id']?.toString() == id);
      logAudit(action: 'delete', tableName: 'teachers', recordId: id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting teacher: $e');
      return false;
    }
  }

  Future<bool> deactivateTeacher(String id) async {
    try {
      await supabase.from('teachers').update({'is_active': false}).eq('id', id).eq('school_id', schoolId);
      _teachers.removeWhere((t) => t['id']?.toString() == id);
      logAudit(action: 'deactivate', tableName: 'teachers', recordId: id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deactivating teacher: $e');
      return false;
    }
  }

  // ==========================================
  // TEACHER ASSIGNMENTS (called from PageTeachers)
  // ==========================================

  Future<void> loadTeacherAssignments(String teacherId) async {
    try {
      // Form teacher: check classes table where class_teacher_id matches
      final formTeacherClass = await supabase
          .from('classes')
          .select('id')
          .eq('class_teacher_id', teacherId)
          .eq('school_id', schoolId)
          .maybeSingle();

      // Subject teacher: check class_subjects table where teacher_id matches
      final subjectAssignments = await supabase
          .from('class_subjects')
          .select('class_id, subject_id')
          .eq('teacher_id', teacherId)
          .eq('school_id', schoolId);

      final idx = _teachers.indexWhere((t) => t['id']?.toString() == teacherId);

      if (idx != -1) {
        _teachers[idx] = Map<String, dynamic>.from(_teachers[idx]);
        _teachers[idx]['formTeacherClassId'] = formTeacherClass?['id']?.toString();
        _teachers[idx]['assignedSubjects'] = subjectAssignments.map((a) => {
              'classId': a['class_id']?.toString(),
              'subjectId': a['subject_id']?.toString(),
            }).toList();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading teacher assignments: $e');
    }
  }

  Future<void> assignFormTeacher(String teacherId, String? classId) async {
    try {
      // Clear any previous class where this teacher was form teacher
      await supabase
          .from('classes')
          .update({'class_teacher_id': null})
          .eq('class_teacher_id', teacherId)
          .eq('school_id', schoolId);

      if (classId != null) {
        // Also clear any existing form teacher for this class
        await supabase
            .from('classes')
            .update({'class_teacher_id': null})
            .eq('id', classId)
            .eq('school_id', schoolId)
            .not('class_teacher_id', 'is', null);

        await supabase
            .from('classes')
            .update({'class_teacher_id': teacherId})
            .eq('id', classId)
            .eq('school_id', schoolId);
      }

      await loadTeacherAssignments(teacherId);
    } catch (e) {
      debugPrint('Error assigning form teacher: $e');
    }
  }

  Future<void> assignSubjectToTeacher(String teacherId, String subjectId, String classId) async {
    try {
      // Find the class_subjects row for this class + subject combo
      final row = await supabase
          .from('class_subjects')
          .select('id, teacher_id')
          .eq('class_id', classId)
          .eq('subject_id', subjectId)
          .eq('school_id', schoolId)
          .maybeSingle();

      if (row != null) {
        // Update the teacher_id on the existing class_subjects row
        await supabase
            .from('class_subjects')
            .update({'teacher_id': teacherId})
            .eq('id', row['id']);
      } else {
        debugPrint('No class_subjects row found for class=$classId subject=$subjectId — subject not linked to this class');
      }

      await loadTeacherAssignments(teacherId);
    } catch (e) {
      debugPrint('Error assigning subject: $e');
    }
  }

  Future<void> removeSubjectFromTeacher(String teacherId, String subjectId, String classId) async {
    try {
      // Set teacher_id to null on the matching class_subjects row
      await supabase
          .from('class_subjects')
          .update({'teacher_id': null})
          .eq('class_id', classId)
          .eq('subject_id', subjectId)
          .eq('teacher_id', teacherId)
          .eq('school_id', schoolId);

      await loadTeacherAssignments(teacherId);
    } catch (e) {
      debugPrint('Error removing subject: $e');
    }
  }

  // ==========================================
  // CREDENTIALS
  // ==========================================

  Future<Map<String, dynamic>?> generateTeacherCredentialInDb(String teacherId) async {
    try {
      if (teacherId.isEmpty) return null;

      final teacher = _teachers.cast<Map<String, dynamic>?>().firstWhere(
            (t) => t?['id']?.toString() == teacherId,
            orElse: () => null,
          );

      if (teacher == null || teacher.isEmpty) {
        debugPrint('Teacher not found: $teacherId');
        return null;
      }

      final eu = (teacher['username'] ?? '').toString().trim();

      if (eu.isNotEmpty) {
        final ep = (teacher['password'] ?? '').toString().trim();
        if (ep.isNotEmpty) {
          final fn = (teacher['first_name'] ?? '').toString().trim();
          final ln = (teacher['last_name'] ?? '').toString().trim();
          final nameToShow = '$fn $ln'.trim();

          final existing = {
            'teacherId': teacherId,
            'name': nameToShow,
            'username': eu,
            'password': ep,
            'existing': true,
          };
          _teacherCredentials.removeWhere((c) => c['teacherId']?.toString() == teacherId);
          _teacherCredentials.add(existing);
          notifyListeners();
          return existing;
        }
      }

      final fn = (teacher['first_name'] ?? 'teacher').toString().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      final ln = (teacher['last_name'] ?? '').toString().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      final uid = DateTime.now().millisecondsSinceEpoch.toString().substring(5);
      final username = fn.isNotEmpty ? '${fn}${ln.isNotEmpty ? '_$ln' : ''}_$uid' : 'teacher_$uid';
      final now = DateTime.now();
      final password = 'Tchr@${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}!';

      await supabase.from('teachers').update({'username': username, 'password': password}).eq('id', teacherId).eq('school_id', schoolId);

      final idx = _teachers.indexWhere((t) => t['id']?.toString() == teacherId);
      if (idx != -1) {
        _teachers[idx] = Map<String, dynamic>.from(_teachers[idx]);
        _teachers[idx]['username'] = username;
        _teachers[idx]['password'] = password;
      }

      final credential = {
        'teacherId': teacherId,
        'name': '$fn $ln'.trim(),
        'username': username,
        'password': password,
        'existing': false,
      };

      _teacherCredentials.removeWhere((c) => c['teacherId']?.toString() == teacherId);
      _teacherCredentials.add(credential);

      logAudit(action: 'generate_credentials', tableName: 'teachers', recordId: teacherId, newData: {'username': username});
      notifyListeners();
      return credential;
    } catch (e, st) {
      debugPrint('Teacher credential error: $e\n$st');
      return null;
    }
  }

  Future<int> generateAllMissingCredentials() async {
    int count = 0;
    for (final t in _teachers) {
      final eu = (t['username'] ?? '').toString().trim();
      if (eu.isEmpty) {
        final result = await generateTeacherCredentialInDb(t['id']?.toString() ?? '');
        if (result != null) count++;
      }
    }
    if (count > 0) notifyListeners();
    return count;
  }

  void clearCredentials() {
    _teacherCredentials.clear();
    notifyListeners();
  }

  // ==========================================
  // UTILITY
  // ==========================================

  Map<String, dynamic>? getTeacherById(String teacherId) {
    if (teacherId == null || teacherId.isEmpty) return null;
    try {
      return _teachers.cast<Map<String, dynamic>?>().firstWhere(
            (t) => t?['id']?.toString() == teacherId,
            orElse: () => null,
          );
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic>? getTeacherByStaffId(String staffId) {
    if (staffId.isEmpty) return null;
    try {
      return _teachers.cast<Map<String, dynamic>?>().firstWhere(
            (t) => t?['staff_id']?.toString() == staffId,
            orElse: () => null,
          );
    } catch (e) {
      return null;
    }
  }

  String getTeacherDisplayName(Map<String, dynamic>? teacherData) {
    if (teacherData == null) return '';
    final first = (teacherData['first_name'] ?? '').toString().trim();
    final last = (teacherData['last_name'] ?? '').toString().trim();
    if (first.isEmpty && last.isEmpty) return 'Unknown';
    return '$first $last'.trim();
  }

  String getTeacherFullDisplayName(Map<String, dynamic>? teacherData) {
    if (teacherData == null) return '';
    final gender = (teacherData['gender'] ?? '').toString().toLowerCase();
    final title = gender == 'female' ? 'Mrs.' : 'Mr.';
    final name = getTeacherDisplayName(teacherData);
    if (name == 'Unknown') return 'Unknown';
    return '$title $name';
  }

  String getTeacherName(String? teacherId) {
    if (teacherId == null || teacherId.isEmpty) return '';
    final t = getTeacherById(teacherId);
    return getTeacherDisplayName(t);
  }

  List<Map<String, dynamic>> getTeachersByDepartment(String department) {
    if (department.isEmpty) return _teachers;
    return _teachers.where((t) => (t['department'] ?? '').toString().toLowerCase() == department.toLowerCase()).toList();
  }

  List<String> get departments {
    final depts = _teachers.map((t) => (t['department'] ?? '').toString().trim()).where((d) => d.isNotEmpty).toSet().toList();
    depts.sort();
    return depts;
  }

  int get teacherCount => _teachers.length;

  // ==========================================
  // LOCAL STATE
  // ==========================================

  void addTeacher(Map<String, dynamic> t) {
    _teachers.add(Map<String, dynamic>.from(t));
    notifyListeners();
  }

  void deleteTeacher(String id) {
    _teachers.removeWhere((t) => t['id']?.toString() == id);
    notifyListeners();
  }

  void generateTeacherCredential(String teacherId) {
    try {
      final t = _teachers.cast<Map<String, dynamic>?>().firstWhere(
            (t) => t?['id']?.toString() == teacherId,
            orElse: () => null,
          );
      if (t == null || t.isEmpty) return;

      final fn = (t['first_name'] ?? '').toString().trim();
      final ln = (t['last_name'] ?? '').toString().trim();

      _teacherCredentials.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'teacherId': teacherId,
        'name': '$fn $ln'.trim(),
        'username': 'teacher.${t['staff_id'] ?? teacherId}',
        'password': 'Tchr@${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}!',
        'existing': false,
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Local teacher credential error: $e');
    }
  }
}
