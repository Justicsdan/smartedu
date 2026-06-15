import 'package:flutter/foundation.dart';
import 'services/db_proxy.dart';
import 'school_model.dart';

class SuperAdminProvider extends ChangeNotifier {
  Map<String, dynamic> _currentAdmin = {};
  Map<String, dynamic> get currentAdmin => _currentAdmin;
  String _adminName = '';
  String get adminName => _adminName;
  String _adminUsername = '';
  String get adminUsername => _adminUsername;
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
  final List<School> _schools = [];
  List<School> get schools => _schools;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String _searchQuery = '';
  String get searchQuery => _searchQuery;
  String _filterType = 'all';
  String get filterType => _filterType;
  String _filterStatus = 'all';
  String get filterStatus => _filterStatus;
  int _totalStudents = 0; int get totalStudents => _totalStudents;
  int _totalTeachers = 0; int get totalTeachers => _totalTeachers;
  int _totalClasses = 0; int get totalClasses => _totalClasses;
  int _activeSchools = 0; int get activeSchools => _activeSchools;
  int _inactiveSchools = 0; int get inactiveSchools => _inactiveSchools;
  int _trialSchools = 0; int get trialSchools => _trialSchools;
  int _paidSchools = 0; int get paidSchools => _paidSchools;
  int _expiredSchools = 0; int get expiredSchools => _expiredSchools;

  void login(Map<String, dynamic> admin) { _currentAdmin = admin; _adminName = admin['name'] ?? 'Platform Owner'; _adminUsername = admin['username'] ?? ''; _isLoggedIn = true; notifyListeners(); }
  void logout() { _currentAdmin = {}; _adminName = ''; _adminUsername = ''; _isLoggedIn = false; _schools.clear(); notifyListeners(); }

  Future<void> fetchSchools() async {
    _isLoading = true; notifyListeners();
    try {
      final response = await DbProxy.instance.from('schools').select('id, school_code, name, location, address, logo_url, motto, official_phone, official_email, website, whatsapp, school_type, is_active, deactivated_at, subscription_plan, subscription_status, subscription_expires_at, trial_ends_at, max_students, max_teachers, admin_username, created_at, last_login, students(count), teachers(count), classes(count)').order('created_at', ascending: false).get();
      _schools.clear(); _totalStudents = 0; _totalTeachers = 0; _totalClasses = 0; _activeSchools = 0; _inactiveSchools = 0; _trialSchools = 0; _paidSchools = 0; _expiredSchools = 0;
      for (final row in response) {
        final sc = _extractCount(row['students']); final tc = _extractCount(row['teachers']); final cc = _extractCount(row['classes']);
        final school = School.fromMap(row).copyWith(studentCount: sc, teacherCount: tc, classCount: cc);
        _schools.add(school); _totalStudents += sc; _totalTeachers += tc; _totalClasses += cc;
        if (school.isActive) { _activeSchools++; } else { _inactiveSchools++; }
        final sub = school.subscriptionStatus; if (sub == 'trial') _trialSchools++; if (sub == 'active') _paidSchools++; if (sub == 'expired') _expiredSchools++;
      }
    } catch (e) { debugPrint('Error fetching schools: $e'); }
    _isLoading = false; notifyListeners();
  }

  int _extractCount(dynamic d) { try { final l = d as List<dynamic>?; if (l != null && l.isNotEmpty) return l[0]['count'] as int? ?? 0; } catch (_) {} return 0; }

  Future<Map<String, dynamic>?> getSchoolDetails(String schoolId) async {
    try { final r = await DbProxy.instance.from('schools').select('id, school_code, name, location, address, logo_url, motto, official_phone, official_email, website, whatsapp, school_type, is_active, deactivated_at, subscription_plan, subscription_status, subscription_expires_at, trial_ends_at, max_students, max_teachers, admin_username, created_at, last_login, students(count), teachers(count), classes(count), subjects(count), academic_sessions(count)').eq('id', schoolId).maybeSingle(); return r != null ? Map<String, dynamic>.from(r) : null; } catch (e) { debugPrint('Error fetching school details: $e'); return null; }
  }

  List<School> get filteredSchools {
    List<School> result = List.from(_schools);
    if (_searchQuery.isNotEmpty) { final q = _searchQuery.toLowerCase(); result = result.where((s) => s.name.toLowerCase().contains(q) || (s.location ?? '').toLowerCase().contains(q) || (s.adminUsername ?? '').toLowerCase().contains(q) || s.officialEmail.toLowerCase().contains(q)).toList(); }
    if (_filterType.isNotEmpty && _filterType != 'all') result = result.where((s) => s.schoolType == _filterType).toList();
    switch (_filterStatus) { case 'active': result = result.where((s) => s.isActive).toList(); break; case 'inactive': result = result.where((s) => !s.isActive).toList(); break; case 'trial': result = result.where((s) => s.subscriptionStatus == 'trial').toList(); break; case 'active_sub': result = result.where((s) => s.subscriptionStatus == 'active').toList(); break; case 'expired': result = result.where((s) => s.subscriptionStatus == 'expired').toList(); break; }
    return result;
  }
  void setSearchQuery(String q) { _searchQuery = q; notifyListeners(); }
  void setFilterType(String t) { _filterType = t; notifyListeners(); }
  void setFilterStatus(String s) { _filterStatus = s; notifyListeners(); }
  void clearFilters() { _searchQuery = ''; _filterType = 'all'; _filterStatus = 'all'; notifyListeners(); }

  List<School> getActiveSchools() => _schools.where((s) => s.isActive).toList();
  List<School> getInactiveSchools() => _schools.where((s) => !s.isActive).toList();
  List<School> getTrialSchools() => _schools.where((s) => s.subscriptionStatus == 'trial').toList();
  List<School> getActiveSubscriptionSchools() => _schools.where((s) => s.subscriptionStatus == 'active').toList();
  List<School> getExpiredSchools() => _schools.where((s) => s.subscriptionStatus == 'expired').toList();
  List<School> getOverLimitSchools() => _schools.where((s) => s.isOverStudentLimit || s.isOverTeacherLimit).toList();
  List<School> searchSchools(String query) { if (query.isEmpty) return _schools; final lq = query.toLowerCase(); return _schools.where((s) => s.name.toLowerCase().contains(lq) || (s.location ?? '').toLowerCase().contains(lq) || (s.adminUsername ?? '').toLowerCase().contains(lq) || s.officialEmail.toLowerCase().contains(lq)).toList(); }
  List<School> getSchoolsByType(String type) { if (type.isEmpty || type == 'all') return _schools; return _schools.where((s) => s.schoolType == type).toList(); }
  Map<String, int> getSchoolTypeDistribution() { Map<String, int> d = {}; for (final s in _schools) { final t = s.schoolType; d[t] = (d[t] ?? 0) + 1; } return d; }
  Map<String, int> getSubscriptionDistribution() { Map<String, int> d = {}; for (final s in _schools) { final st = s.subscriptionStatus; d[st] = (d[st] ?? 0) + 1; } return d; }

  Future<String> _generateSchoolCode() async { try { final r = await DbProxy.instance.from('schools').select('school_code').order('school_code', ascending: false).limit(1).get(); if (r.isNotEmpty && r[0]['school_code'] != null) { final mx = int.tryParse(r[0]['school_code'] as String) ?? 0; return (mx + 1).toString().padLeft(4, '0'); } } catch (_) {} return '0001'; }

  String _generateUsername(String schoolName) { final clean = schoolName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ''); final prefix = clean.length > 6 ? clean.substring(0, 6) : clean; final suffix = DateTime.now().millisecondsSinceEpoch.toString().substring(7); return '${prefix}admin$suffix'; }

  String _generateSecurePassword() {
    const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ'; const lower = 'abcdefghjkmnpqrstuvwxyz'; const digits = '23456789'; const special = '@#\$%&*';
    final random = DateTime.now().microsecondsSinceEpoch; final buffer = StringBuffer();
    buffer.write(upper[random % upper.length]); buffer.write(lower[random % lower.length]); buffer.write(digits[random % digits.length]); buffer.write(special[random % special.length]);
    const all = '$upper$lower$digits$special';
    for (int i = 4; i < 12; i++) { buffer.write(all[random % (i + 13) % all.length]); }
    final chars = buffer.toString().split('');
    for (int i = chars.length - 1; i > 0; i--) { final j = random % (i + 1); final t = chars[i]; chars[i] = chars[j]; chars[j] = t; }
    return chars.join('');
  }

  Future<Map<String, String>?> addSchool({required String name, required String location, required String schoolType, String logoUrl = '', String whatsapp = '', String officialPhone = '', String officialEmail = '', String motto = ''}) async {
    try {
      final username = _generateUsername(name); final password = _generateSecurePassword();
      final result = await DbProxy.instance.from('schools').insert({'name': name, 'location': location, 'logo_url': logoUrl.isNotEmpty ? logoUrl : null, 'whatsapp': whatsapp.isNotEmpty ? whatsapp : null, 'official_phone': officialPhone.isNotEmpty ? officialPhone : null, 'official_email': officialEmail.isNotEmpty ? officialEmail : null, 'motto': motto.isNotEmpty ? motto : null, 'school_type': schoolType, 'is_active': true, 'subscription_plan': 'free', 'subscription_status': 'trial', 'trial_ends_at': DateTime.now().add(const Duration(days: 14)).toIso8601String(), 'max_students': 100, 'max_teachers': 20, 'admin_username': username, 'admin_password': password});
      final sr = result.first;
      _schools.insert(0, School.fromMap(sr)); _activeSchools++; _trialSchools++; notifyListeners(); return {'username': username, 'password': password};
    } catch (e) { debugPrint('Error adding school: $e'); return null; }
  }

  Future<Map<String, String>?> addSchoolWithSetup({required String name, required String location, required String schoolType, String logoUrl = '', String whatsapp = '', String officialPhone = '', String officialEmail = '', String motto = '', String adminFirstName = 'School', String adminLastName = 'Admin'}) async {
    try {
      final username = _generateUsername(name); final password = _generateSecurePassword(); final schoolCode = await _generateSchoolCode();
      final schoolResult = await DbProxy.instance.from('schools').insert({'name': name, 'location': location, 'logo_url': logoUrl.isNotEmpty ? logoUrl : null, 'whatsapp': whatsapp.isNotEmpty ? whatsapp : null, 'official_phone': officialPhone.isNotEmpty ? officialPhone : null, 'official_email': officialEmail.isNotEmpty ? officialEmail : null, 'motto': motto.isNotEmpty ? motto : null, 'school_type': schoolType, 'school_code': schoolCode, 'is_active': true, 'subscription_plan': 'free', 'subscription_status': 'trial', 'trial_ends_at': DateTime.now().add(const Duration(days: 14)).toIso8601String(), 'max_students': 100, 'max_teachers': 20, 'admin_username': username, 'admin_password': password});
      final sr = schoolResult.first;
      final schoolId = sr['id'];
      final yr = DateTime.now().year; final sessName = '$yr/${yr + 1}';
      final sessResult = await DbProxy.instance.from('academic_sessions').insert({'school_id': schoolId, 'name': sessName, 'is_current': true});
      final sessR = sessResult.first;
      await DbProxy.instance.from('terms').insert({'school_id': schoolId, 'session_id': sessR['id'], 'name': 'First Term', 'is_current': true, 'term_start_date': DateTime.now().toIso8601String().split('T').first});
      final grading = schoolType == 'primary' ? [{'min': 70, 'max': 100, 'grade': 'A', 'remark': 'Excellent'}, {'min': 60, 'max': 69, 'grade': 'B', 'remark': 'Very Good'}, {'min': 50, 'max': 59, 'grade': 'C', 'remark': 'Good'}, {'min': 45, 'max': 49, 'grade': 'D', 'remark': 'Fair'}, {'min': 0, 'max': 44, 'grade': 'F', 'remark': 'Fail'}] : [{'min': 75, 'max': 100, 'grade': 'A1', 'remark': 'Excellent'}, {'min': 70, 'max': 74, 'grade': 'B2', 'remark': 'Very Good'}, {'min': 65, 'max': 69, 'grade': 'B3', 'remark': 'Good'}, {'min': 60, 'max': 64, 'grade': 'C4', 'remark': 'Credit'}, {'min': 55, 'max': 59, 'grade': 'C5', 'remark': 'Credit'}, {'min': 50, 'max': 54, 'grade': 'C6', 'remark': 'Credit'}, {'min': 45, 'max': 49, 'grade': 'D7', 'remark': 'Pass'}, {'min': 40, 'max': 44, 'grade': 'E8', 'remark': 'Pass'}, {'min': 0, 'max': 39, 'grade': 'F9', 'remark': 'Fail'}];
      await DbProxy.instance.from('school_settings').insert({'school_id': schoolId, 'exam_template': schoolType == 'primary' ? 'Default' : 'WAEC', 'grading_system': grading, 'assessment_types': [{'id': 'ca1', 'name': 'CA1', 'max': 10}, {'id': 'ca2', 'name': 'CA2', 'max': 10}, {'id': 'assignment', 'name': 'Assignment', 'max': 10}, {'id': 'midterm', 'name': 'Mid-term', 'max': 20}, {'id': 'exam', 'name': 'Exam', 'max': 50}], 'subject_max_score': 100, 'show_position': true, 'show_grade_only': false, 'current_session': sessName, 'current_term': 'First Term', 'auto_compute_positions': true, 'pass_mark': schoolType == 'primary' ? 50 : 40});
      _schools.insert(0, School.fromMap(sr)); _activeSchools++; _trialSchools++; notifyListeners(); return {'username': username, 'password': password, 'school_code': schoolCode, 'school_name': sr['name']};
    } catch (e) { debugPrint('Error adding school with setup: $e'); return null; }
  }

  Future<bool> updateSchool(String id, {String? name, String? location, String? address, String? schoolType, String? logoUrl, String? whatsapp, String? officialPhone, String? officialEmail, String? website, String? motto, int? maxStudents, int? maxTeachers}) async {
    try {
      final u = <String, dynamic>{};
      if (name != null) u['name'] = name; if (location != null) u['location'] = location; if (address != null) u['address'] = address; if (schoolType != null) u['school_type'] = schoolType; if (logoUrl != null) u['logo_url'] = logoUrl; if (whatsapp != null) u['whatsapp'] = whatsapp; if (officialPhone != null) u['official_phone'] = officialPhone; if (officialEmail != null) u['official_email'] = officialEmail; if (website != null) u['website'] = website; if (motto != null) u['motto'] = motto; if (maxStudents != null) u['max_students'] = maxStudents; if (maxTeachers != null) u['max_teachers'] = maxTeachers;
      if (u.isEmpty) return false;
      await DbProxy.instance.from('schools').eq('id', id).update(u);
      final idx = _schools.indexWhere((s) => s.id == id);
      if (idx != -1) { _schools[idx] = _schools[idx].copyWith(name: name, location: location, address: address, schoolType: schoolType, logoUrl: logoUrl, whatsapp: whatsapp, officialPhone: officialPhone, officialEmail: officialEmail, website: website, motto: motto, maxStudents: maxStudents, maxTeachers: maxTeachers); }
      notifyListeners(); return true;
    } catch (e) { debugPrint('Error updating school: $e'); return false; }
  }

  Future<bool> deleteSchool(String id) async {
    try {
      final school = _schools.firstWhere((s) => s.id == id);
      await DbProxy.instance.from('schools').eq('id', id).delete();
      _schools.removeWhere((s) => s.id == id); _totalStudents -= school.studentCount; _totalTeachers -= school.teacherCount; _totalClasses -= school.classCount;
      if (school.isActive) { _activeSchools--; } else { _inactiveSchools--; }
      final sub = school.subscriptionStatus; if (sub == 'trial') _trialSchools--; if (sub == 'active') _paidSchools--; if (sub == 'expired') _expiredSchools--;
      notifyListeners(); return true;
    } catch (e) { debugPrint('Error deleting school: $e'); return false; }
  }

  Future<bool> toggleSchoolStatus(String id) async {
    try {
      final school = _schools.firstWhere((s) => s.id == id); final ns = !school.isActive;
      if (ns) { await DbProxy.instance.from('schools').eq('id', id).update({'is_active': true, 'deactivated_at': null}); } else { await DbProxy.instance.from('schools').eq('id', id).update({'is_active': false, 'deactivated_at': DateTime.now().toUtc().toIso8601String()}); }
      final idx = _schools.indexWhere((s) => s.id == id); if (idx != -1) { _schools[idx] = _schools[idx].copyWith(isActive: ns); }
      if (ns) { _activeSchools++; _inactiveSchools--; } else { _activeSchools--; _inactiveSchools++; }
      notifyListeners(); return true;
    } catch (e) { debugPrint('Error toggling school status: $e'); return false; }
  }

  Future<bool> toggleSubscriptionStatus(String id) async {
    try {
      final school = _schools.firstWhere((s) => s.id == id); final ns = (school.subscriptionStatus == 'active') ? 'expired' : 'active';
      final u = <String, dynamic>{'subscription_status': ns}; if (ns == 'active') { u['subscription_expires_at'] = DateTime.now().add(const Duration(days: 365)).toIso8601String(); } else { u['subscription_expires_at'] = null; }
      await DbProxy.instance.from('schools').eq('id', id).update(u);
      final idx = _schools.indexWhere((s) => s.id == id); if (idx != -1) { _schools[idx] = _schools[idx].copyWith(subscriptionStatus: ns); }
      if (ns == 'active') { _paidSchools++; if (school.subscriptionStatus == 'expired') _expiredSchools--; if (school.subscriptionStatus == 'trial') _trialSchools--; } else { _expiredSchools++; if (school.subscriptionStatus == 'active') _paidSchools--; }
      notifyListeners(); return true;
    } catch (e) { debugPrint('Error toggling subscription: $e'); return false; }
  }

  Future<bool> togglePaymentStatus(String id) async => toggleSubscriptionStatus(id);

  Future<bool> extendTrial(String id, int days) async {
    try {
      final school = _schools.firstWhere((s) => s.id == id); final ne = (school.trialEndsAt ?? DateTime.now()).add(Duration(days: days));
      await DbProxy.instance.from('schools').eq('id', id).update({'subscription_status': 'trial', 'trial_ends_at': ne.toUtc().toIso8601String()});
      final idx = _schools.indexWhere((s) => s.id == id); if (idx != -1) { _schools[idx] = _schools[idx].copyWith(subscriptionStatus: 'trial', trialEndsAt: ne); }
      notifyListeners(); return true;
    } catch (e) { debugPrint('Error extending trial: $e'); return false; }
  }

  Future<Map<String, String>?> regenerateLogin(String id) async {
    try {
      final school = _schools.firstWhere((s) => s.id == id); final username = _generateUsername(school.name); final password = _generateSecurePassword();
      await DbProxy.instance.from('schools').eq('id', id).update({'admin_username': username, 'admin_password': password});
      final idx = _schools.indexWhere((s) => s.id == id); if (idx != -1) { _schools[idx] = _schools[idx].copyWith(adminUsername: username); }
      notifyListeners(); return {'username': username, 'password': password};
    } catch (e) { debugPrint('Error regenerating login: $e'); return null; }
  }

  Future<void> activateAllSchools() async {
    try { await DbProxy.instance.from('schools').update({'is_active': true, 'deactivated_at': null}); for (int i = 0; i < _schools.length; i++) { _schools[i] = _schools[i].copyWith(isActive: true); } _activeSchools = _schools.length; _inactiveSchools = 0; notifyListeners(); } catch (e) { debugPrint('Error activating all schools: $e'); }
  }

  Future<void> activateAllSubscriptions({int days = 365}) async {
    try { final exp = DateTime.now().add(Duration(days: days)).toUtc().toIso8601String(); await DbProxy.instance.from('schools').update({'subscription_status': 'active', 'subscription_expires_at': exp}); for (int i = 0; i < _schools.length; i++) { _schools[i] = _schools[i].copyWith(subscriptionStatus: 'active'); } _paidSchools = _schools.length; _expiredSchools = 0; _trialSchools = 0; notifyListeners(); } catch (e) { debugPrint('Error activating all subscriptions: $e'); }
  }

  Future<void> extendAllTrials({int days = 14}) async {
    try { final ne = DateTime.now().add(Duration(days: days)).toUtc().toIso8601String(); await DbProxy.instance.from('schools').eq('subscription_status', 'trial').update({'trial_ends_at': ne}); for (int i = 0; i < _schools.length; i++) { if (_schools[i].subscriptionStatus == 'trial') { _schools[i] = _schools[i].copyWith(trialEndsAt: DateTime.now().add(Duration(days: days))); } } notifyListeners(); } catch (e) { debugPrint('Error extending all trials: $e'); }
  }

  Map<String, dynamic> getPlatformStats() {
    return {'totalSchools': _schools.length, 'activeSchools': _activeSchools, 'inactiveSchools': _inactiveSchools, 'trialSchools': _trialSchools, 'activeSubscriptions': _paidSchools, 'expiredSubscriptions': _expiredSchools, 'totalStudents': _totalStudents, 'totalTeachers': _totalTeachers, 'totalClasses': _totalClasses, 'avgStudentsPerSchool': _schools.isNotEmpty ? (_totalStudents / _schools.length).round() : 0, 'avgTeachersPerSchool': _schools.isNotEmpty ? (_totalTeachers / _schools.length).round() : 0, 'typeDistribution': getSchoolTypeDistribution(), 'subscriptionDistribution': getSubscriptionDistribution(), 'overLimitSchools': _schools.where((s) => s.isOverStudentLimit || s.isOverTeacherLimit).length};
  }

  List<School> getRecentSchools({int limit = 5}) => _schools.take(limit).toList();
  List<School> getLargestSchools({int limit = 10}) { final sorted = List<School>.from(_schools); sorted.sort((a, b) => b.studentCount.compareTo(a.studentCount)); return sorted.take(limit).toList(); }
  List<School> getExpiringTrials({int days = 7}) { return _schools.where((s) { if (s.subscriptionStatus != 'trial' || s.trialEndsAt == null) return false; final r = s.trialEndsAt!.difference(DateTime.now()).inDays; return r >= 0 && r <= days; }).toList(); }
  List<School> getExpiringSubscriptions({int days = 7}) { return _schools.where((s) { if (s.subscriptionStatus != 'active' || s.subscriptionExpiresAt == null) return false; final r = s.subscriptionExpiresAt!.difference(DateTime.now()).inDays; return r >= 0 && r <= days; }).toList(); }

  void reset() { _schools.clear(); _totalStudents = 0; _totalTeachers = 0; _totalClasses = 0; _activeSchools = 0; _inactiveSchools = 0; _trialSchools = 0; _paidSchools = 0; _expiredSchools = 0; _searchQuery = ''; _filterType = 'all'; _filterStatus = 'all'; _isLoading = false; notifyListeners(); }

  Future<Map<String, String>?> fetchSchoolCredentials(String schoolId) async {
    try { final r = await DbProxy.instance.from('schools').select('admin_username, admin_password').eq('id', schoolId).maybeSingle(); if (r != null) return {'username': r['admin_username'] as String? ?? '', 'password': r['admin_password'] as String? ?? ''}; return null; } catch (e) { debugPrint('Error fetching credentials: $e'); return null; }
  }

  Future<Map<String, String>?> regenerateSchoolPassword(String schoolId) async {
    try {
      final existing = await DbProxy.instance.from('schools').select('admin_username, name').eq('id', schoolId).single();
      String username = (existing['admin_username'] as String? ?? '').trim(); final schoolName = (existing['name'] as String? ?? '').trim();
      if (username.isEmpty && schoolName.isNotEmpty) { username = _generateUsername(schoolName); }
      final password = _generateSecurePassword();
      await DbProxy.instance.from('schools').eq('id', schoolId).update({'admin_username': username, 'admin_password': password});
      final idx = _schools.indexWhere((s) => s.id == schoolId); if (idx != -1) { _schools[idx] = _schools[idx].copyWith(adminUsername: username); }
      notifyListeners(); return {'username': username, 'password': password};
    } catch (e) { debugPrint('Error regenerating password: $e'); return null; }
  }
}
