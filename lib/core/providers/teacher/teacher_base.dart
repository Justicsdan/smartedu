import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/db_proxy.dart';

abstract class TeacherBase extends ChangeNotifier {
  String _schoolId = '';
  String get schoolId => _schoolId;

  String _teacherId = '';
  String get teacherId => _teacherId;

  bool _isInitialized = false;
  final List<RealtimeChannel> _realtimeChannels = [];
  bool get isInitialized => _isInitialized;

  Map<String, dynamic>? _currentSession;
  Map<String, dynamic>? _currentTerm;
  Map<String, dynamic>? get currentSession => _currentSession;
  Map<String, dynamic>? get currentTerm => _currentTerm;

  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _phone = '';
  String _staffId = '';
  String _schoolName = '';
  String _schoolLogoUrl = '';
  String get firstName => _firstName;
  String get lastName => _lastName;
  String get fullName => '$_firstName $_lastName'.trim();
  String get email => _email;
  String get phone => _phone;
  String get staffId => _staffId;
  String get schoolName => _schoolName;
  String get schoolLogoUrl => _schoolLogoUrl;
  String get teacherName => fullName;

  List<Map<String, dynamic>> _gradingSystem = [];
  List<Map<String, dynamic>> _assessmentTypes = [];
  int _subjectMaxScore = 100;
  bool _showPosition = true;
  List<Map<String, dynamic>> get gradingSystem => _gradingSystem;
  List<Map<String, dynamic>> get assessmentTypes => _assessmentTypes;
  int get subjectMaxScore => _subjectMaxScore;
  bool get showPosition => _showPosition;

  List<Map<String, dynamic>> _academicSessions = [];
  List<Map<String, dynamic>> _terms = [];
  List<Map<String, dynamic>> get academicSessions => _academicSessions;
  List<Map<String, dynamic>> get terms => _terms;

  Map<String, dynamic>? _schoolSettings;
  Map<String, dynamic>? get schoolSettings => _schoolSettings;

  List<Map<String, dynamic>> _myAssignments = [];
  List<Map<String, dynamic>> get assignments => _myAssignments;

  Map<String, dynamic>? get currentTeacher => {
        'id': _teacherId,
        'first_name': _firstName,
        'last_name': _lastName,
        'staff_id': _staffId,
        'email': _email,
      };

  // ═══════════════════════════════════════════════════════════
  // LOGIN — direct Supabase (no JWT available yet)
  // ═══════════════════════════════════════════════════════════

  Future<bool> login(String username, String password) async {
    try {
      final r = await Supabase.instance.client
          .from('teachers')
          .select('*, schools(name, logo_url)')
          .eq('username', username.trim())
          .eq('password', password)
          .eq('is_active', true)
          .maybeSingle();
      if (r == null) return false;
      _teacherId = r['id'].toString();
      _schoolId = r['school_id'].toString();
      _firstName = r['first_name'] ?? '';
      _lastName = r['last_name'] ?? '';
      _email = r['email'] ?? '';
      _phone = r['phone'] ?? '';
      _staffId = r['staff_id'] ?? '';
      final school = r['schools'] as Map<String, dynamic>? ?? {};
      _schoolName = school['name'] ?? '';
      _schoolLogoUrl = school['logo_url'] ?? '';
      try {
        await Supabase.instance.client.from('login_history').insert({
          'school_id': _schoolId,
          'user_id': _teacherId,
          'user_type': 'teacher',
          'username': username,
          'is_successful': true,
        });
      } catch (_) {}
      try {
        await Supabase.instance.client
            .from('teachers')
            .update({'last_login': DateTime.now().toIso8601String()})
            .eq('id', _teacherId);
      } catch (_) {}
      await _loadSessions();
      await _loadSettings();
      _isInitialized = true;
      _setupRealtime();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Teacher login error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SESSIONS / TERMS / SETTINGS — direct Supabase (used by login)
  // ═══════════════════════════════════════════════════════════

  Future<void> _loadSessions() async {
    try {
      final r = await Supabase.instance.client
          .from('academic_sessions')
          .select()
          .eq('school_id', _schoolId)
          .order('name', ascending: false);
      _academicSessions = List<Map<String, dynamic>>.from(r);
      _currentSession = _academicSessions.isNotEmpty
          ? _academicSessions.firstWhere(
              (s) => s['is_current'] == true,
              orElse: () => _academicSessions.first,
            )
          : null;
      if (_currentSession != null) await _loadTerms();
    } catch (e) {
      debugPrint('Load sessions error: $e');
    }
  }

  Future<void> _loadTerms() async {
    if (_currentSession == null) return;
    try {
      final r = await Supabase.instance.client
          .from('terms')
          .select()
          .eq('school_id', _schoolId)
          .eq('session_id', _currentSession!['id'])
          .order('created_at');
      _terms = List<Map<String, dynamic>>.from(r);
      _currentTerm = _terms.isNotEmpty
          ? _terms.firstWhere(
              (t) => t['is_current'] == true,
              orElse: () => _terms.first,
            )
          : null;
    } catch (e) {
      debugPrint('Load terms error: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final r = await Supabase.instance.client
          .from('school_settings')
          .select()
          .eq('school_id', _schoolId)
          .maybeSingle();
      if (r != null) {
        _schoolSettings = Map<String, dynamic>.from(r);
        _gradingSystem = List<Map<String, dynamic>>.from(
          r['grading_system']?.map((e) => Map<String, dynamic>.from(e)) ?? [],
        );
        _assessmentTypes = List<Map<String, dynamic>>.from(
          r['assessment_types']?.map((e) => Map<String, dynamic>.from(e)) ??
              [],
        );
        _subjectMaxScore = r['subject_max_score'] ?? 100;
        _showPosition = r['show_position'] ?? true;
      }
    } catch (e) {
      debugPrint('Load settings error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SESSIONS / TERMS / SETTINGS — DbProxy (used by initialize)
  // ═══════════════════════════════════════════════════════════

  Future<void> _loadSessionsViaProxy() async {
    try {
      final r = await DbProxy.instance
          .from('academic_sessions')
          .select()
          .eq('school_id', _schoolId)
          .order('name', ascending: false)
          .get();
      _academicSessions = r;
      _currentSession = _academicSessions.isNotEmpty
          ? _academicSessions.firstWhere(
              (s) => s['is_current'] == true,
              orElse: () => _academicSessions.first,
            )
          : null;
      if (_currentSession != null) await _loadTermsViaProxy();
    } catch (e) {
      debugPrint('Load sessions (proxy) error: $e');
    }
  }

  Future<void> _loadTermsViaProxy() async {
    if (_currentSession == null) return;
    try {
      final r = await DbProxy.instance
          .from('terms')
          .select()
          .eq('school_id', _schoolId)
          .eq('session_id', _currentSession!['id'])
          .order('created_at')
          .get();
      _terms = r;
      _currentTerm = _terms.isNotEmpty
          ? _terms.firstWhere(
              (t) => t['is_current'] == true,
              orElse: () => _terms.first,
            )
          : null;
    } catch (e) {
      debugPrint('Load terms (proxy) error: $e');
    }
  }

  Future<void> _loadSettingsViaProxy() async {
    try {
      final r = await DbProxy.instance
          .from('school_settings')
          .select()
          .eq('school_id', _schoolId)
          .maybeSingle();
      if (r != null) {
        _schoolSettings = Map<String, dynamic>.from(r);
        _gradingSystem = List<Map<String, dynamic>>.from(
          r['grading_system']?.map((e) => Map<String, dynamic>.from(e)) ?? [],
        );
        _assessmentTypes = List<Map<String, dynamic>>.from(
          r['assessment_types']?.map((e) => Map<String, dynamic>.from(e)) ??
              [],
        );
        _subjectMaxScore = r['subject_max_score'] ?? 100;
        _showPosition = r['show_position'] ?? true;
      }
    } catch (e) {
      debugPrint('Load settings (proxy) error: $e');
    }
  }

  Future<bool> setCurrentTerm(String termId) async {
    try {
      _currentTerm = _terms.firstWhere((t) => t['id'] == termId);
      await loadTeacherData();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  String calculateGrade(double total) {
    for (var g in _gradingSystem) {
      if (total >= (g['min'] as num) && total <= (g['max'] as num)) {
        return g['grade'] as String;
      }
    }
    return 'F';
  }

  Future<void> loadTeacherData() async {}

  // ═══════════════════════════════════════════════════════════
  // INITIALIZE — DbProxy (called after login_page.dart sets JWT)
  // ═══════════════════════════════════════════════════════════

  Future<void> initialize({
    required Map<String, dynamic> loginData,
    required String schoolId,
    required String teacherId,
  }) async {
    try {
      debugPrint(
          'Teacher initialize: schoolId=$schoolId, teacherId=$teacherId');
      _schoolId = schoolId;
      _teacherId = teacherId;
      _firstName = loginData['firstName'] ?? loginData['first_name'] ?? '';
      _lastName = loginData['lastName'] ?? loginData['last_name'] ?? '';
      _email = loginData['email'] ?? '';
      _phone = loginData['phone'] ?? '';
      _staffId = loginData['staffId'] ?? loginData['staff_id'] ?? '';

      debugPrint('Loading school info...');
      try {
        final school = await DbProxy.instance
            .from('schools')
            .select('name, logo_url')
            .eq('id', _schoolId)
            .maybeSingle();
        _schoolName = school?['name']?.toString() ?? '';
        _schoolLogoUrl = school?['logo_url']?.toString() ?? '';
      } catch (e) {
        debugPrint(
            'School query via proxy failed (schools not in teacher whitelist): $e');
      }
      debugPrint('School name: $_schoolName');

      debugPrint('Loading sessions...');
      await _loadSessionsViaProxy();

      debugPrint('Loading settings...');
      await _loadSettingsViaProxy();

      debugPrint('Loading teacher data (roles, students, scores)...');
      await loadTeacherData();

      debugPrint('Teacher initialization complete.');
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Teacher initialize FAILED: $e');
      rethrow;
    }
  }

  List<String> get assignedClassIds => [];
  List<Map<String, dynamic>> get assignedSubjects => [];
  List<Map<String, dynamic>> get students => [];
  Map<String, dynamic>? get formTeacherAssignment => null;
  String? get formTeacherClassId => null;
  String getClassName(String? id) => 'Class $id';
  String getSubjectName(dynamic id) => 'Subject';
  List<Map<String, dynamic>> getStudentsInClass(String id) => [];
  Map<String, dynamic>? getFormTeacherClass() => null;
  Map<String, dynamic>? getExistingScore(String s, String sub) => null;
  void saveScore(Map<String, dynamic> data) {}

  // ═══════════════════════════════════════════════════════════
  // ASSIGNMENTS — DbProxy
  // ═══════════════════════════════════════════════════════════

  Future<void> loadMyAssignments() async {
    try {
      final r = await DbProxy.instance
          .from('assignments')
          .select('*, subjects(name, code), classes(name, section)')
          .eq('school_id', schoolId)
          .eq('teacher_id', teacherId)
          .order('created_at', ascending: false)
          .get();
      _myAssignments = r;
    } catch (e) {
      debugPrint('Error loading teacher assignments: $e');
      _myAssignments = [];
    }
  }

  Future<bool> addAssignment(Map<String, dynamic> data) async {
    if (currentSession == null) {
      debugPrint('Cannot add assignment: no active session');
      return false;
    }
    try {
      final dueRaw = data['due_date'];
      DateTime? dueDate;
      if (dueRaw is DateTime) {
        dueDate = dueRaw;
      } else if (dueRaw is String && dueRaw.isNotEmpty) {
        dueDate = DateTime.tryParse(dueRaw);
      }

      final insertRow = <String, dynamic>{
        'school_id': schoolId,
        'teacher_id': teacherId,
        'subject_id': data['subject_id'],
        'class_id': data['class_id'],
        'session_id': currentSession!['id'],
        'term_id': currentTerm?['id'],
        'title': (data['title'] ?? '').toString().trim(),
        'description': (data['description'] ?? '').toString(),
        'due_date': dueDate?.toUtc().toIso8601String(),
        'total_marks': data['total_marks'] ?? 20,
        'attachment_url': data['attachment_url'] ?? '',
        'is_published': false,
      };

      final result = await DbProxy.instance
          .from('assignments')
          .insert(insertRow);
      if (result.isNotEmpty) {
        final r = Map<String, dynamic>.from(result.first);
        if (data['subjects'] != null) r['subjects'] = data['subjects'];
        if (data['classes'] != null) r['classes'] = data['classes'];
        _myAssignments.insert(0, r);
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding assignment: $e');
      return false;
    }
  }

  Future<bool> deleteAssignment(String id) async {
    try {
      await DbProxy.instance.from('assignments').eq('id', id).delete();
      _myAssignments.removeWhere((a) => a['id']?.toString() == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting assignment: $e');
      return false;
    }
  }

  Future<bool> toggleAssignmentPublished(String id, bool published) async {
    try {
      await DbProxy.instance.from('assignments').eq('id', id).update({'is_published': published});
      final i = _myAssignments.indexWhere((a) => a['id']?.toString() == id);
      if (i != -1) {
        _myAssignments[i] = Map<String, dynamic>.from(_myAssignments[i]);
        _myAssignments[i]['is_published'] = published;
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error toggling assignment: $e');
      return false;
    }
  }

  List<Map<String, dynamic>> getAssignmentsForClass(String classId) {
    return _myAssignments
        .where((a) => a['class_id']?.toString() == classId)
        .toList();
  }

  List<Map<String, dynamic>> getAssignmentsForClassSubject(
      String classId, String subjectId) {
    return _myAssignments
        .where((a) =>
            a['class_id']?.toString() == classId &&
            a['subject_id']?.toString() == subjectId)
        .toList();
  }

  // ═══════════════════════════════════════════════════════════
  // REALTIME — direct Supabase (not proxied)
  // ═══════════════════════════════════════════════════════════

  void _setupRealtime() {
    if (_schoolId.isEmpty || _realtimeChannels.isNotEmpty) return;
    final supabase = Supabase.instance.client;
    final ch = supabase.channel('teacher-realtime-$_schoolId');
    ch
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'school_settings',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'school_id',
              value: _schoolId),
          callback: (_) {
            _loadSettingsViaProxy();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'academic_sessions',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'school_id',
              value: _schoolId),
          callback: (_) {
            _loadSessionsViaProxy();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'terms',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'school_id',
              value: _schoolId),
          callback: (_) {
            _loadTermsViaProxy();
            notifyListeners();
          },
        )
        .subscribe();
    _realtimeChannels.add(ch);
  }

  @override
  void dispose() {
    for (final ch in _realtimeChannels) {
      try {
        ch.unsubscribe();
      } catch (_) {}
    }
    _realtimeChannels.clear();
    super.dispose();
  }
}
