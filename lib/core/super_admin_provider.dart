import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'school_model.dart';

/// Super Admin Provider — manages all schools on the platform.
/// Handles school CRUD, subscription management, analytics.
///
/// MASTER PLAN:
/// - School admin credentials live in schools table (admin_username/admin_password)
/// - school_admins table does NOT exist — do NOT reference it
/// - Subscription replaces boolean has_paid_current_term
/// - NEVER fetches admin_password in list views
/// - Passwords only returned once at creation time

class SuperAdminProvider extends ChangeNotifier {

  // ==========================================
  // ADMIN STATE
  // ==========================================
  Map<String, dynamic> _currentAdmin = {};
  Map<String, dynamic> get currentAdmin => _currentAdmin;

  String _adminName = '';
  String get adminName => _adminName;

  String _adminUsername = '';
  String get adminUsername => _adminUsername;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  // ==========================================
  // SCHOOLS STATE
  // ==========================================
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

  // ==========================================
  // AGGREGATED STATISTICS
  // ==========================================
  int _totalStudents = 0;
  int get totalStudents => _totalStudents;

  int _totalTeachers = 0;
  int get totalTeachers => _totalTeachers;

  int _totalClasses = 0;
  int get totalClasses => _totalClasses;

  int _activeSchools = 0;
  int get activeSchools => _activeSchools;

  int _inactiveSchools = 0;
  int get inactiveSchools => _inactiveSchools;

  int _trialSchools = 0;
  int get trialSchools => _trialSchools;

  int _paidSchools = 0;
  int get paidSchools => _paidSchools;

  int _expiredSchools = 0;
  int get expiredSchools => _expiredSchools;

  // ==========================================
  // LOGIN / LOGOUT
  // ==========================================

  void login(Map<String, dynamic> admin) {
    _currentAdmin = admin;
    _adminName = admin['name'] ?? 'Platform Owner';
    _adminUsername = admin['username'] ?? '';
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _currentAdmin = {};
    _adminName = '';
    _adminUsername = '';
    _isLoggedIn = false;
    _schools.clear();
    notifyListeners();
  }

  // ==========================================
  // FETCH SCHOOLS (SECURE — no passwords)
  // ==========================================

  Future<void> fetchSchools() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await Supabase.instance.client
          .from('schools')
          .select('''
            id, school_code, name, location, address, logo_url, motto, official_phone, official_email,
            website, whatsapp, school_type, is_active, deactivated_at,
            subscription_plan, subscription_status, subscription_expires_at, trial_ends_at,
            max_students, max_teachers,
            admin_username, created_at, last_login,
            students(count),
            teachers(count),
            classes(count)
          ''')
          .order('created_at', ascending: false);

      _schools.clear();
      _totalStudents = 0;
      _totalTeachers = 0;
      _totalClasses = 0;
      _activeSchools = 0;
      _inactiveSchools = 0;
      _trialSchools = 0;
      _paidSchools = 0;
      _expiredSchools = 0;

      for (final row in response) {
        final studentCount = _extractCount(row['students']);
        final teacherCount = _extractCount(row['teachers']);
        final classCount = _extractCount(row['classes']);

        final school = School.fromMap(row).copyWith(
          studentCount: studentCount,
          teacherCount: teacherCount,
          classCount: classCount,
        );

        _schools.add(school);

        _totalStudents += studentCount;
        _totalTeachers += teacherCount;
        _totalClasses += classCount;

        if (school.isActive) {
          _activeSchools++;
        } else {
          _inactiveSchools++;
        }

        final subStatus = school.subscriptionStatus;
        if (subStatus == 'trial') _trialSchools++;
        if (subStatus == 'active') _paidSchools++;
        if (subStatus == 'expired') _expiredSchools++;
      }
    } catch (e) {
      debugPrint('Error fetching schools: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  int _extractCount(dynamic countData) {
    try {
      final list = countData as List<dynamic>?;
      if (list != null && list.isNotEmpty) {
        return list[0]['count'] as int? ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  Future<Map<String, dynamic>?> getSchoolDetails(String schoolId) async {
    try {
      final response = await Supabase.instance.client
          .from('schools')
          .select('''
            id, school_code, name, location, address, logo_url, motto, official_phone, official_email,
            website, whatsapp, school_type, is_active, deactivated_at,
            subscription_plan, subscription_status, subscription_expires_at, trial_ends_at,
            max_students, max_teachers,
            admin_username, created_at, last_login,
            students(count),
            teachers(count),
            classes(count),
            subjects(count),
            academic_sessions(count)
          ''')
          .eq('id', schoolId)
          .maybeSingle();

      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      debugPrint('Error fetching school details: $e');
      return null;
    }
  }

  // ==========================================
  // FILTERS
  // ==========================================

  List<School> get filteredSchools {
    List<School> result = List.from(_schools);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((s) =>
        s.name.toLowerCase().contains(q) ||
        (s.location ?? '').toLowerCase().contains(q) ||
        (s.adminUsername ?? '').toLowerCase().contains(q) ||
        s.officialEmail.toLowerCase().contains(q)
      ).toList();
    }

    if (_filterType.isNotEmpty && _filterType != 'all') {
      result = result.where((s) => s.schoolType == _filterType).toList();
    }

    switch (_filterStatus) {
      case 'active':
        result = result.where((s) => s.isActive).toList();
        break;
      case 'inactive':
        result = result.where((s) => !s.isActive).toList();
        break;
      case 'trial':
        result = result.where((s) => s.subscriptionStatus == 'trial').toList();
        break;
      case 'active_sub':
        result = result.where((s) => s.subscriptionStatus == 'active').toList();
        break;
      case 'expired':
        result = result.where((s) => s.subscriptionStatus == 'expired').toList();
        break;
    }

    return result;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterType(String type) {
    _filterType = type;
    notifyListeners();
  }

  void setFilterStatus(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterType = 'all';
    _filterStatus = 'all';
    notifyListeners();
  }

  // ==========================================
  // CONVENIENCE LISTS
  // ==========================================

  List<School> getActiveSchools() => _schools.where((s) => s.isActive).toList();
  List<School> getInactiveSchools() => _schools.where((s) => !s.isActive).toList();
  List<School> getTrialSchools() => _schools.where((s) => s.subscriptionStatus == 'trial').toList();
  List<School> getActiveSubscriptionSchools() => _schools.where((s) => s.subscriptionStatus == 'active').toList();
  List<School> getExpiredSchools() => _schools.where((s) => s.subscriptionStatus == 'expired').toList();
  List<School> getOverLimitSchools() => _schools.where((s) => s.isOverStudentLimit || s.isOverTeacherLimit).toList();

  List<School> searchSchools(String query) {
    if (query.isEmpty) return _schools;
    final lowerQuery = query.toLowerCase();
    return _schools.where((s) {
      return s.name.toLowerCase().contains(lowerQuery) ||
          (s.location ?? '').toLowerCase().contains(lowerQuery) ||
          (s.adminUsername ?? '').toLowerCase().contains(lowerQuery) ||
          s.officialEmail.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  List<School> getSchoolsByType(String type) {
    if (type.isEmpty || type == 'all') return _schools;
    return _schools.where((s) => s.schoolType == type).toList();
  }

  Map<String, int> getSchoolTypeDistribution() {
    Map<String, int> distribution = {};
    for (final school in _schools) {
      final type = school.schoolType;
      distribution[type] = (distribution[type] ?? 0) + 1;
    }
    return distribution;
  }

  Map<String, int> getSubscriptionDistribution() {
    Map<String, int> distribution = {};
    for (final school in _schools) {
      final status = school.subscriptionStatus;
      distribution[status] = (distribution[status] ?? 0) + 1;
    }
    return distribution;
  }

  // ==========================================
  // SCHOOL CODE GENERATION
  // ==========================================

  Future<String> _generateSchoolCode() async {
    try {
      final result = await Supabase.instance.client
          .from('schools')
          .select('school_code')
          .order('school_code', ascending: false)
          .limit(1);
      if (result.isNotEmpty && result[0]['school_code'] != null) {
        final maxCode = int.tryParse(result[0]['school_code'] as String) ?? 0;
        final nextCode = maxCode + 1;
        return nextCode.toString().padLeft(4, '0');
      }
    } catch (_) {}
    return '0001';
  }

  // ==========================================
  // CREDENTIAL GENERATION
  // ==========================================

  String _generateUsername(String schoolName) {
    final clean = schoolName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final prefix = clean.length > 6 ? clean.substring(0, 6) : clean;
    final suffix = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    return '${prefix}admin$suffix';
  }

  String _generateSecurePassword() {
    const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    const lower = 'abcdefghjkmnpqrstuvwxyz';
    const digits = '23456789';
    const special = '@#\$%&*';

    final random = DateTime.now().microsecondsSinceEpoch;
    final buffer = StringBuffer();

    buffer.write(upper[random % upper.length]);
    buffer.write(lower[random % lower.length]);
    buffer.write(digits[random % digits.length]);
    buffer.write(special[random % special.length]);

    const all = '$upper$lower$digits$special';
    for (int i = 4; i < 12; i++) {
      buffer.write(all[random % (i + 13) % all.length]);
    }

    final chars = buffer.toString().split('');
    for (int i = chars.length - 1; i > 0; i--) {
      final j = random % (i + 1);
      final temp = chars[i];
      chars[i] = chars[j];
      chars[j] = temp;
    }

    return chars.join('');
  }

  // ==========================================
  // SCHOOL CREATION
  // Credentials stored in schools table (admin_username/admin_password).
  // ==========================================

  Future<Map<String, String>?> addSchool({
    required String name,
    required String location,
    required String schoolType,
    String logoUrl = '',
    String whatsapp = '',
    String officialPhone = '',
    String officialEmail = '',
    String motto = '',
  }) async {
    try {
      final username = _generateUsername(name);
      final password = _generateSecurePassword();

      final schoolResponse = await Supabase.instance.client.from('schools').insert({
        'name': name,
        'location': location,
        'logo_url': logoUrl.isNotEmpty ? logoUrl : null,
        'whatsapp': whatsapp.isNotEmpty ? whatsapp : null,
        'official_phone': officialPhone.isNotEmpty ? officialPhone : null,
        'official_email': officialEmail.isNotEmpty ? officialEmail : null,
        'motto': motto.isNotEmpty ? motto : null,
        'school_type': schoolType,
        'is_active': true,
        'subscription_plan': 'free',
        'subscription_status': 'trial',
        'trial_ends_at': DateTime.now().add(const Duration(days: 14)).toIso8601String(),
        'max_students': 100,
        'max_teachers': 20,
        'admin_username': username,
        'admin_password': password,
      }).select('id, name, location, logo_url, whatsapp, school_type, is_active, admin_username, created_at').single();

      _schools.insert(0, School.fromMap(schoolResponse));
      _activeSchools++;
      _trialSchools++;
      notifyListeners();

      return {'username': username, 'password': password};
    } catch (e) {
      debugPrint('Error adding school: $e');
      return null;
    }
  }

  Future<Map<String, String>?> addSchoolWithSetup({
    required String name,
    required String location,
    required String schoolType,
    String logoUrl = '',
    String whatsapp = '',
    String officialPhone = '',
    String officialEmail = '',
    String motto = '',
    String adminFirstName = 'School',
    String adminLastName = 'Admin',
  }) async {
    try {
      final username = _generateUsername(name);
      final password = _generateSecurePassword();
      final schoolCode = await _generateSchoolCode();

      // 1. Create school record
      final schoolResponse = await Supabase.instance.client.from('schools').insert({
        'name': name,
        'location': location,
        'logo_url': logoUrl.isNotEmpty ? logoUrl : null,
        'whatsapp': whatsapp.isNotEmpty ? whatsapp : null,
        'official_phone': officialPhone.isNotEmpty ? officialPhone : null,
        'official_email': officialEmail.isNotEmpty ? officialEmail : null,
        'motto': motto.isNotEmpty ? motto : null,
        'school_type': schoolType,
        'school_code': schoolCode,
        'is_active': true,
        'subscription_plan': 'free',
        'subscription_status': 'trial',
        'trial_ends_at': DateTime.now().add(const Duration(days: 14)).toIso8601String(),
        'max_students': 100,
        'max_teachers': 20,
        'admin_username': username,
        'admin_password': password,
      }).select('id, name, school_code, location, logo_url, whatsapp, school_type, is_active, admin_username, created_at').single();

      final schoolId = schoolResponse['id'];

      // 2. Create academic session
      final currentYear = DateTime.now().year;
      final nextYear = currentYear + 1;
      final sessionName = '$currentYear/$nextYear';

      final sessionResponse = await Supabase.instance.client.from('academic_sessions').insert({
        'school_id': schoolId,
        'name': sessionName,
        'is_current': true,
      }).select('id').single();

      // 3. Create first term
      await Supabase.instance.client.from('terms').insert({
        'school_id': schoolId,
        'session_id': sessionResponse['id'],
        'name': 'First Term',
        'is_current': true,
        'term_start_date': DateTime.now().toIso8601String().split('T').first,
      });

      // 4. Create school_settings with appropriate grading
      final gradingSystem = schoolType == 'primary'
          ? [
              {'min': 70, 'max': 100, 'grade': 'A', 'remark': 'Excellent'},
              {'min': 60, 'max': 69, 'grade': 'B', 'remark': 'Very Good'},
              {'min': 50, 'max': 59, 'grade': 'C', 'remark': 'Good'},
              {'min': 45, 'max': 49, 'grade': 'D', 'remark': 'Fair'},
              {'min': 0, 'max': 44, 'grade': 'F', 'remark': 'Fail'},
            ]
          : [
              {'min': 75, 'max': 100, 'grade': 'A1', 'remark': 'Excellent'},
              {'min': 70, 'max': 74, 'grade': 'B2', 'remark': 'Very Good'},
              {'min': 65, 'max': 69, 'grade': 'B3', 'remark': 'Good'},
              {'min': 60, 'max': 64, 'grade': 'C4', 'remark': 'Credit'},
              {'min': 55, 'max': 59, 'grade': 'C5', 'remark': 'Credit'},
              {'min': 50, 'max': 54, 'grade': 'C6', 'remark': 'Credit'},
              {'min': 45, 'max': 49, 'grade': 'D7', 'remark': 'Pass'},
              {'min': 40, 'max': 44, 'grade': 'E8', 'remark': 'Pass'},
              {'min': 0, 'max': 39, 'grade': 'F9', 'remark': 'Fail'},
            ];

      await Supabase.instance.client.from('school_settings').insert({
        'school_id': schoolId,
        'exam_template': schoolType == 'primary' ? 'Default' : 'WAEC',
        'grading_system': gradingSystem,
        'assessment_types': [
          {'id': 'ca1', 'name': 'CA1', 'max': 10},
          {'id': 'ca2', 'name': 'CA2', 'max': 10},
          {'id': 'assignment', 'name': 'Assignment', 'max': 10},
          {'id': 'midterm', 'name': 'Mid-term', 'max': 20},
          {'id': 'exam', 'name': 'Exam', 'max': 50},
        ],
        'subject_max_score': 100,
        'show_position': true,
        'show_grade_only': false,
        'current_session': sessionName,
        'current_term': 'First Term',
        'auto_compute_positions': true,
        'pass_mark': schoolType == 'primary' ? 50 : 40,
      });

      _schools.insert(0, School.fromMap(schoolResponse));
      _activeSchools++;
      _trialSchools++;
      notifyListeners();

      return {'username': username, 'password': password, 'school_code': schoolCode, 'school_name': schoolResponse['name']};
    } catch (e) {
      debugPrint('Error adding school with setup: $e');
      return null;
    }
  }

  // ==========================================
  // SCHOOL UPDATE
  // ==========================================

  Future<bool> updateSchool(String id, {
    String? name,
    String? location,
    String? address,
    String? schoolType,
    String? logoUrl,
    String? whatsapp,
    String? officialPhone,
    String? officialEmail,
    String? website,
    String? motto,
    int? maxStudents,
    int? maxTeachers,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (location != null) updates['location'] = location;
      if (address != null) updates['address'] = address;
      if (schoolType != null) updates['school_type'] = schoolType;
      if (logoUrl != null) updates['logo_url'] = logoUrl;
      if (whatsapp != null) updates['whatsapp'] = whatsapp;
      if (officialPhone != null) updates['official_phone'] = officialPhone;
      if (officialEmail != null) updates['official_email'] = officialEmail;
      if (website != null) updates['website'] = website;
      if (motto != null) updates['motto'] = motto;
      if (maxStudents != null) updates['max_students'] = maxStudents;
      if (maxTeachers != null) updates['max_teachers'] = maxTeachers;

      if (updates.isEmpty) return false;

      await Supabase.instance.client.from('schools').update(updates).eq('id', id);

      final index = _schools.indexWhere((s) => s.id == id);
      if (index != -1) {
        _schools[index] = _schools[index].copyWith(
          name: name,
          location: location,
          address: address,
          schoolType: schoolType,
          logoUrl: logoUrl,
          whatsapp: whatsapp,
          officialPhone: officialPhone,
          officialEmail: officialEmail,
          website: website,
          motto: motto,
          maxStudents: maxStudents,
          maxTeachers: maxTeachers,
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating school: $e');
      return false;
    }
  }

  // ==========================================
  // SCHOOL DELETION
  // ==========================================

  Future<bool> deleteSchool(String id) async {
    try {
      final school = _schools.firstWhere((s) => s.id == id);
      await Supabase.instance.client.from('schools').delete().eq('id', id);

      _schools.removeWhere((s) => s.id == id);

      _totalStudents -= school.studentCount;
      _totalTeachers -= school.teacherCount;
      _totalClasses -= school.classCount;

      if (school.isActive) {
        _activeSchools--;
      } else {
        _inactiveSchools--;
      }

      final sub = school.subscriptionStatus;
      if (sub == 'trial') _trialSchools--;
      if (sub == 'active') _paidSchools--;
      if (sub == 'expired') _expiredSchools--;

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting school: $e');
      return false;
    }
  }

  // ==========================================
  // STATUS TOGGLES
  // ==========================================

  Future<bool> toggleSchoolStatus(String id) async {
    try {
      final school = _schools.firstWhere((s) => s.id == id);
      final newStatus = !school.isActive;

      if (newStatus) {
        await Supabase.instance.client.from('schools').update({
          'is_active': true,
          'deactivated_at': null,
        }).eq('id', id);
      } else {
        await Supabase.instance.client.from('schools').update({
          'is_active': false,
          'deactivated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', id);
      }

      final index = _schools.indexWhere((s) => s.id == id);
      if (index != -1) {
        _schools[index] = _schools[index].copyWith(isActive: newStatus);
      }

      if (newStatus) {
        _activeSchools++;
        _inactiveSchools--;
      } else {
        _activeSchools--;
        _inactiveSchools++;
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error toggling school status: $e');
      return false;
    }
  }

  Future<bool> toggleSubscriptionStatus(String id) async {
    try {
      final school = _schools.firstWhere((s) => s.id == id);
      final newStatus = (school.subscriptionStatus == 'active') ? 'expired' : 'active';

      final updates = <String, dynamic>{'subscription_status': newStatus};
      if (newStatus == 'active') {
        updates['subscription_expires_at'] = DateTime.now().add(const Duration(days: 365)).toIso8601String();
      } else {
        updates['subscription_expires_at'] = null;
      }

      await Supabase.instance.client.from('schools').update(updates).eq('id', id);

      final index = _schools.indexWhere((s) => s.id == id);
      if (index != -1) {
        _schools[index] = _schools[index].copyWith(subscriptionStatus: newStatus);
      }

      if (newStatus == 'active') {
        _paidSchools++;
        if (school.subscriptionStatus == 'expired') _expiredSchools--;
        if (school.subscriptionStatus == 'trial') _trialSchools--;
      } else {
        _expiredSchools++;
        if (school.subscriptionStatus == 'active') _paidSchools--;
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error toggling subscription: $e');
      return false;
    }
  }

  Future<bool> togglePaymentStatus(String id) async => toggleSubscriptionStatus(id);

  Future<bool> extendTrial(String id, int days) async {
    try {
      final school = _schools.firstWhere((s) => s.id == id);
      final currentEnd = school.trialEndsAt ?? DateTime.now();
      final newEnd = currentEnd.add(Duration(days: days));

      await Supabase.instance.client.from('schools').update({
        'subscription_status': 'trial',
        'trial_ends_at': newEnd.toUtc().toIso8601String(),
      }).eq('id', id);

      final index = _schools.indexWhere((s) => s.id == id);
      if (index != -1) {
        _schools[index] = _schools[index].copyWith(
          subscriptionStatus: 'trial',
          trialEndsAt: newEnd,
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error extending trial: $e');
      return false;
    }
  }

  // ==========================================
  // CREDENTIAL REGENERATION
  // ==========================================

  Future<Map<String, String>?> regenerateLogin(String id) async {
    try {
      final school = _schools.firstWhere((s) => s.id == id);
      final username = _generateUsername(school.name);
      final password = _generateSecurePassword();

      await Supabase.instance.client.from('schools').update({
        'admin_username': username,
        'admin_password': password,
      }).eq('id', id);

      final index = _schools.indexWhere((s) => s.id == id);
      if (index != -1) {
        _schools[index] = _schools[index].copyWith(adminUsername: username);
      }

      notifyListeners();

      return {'username': username, 'password': password};
    } catch (e) {
      debugPrint('Error regenerating login: $e');
      return null;
    }
  }

  // ==========================================
  // BULK OPERATIONS
  // ==========================================

  Future<void> activateAllSchools() async {
    try {
      await Supabase.instance.client.from('schools').update({
        'is_active': true,
        'deactivated_at': null,
      });

      for (int i = 0; i < _schools.length; i++) {
        _schools[i] = _schools[i].copyWith(isActive: true);
      }
      _activeSchools = _schools.length;
      _inactiveSchools = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error activating all schools: $e');
    }
  }

  Future<void> activateAllSubscriptions({int days = 365}) async {
    try {
      final expiry = DateTime.now().add(Duration(days: days)).toUtc().toIso8601String();
      await Supabase.instance.client.from('schools').update({
        'subscription_status': 'active',
        'subscription_expires_at': expiry,
      });

      for (int i = 0; i < _schools.length; i++) {
        _schools[i] = _schools[i].copyWith(subscriptionStatus: 'active');
      }
      _paidSchools = _schools.length;
      _expiredSchools = 0;
      _trialSchools = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error activating all subscriptions: $e');
    }
  }

  Future<void> extendAllTrials({int days = 14}) async {
    try {
      final newEnd = DateTime.now().add(Duration(days: days)).toUtc().toIso8601String();
      await Supabase.instance.client.from('schools').update({
        'trial_ends_at': newEnd,
      }).eq('subscription_status', 'trial');

      for (int i = 0; i < _schools.length; i++) {
        if (_schools[i].subscriptionStatus == 'trial') {
          _schools[i] = _schools[i].copyWith(trialEndsAt: DateTime.now().add(Duration(days: days)));
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error extending all trials: $e');
    }
  }

  // ==========================================
  // ANALYTICS
  // ==========================================

  Map<String, dynamic> getPlatformStats() {
    return {
      'totalSchools': _schools.length,
      'activeSchools': _activeSchools,
      'inactiveSchools': _inactiveSchools,
      'trialSchools': _trialSchools,
      'activeSubscriptions': _paidSchools,
      'expiredSubscriptions': _expiredSchools,
      'totalStudents': _totalStudents,
      'totalTeachers': _totalTeachers,
      'totalClasses': _totalClasses,
      'avgStudentsPerSchool': _schools.isNotEmpty ? (_totalStudents / _schools.length).round() : 0,
      'avgTeachersPerSchool': _schools.isNotEmpty ? (_totalTeachers / _schools.length).round() : 0,
      'typeDistribution': getSchoolTypeDistribution(),
      'subscriptionDistribution': getSubscriptionDistribution(),
      'overLimitSchools': _schools.where((s) => s.isOverStudentLimit || s.isOverTeacherLimit).length,
    };
  }

  List<School> getRecentSchools({int limit = 5}) => _schools.take(limit).toList();

  List<School> getLargestSchools({int limit = 10}) {
    final sorted = List<School>.from(_schools);
    sorted.sort((a, b) => b.studentCount.compareTo(a.studentCount));
    return sorted.take(limit).toList();
  }

  List<School> getExpiringTrials({int days = 7}) {
    return _schools.where((s) {
      if (s.subscriptionStatus != 'trial' || s.trialEndsAt == null) return false;
      final remaining = s.trialEndsAt!.difference(DateTime.now()).inDays;
      return remaining >= 0 && remaining <= days;
    }).toList();
  }

  List<School> getExpiringSubscriptions({int days = 7}) {
    return _schools.where((s) {
      if (s.subscriptionStatus != 'active' || s.subscriptionExpiresAt == null) return false;
      final remaining = s.subscriptionExpiresAt!.difference(DateTime.now()).inDays;
      return remaining >= 0 && remaining <= days;
    }).toList();
  }

  // ==========================================
  // RESET
  // ==========================================

  void reset() {
    _schools.clear();
    _totalStudents = 0;
    _totalTeachers = 0;
    _totalClasses = 0;
    _activeSchools = 0;
    _inactiveSchools = 0;
    _trialSchools = 0;
    _paidSchools = 0;
    _expiredSchools = 0;
    _searchQuery = '';
    _filterType = 'all';
    _filterStatus = 'all';
    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, String>?> fetchSchoolCredentials(String schoolId) async {
    try {
      final response = await Supabase.instance.client
          .from('schools')
          .select('admin_username, admin_password')
          .eq('id', schoolId)
          .maybeSingle();
      if (response != null) {
        return {
          'username': response['admin_username'] as String? ?? '',
          'password': response['admin_password'] as String? ?? '',
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching credentials: $e');
      return null;
    }
  }

  Future<Map<String, String>?> regenerateSchoolPassword(String schoolId) async {
    try {
      final existing = await Supabase.instance.client
          .from('schools')
          .select('admin_username, name')
          .eq('id', schoolId)
          .single();
      String username = (existing['admin_username'] as String? ?? '').trim();
      final schoolName = (existing['name'] as String? ?? '').trim();
      if (username.isEmpty && schoolName.isNotEmpty) {
        username = _generateUsername(schoolName);
      }
      final password = _generateSecurePassword();
      await Supabase.instance.client.from('schools').update({
        'admin_username': username,
        'admin_password': password,
      }).eq('id', schoolId);
      final index = _schools.indexWhere((s) => s.id == schoolId);
      if (index != -1) {
        _schools[index] = _schools[index].copyWith(adminUsername: username);
      }
      notifyListeners();
      return {'username': username, 'password': password};
    } catch (e) {
      debugPrint('Error regenerating password: $e');
      return null;
    }
  }
}
