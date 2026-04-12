import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Student base class.
/// Holds student profile, school branding, academic context.
/// All mixins (Results, Attendance, CBT, Fees) extend this.
///
/// MASTER PLAN:
/// - Student login fetches school branding for print isolation
/// - initialize() uses pre-fetched login data (zero extra queries)
/// - schoolName, schoolLogoUrl etc. come from THIS school only
/// - Student cannot change current term globally — only local view
/// - V4: Added supabase getter so child mixins can access DB
/// - V4: Added locale/currency/branding colors for school-independent printing

abstract class StudentBase extends ChangeNotifier {

  // ==========================================
  // SUPABASE CLIENT
  // Child mixins (Results, Attendance, CBT, Fees) all need this.
  // Without it, every mixin throws "getter 'supabase' isn't defined".
  // ==========================================
  SupabaseClient get supabase => Supabase.instance.client;

  // ==========================================
  // CORE STATE
  // ==========================================
  String _schoolId = '';
  String get schoolId => _schoolId;

  String _studentId = '';
  String get studentId => _studentId;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // ==========================================
  // ACADEMIC CONTEXT
  // ==========================================
  Map<String, dynamic>? _currentSession;
  Map<String, dynamic>? get currentSession => _currentSession;

  Map<String, dynamic>? _currentTerm;
  Map<String, dynamic>? get currentTerm => _currentTerm;

  String? _currentSessionId;
  String? get currentSessionId => _currentSessionId;

  String? _currentTermId;
  String? get currentTermId => _currentTermId;

  String _currentSessionName = '';
  String get currentSessionName => _currentSessionName;

  String _currentTermName = '';
  String get currentTermName => _currentTermName;

  // ==========================================
  // STUDENT PROFILE
  // ==========================================
  String _firstName = '';
  String _lastName = '';
  String _middleName = '';
  String _admissionNo = '';
  String _gender = '';
  String _dateOfBirth = '';
  String _classId = '';
  String _className = '';
  String _classSection = '';
  String _parentPhone = '';
  String _parentName = '';
  String _parentEmail = '';
  String _passportUrl = '';

  String get firstName => _firstName;
  String get lastName => _lastName;
  String get middleName => _middleName;
  String get fullName {
    final parts = [_firstName, _middleName, _lastName].where((s) => s.isNotEmpty);
    return parts.join(' ');
  }
  String get admissionNo => _admissionNo;
  String get gender => _gender;
  String get dateOfBirth => _dateOfBirth;
  String get classId => _classId;
  String get className => _className;
  String get classSection => _classSection;
  String get parentPhone => _parentPhone;
  String get parentName => _parentName;
  String get parentEmail => _parentEmail;
  String get passportUrl => _passportUrl;

  /// Display name for UI: "Alice Johnson (ADM001)"
  String get studentName => _admissionNo.isNotEmpty ? '$fullName ($_admissionNo)' : fullName;

  /// Class display: "SS1 A" or "SS1"
  String get classDisplay {
    if (_className.isEmpty) return '';
    if (_classSection.isNotEmpty) return '$_className $_classSection';
    return _className;
  }

  // ==========================================
  // SCHOOL BRANDING (for print isolation)
  /// These come from the student's school — NEVER from the platform.
  /// Used when student views/prints their own results.
  // ==========================================
  String _schoolName = '';
  String _schoolLogoUrl = '';
  String _schoolMotto = '';
  String _schoolAddress = '';
  String _schoolPhone = '';
  String _schoolEmail = '';
  String _schoolWebsite = '';
  String _schoolType = 'secondary';
  String? _principalSignatureUrl;
  String? _schoolStampUrl;
  String _principalName = '';

  String get schoolName => _schoolName;
  String get schoolLogoUrl => _schoolLogoUrl;
  String get schoolMotto => _schoolMotto;
  String get schoolAddress => _schoolAddress;
  String get schoolPhone => _schoolPhone;
  String get schoolEmail => _schoolEmail;
  String get schoolWebsite => _schoolWebsite;
  String get schoolType => _schoolType;
  String? get principalSignatureUrl => _principalSignatureUrl;
  String? get schoolStampUrl => _schoolStampUrl;
  String get principalName => _principalName;
  bool get hasSchoolLogo => _schoolLogoUrl.isNotEmpty;
  bool get hasPassport => _passportUrl.isNotEmpty;

  /// Export identity for student's own result prints.
  /// Zero platform branding — only this school's identity.
  Map<String, dynamic> get schoolInfoMap => {
    'id': _schoolId,
    'name': _schoolName,
    'logo_url': _schoolLogoUrl,
    'address': _schoolAddress,
    'phone': _schoolPhone,
    'whatsapp': _schoolPhone,
    'email': _schoolEmail,
    'website': _schoolWebsite,
    'motto': _schoolMotto,
    'principal_name': _principalName,
    'principal_signature_url': _principalSignatureUrl ?? '',
    'school_stamp_url': _schoolStampUrl ?? '',
    'school_type': _schoolType,
    // [V4] Branding colors for school-independent printing
    'primary_color': _primaryColor,
    'secondary_color': _secondaryColor,
    'accent_color': _accentColor,
    'text_color': _textColor,
    'header_bg_color': _headerBgColor,
    'header_text_color': _headerTextColor,
    'font_family': _fontFamily,
    'result_watermark_text': _resultWatermarkText,
    // [V4] Locale & currency
    'locale': _locale,
    'currency_code': _currencyCode,
    'currency_symbol': _currencySymbol,
  };

  // ==========================================
  // SCHOOL SETTINGS (from school_settings table)
  // ==========================================
  List<Map<String, dynamic>> _gradingSystem = [];
  List<Map<String, dynamic>> _assessmentTypes = [];
  int _subjectMaxScore = 100;
  bool _showPosition = true;
  bool _showGradeOnly = false;
  String _dateFormat = 'dd/MM/yyyy';
  String _examTemplate = 'WAEC';

  // Result layout
  bool _showTeacherComment = true;
  bool _showPrincipalComment = true;
  bool _showConduct = true;
  bool _showAttendanceSummary = true;
  bool _showGradingKey = true;
  bool _showStudentPassportOnResult = true;
  bool _showSchoolStamp = false;
  bool _showBarcode = false;
  String _resultOrientation = 'portrait';
  String _resultPaperSize = 'A4';
  String _logoPosition = 'left';
  String _resultHeaderText = '';
  String _resultFooterText = '';

  // Academic
  bool _autoComputePositions = true;
  double _passMark = 40;

  // [V4] Cumulative
  bool _showCumulative = false;

  // [V4] Locale & currency
  String _locale = 'en';
  String _currencyCode = 'NGN';
  String _currencySymbol = '₦';

  // [V4] Branding colors
  String _primaryColor = '#1a237e';
  String _secondaryColor = '#ffffff';
  String _accentColor = '#ff6f00';
  String _textColor = '#212121';
  String _headerBgColor = '#1a237e';
  String _headerTextColor = '#ffffff';
  String _fontFamily = 'default';
  String _resultWatermarkText = '';

  List<Map<String, dynamic>> get gradingSystem => _gradingSystem;
  List<Map<String, dynamic>> get assessmentTypes => _assessmentTypes;
  int get subjectMaxScore => _subjectMaxScore;
  bool get showPosition => _showPosition;
  bool get showGradeOnly => _showGradeOnly;
  String get dateFormat => _dateFormat;
  String get examTemplate => _examTemplate;
  bool get showTeacherComment => _showTeacherComment;
  bool get showPrincipalComment => _showPrincipalComment;
  bool get showConduct => _showConduct;
  bool get showAttendanceSummary => _showAttendanceSummary;
  bool get showGradingKey => _showGradingKey;
  bool get showStudentPassportOnResult => _showStudentPassportOnResult;
  bool get showSchoolStamp => _showSchoolStamp;
  bool get showBarcode => _showBarcode;
  String get resultOrientation => _resultOrientation;
  String get resultPaperSize => _resultPaperSize;
  String get logoPosition => _logoPosition;
  String get resultHeaderText => _resultHeaderText;
  String get resultFooterText => _resultFooterText;
  bool get autoComputePositions => _autoComputePositions;
  double get passMark => _passMark;
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
  int get totalMaxScore => _assessmentTypes.fold<int>(0, (sum, t) => sum + ((t['max'] as num?)?.toInt() ?? 0));

  // ==========================================
  // SESSIONS & TERMS LISTS
  // ==========================================
  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _terms = [];

  List<Map<String, dynamic>> get sessions => _sessions;
  List<Map<String, dynamic>> get terms => _terms;

  // ==========================================
  // LOGIN
  // Fetches student + joins classes + schools for branding.
  // ==========================================
  Future<bool> login(String username, String pin) async {
    try {
      final r = await supabase
          .from('students')
          .select('''
            *,
            classes(name, section),
            schools(
              name, logo_url, motto, address, official_phone, official_email,
              website, school_type, principal_signature_url, school_stamp_url
            )
          ''')
          .eq('username', username.trim())
          .eq('pin', pin.trim())
          .eq('is_active', true)
          .maybeSingle();

      if (r == null) return false;

      final gradStatus = r['graduation_status'] as String? ?? 'active';
      if (gradStatus != 'active') return false;

      _studentId = r['id'].toString();
      _schoolId = r['school_id'].toString();
      _firstName = r['first_name'] ?? '';
      _lastName = r['last_name'] ?? '';
      _middleName = r['middle_name'] ?? '';
      _admissionNo = r['admission_no'] ?? '';
      _gender = r['gender'] ?? '';
      _dateOfBirth = r['date_of_birth']?.toString() ?? '';
      _classId = (r['class_id'] ?? '').toString();
      _parentPhone = r['parent_phone'] ?? '';
      _parentName = r['parent_name'] ?? '';
      _parentEmail = r['parent_email'] ?? '';
      _passportUrl = r['passport_url'] ?? '';

      final cls = r['classes'] as Map<String, dynamic>? ?? {};
      _className = cls['name']?.toString() ?? '';
      _classSection = cls['section']?.toString() ?? '';

      final school = r['schools'] as Map<String, dynamic>? ?? {};
      _schoolName = school['name']?.toString() ?? '';
      _schoolLogoUrl = school['logo_url']?.toString() ?? '';
      _schoolMotto = school['motto']?.toString() ?? '';
      _schoolAddress = school['address']?.toString() ?? '';
      _schoolPhone = (school['official_phone']?.toString() ?? '').isNotEmpty
          ? school['official_phone'].toString()
          : (school['whatsapp']?.toString() ?? '');
      _schoolEmail = school['official_email']?.toString() ?? '';
      _schoolWebsite = school['website']?.toString() ?? '';
      _schoolType = school['school_type']?.toString() ?? 'secondary';
      _principalSignatureUrl = school['principal_signature_url']?.toString();
      _schoolStampUrl = school['school_stamp_url']?.toString();

      await _loadSessions();
      await _loadSettings();
      await _loadStudentData();

      _isInitialized = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Student login error: $e');
      return false;
    }
  }

  // ==========================================
  // INITIALIZE FROM LOGIN DATA (preferred — no extra DB queries)
  // ==========================================
  Future<void> initialize(String schoolId, String studentId, Map<String, dynamic>? data) async {
    try {
      _schoolId = schoolId;
      _studentId = studentId;

      if (data == null) return;

      _firstName = data['first_name']?.toString() ?? '';
      _lastName = data['last_name']?.toString() ?? '';
      _middleName = data['middle_name']?.toString() ?? '';
      _admissionNo = data['admission_no']?.toString() ?? '';
      _gender = data['gender']?.toString() ?? '';
      _dateOfBirth = data['date_of_birth']?.toString() ?? '';
      _classId = data['class_id']?.toString() ?? '';
      _parentPhone = data['parent_phone']?.toString() ?? '';
      _parentName = data['parent_name']?.toString() ?? '';
      _parentEmail = data['parent_email']?.toString() ?? '';
      _passportUrl = data['passport_url']?.toString() ?? '';

      if (data['classes'] != null) {
        final cls = data['classes'] as Map<String, dynamic>;
        _className = cls['name']?.toString() ?? '';
        _classSection = cls['section']?.toString() ?? '';
      }

      _schoolName = data['schoolName']?.toString() ?? '';
      _schoolLogoUrl = data['logo_url']?.toString() ?? data['schoolLogo']?.toString() ?? '';
      _schoolMotto = data['schoolMotto']?.toString() ?? '';
      _schoolAddress = data['schoolAddress']?.toString() ?? '';
      _schoolPhone = data['schoolPhone']?.toString() ?? '';
      _schoolEmail = data['schoolEmail']?.toString() ?? '';
      _schoolWebsite = data['schoolWebsite']?.toString() ?? '';
      _schoolType = data['school_type']?.toString() ?? data['schoolType']?.toString() ?? 'secondary';
      _principalSignatureUrl = data['principalSignatureUrl']?.toString();
      _schoolStampUrl = data['schoolStampUrl']?.toString();

      await _loadSessions();
      await _loadSettings();
      await _loadStudentData();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Student init error: $e');
    }
  }

  // ==========================================
  // SESSIONS & TERMS LOADERS
  // ==========================================
  Future<void> _loadSessions() async {
    try {
      final r = await supabase
          .from('academic_sessions')
          .select()
          .eq('school_id', _schoolId)
          .order('name', ascending: false);

      _sessions = List<Map<String, dynamic>>.from(r);

      _currentSession = _sessions.isNotEmpty
          ? _sessions.cast<Map<String, dynamic>?>().firstWhere(
              (s) => s?['is_current'] == true,
              orElse: () => _sessions.first,
            )
          : null;

      if (_currentSession != null) {
        _currentSessionId = _currentSession!['id']?.toString();
        _currentSessionName = _currentSession!['name']?.toString() ?? '';
        await _loadTerms();
      }
    } catch (e) {
      debugPrint('Error loading sessions: $e');
    }
  }

  Future<void> _loadTerms() async {
    if (_currentSessionId == null) return;
    try {
      final r = await supabase
          .from('terms')
          .select()
          .eq('school_id', _schoolId)
          .eq('session_id', _currentSessionId!)
          .order('created_at');

      _terms = List<Map<String, dynamic>>.from(r);

      _currentTerm = _terms.isNotEmpty
          ? _terms.cast<Map<String, dynamic>?>().firstWhere(
              (t) => t?['is_current'] == true,
              orElse: () => _terms.first,
            )
          : null;

      if (_currentTerm != null) {
        _currentTermId = _currentTerm!['id']?.toString();
        _currentTermName = _currentTerm!['name']?.toString() ?? '';
      }
    } catch (e) {
      debugPrint('Error loading terms: $e');
    }
  }

  // ==========================================
  // SETTINGS LOADER
  // ==========================================
  Future<void> _loadSettings() async {
    try {
      final r = await supabase
          .from('school_settings')
          .select()
          .eq('school_id', _schoolId)
          .maybeSingle();

      if (r != null) {
        _gradingSystem = _parseJsonList(r['grading_system']);
        _assessmentTypes = _parseJsonList(r['assessment_types']);
        _subjectMaxScore = r['subject_max_score'] as int? ?? 100;
        _showPosition = r['show_position'] as bool? ?? true;
        _showGradeOnly = r['show_grade_only'] as bool? ?? false;
        _dateFormat = r['date_format'] as String? ?? 'dd/MM/yyyy';
        _examTemplate = r['exam_template'] as String? ?? 'WAEC';
        _principalName = r['principal_name'] as String? ?? '';

        _showTeacherComment = r['show_teacher_comment'] as bool? ?? true;
        _showPrincipalComment = r['show_principal_comment'] as bool? ?? true;
        _showConduct = r['show_conduct'] as bool? ?? true;
        _showAttendanceSummary = r['show_attendance_summary'] as bool? ?? true;
        _showGradingKey = r['show_grading_key'] as bool? ?? true;
        _showStudentPassportOnResult = r['show_student_passport_on_result'] as bool? ?? true;
        _showSchoolStamp = r['show_school_stamp'] as bool? ?? false;
        _showBarcode = r['show_barcode'] as bool? ?? false;
        _resultOrientation = r['result_orientation'] as String? ?? 'portrait';
        _resultPaperSize = r['result_paper_size'] as String? ?? 'A4';
        _logoPosition = r['logo_position'] as String? ?? 'left';
        _resultHeaderText = r['result_header_text'] as String? ?? '';
        _resultFooterText = r['result_footer_text'] as String? ?? '';

        _autoComputePositions = r['auto_compute_positions'] as bool? ?? true;
        _passMark = (r['pass_mark'] as num?)?.toDouble() ?? 40;

        // [V4] New fields
        _showCumulative = r['show_cumulative'] as bool? ?? false;
        _locale = r['locale'] as String? ?? 'en';
        _currencyCode = r['currency_code'] as String? ?? 'NGN';
        _currencySymbol = r['currency_symbol'] as String? ?? '₦';
        _primaryColor = r['primary_color'] as String? ?? '#1a237e';
        _secondaryColor = r['secondary_color'] as String? ?? '#ffffff';
        _accentColor = r['accent_color'] as String? ?? '#ff6f00';
        _textColor = r['text_color'] as String? ?? '#212121';
        _headerBgColor = r['header_bg_color'] as String? ?? '#1a237e';
        _headerTextColor = r['header_text_color'] as String? ?? '#ffffff';
        _fontFamily = r['font_family'] as String? ?? 'default';
        _resultWatermarkText = r['result_watermark_text'] as String? ?? '';
      }
    } catch (e) {
      debugPrint('Error loading student settings: $e');
    }
  }

  List<Map<String, dynamic>> _parseJsonList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  // ==========================================
  // SET CURRENT TERM (local view only)
  // ==========================================
  Future<bool> setCurrentTerm(String termId) async {
    try {
      // [FIX] orElse returns null, then check for null before accessing
      final term = _terms.cast<Map<String, dynamic>?>().firstWhere(
        (t) => t?['id']?.toString() == termId,
        orElse: () => null,
      );

      // [FIX] Null check before isEmpty and [] access
      if (term == null) return false;

      _currentTerm = term;
      _currentTermId = term['id']?.toString() ?? '';
      _currentTermName = term['name']?.toString() ?? '';

      await _loadStudentData();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error setting current term: $e');
      return false;
    }
  }

  // ==========================================
  // GRADE COMPUTATION
  // ==========================================
  String calculateGrade(double total) {
    for (final g in _gradingSystem) {
      final min = (g['min'] as num?)?.toDouble();
      final max = (g['max'] as num?)?.toDouble();
      if (min != null && max != null && total >= min && total <= max) {
        return g['grade']?.toString() ?? '';
      }
    }
    return 'F';
  }

  String getGradeRemark(double total) {
    for (final g in _gradingSystem) {
      final min = (g['min'] as num?)?.toDouble();
      final max = (g['max'] as num?)?.toDouble();
      if (min != null && max != null && total >= min && total <= max) {
        return g['remark']?.toString() ?? '';
      }
    }
    return 'Fail';
  }

  double getMaxForAssessment(String assessmentId) {
    for (final t in _assessmentTypes) {
      if (t['id']?.toString() == assessmentId) {
        return (t['max'] as num?)?.toDouble() ?? 0;
      }
    }
    return 0;
  }

  // ==========================================
  // STUB — implemented by mixins
  // ==========================================
  Future<void> _loadStudentData() async {}

  // ==========================================
  // DASHBOARD STUBS — implemented by mixins
  // ==========================================
  List<Map<String, dynamic>> get scores => [];
  List<Map<String, dynamic>> get assignments => [];
  List<Map<String, dynamic>> get cbtExams => [];
  double getOverallAverage() => 0.0;

  // ==========================================
  // RESET (on logout)
  // ==========================================
  void reset() {
    _schoolId = '';
    _studentId = '';
    _isInitialized = false;
    _currentSession = null;
    _currentTerm = null;
    _currentSessionId = null;
    _currentTermId = null;
    _currentSessionName = '';
    _currentTermName = '';
    _firstName = '';
    _lastName = '';
    _middleName = '';
    _admissionNo = '';
    _gender = '';
    _dateOfBirth = '';
    _classId = '';
    _className = '';
    _classSection = '';
    _parentPhone = '';
    _parentName = '';
    _parentEmail = '';
    _passportUrl = '';
    _schoolName = '';
    _schoolLogoUrl = '';
    _schoolMotto = '';
    _schoolAddress = '';
    _schoolPhone = '';
    _schoolEmail = '';
    _schoolWebsite = '';
    _schoolType = '';
    _principalSignatureUrl = null;
    _schoolStampUrl = null;
    _principalName = '';
    _gradingSystem = [];
    _assessmentTypes = [];
    _subjectMaxScore = 100;
    _showPosition = true;
    _sessions = [];
    _terms = [];
    // [V4] Reset new fields
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
    _showCumulative = false;
    notifyListeners();
  }

  @override
  void dispose() {
    reset();
    super.dispose();
  }
}
