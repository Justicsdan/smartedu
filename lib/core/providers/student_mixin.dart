// ==========================================
// File: lib/core/providers/student_mixin.dart
// ==========================================
import 'package:flutter/foundation.dart';
import '../services/db_proxy.dart';
import 'base_provider.dart';
import 'comment_mixin.dart';
import 'session_mixin.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Student management mixin for school admin.
/// Handles CRUD operations for students within a school.
///
/// MASTER PLAN V5:
/// - Every query filters by school_id — tenant isolation
/// - Student CRUD with class join for readable display
/// - Credentials generation (username + PIN) with uniqueness enforcement
/// - Soft consideration for global scale (subscription limits)
/// - All IDs are UUID strings
/// - V4: Fixed Postgrest v2 multi-order crash (merged into comma-separated string)
/// - V4: Fixed Postgrest v2 RPC params syntax
/// - V4: Fixed getExistingBehavioral Map/List type mismatch
/// - V5: FIXED name/full_name always saved (was missing — caused display issues)
/// - V5: FIXED passport_url from add page was being discarded
/// - V5: FIXED credential return now includes student name for printing

mixin StudentMixin on BaseProvider, CommentMixin, SessionMixin {

  // ==========================================
  // STATE
  // ==========================================
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _studentCredentials = [];

  // ==========================================
  // ABSTRACT GETTERS
  // ==========================================
  @override
  List<Map<String, dynamic>> get students => _students;

  @override
  List<Map<String, dynamic>> get studentCredentials => _studentCredentials;

  // ==========================================
  // LOAD STUDENTS
  // ==========================================

  Future<void> loadStudents() async {
    if (schoolId.isEmpty) {
      _students = [];
      notifyListeners();
      return;
    }

    try {
      final r = await supabase
          .from('students')
          .select('''
            *,
            classes(name, section, class_level)
          ''')
          .eq('school_id', schoolId)
          .eq('is_active', true)
          .neq('graduation_status', 'graduated')
          .order('class_id,last_name,first_name', ascending: true);

      _students = List<Map<String, dynamic>>.from(r);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading students: $e');
      _students = [];
      notifyListeners();
    }
  }

  Future<void> loadStudentsForClass(String classId) async {
    if (schoolId.isEmpty || classId.isEmpty) {
      _students = [];
      notifyListeners();
      return;
    }

    try {
      final r = await supabase
          .from('students')
          .select('''
            *,
            classes(name, section, class_level)
          ''')
          .eq('school_id', schoolId)
          .eq('class_id', classId)
          .eq('is_active', true)
          .neq('graduation_status', 'graduated')
          .order('last_name,first_name', ascending: true);

      _students = List<Map<String, dynamic>>.from(r);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading class students: $e');
      _students = [];
      notifyListeners();
    }
  }

  Future<void> loadStudentsFiltered({
    String? classId,
    String? searchQuery,
    String? graduationStatus,
    bool activeOnly = true,
  }) async {
    if (schoolId.isEmpty) {
      _students = [];
      notifyListeners();
      return;
    }

    try {
      var q = supabase
          .from('students')
          .select('''
            *,
            classes(name, section, class_level)
          ''')
          .eq('school_id', schoolId);

      if (activeOnly) {
        q = q.eq('is_active', true);
      }

      if (classId != null && classId.isNotEmpty) {
        q = q.eq('class_id', classId);
      }

      if (graduationStatus != null && graduationStatus.isNotEmpty) {
        q = q.eq('graduation_status', graduationStatus);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        q = q.or(
          'first_name.ilike.%$searchQuery%,last_name.ilike.%$searchQuery%,admission_no.ilike.%$searchQuery%,middle_name.ilike.%$searchQuery%',
        );
      }

      final r = await q.order('last_name,first_name', ascending: true);

      _students = List<Map<String, dynamic>>.from(r);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading filtered students: $e');
      _students = [];
      notifyListeners();
    }
  }

  Future<void> refreshStudents() async {
    await loadStudents();
  }

  // ==========================================
  // ADD STUDENT
  // ==========================================

  Future<Map<String, dynamic>?> addStudent(Map<String, dynamic> data) async {
    if (schoolId.isEmpty) return null;

    try {
      final username = await _generateUniqueUsername(
        firstName: data['first_name'] ?? '',
        lastName: data['last_name'] ?? '',
        admissionNo: data['admission_no'] ?? '',
      );
      final pin = _generatePin();

      // V5 FIX: Build full name properly
      final firstName = (data['first_name'] ?? '').toString().trim();
      final middleName = (data['middle_name'] ?? '').toString().trim();
      final lastName = (data['last_name'] ?? '').toString().trim();

      // Priority: use from page, else build from parts
      String fullName = '';
      if (data['full_name'] != null && data['full_name'].toString().trim().isNotEmpty) {
        fullName = data['full_name'].toString().trim();
      } else if (data['name'] != null && data['name'].toString().trim().isNotEmpty) {
        fullName = data['name'].toString().trim();
      } else {
        final parts = [firstName, middleName, lastName].where((s) => s.isNotEmpty).join(' ');
        fullName = parts.isNotEmpty ? parts : 'Unknown';
      }

      final student = <String, dynamic>{
        'school_id': schoolId,
        'name': fullName,              // V5 FIX: was missing
        'full_name': fullName,          // V5 FIX: was missing
        'admission_no': (data['admission_no'] ?? '').toString().trim(),
        'first_name': firstName,
        'middle_name': middleName,
        'last_name': lastName,
        'gender': data['gender'] ?? '',
        'date_of_birth': data['date_of_birth'],
        'school_level': data['school_level'] ?? 'secondary',
        'admission_session': data['admission_session'] ?? '',
        'admission_mode': data['admission_mode'] ?? '',
        'class_admission_year': data['class_admission_year'],
        'class_id': data['class_id'],
        'sport_team': data['sport_team'] ?? '',
        'club_society': data['club_society'] ?? '',
        'parent_phone': (data['parent_phone'] ?? '').toString().trim(),
        'parent_name': (data['parent_name'] ?? '').toString().trim(),
        'parent_email': (data['parent_email'] ?? '').toString().trim(),
        'parent_occupation': (data['parent_occupation'] ?? '').toString().trim(),
        'home_address': (data['home_address'] ?? '').toString().trim(),
        'passport_url': data['passport_url'] ?? '',  // V5 FIX: was missing — photo was discarded
        'username': username,
        'pin': pin,
        'is_active': true,
        'graduation_status': 'active',
      };

      final r = await supabase
          .from('students')
          .insert(student)
          .select('''
            *,
            classes(name, section, class_level),
            schools(name, logo_url)
          ''')
          .single();

      final result = Map<String, dynamic>.from(r);
      _students.add(result);

      final clsId = data['class_id']?.toString();
      if (clsId != null && clsId.isNotEmpty) {
        await syncClassStudentCounts(schoolId, clsId);
      }

      logAudit(
        action: 'create',
        tableName: 'students',
        recordId: result['id']?.toString(),
        newData: student,
      );
      notifyListeners();
      return result;
    } catch (e) {
      debugPrint('Error adding student: $e');
      return null;
    }
  }

  Future<int> addStudentsBatch(List<Map<String, dynamic>> studentsData) async {
    if (schoolId.isEmpty || studentsData.isEmpty) return 0;

    int successCount = 0;
    for (final data in studentsData) {
      final result = await addStudent(data);
      if (result != null) successCount++;
    }
    return successCount;
  }

  // ==========================================
  // UPDATE STUDENT
  // ==========================================

  Future<bool> updateStudent(String studentId, Map<String, dynamic> updates) async {
    if (studentId.isEmpty || schoolId.isEmpty) return false;

    try {
      final safeUpdates = Map<String, dynamic>.from(updates)
        ..remove('id')
        ..remove('school_id')
        ..remove('username')
        ..remove('pin')
        ..remove('created_at')
        ..remove('updated_at');

      if (safeUpdates.isEmpty) return true;

      // V5 FIX: If name parts changed, rebuild full name
      if (safeUpdates.containsKey('first_name') || safeUpdates.containsKey('middle_name') || safeUpdates.containsKey('last_name')) {
        final existing = getStudentById(studentId);
        final fn = (safeUpdates['first_name'] ?? existing?['first_name'] ?? '').toString().trim();
        final mn = (safeUpdates['middle_name'] ?? existing?['middle_name'] ?? '').toString().trim();
        final ln = (safeUpdates['last_name'] ?? existing?['last_name'] ?? '').toString().trim();
        final parts = [fn, mn, ln].where((s) => s.isNotEmpty).join(' ');
        if (parts.isNotEmpty) {
          safeUpdates['name'] = parts;
          safeUpdates['full_name'] = parts;
        }
      }

      await supabase
          .from('students')
          .update(safeUpdates)
          .eq('id', studentId)
          .eq('school_id', schoolId);

      final index = _students.indexWhere((s) => s['id']?.toString() == studentId);
      if (index != -1) {
        _students[index] = {..._students[index], ...safeUpdates};
      }

      if (updates.containsKey('class_id')) {
        final oldClassId = index != -1 ? _students[index]['class_id']?.toString() : null;
        final newClassId = updates['class_id']?.toString();
        if (oldClassId != newClassId && oldClassId != null) {
          if (oldClassId.isNotEmpty) await syncClassStudentCounts(schoolId, oldClassId);
          if (newClassId != null && newClassId.isNotEmpty) await syncClassStudentCounts(schoolId, newClassId);
        }
      }

      logAudit(action: 'update', tableName: 'students', recordId: studentId, newData: safeUpdates);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating student: $e');
      return false;
    }
  }

  Future<bool> promoteStudents({
    required List<String> studentIds,
    required String toClassId,
    required String sessionId,
    required String termId,
    String? reason,
  }) async {
    if (schoolId.isEmpty || studentIds.isEmpty || toClassId.isEmpty) return false;

    try {
      int count = 0;
      for (final studentId in studentIds) {
        final r = await supabase
            .from('students')
            .update({'class_id': toClassId, 'graduation_status': 'promoted'})
            .eq('id', studentId)
            .eq('school_id', schoolId)
            .select('id');

        if (r != null && r.isNotEmpty) count++;

        await supabase.from('promotions').insert({
          'school_id': schoolId,
          'student_id': studentId,
          'from_class_id': '',
          'to_class_id': toClassId,
          'session_id': sessionId,
          'type': 'promoted',
          'reason': reason ?? '',
        });
      }

      await loadStudents();
      if (count > 0) {
        await syncClassStudentCounts(schoolId, toClassId);
        logAudit(action: 'bulk_promote', tableName: 'students', newData: {'count': count, 'to_class_id': toClassId});
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error promoting students: $e');
      return false;
    }
  }

  // ==========================================
  // DELETE STUDENT
  // ==========================================

  Future<bool> deleteStudentFromDb(String studentId) async {
    if (studentId.isEmpty || schoolId.isEmpty) return false;

    try {
      final student = getStudentById(studentId);
      await DbProxy.instance.from('students').eq('id', studentId).eq('school_id', schoolId).update({'is_active': false});
      _students.removeWhere((s) => s['id']?.toString() == studentId);

      if (student != null) {
        final clsId = student['class_id']?.toString();
        if (clsId != null && clsId.isNotEmpty) await syncClassStudentCounts(schoolId, clsId);
      }
      logAudit(action: 'delete', tableName: 'students', recordId: studentId, oldData: student);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting student: $e');
      return false;
    }
  }

  Future<bool> softDeleteStudent(String studentId) async {
    return updateStudent(studentId, {'graduation_status': 'withdrawn', 'is_active': false});
  }

  Future<int> softDeleteStudents(List<String> studentIds) async {
    int count = 0;
    for (final id in studentIds) {
      if (await softDeleteStudent(id)) count++;
    }
    return count;
  }

  // ==========================================
  // CREDENTIALS
  // ==========================================

  /// V5 FIX: Now returns student name for printing credentials
  Future<Map<String, dynamic>?> generateStudentCredentialInDb(String studentId) async {
    if (studentId.isEmpty || schoolId.isEmpty) return null;

    try {
      final student = getStudentById(studentId);
      if (student == null) return null;

      // V5 FIX: Get display name using proper method
      final studentName = getStudentDisplayName(student);

      final username = await _generateUniqueUsername(
        firstName: student['first_name'] ?? '',
        lastName: student['last_name'] ?? '',
        admissionNo: student['admission_no'] ?? '',
      );
      final pin = _generatePin();

      await DbProxy.instance.from('students').eq('id', studentId).eq('school_id', schoolId).update({'username': username, 'pin': pin});

      final index = _students.indexWhere((s) => s['id']?.toString() == studentId);
      if (index != -1) {
        _students[index] = {..._students[index], 'username': username, 'pin': pin};
        notifyListeners();
      }

      // V5 FIX: Return includes name, admission_no for printing
      final credential = {
        'student_id': studentId,
        'name': studentName,
        'admission_no': student['admission_no'] ?? '',
        'class_name': getStudentClassDisplay(student),
        'username': username,
        'pin': pin,
      };

      // Store in credentials list for bulk printing
      _studentCredentials.removeWhere((c) => c['student_id']?.toString() == studentId);
      _studentCredentials.add(credential);

      logAudit(action: 'generate_credentials', tableName: 'students', recordId: studentId, newData: {'username': username, 'pin': '[HIDDEN]'});
      notifyListeners();
      return credential;
    } catch (e) {
      debugPrint('Error generating student credentials: $e');
      return null;
    }
  }

  /// V5 FIX: Now includes student name in each credential entry
  Future<List<Map<String, dynamic>>> bulkGenerateCredentials(List<String> studentIds) async {
    final credentials = <Map<String, dynamic>>[];
    for (final id in studentIds) {
      final cred = await generateStudentCredentialInDb(id);
      if (cred != null) {
        credentials.add({
          'student_id': id,
          'name': cred['name'] ?? '',
          'admission_no': cred['admission_no'] ?? '',
          'class_name': cred['class_name'] ?? '',
          'username': cred['username'],
          'pin': cred['pin'],
        });
      }
    }
    return credentials;
  }

  Future<Map<String, dynamic>?> regenerateStudentCredentials(String studentId) async {
    return generateStudentCredentialInDb(studentId);
  }

  Future<bool> resetStudentPin(String studentId, String newPin) async {
    if (studentId.isEmpty || schoolId.isEmpty || newPin.trim().length < 4) return false;

    try {
      await DbProxy.instance.from('students').eq('id', studentId).eq('school_id', schoolId).update({'pin': newPin.trim()});
      final index = _students.indexWhere((s) => s['id']?.toString() == studentId);
      if (index != -1) {
        _students[index] = {..._students[index], 'pin': '[RESET]'};
        notifyListeners();
      }
      logAudit(action: 'reset_pin', tableName: 'students', recordId: studentId);
      return true;
    } catch (e) {
      debugPrint('Error resetting student PIN: $e');
      return false;
    }
  }

  Future<String> _generateUniqueUsername({required String firstName, required String lastName, required String admissionNo}) async {
    final base = '${_clean(firstName)}.${_clean(lastName)}'.toLowerCase();
    const suffixChars = 'abcdefghjkmnpqrstuvwxyz23456789';
    final now = DateTime.now().microsecondsSinceEpoch;

    for (int attempt = 0; attempt < 10; attempt++) {
      final suffix = List.generate(4, (i) => suffixChars[(now + i * 7) % suffixChars.length]).join();
      final candidate = '${base}_$suffix';
      final exists = await DbProxy.instance.from('students').eq('school_id', schoolId).eq('username', candidate).select('id').maybeSingle();
      if (exists == null) return candidate;
    }

    final admClean = admissionNo.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    if (admClean.length >= 3) {
      return '${admClean}_${List.generate(3, (i) => suffixChars[(now + i * 11) % suffixChars.length]).join()}';
    }
    return '${base}_${List.generate(6, (i) => suffixChars[(now + i * 13) % suffixChars.length]).join()}';
  }

  String _generatePin() {
    const digits = '0123456789';
    final now = DateTime.now().microsecondsSinceEpoch;
    return List.generate(4, (i) => digits[(now + i * 7) % digits.length]).join();
  }

  String _clean(String input) => input.replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();

  // ==========================================
  // LOOKUP HELPERS
  // ==========================================

  Map<String, dynamic>? getStudentById(String studentId) {
    if (studentId.isEmpty) return null;
    try {
      return _students.cast<Map<String, dynamic>?>().firstWhere((s) => s?['id']?.toString() == studentId, orElse: () => null);
    } catch (_) { return null; }
  }

  Map<String, dynamic>? getStudentByAdmissionNo(String admissionNo) {
    if (admissionNo.isEmpty) return null;
    try {
      return _students.cast<Map<String, dynamic>?>().firstWhere((s) => s?['admission_no']?.toString() == admissionNo, orElse: () => null);
    } catch (_) { return null; }
  }

  Map<String, dynamic>? getStudentByUsername(String username) {
    if (username.isEmpty) return null;
    try {
      return _students.cast<Map<String, dynamic>?>().firstWhere((s) => s?['username']?.toString() == username, orElse: () => null);
    } catch (_) { return null; }
  }

  List<Map<String, dynamic>> getStudentsInClass(String classId) {
    if (classId.isEmpty) return [];
    return _students.where((s) => s['class_id']?.toString() == classId).toList();
  }

  int countStudentsInClass(String classId) => getStudentsInClass(classId).length;

  List<Map<String, dynamic>> searchStudents(String query) {
    if (query.isEmpty) return _students;
    final lowerQuery = query.toLowerCase();
    return _students.where((s) {
      // V5 FIX: Also search in name/full_name fields
      final fullName = '${s['full_name'] ?? ''} ${s['name'] ?? ''}'.toLowerCase();
      final parts = '${s['first_name'] ?? ''} ${s['middle_name'] ?? ''} ${s['last_name'] ?? ''}'.toLowerCase();
      final admNo = (s['admission_no'] ?? '').toString().toLowerCase();
      return fullName.contains(lowerQuery) || parts.contains(lowerQuery) || admNo.contains(lowerQuery);
    }).toList();
  }

  List<Map<String, dynamic>> getStudentsByStatus(String status) => _students.where((s) => s['graduation_status']?.toString() == status).toList();
  List<Map<String, dynamic>> getActiveStudents() => getStudentsByStatus('active');
  List<Map<String, dynamic>> getGraduatedStudents() => getStudentsByStatus('graduated');

  /// V5 FIX: Prioritizes full_name/name field, falls back to building from parts
  String getStudentDisplayName(Map<String, dynamic> student) {
    // Try stored full_name first
    final storedName = (student['full_name'] ?? student['name'] ?? '').toString().trim();
    if (storedName.isNotEmpty && storedName != 'Unknown') {
      final admNo = (student['admission_no'] ?? '').toString();
      return admNo.isNotEmpty ? '$storedName ($admNo)' : storedName;
    }
    // Fallback: build from parts
    final name = [student['first_name'] ?? '', student['middle_name'] ?? '', student['last_name'] ?? ''].where((s) => (s as String).isNotEmpty).join(' ');
    final admNo = (student['admission_no'] ?? '').toString();
    if (name.isEmpty) return admNo.isNotEmpty ? admNo : 'Unknown';
    return admNo.isNotEmpty ? '$name ($admNo)' : name;
  }

  /// V5 FIX: Returns name without admission number (for printing)
  String getStudentNameOnly(Map<String, dynamic> student) {
    final storedName = (student['full_name'] ?? student['name'] ?? '').toString().trim();
    if (storedName.isNotEmpty && storedName != 'Unknown') return storedName;
    return [student['first_name'] ?? '', student['middle_name'] ?? '', student['last_name'] ?? ''].where((s) => (s as String).isNotEmpty).join(' ');
  }

  String getStudentClassDisplay(Map<String, dynamic> student) {
    final cls = student['classes'] as Map<String, dynamic>?;
    if (cls == null) return '';
    final name = cls['name']?.toString() ?? '';
    final section = cls['section']?.toString() ?? '';
    return section.isNotEmpty ? '$name $section' : name;
  }

  String getStudentFullDisplay(Map<String, dynamic> student) {
    final displayName = getStudentDisplayName(student);
    final classDisplay = getStudentClassDisplay(student);
    return classDisplay.isNotEmpty ? '$displayName — $classDisplay' : displayName;
  }

  @override
  Future<void> loadSessions() async => await loadAcademicSessions();

  Future<bool> updateSchoolBranding({bool? showGradeOnly}) async => updateDisplaySettings(showGradeOnly: showGradeOnly);

  Future<Map<String, dynamic>?> getExistingBehavioral(String studentId, String? termId) async {
    final comments = await getTermCommentsForTerm(
      studentId: studentId,
      termId: termId ?? currentTerm?['id']?.toString() ?? '',
    );
    return comments;
  }

  Future<void> loadStudentsPaginated({int page = 1, int pageSize = 50}) async {
    if (schoolId.isEmpty) { _students = []; notifyListeners(); return; }
    try {
      final from = (page - 1) * pageSize;
      final to = from + pageSize;
      final r = await DbProxy.instance.from('students').select('*, classes(name, section, class_level)').eq('school_id', schoolId).eq('is_active', true).neq('graduation_status', 'graduated').order('last_name,first_name', ascending: true).range(from, to).get();

      if (page == 1) { _students = List<Map<String, dynamic>>.from(r); }
      else { _students.addAll(List<Map<String, dynamic>>.from(r)); }
      notifyListeners();
    } catch (e) { debugPrint('Error loading paginated students: $e'); }
  }

  int get totalStudentCount => _students.length;

  List<String> getClassesWithStudents() {
    final classIds = <String>{};
    for (final s in _students) { final c = s['class_id']?.toString() ?? ''; if (c.isNotEmpty) classIds.add(c); }
    return classIds.toList();
  }

  Map<String, int> getStudentCountPerClass() {
    final counts = <String, int>{};
    for (final s in _students) { final c = s['class_id']?.toString() ?? ''; if (c.isNotEmpty) counts[c] = (counts[c] ?? 0) + 1; }
    return counts;
  }

  String getStudentPassportUrl(String studentId) => (getStudentById(studentId)?['passport_url'] ?? '').toString();

  Future<bool> admissionNoExists(String admissionNo) async {
    if (schoolId.isEmpty || admissionNo.isEmpty) return false;
    try { return (await DbProxy.instance.from('students').eq('school_id', schoolId).eq('admission_no', admissionNo.trim()).select('id').maybeSingle()) != null; }
    catch (e) { debugPrint('Error checking admission number: $e'); return false; }
  }

  Future<bool> usernameExists(String username) async {
    if (schoolId.isEmpty || username.isEmpty) return false;
    try { return (await DbProxy.instance.from('students').eq('school_id', schoolId).eq('username', username.trim()).select('id').maybeSingle()) != null; }
    catch (e) { debugPrint('Error checking username: $e'); return false; }
  }

  void clearStudents() { _students = []; _studentCredentials = []; notifyListeners(); }

  Future<void> syncClassStudentCounts(String sid, String classId) async {
    try {
      await supabase.rpc('sync_class_student_counts', params: {
        'p_school_id': sid,
        'p_class_id': classId,
      });
    } catch (e) { debugPrint('Error syncing class count: $e'); }
  }

  Future<void> syncAllClassStudentCounts() async {
    try {
      await supabase.rpc('sync_all_class_counts', params: {
        'p_school_id': schoolId,
      });
    } catch (e) { debugPrint('Error syncing all class counts: $e'); }
  }

  /// V5 FIX: Export now uses full_name field properly
  Future<List<dynamic>> exportStudentData({String? classId, List<String>? fields}) async {
    var students = _students;
    if (classId != null && classId.isNotEmpty) students = getStudentsInClass(classId);
    if (students.isEmpty) return [];

    const defaultFields = [
      {'key': 'admission_no', 'label': 'Adm No'}, {'key': 'full_name', 'label': 'Full Name'},
      {'key': 'gender', 'label': 'Gender'}, {'key': 'class_name', 'label': 'Class'},
      {'key': 'parent_name', 'label': 'Parent Name'}, {'key': 'parent_phone', 'label': 'Parent Phone'},
      {'key': 'parent_email', 'label': 'Parent Email'},
    ];
    final exportFields = fields ?? defaultFields.map((f) => f['key'] as String).toList();

    final rows = students.map((student) {
      final cls = student['classes'] as Map<String, dynamic>?;
      final row = <String, dynamic>{};
      for (final field in exportFields) {
        switch (field) {
          case 'full_name':
            // V5: Use stored full_name first
            final stored = (student['full_name'] ?? student['name'] ?? '').toString().trim();
            row['Full Name'] = stored.isNotEmpty ? stored : '${student['first_name'] ?? ''} ${student['middle_name'] ?? ''} ${student['last_name'] ?? ''}'.trim();
            break;
          case 'class_name': row['Class'] = '${cls?['name'] ?? ''}${cls?['section'] != null ? ' ${cls?['section']}' : ''}'.trim(); break;
          case 'admission_no': row['Adm No'] = student['admission_no'] ?? ''; break;
          case 'gender': row['Gender'] = student['gender'] ?? ''; break;
          case 'parent_name': row['Parent Name'] = student['parent_name'] ?? ''; break;
          case 'parent_phone': row['Parent Phone'] = student['parent_phone'] ?? ''; break;
          case 'parent_email': row['Parent Email'] = student['parent_email'] ?? ''; break;
          default: row[field] = student[field] ?? '';
        }
      }
      return row;
    }).toList();

    return [exportFields, ...rows];
  }

  Future<Map<String, dynamic>> canAddMoreStudents({int count = 1}) async {
    if (schoolId.isEmpty) return {'exceeded': false, 'current': 0, 'max': 100, 'remaining': 100};
    try {
      final school = await DbProxy.instance.from('schools').eq('id', schoolId).select('max_students, student_count').single();
      final current = (school['student_count'] as int?) ?? 0;
      final max = (school['max_students'] as int?) ?? 100;
      final newTotal = current + count;
      return {'exceeded': newTotal > max, 'current': current, 'max': max, 'remaining': max > newTotal ? max - newTotal : 0};
    } catch (e) {
      debugPrint('Error checking student limit: $e');
      return {'exceeded': false, 'current': 0, 'max': 100, 'remaining': 100};
    }
  }
}
