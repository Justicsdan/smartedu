// ==========================================
// File: lib/core/providers/base_provider.dart
// ==========================================
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartedu/utils/grading_utils.dart';
import '../services/db_proxy.dart';

abstract class BaseProvider extends ChangeNotifier {

  SupabaseClient get supabase => Supabase.instance.client;

  String _schoolId = '';
  String get schoolId => _schoolId;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String _currentUserId = '';
  String get currentUserId => _currentUserId;

  String _currentUserRole = '';
  String get currentUserRole => _currentUserRole;

  bool _hasPaidCurrentTerm = false;
  bool get hasPaidCurrentTerm => _hasPaidCurrentTerm;

  String? _loginWarning;
  String? get loginWarning => _loginWarning;

  Map<String, dynamic>? currentSession;
  Map<String, dynamic>? currentTerm;

  List<Map<String, dynamic>> get sessionsList => _sessionsList;
  List<Map<String, dynamic>> _sessionsList = [];
  set sessionsList(List<Map<String, dynamic>> value) {
    _sessionsList = value;
    notifyListeners();
  }

  List<Map<String, dynamic>> get termsList => _termsList;
  List<Map<String, dynamic>> _termsList = [];
  set termsList(List<Map<String, dynamic>> value) {
    _termsList = value;
    notifyListeners();
  }

  Map<String, dynamic>? _currentUserData;
  Map<String, dynamic>? get currentUserData => _currentUserData;
  Map<String, dynamic>? get currentTeacher => _currentUserData;
  Map<String, dynamic>? get currentStudent => _currentUserData;

  String _schoolName = '';
  String get schoolName => _schoolName;

  String _schoolLocation = '';
  String _schoolAddress = '';
  String _schoolOfficialPhone = '';
  String _schoolWhatsApp = '';
  String _schoolOfficialEmail = '';
  String _schoolLogoUrl = '';
  String _schoolMotto = '';
  String _schoolWebsite = '';
  String _schoolType = 'secondary';
  bool _isActive = true;
  String? _principalSignatureUrl;
  String? _schoolStampUrl;

  String _schoolCountry = '';
  String _schoolState = '';
  String _schoolCity = '';

  String _subscriptionPlan = 'free';
  String _subscriptionStatus = 'trial';
  String? _subscriptionExpiresAt;
  String? _trialEndsAt;

  String get schoolLocation => _schoolLocation;
  String get schoolAddress => _schoolAddress;
  String get schoolOfficialPhone => _schoolOfficialPhone;
  String get schoolWhatsApp => _schoolWhatsApp;
  String get schoolPhone => _schoolOfficialPhone.isNotEmpty ? _schoolOfficialPhone : _schoolWhatsApp;
  String get schoolEmail => _schoolOfficialEmail;
  String get schoolLogoUrl => _schoolLogoUrl;
  String get schoolMotto => _schoolMotto;
  String get schoolWebsite => _schoolWebsite;
  String get schoolType => _schoolType;
  bool get isActive => _isActive;
  String? get principalSignatureUrl => _principalSignatureUrl;
  String? get schoolStampUrl => _schoolStampUrl;
  String get schoolCountry => _schoolCountry;
  String get schoolState => _schoolState;
  String get schoolCity => _schoolCity;
  String get subscriptionPlan => _subscriptionPlan;
  String get subscriptionStatus => _subscriptionStatus;
  bool get hasLogo => _schoolLogoUrl.isNotEmpty;
  bool get hasStamp => _schoolStampUrl != null && _schoolStampUrl!.isNotEmpty;
  bool get hasPrincipalSignature => _principalSignatureUrl != null && _principalSignatureUrl!.isNotEmpty;

  Map<String, dynamic>? _schoolSettings;
  Map<String, dynamic>? get schoolSettings => _schoolSettings;

  List<Map<String, dynamic>> _gradingSystem = [];
  List<Map<String, dynamic>> _assessmentTypes = [];
  int _subjectMaxScore = 100;
  String _examTemplate = 'WAEC';
  bool _showPosition = true;
  bool _showGradeOnly = false;
  String _dateFormat = 'dd/MM/yyyy';
  String _timezone = 'UTC';
  String _principalName = '';

  List<Map<String, dynamic>> get gradingSystem => _gradingSystem;
  List<Map<String, dynamic>> get assessmentTypes => _assessmentTypes;
  int get subjectMaxScore => _subjectMaxScore;
  String get examTemplate => _examTemplate;
  bool get showPosition => _showPosition;
  bool get showGradeOnly => _showGradeOnly;
  String get dateFormat => _dateFormat;
  String get timezone => _timezone;
  String get principalName => _principalName;
  int get totalMaxScore => _assessmentTypes.fold<int>(0, (sum, t) => sum + ((t['max'] as num?)?.toInt() ?? 0));
  bool get hasCustomGrading => _gradingSystem.isNotEmpty;

  String _resultOrientation = 'portrait';
  String _resultPaperSize = 'A4';
  String _logoPosition = 'left';
  bool _showStudentPassportOnResult = true;
  bool _showSchoolStamp = false;
  bool _showBarcode = false;
  String _resultHeaderText = '';
  String _resultFooterText = '';
  bool _showTeacherComment = true;
  bool _showPrincipalComment = true;
  bool _showConduct = true;
  bool _showAttendanceSummary = true;
  bool _showGradingKey = true;

  bool _autoComputePositions = true;
  double _passMark = 40;
  double _promoteThreshold = 50;
  bool _showCumulative = false;

  String _locale = 'en';
  String _currencyCode = 'NGN';
  String _currencySymbol = '₦';

  String _primaryColor = '#1a237e';
  String _secondaryColor = '#ffffff';
  String _accentColor = '#ff6f00';
  String _textColor = '#212121';
  String _headerBgColor = '#1a237e';
  String _headerTextColor = '#ffffff';
  String _fontFamily = 'default';
  String _resultWatermarkText = '';

  String get resultOrientation => _resultOrientation;
  String get resultPaperSize => _resultPaperSize;
  String get logoPosition => _logoPosition;
  bool get showStudentPassportOnResult => _showStudentPassportOnResult;
  bool get showSchoolStampOnResult => _showSchoolStamp;
  bool get showBarcode => _showBarcode;
  String get resultHeaderText => _resultHeaderText;
  String get resultFooterText => _resultFooterText;
  bool get showTeacherComment => _showTeacherComment;
  bool get showPrincipalComment => _showPrincipalComment;
  bool get showConduct => _showConduct;
  bool get showAttendanceSummary => _showAttendanceSummary;
  bool get showGradingKey => _showGradingKey;
  bool get autoComputePositions => _autoComputePositions;
  double get passMark => _passMark;
  double get promoteThreshold => _promoteThreshold;
  bool get showCumulative => _showCumulative;
  String get locale => _locale;
  String get currencyCode => _currencyCode;
  String get currencySymbol => _currencySymbol;
  String get primaryColor => _primaryColor;
  String get secondaryColor => _secondaryColor;
  String get accentColor => _accentColor;
  String get textColor => _textColor;
  String get headerBgColor => _headerBgColor;
  String get headerTextColor => _headerTextColor;
  String get fontFamily => _fontFamily;
  String get resultWatermarkText => _resultWatermarkText;

  Map<String, dynamic> get schoolInfoMap => {
    'id': _schoolId,
    'name': _schoolName,
    'logo_url': _schoolLogoUrl,
    'address': fullAddress,
    'location': _schoolLocation,
    'city': _schoolCity,
    'state': _schoolState,
    'country': _schoolCountry,
    'phone': schoolPhone,
    'whatsapp': _schoolWhatsApp,
    'email': _schoolOfficialEmail,
    'website': _schoolWebsite,
    'motto': _schoolMotto,
    'principal_name': _principalName,
    'principal_signature_url': _principalSignatureUrl ?? '',
    'school_stamp_url': _schoolStampUrl ?? '',
    'exam_template': _examTemplate,
    'school_type': _schoolType,
    'timezone': _timezone,
    'date_format': _dateFormat,
    'subject_max_score': _subjectMaxScore,
    'show_position': _showPosition,
    'result_orientation': _resultOrientation,
    'result_paper_size': _resultPaperSize,
    'logo_position': _logoPosition,
    'show_student_passport': _showStudentPassportOnResult,
    'show_school_stamp': _showSchoolStamp,
    'show_teacher_comment': _showTeacherComment,
    'show_principal_comment': _showPrincipalComment,
    'show_conduct': _showConduct,
    'show_attendance_summary': _showAttendanceSummary,
    'show_grading_key': _showGradingKey,
    'show_cumulative': _showCumulative,
    'result_header_text': _resultHeaderText,
    'result_footer_text': _resultFooterText,
    'grading_system': _gradingSystem,
    'assessment_types': _assessmentTypes,
    'school_settings': _schoolSettings,
    'locale': _locale,
    'currency_code': _currencyCode,
    'currency_symbol': _currencySymbol,
    'primary_color': _primaryColor,
    'secondary_color': _secondaryColor,
    'accent_color': _accentColor,
    'text_color': _textColor,
    'header_bg_color': _headerBgColor,
    'header_text_color': _headerTextColor,
    'font_family': _fontFamily,
    'result_watermark_text': _resultWatermarkText,
  };

  String get fullAddress {
    if (_schoolAddress.isNotEmpty) return _schoolAddress;
    final parts = <String>[
      if (_schoolLocation.isNotEmpty) _schoolLocation,
      if (_schoolCity.isNotEmpty) _schoolCity,
      if (_schoolState.isNotEmpty) _schoolState,
      if (_schoolCountry.isNotEmpty) _schoolCountry,
    ];
    return parts.isEmpty ? 'Address not set' : parts.join(', ');
  }

  String get shortAddress {
    if (_schoolAddress.isNotEmpty) return _schoolAddress.split(',').first.trim();
    if (_schoolLocation.isNotEmpty) return _schoolLocation;
    final parts = <String>[
      if (_schoolCity.isNotEmpty) _schoolCity,
      if (_schoolState.isNotEmpty) _schoolState,
    ];
    return parts.isEmpty ? '' : parts.join(', ');
  }

  String? get subscriptionWarning {
    if (_subscriptionStatus == 'expired') return 'Subscription expired. Please renew.';
    if (_subscriptionStatus == 'trial' && _trialEndsAt != null) {
      final end = DateTime.tryParse(_trialEndsAt!);
      if (end != null) {
        final days = end.difference(DateTime.now()).inDays;
        if (days < 0) return 'Free trial ended. Please upgrade.';
        if (days <= 7) return 'Trial ends in $days day(s). Upgrade now.';
      }
    }
    return null;
  }

  Map<String, dynamic> get schoolSetup => {
    'examTemplate': _examTemplate,
    'gradingSystem': _gradingSystem,
    'assessmentTypes': _assessmentTypes,
    'subjectMaxScore': _subjectMaxScore,
    'showPosition': _showPosition,
    'showGradeOnly': _showGradeOnly,
  };

  Map<String, dynamic> get resultSettings => {
    'result_orientation': _resultOrientation,
    'result_paper_size': _resultPaperSize,
    'logo_position': _logoPosition,
    'show_student_passport_on_result': _showStudentPassportOnResult,
    'show_school_stamp': _showSchoolStamp,
    'show_barcode': _showBarcode,
    'result_header_text': _resultHeaderText,
    'result_footer_text': _resultFooterText,
    'show_teacher_comment': _showTeacherComment,
    'show_principal_comment': _showPrincipalComment,
    'show_conduct': _showConduct,
    'show_attendance_summary': _showAttendanceSummary,
    'show_grading_key': _showGradingKey,
    'auto_compute_positions': _autoComputePositions,
    'pass_mark': _passMark,
    'promote_threshold': _promoteThreshold,
    'show_cumulative': _showCumulative,
    'primary_color': _primaryColor,
    'secondary_color': _secondaryColor,
    'accent_color': _accentColor,
    'text_color': _textColor,
    'header_bg_color': _headerBgColor,
    'header_text_color': _headerTextColor,
    'font_family': _fontFamily,
    'result_watermark_text': _resultWatermarkText,
    'locale': _locale,
    'currency_code': _currencyCode,
    'currency_symbol': _currencySymbol,
  };

  List<Map<String, dynamic>> get students;
  List<Map<String, dynamic>> get teachers;
  List<Map<String, dynamic>> get classes;
  List<Map<String, dynamic>> get subjects;
  List<Map<String, dynamic>> get classSubjects;
  List<Map<String, dynamic>> get assignments;
  List<Map<String, dynamic>> get scores;
  List<Map<String, dynamic>> get cbtExams;
  List<Map<String, dynamic>> get academicSessions;
  List<Map<String, dynamic>> get terms;
  List<Map<String, dynamic>> get teacherCredentials;
  List<Map<String, dynamic>> get studentCredentials;

  Future<void> logAudit({
    required String action,
    required String tableName,
    String? recordId,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
  }) async {
    if (_schoolId.isEmpty) return;
    try {
      await DbProxy.instance.from('audit_logs').insert({
        'school_id': _schoolId,
        'user_id': _currentUserId.isNotEmpty ? _currentUserId : null,
        'user_type': _currentUserRole.isNotEmpty ? _currentUserRole : 'unknown',
        'action': action,
        'table_name': tableName,
        'record_id': recordId,
        'old_data': oldData,
        'new_data': newData,
      });
    } catch (e) {
      debugPrint('Audit log skipped (expected if using custom auth without JWT): $e');
    }
  }

  Future<void> initialize(String schoolId, Map<String, dynamic>? loginData) async {
    if (schoolId.isEmpty) throw Exception('School ID is required');
    _schoolId = schoolId;
    _currentUserId = loginData?['id']?.toString() ?? '';
    _currentUserRole = loginData?['role']?.toString() ?? '';
    _currentUserData = loginData;
    try {
      await Future.wait([
        _loadSchoolInfo(),
        _loadSchoolSettings(),
      ]);
      await loadAcademicSessions();
      await _loadCoreNavigationData();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Initialization error for school $_schoolId: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  Future<void> initializeFromLoginData(Map<String, dynamic> loginData) async {
    _schoolId = loginData['school_id']?.toString() ?? loginData['schoolId']?.toString() ?? '';
    _currentUserId = loginData['id']?.toString() ?? '';
    _currentUserRole = loginData['role']?.toString() ?? '';
    _currentUserData = loginData;
    _hasPaidCurrentTerm = loginData['has_paid_current_term'] as bool? ?? false;
    _loginWarning = loginData['warning']?.toString();

    if (_schoolId.isEmpty) throw Exception('School ID is required');

    try {
      _schoolName = loginData['school_name']?.toString() ?? loginData['schoolName']?.toString() ?? '';
      _schoolLogoUrl = loginData['logo_url']?.toString() ?? '';
      _schoolLocation = loginData['location']?.toString() ?? '';
      _schoolType = loginData['school_type']?.toString() ?? 'secondary';

      await Future.wait([
        _loadSchoolInfo(),
        _loadSchoolSettings(),
        loadAcademicSessions(),
      ]);
      await _loadCoreNavigationData();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Init from login data error: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  Future<void> refreshSchoolInfo() async {
    await Future.wait([
      _loadSchoolInfo(),
      _loadSchoolSettings(),
    ]);
    notifyListeners();
  }

  void clearState() {
    _schoolId = '';
    _currentUserId = '';
    _currentUserRole = '';
    _currentUserData = null;
    _isInitialized = false;
    _hasPaidCurrentTerm = false;
    _loginWarning = null;
    _sessionsList = [];
    _termsList = [];
    currentSession = null;
    currentTerm = null;
    _schoolName = '';
    _schoolLocation = '';
    _schoolAddress = '';
    _schoolOfficialPhone = '';
    _schoolWhatsApp = '';
    _schoolOfficialEmail = '';
    _schoolLogoUrl = '';
    _schoolMotto = '';
    _schoolWebsite = '';
    _schoolType = 'secondary';
    _isActive = true;
    _principalSignatureUrl = null;
    _schoolStampUrl = null;
    _schoolCountry = '';
    _schoolState = '';
    _schoolCity = '';
    _subscriptionPlan = 'free';
    _subscriptionStatus = 'trial';
    _subscriptionExpiresAt = null;
    _trialEndsAt = null;
    _schoolSettings = null;
    _gradingSystem = [];
    _assessmentTypes = [];
    _subjectMaxScore = 100;
    _examTemplate = 'WAEC';
    _showPosition = true;
    _showGradeOnly = false;
    _dateFormat = 'dd/MM/yyyy';
    _timezone = 'UTC';
    _principalName = '';
    _resultOrientation = 'portrait';
    _resultPaperSize = 'A4';
    _logoPosition = 'left';
    _showStudentPassportOnResult = true;
    _showSchoolStamp = false;
    _showBarcode = false;
    _resultHeaderText = '';
    _resultFooterText = '';
    _showTeacherComment = true;
    _showPrincipalComment = true;
    _showConduct = true;
    _showAttendanceSummary = true;
    _showGradingKey = true;
    _autoComputePositions = true;
    _passMark = 40;
    _promoteThreshold = 50;
    _showCumulative = false;
    _locale = 'en';
    _currencyCode = 'NGN';
    _currencySymbol = '₦';
    _primaryColor = '#1a237e';
    _secondaryColor = '#ffffff';
    _accentColor = '#ff6f00';
    _textColor = '#212121';
    _headerBgColor = '#1a237e';
    _headerTextColor = '#ffffff';
    _fontFamily = 'default';
    _resultWatermarkText = '';
    notifyListeners();
  }

  Future<void> _loadSchoolInfo() async {
    try {
      final r = await supabase
          .from('schools')
          .select(
            'name, location, address, logo_url, motto, official_phone, official_email, '
            'website, whatsapp, school_type, is_active, principal_signature_url, '
            'school_stamp_url, subscription_plan, subscription_status, '
            'subscription_expires_at, trial_ends_at'
          )
          .eq('id', _schoolId)
          .maybeSingle();

      if (r != null) {
        _schoolName = (r['name'] ?? '').toString();
        _schoolLocation = (r['location'] ?? '').toString();
        _schoolAddress = (r['address'] ?? '').toString();
        _schoolLogoUrl = (r['logo_url'] ?? '').toString();
        _schoolMotto = (r['motto'] ?? '').toString();
        _schoolOfficialPhone = (r['official_phone'] ?? '').toString();
        _schoolOfficialEmail = (r['official_email'] ?? '').toString();
        _schoolWebsite = (r['website'] ?? '').toString();
        _schoolWhatsApp = (r['whatsapp'] ?? '').toString();
        _schoolType = (r['school_type'] ?? 'secondary').toString();
        _isActive = r['is_active'] ?? true;
        _principalSignatureUrl = r['principal_signature_url']?.toString();
        _schoolStampUrl = r['school_stamp_url']?.toString();
        _subscriptionPlan = (r['subscription_plan'] ?? 'free').toString();
        _subscriptionStatus = (r['subscription_status'] ?? 'trial').toString();
        _subscriptionExpiresAt = r['subscription_expires_at']?.toString();
        _trialEndsAt = r['trial_ends_at']?.toString();
      }
    } catch (e) {
      debugPrint('Error loading school info: $e');
    }
  }

  Future<void> _loadSchoolSettings() async {
    try {
      final r = await supabase
          .from('school_settings')
          .select()
          .eq('school_id', _schoolId)
          .maybeSingle();

      if (r != null) {
        _schoolSettings = Map<String, dynamic>.from(r);
        _gradingSystem = _parseJsonList(r['grading_system']);
        _assessmentTypes = _parseJsonList(r['assessment_types']);
        _subjectMaxScore = (r['subject_max_score'] as int?) ?? 100;
        _examTemplate = (r['exam_template'] as String?) ?? 'WAEC';
        _showPosition = (r['show_position'] as bool?) ?? true;
        _showGradeOnly = (r['show_grade_only'] as bool?) ?? false;
        _dateFormat = (r['date_format'] as String?) ?? 'dd/MM/yyyy';
        _timezone = (r['timezone'] as String?) ?? 'UTC';
        _principalName = (r['principal_name'] as String?) ?? '';
        _resultOrientation = (r['result_orientation'] as String?) ?? 'portrait';
        _resultPaperSize = (r['result_paper_size'] as String?) ?? 'A4';
        _logoPosition = (r['logo_position'] as String?) ?? 'left';
        _showStudentPassportOnResult = (r['show_student_passport_on_result'] as bool?) ?? true;
        _showSchoolStamp = (r['show_school_stamp'] as bool?) ?? false;
        _showBarcode = (r['show_barcode'] as bool?) ?? false;
        _resultHeaderText = (r['result_header_text'] as String?) ?? '';
        _resultFooterText = (r['result_footer_text'] as String?) ?? '';
        _showTeacherComment = (r['show_teacher_comment'] as bool?) ?? true;
        _showPrincipalComment = (r['show_principal_comment'] as bool?) ?? true;
        _showConduct = (r['show_conduct'] as bool?) ?? true;
        _showAttendanceSummary = (r['show_attendance_summary'] as bool?) ?? true;
        _showGradingKey = (r['show_grading_key'] as bool?) ?? true;
        _autoComputePositions = (r['auto_compute_positions'] as bool?) ?? true;
        _passMark = (r['pass_mark'] as num?)?.toDouble() ?? 40;
        _promoteThreshold = (r['promote_threshold'] as num?)?.toDouble() ?? 50;
        _showCumulative = (r['show_cumulative'] as bool?) ?? false;
        _locale = (r['locale'] as String?) ?? 'en';
        _currencyCode = (r['currency_code'] as String?) ?? 'NGN';
        _currencySymbol = (r['currency_symbol'] as String?) ?? '₦';
        _primaryColor = (r['primary_color'] as String?) ?? '#1a237e';
        _secondaryColor = (r['secondary_color'] as String?) ?? '#ffffff';
        _accentColor = (r['accent_color'] as String?) ?? '#ff6f00';
        _textColor = (r['text_color'] as String?) ?? '#212121';
        _headerBgColor = (r['header_bg_color'] as String?) ?? '#1a237e';
        _headerTextColor = (r['header_text_color'] as String?) ?? '#ffffff';
        _fontFamily = (r['font_family'] as String?) ?? 'default';
        _resultWatermarkText = (r['result_watermark_text'] as String?) ?? '';
      } else {
        await _createDefaultSettings();
      }
    } catch (e) {
      debugPrint('Error loading school settings: $e');
      _setDefaultSettings();
    }
  }

  List<Map<String, dynamic>> _parseJsonList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

    Future<void> _createDefaultSettings() async {
    try {
      final defaultGrading = GradingUtils.getDefaultGradingSystem('WAEC');
      final defaultAssessments = GradingUtils.getDefaultAssessmentTypes('WAEC');
      final r = await supabase
          .from('school_settings')
          .insert({
            'school_id': _schoolId,
            'exam_template': 'WAEC',
            'grading_system': defaultGrading,
            'assessment_types': defaultAssessments,
            'subject_max_score': 100,
            'show_position': true,
            'show_grade_only': false,
            'date_format': 'dd/MM/yyyy',
            'timezone': 'UTC',
            'principal_name': '',
            'locale': 'en',
            'currency_code': 'NGN',
            'currency_symbol': '₦',
            'primary_color': '#1a237e',
            'secondary_color': '#ffffff',
            'accent_color': '#ff6f00',
            'text_color': '#212121',
            'header_bg_color': '#1a237e',
            'header_text_color': '#ffffff',
            'font_family': 'default',
            'show_cumulative': false,
          })
          .select()
          .maybeSingle();
      if (r != null) {
        _schoolSettings = Map<String, dynamic>.from(r);
        _gradingSystem = defaultGrading;
        _assessmentTypes = defaultAssessments;
        await logAudit(action: 'create', tableName: 'school_settings', newData: r);
      }
    } catch (e) {
      debugPrint('Error creating default settings: $e');
      _setDefaultSettings();
    }
  }

  void _setDefaultSettings() {
    _gradingSystem = GradingUtils.getDefaultGradingSystem('WAEC');
    _assessmentTypes = GradingUtils.getDefaultAssessmentTypes('WAEC');
    _subjectMaxScore = 100;
    _examTemplate = 'WAEC';
    _showPosition = true;
    _showGradeOnly = false;
    _dateFormat = 'dd/MM/yyyy';
    _timezone = 'UTC';
    _locale = 'en';
    _currencyCode = 'NGN';
    _currencySymbol = '₦';
    _primaryColor = '#1a237e';
    _secondaryColor = '#ffffff';
    _accentColor = '#ff6f00';
    _textColor = '#212121';
    _headerBgColor = '#1a237e';
    _headerTextColor = '#ffffff';
    _fontFamily = 'default';
    _showCumulative = false;
  }

  Future<void> _loadCoreNavigationData() async {
    try {
      // Critical: blocks render — dashboard needs these to display
      await Future.wait([
        loadClasses(),
        loadSubjects(),
        loadStudents(),
        loadTeachers(),
      ]);
      // Deferred: loads in background after page is visible
      _loadDeferredData();
    } catch (e) {
      debugPrint('Error loading core navigation data: $e');
    }
  }

  Future<void> loadCbtExams() async {}

  Future<void> _loadDeferredData() async {
    try {
      await Future.wait([
        loadClassSubjects(),
        loadAssignments(),
        loadCbtExams(),
      ]);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading deferred data: $e');
    }
  }

  Future<void> reloadData() async {
    if (_schoolId.isEmpty) return;
    await _loadCoreNavigationData();
    notifyListeners();
  }

  Future<void> reloadScores() async {
    if (_schoolId.isEmpty || currentSession == null || currentTerm == null) return;
    await loadScores();
    notifyListeners();
  }

  Future<void> loadStudents() async {}
  Future<void> loadTeachers() async {}
  Future<void> loadClasses() async {}
  Future<void> loadSubjects() async {}
  Future<void> loadClassSubjects() async {}
  Future<void> loadAssignments() async {}
  Future<void> loadScores() async {}
  Future<void> loadAcademicSessions() async {}

  Future<bool> updateSchoolSettingsInDb({
    String? name,
    String? address,
    String? location,
    String? officialPhone,
    String? whatsapp,
    String? email,
    String? logoUrl,
    String? motto,
    String? country,
    String? state,
    String? city,
    String? website,
    String? principalSignatureUrl,
    String? schoolStampUrl,
  }) async {
    if (_schoolId.isEmpty) return false;
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (address != null) updates['address'] = address;
      if (location != null) updates['location'] = location;
      if (officialPhone != null) updates['official_phone'] = officialPhone;
      if (whatsapp != null) updates['whatsapp'] = whatsapp;
      if (email != null) updates['official_email'] = email;
      if (logoUrl != null) updates['logo_url'] = logoUrl;
      if (motto != null) updates['motto'] = motto;
      if (website != null) updates['website'] = website;
      if (principalSignatureUrl != null) updates['principal_signature_url'] = principalSignatureUrl;
      if (schoolStampUrl != null) updates['school_stamp_url'] = schoolStampUrl;
      if (updates.isNotEmpty) {
        await DbProxy.instance.from('schools').eq('id', _schoolId).update(updates);
        await logAudit(action: 'update', tableName: 'schools', recordId: _schoolId, newData: updates);
      }
      if (name != null) _schoolName = name;
      if (address != null) _schoolAddress = address;
      if (location != null) _schoolLocation = location;
      if (officialPhone != null) _schoolOfficialPhone = officialPhone;
      if (whatsapp != null) _schoolWhatsApp = whatsapp;
      if (email != null) _schoolOfficialEmail = email;
      if (logoUrl != null) _schoolLogoUrl = logoUrl;
      if (motto != null) _schoolMotto = motto;
      if (country != null) _schoolCountry = country;
      if (state != null) _schoolState = state;
      if (city != null) _schoolCity = city;
      if (website != null) _schoolWebsite = website;
      if (principalSignatureUrl != null) _principalSignatureUrl = principalSignatureUrl;
      if (schoolStampUrl != null) _schoolStampUrl = schoolStampUrl;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating school settings: $e');
      return false;
    }
  }

  Future<bool> updateGradingSystem(List<Map<String, dynamic>> grading) async {
    try {
      await DbProxy.instance.from('school_settings').eq('school_id', _schoolId).update({'grading_system': grading});
      _gradingSystem = grading;
      await logAudit(action: 'update', tableName: 'school_settings', newData: {'grading_system': 'updated'});
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating grading system: $e');
      return false;
    }
  }

  Future<bool> updateAssessmentTypes(List<Map<String, dynamic>> types) async {
    try {
      final maxScore = types.fold<int>(0, (s, t) => s + ((t['max'] as num?)?.toInt() ?? 0));
      await DbProxy.instance.from('school_settings').eq('school_id', _schoolId).update({
        'assessment_types': types,
        'subject_max_score': maxScore,
      });
      _assessmentTypes = types;
      _subjectMaxScore = maxScore;
      await logAudit(action: 'update', tableName: 'school_settings', newData: {'assessment_types': 'updated'});
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating assessment types: $e');
      return false;
    }
  }

  Future<bool> updateExamTemplate(String template) async {
    try {
      final defaultGrading = GradingUtils.getDefaultGradingSystem(template);
      final defaultAssessments = GradingUtils.getDefaultAssessmentTypes(template);
      await DbProxy.instance.from('school_settings').eq('school_id', _schoolId).update({
        'exam_template': template,
        'grading_system': defaultGrading,
        'assessment_types': defaultAssessments,
      });
      _examTemplate = template;
      _gradingSystem = defaultGrading;
      _assessmentTypes = defaultAssessments;
      _subjectMaxScore = defaultAssessments.fold<int>(0, (s, t) => s + ((t['max'] as num?)?.toInt() ?? 0));
      await logAudit(action: 'update', tableName: 'school_settings', newData: {'exam_template': template});
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating exam template: $e');
      return false;
    }
  }

  Future<bool> updateDisplaySettings({
    bool? showPosition,
    bool? showGradeOnly,
    String? dateFormat,
    String? timezone,
    String? principalName,
    String? motto,
  }) async {
    try {
      final u = <String, dynamic>{};
      if (showPosition != null) u['show_position'] = showPosition;
      if (showGradeOnly != null) u['show_grade_only'] = showGradeOnly;
      if (dateFormat != null) u['date_format'] = dateFormat;
      if (timezone != null) u['timezone'] = timezone;
      if (principalName != null) u['principal_name'] = principalName;
      if (motto != null) {
        await DbProxy.instance.from('schools').eq('id', _schoolId).update({'motto': motto});
        _schoolMotto = motto;
      }
      if (u.isNotEmpty) {
        await DbProxy.instance.from('school_settings').eq('school_id', _schoolId).update(u);
        await logAudit(action: 'update', tableName: 'school_settings', newData: u);
      }
      if (showPosition != null) _showPosition = showPosition;
      if (showGradeOnly != null) _showGradeOnly = showGradeOnly;
      if (dateFormat != null) _dateFormat = dateFormat;
      if (timezone != null) _timezone = timezone;
      if (principalName != null) _principalName = principalName;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating display settings: $e');
      return false;
    }
  }

  Future<bool> updateResultSettings(Map<String, dynamic> updates) async {
    try {
      if (updates.isNotEmpty) {
        await DbProxy.instance.from('school_settings').eq('school_id', _schoolId).update(updates);
        await logAudit(action: 'update', tableName: 'school_settings', newData: updates);
        if (updates.containsKey('result_orientation')) _resultOrientation = updates['result_orientation'] as String? ?? _resultOrientation;
        if (updates.containsKey('result_paper_size')) _resultPaperSize = updates['result_paper_size'] as String? ?? _resultPaperSize;
        if (updates.containsKey('logo_position')) _logoPosition = updates['logo_position'] as String? ?? _logoPosition;
        if (updates.containsKey('show_student_passport_on_result')) _showStudentPassportOnResult = updates['show_student_passport_on_result'] as bool? ?? _showStudentPassportOnResult;
        if (updates.containsKey('show_school_stamp')) _showSchoolStamp = updates['show_school_stamp'] as bool? ?? _showSchoolStamp;
        if (updates.containsKey('show_barcode')) _showBarcode = updates['show_barcode'] as bool? ?? _showBarcode;
        if (updates.containsKey('result_header_text')) _resultHeaderText = updates['result_header_text'] as String? ?? _resultHeaderText;
        if (updates.containsKey('result_footer_text')) _resultFooterText = updates['result_footer_text'] as String? ?? _resultFooterText;
        if (updates.containsKey('show_teacher_comment')) _showTeacherComment = updates['show_teacher_comment'] as bool? ?? _showTeacherComment;
        if (updates.containsKey('show_principal_comment')) _showPrincipalComment = updates['show_principal_comment'] as bool? ?? _showPrincipalComment;
        if (updates.containsKey('show_conduct')) _showConduct = updates['show_conduct'] as bool? ?? _showConduct;
        if (updates.containsKey('show_attendance_summary')) _showAttendanceSummary = updates['show_attendance_summary'] as bool? ?? _showAttendanceSummary;
        if (updates.containsKey('show_grading_key')) _showGradingKey = updates['show_grading_key'] as bool? ?? _showGradingKey;
        if (updates.containsKey('auto_compute_positions')) _autoComputePositions = updates['auto_compute_positions'] as bool? ?? _autoComputePositions;
        if (updates.containsKey('pass_mark')) _passMark = (updates['pass_mark'] as num?)?.toDouble() ?? _passMark;
        if (updates.containsKey('promote_threshold')) _promoteThreshold = (updates['promote_threshold'] as num?)?.toDouble() ?? _promoteThreshold;
        if (updates.containsKey('show_cumulative')) _showCumulative = updates['show_cumulative'] as bool? ?? _showCumulative;
        if (updates.containsKey('locale')) _locale = updates['locale'] as String? ?? _locale;
        if (updates.containsKey('currency_code')) _currencyCode = updates['currency_code'] as String? ?? _currencyCode;
        if (updates.containsKey('currency_symbol')) _currencySymbol = updates['currency_symbol'] as String? ?? _currencySymbol;
        if (updates.containsKey('primary_color')) _primaryColor = updates['primary_color'] as String? ?? _primaryColor;
        if (updates.containsKey('secondary_color')) _secondaryColor = updates['secondary_color'] as String? ?? _secondaryColor;
        if (updates.containsKey('accent_color')) _accentColor = updates['accent_color'] as String? ?? _accentColor;
        if (updates.containsKey('text_color')) _textColor = updates['text_color'] as String? ?? _textColor;
        if (updates.containsKey('header_bg_color')) _headerBgColor = updates['header_bg_color'] as String? ?? _headerBgColor;
        if (updates.containsKey('header_text_color')) _headerTextColor = updates['header_text_color'] as String? ?? _headerTextColor;
        if (updates.containsKey('font_family')) _fontFamily = updates['font_family'] as String? ?? _fontFamily;
        if (updates.containsKey('result_watermark_text')) _resultWatermarkText = updates['result_watermark_text'] as String? ?? _resultWatermarkText;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating result settings: $e');
      return false;
    }
  }

  String calculateGrade(double total) {
    return GradingUtils.getGradeOnly(total, _gradingSystem);
  }

  Map<String, dynamic> calculateGradeWithRemark(double total) {
    return GradingUtils.getGradeFromSystem(total, _gradingSystem);
  }

  int get passThreshold => GradingUtils.getPassingThreshold(_gradingSystem);

  void updateSchoolSettings(String name, String address, String phone, String email) {
    _schoolName = name;
    _schoolAddress = address;
    _schoolOfficialPhone = phone;
    _schoolOfficialEmail = email;
    notifyListeners();
  }

  void updateSchoolSetup(Map<String, dynamic> updates) {
    if (updates.containsKey('examTemplate')) _examTemplate = updates['examTemplate'] as String;
    notifyListeners();
  }

  void addAssessmentType(String name, int max) {
    _assessmentTypes.add({
      'id': name.toLowerCase().replaceAll('set', '_'),
      'name': name,
      'max': max,
    });
    notifyListeners();
  }

  void removeAssessmentType(String id) {
    _assessmentTypes.removeWhere((t) => t['id'] == id);
    notifyListeners();
  }

  void updateAssessmentType(String id, {String? name, int? max}) {
    final i = _assessmentTypes.indexWhere((t) => t['id'] == id);
    if (i != -1) {
      if (name != null) _assessmentTypes[i]['name'] = name;
      if (max != null) _assessmentTypes[i]['max'] = max;
    }
    notifyListeners();
  }

  void reorderAssessmentTypes(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final item = _assessmentTypes.removeAt(oldIndex);
    _assessmentTypes.insert(newIndex, item);
    notifyListeners();
  }

  String randomString(int len) {
    const chars = 'abcdefghjkmnpqrstuvwxyz23456789';
    final now = DateTime.now().microsecondsSinceEpoch;
    return List.generate(len, (i) => chars[(now + i * 7) % chars.length]).join();
  }

  String secureRandomString(int len) {
    const chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final now = DateTime.now().microsecondsSinceEpoch;
    return List.generate(len, (i) => chars[(now + i * 13) % chars.length]).join();
  }

  @override
  void dispose() {
    clearState();
    super.dispose();
  }
}
