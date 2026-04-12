// =============================================================================
// SMARTEDU MODELS — Matches schema v2.2 exactly
// All IDs are String (UUID). All foreign keys are String (UUID).
// =============================================================================

// =============================================================================
// ENUMS
// =============================================================================

enum ExamTemplate { waec, bece, neco, igcse, primary, american }
enum ResultOrientation { portrait, landscape }
enum ResultPaperSize { a4, a5, letter }
enum LogoPosition { left, center, right }

enum SchoolType { primary, secondary, tertiary, mixed }
enum SubscriptionPlan { free, basic, standard, premium, enterprise }
enum SubscriptionStatus { trial, active, expired, suspended, cancelled }

enum AdminRole { superAdmin, admin, assistant, dataEntry }
enum Gender { male, female, other }
enum GraduationStatus { active, graduated, withdrawn, transferred, expelled }

enum AttendanceStatus { present, absent, late, excused }
enum FeeFrequency { daily, weekly, monthly, termly, annually }

enum CbtOption { a, b, c, d }

enum AuthorType { superAdmin, schoolAdmin, teacher }
enum AnnouncementAudience { all, teachers, students, specificClass }

enum ComplaintCategory { academic, administrative, financial, bullying, health, general }
enum ComplaintStatus { open, inProgress, resolved, closed, rejected }
enum ComplaintPriority { low, normal, high, urgent }

enum UserType { superAdmin, schoolAdmin, teacher, student, parent }
enum DeviceType { android, ios, web, other }

// =============================================================================
// HELPERS
// =============================================================================

T _enumFromString<T>(List<T> values, String? key, {T? fallback}) {
  if (key == null || key.isEmpty) return fallback ?? values.first;
  final cleaned = key.toLowerCase().replaceAll('_', '').replaceAll(' ', '');
  return values.firstWhere(
    (v) => v.toString().split('.').last.toLowerCase().replaceAll('_', '') == cleaned,
    orElse: () => fallback ?? values.first,
  );
}

String _enumToString(dynamic e) {
  if (e == null) return '';
  return e.toString().split('.').last;
}


// =============================================================================
// 2.1 SUPER ADMIN
// =============================================================================

class SuperAdmin {
  final String id;
  final String? authUserId;
  final String username;
  final String name;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  SuperAdmin({
    required this.id,
    this.authUserId,
    required this.username,
    required this.name,
    this.isActive = true,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SuperAdmin.fromJson(Map<String, dynamic> json) {
    return SuperAdmin(
      id: json['id'] as String,
      authUserId: json['auth_user_id'] as String?,
      username: json['username'] as String? ?? '',
      name: json['name'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      lastLogin: json['last_login'] != null ? DateTime.parse(json['last_login']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    if (authUserId != null) 'auth_user_id': authUserId,
    'username': username,
    'name': name,
    'is_active': isActive,
  };
}


// =============================================================================
// 2.2 SCHOOL
// =============================================================================

class School {
  final String id;
  final String name;
  final String? location;
  final String? logoUrl;
  final String motto;
  final String address;
  final String officialPhone;
  final String officialEmail;
  final String website;
  final String? principalSignatureUrl;
  final String? schoolStampUrl;
  final String? whatsapp;
  final SchoolType schoolType;
  final bool isActive;
  final DateTime? deactivatedAt;
  final SubscriptionPlan subscriptionPlan;
  final SubscriptionStatus subscriptionStatus;
  final DateTime? trialEndsAt;
  final DateTime? subscriptionExpiresAt;
  final int maxStudents;
  final int maxTeachers;

  final int studentCount;
  final int teacherCount;
  final int classCount;

  final String? adminUsername;
  final String? adminPassword;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  School({
    required this.id,
    required this.name,
    this.location,
    this.logoUrl,
    this.motto = '',
    this.address = '',
    this.officialPhone = '',
    this.officialEmail = '',
    this.website = '',
    this.principalSignatureUrl,
    this.schoolStampUrl,
    this.whatsapp,
    this.schoolType = SchoolType.secondary,
    this.isActive = true,
    this.deactivatedAt,
    this.subscriptionPlan = SubscriptionPlan.free,
    this.subscriptionStatus = SubscriptionStatus.trial,
    this.trialEndsAt,
    this.subscriptionExpiresAt,
    this.maxStudents = 100,
    this.maxTeachers = 20,
    this.studentCount = 0,
    this.teacherCount = 0,
    this.classCount = 0,
    this.adminUsername,
    this.adminPassword,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      location: json['location'] as String?,
      logoUrl: json['logo_url'] as String?,
      motto: json['motto'] as String? ?? '',
      address: json['address'] as String? ?? '',
      officialPhone: json['official_phone'] as String? ?? '',
      officialEmail: json['official_email'] as String? ?? '',
      website: json['website'] as String? ?? '',
      principalSignatureUrl: json['principal_signature_url'] as String?,
      schoolStampUrl: json['school_stamp_url'] as String?,
      whatsapp: json['whatsapp'] as String?,
      schoolType: _enumFromString(SchoolType.values, json['school_type']),
      isActive: json['is_active'] as bool? ?? true,
      deactivatedAt: json['deactivated_at'] != null ? DateTime.parse(json['deactivated_at']) : null,
      subscriptionPlan: _enumFromString(SubscriptionPlan.values, json['subscription_plan']),
      subscriptionStatus: _enumFromString(SubscriptionStatus.values, json['subscription_status']),
      trialEndsAt: json['trial_ends_at'] != null ? DateTime.parse(json['trial_ends_at']) : null,
      subscriptionExpiresAt: json['subscription_expires_at'] != null ? DateTime.parse(json['subscription_expires_at']) : null,
      maxStudents: json['max_students'] as int? ?? 100,
      maxTeachers: json['max_teachers'] as int? ?? 20,
      studentCount: json['student_count'] as int? ?? 0,
      teacherCount: json['teacher_count'] as int? ?? 0,
      classCount: json['class_count'] as int? ?? 0,
      adminUsername: json['admin_username'] as String?,
      adminPassword: json['admin_password'] as String?,
      lastLogin: json['last_login'] != null ? DateTime.parse(json['last_login']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  School copyWith({
    String? name,
    String? location,
    String? address,
    SchoolType? schoolType,
    String? logoUrl,
    String? whatsapp,
    String? officialPhone,
    String? officialEmail,
    String? website,
    String? motto,
    int? maxStudents,
    int? maxTeachers,
    bool? isActive,
    SubscriptionStatus? subscriptionStatus,
    DateTime? trialEndsAt,
    DateTime? subscriptionExpiresAt,
    int? studentCount,
    int? teacherCount,
    int? classCount,
    String? adminUsername,
  }) {
    return School(
      id: id,
      name: name ?? this.name,
      location: location ?? this.location,
      address: address ?? this.address,
      schoolType: schoolType ?? this.schoolType,
      logoUrl: logoUrl ?? this.logoUrl,
      whatsapp: whatsapp ?? this.whatsapp,
      officialPhone: officialPhone ?? this.officialPhone,
      officialEmail: officialEmail ?? this.officialEmail,
      website: website ?? this.website,
      motto: motto ?? this.motto,
      maxStudents: maxStudents ?? this.maxStudents,
      maxTeachers: maxTeachers ?? this.maxTeachers,
      isActive: isActive ?? this.isActive,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      studentCount: studentCount ?? this.studentCount,
      teacherCount: teacherCount ?? this.teacherCount,
      classCount: classCount ?? this.classCount,
      adminUsername: adminUsername ?? this.adminUsername,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory School.fromMap(Map<String, dynamic> json) => School.fromJson(json);

  Map<String, dynamic> toJson() => {
    'name': name,
    if (location != null) 'location': location,
    if (logoUrl != null) 'logo_url': logoUrl,
    'motto': motto,
    'address': address,
    'official_phone': officialPhone,
    'official_email': officialEmail,
    'website': website,
    if (principalSignatureUrl != null) 'principal_signature_url': principalSignatureUrl,
    if (schoolStampUrl != null) 'school_stamp_url': schoolStampUrl,
    if (whatsapp != null) 'whatsapp': whatsapp,
    'school_type': _enumToString(schoolType),
    'is_active': isActive,
    'subscription_plan': _enumToString(subscriptionPlan),
    'subscription_status': _enumToString(subscriptionStatus),
    'max_students': maxStudents,
    'max_teachers': maxTeachers,
    if (adminUsername != null) 'admin_username': adminUsername,
    if (adminPassword != null) 'admin_password': adminPassword,
  };

  String get displayName => name.trim().isEmpty ? 'Unnamed School' : name;
  String get fullAddress => [address, location].where((s) => s != null && s.isNotEmpty).join(', ');
  bool get isOverStudentLimit => studentCount > maxStudents;
  bool get isOverTeacherLimit => teacherCount > maxTeachers;
}


// =============================================================================
// 2.3 SCHOOL ADMIN
// =============================================================================

class SchoolAdmin {
  final String id;
  final String schoolId;
  final String? authUserId;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? username;
  final String? password;
  final String profilePictureUrl;
  final AdminRole role;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  SchoolAdmin({
    required this.id,
    required this.schoolId,
    this.authUserId,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.username,
    this.password,
    this.profilePictureUrl = '',
    this.role = AdminRole.admin,
    this.isActive = true,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory SchoolAdmin.fromJson(Map<String, dynamic> json) {
    return SchoolAdmin(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      authUserId: json['auth_user_id'] as String?,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      username: json['username'] as String?,
      password: json['password'] as String?,
      profilePictureUrl: json['profile_picture_url'] as String? ?? '',
      role: _enumFromString(AdminRole.values, json['role']),
      isActive: json['is_active'] as bool? ?? true,
      lastLogin: json['last_login'] != null ? DateTime.parse(json['last_login']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    if (authUserId != null) 'auth_user_id': authUserId,
    'first_name': firstName,
    'last_name': lastName,
    if (email != null) 'email': email,
    if (phone != null) 'phone': phone,
    if (username != null) 'username': username,
    if (password != null) 'password': password,
    'profile_picture_url': profilePictureUrl,
    'role': _enumToString(role),
    'is_active': isActive,
  };
}


// =============================================================================
// 2.4 SCHOOL SETTINGS
// =============================================================================

class SchoolSettings {
  final String id;
  final String schoolId;
  final ExamTemplate examTemplate;
  final String currentSession;
  final String currentTerm;
  final List<GradingEntry> gradingSystem;
  final List<AssessmentType> assessmentTypes;
  final int subjectMaxScore;
  final bool showPosition;
  final bool showGradeOnly;
  final String dateFormat;
  final String timezone;
  final String principalName;
  final ResultOrientation resultOrientation;
  final ResultPaperSize resultPaperSize;
  final LogoPosition logoPosition;
  final bool showStudentPassportOnResult;
  final bool showSchoolStamp;
  final bool showBarcode;
  final String resultHeaderText;
  final String resultFooterText;
  final bool showTeacherComment;
  final bool showPrincipalComment;
  final bool showConduct;
  final bool showAttendanceSummary;
  final bool showGradingKey;
  final bool autoComputePositions;
  final double passMark;
  final double promoteThreshold;
  final DateTime createdAt;
  final DateTime updatedAt;

  SchoolSettings({
    required this.id,
    required this.schoolId,
    this.examTemplate = ExamTemplate.waec,
    this.currentSession = '2024/2025',
    this.currentTerm = 'First Term',
    this.gradingSystem = const [],
    this.assessmentTypes = const [],
    this.subjectMaxScore = 100,
    this.showPosition = true,
    this.showGradeOnly = false,
    this.dateFormat = 'dd/MM/yyyy',
    this.timezone = 'UTC',
    this.principalName = '',
    this.resultOrientation = ResultOrientation.portrait,
    this.resultPaperSize = ResultPaperSize.a4,
    this.logoPosition = LogoPosition.left,
    this.showStudentPassportOnResult = true,
    this.showSchoolStamp = false,
    this.showBarcode = false,
    this.resultHeaderText = '',
    this.resultFooterText = '',
    this.showTeacherComment = true,
    this.showPrincipalComment = true,
    this.showConduct = true,
    this.showAttendanceSummary = true,
    this.showGradingKey = true,
    this.autoComputePositions = true,
    this.passMark = 40,
    this.promoteThreshold = 50,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SchoolSettings.fromJson(Map<String, dynamic> json) {
    return SchoolSettings(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      examTemplate: _enumFromString(ExamTemplate.values, json['exam_template']),
      currentSession: json['current_session'] as String? ?? '2024/2025',
      currentTerm: json['current_term'] as String? ?? 'First Term',
      gradingSystem: (json['grading_system'] as List<dynamic>?)
              ?.map((e) => GradingEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      assessmentTypes: (json['assessment_types'] as List<dynamic>?)
              ?.map((e) => AssessmentType.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      subjectMaxScore: json['subject_max_score'] as int? ?? 100,
      showPosition: json['show_position'] as bool? ?? true,
      showGradeOnly: json['show_grade_only'] as bool? ?? false,
      dateFormat: json['date_format'] as String? ?? 'dd/MM/yyyy',
      timezone: json['timezone'] as String? ?? 'UTC',
      principalName: json['principal_name'] as String? ?? '',
      resultOrientation: _enumFromString(ResultOrientation.values, json['result_orientation']),
      resultPaperSize: _enumFromString(ResultPaperSize.values, json['result_paper_size']),
      logoPosition: _enumFromString(LogoPosition.values, json['logo_position']),
      showStudentPassportOnResult: json['show_student_passport_on_result'] as bool? ?? true,
      showSchoolStamp: json['show_school_stamp'] as bool? ?? false,
      showBarcode: json['show_barcode'] as bool? ?? false,
      resultHeaderText: json['result_header_text'] as String? ?? '',
      resultFooterText: json['result_footer_text'] as String? ?? '',
      showTeacherComment: json['show_teacher_comment'] as bool? ?? true,
      showPrincipalComment: json['show_principal_comment'] as bool? ?? true,
      showConduct: json['show_conduct'] as bool? ?? true,
      showAttendanceSummary: json['show_attendance_summary'] as bool? ?? true,
      showGradingKey: json['show_grading_key'] as bool? ?? true,
      autoComputePositions: json['auto_compute_positions'] as bool? ?? true,
      passMark: (json['pass_mark'] as num?)?.toDouble() ?? 40,
      promoteThreshold: (json['promote_threshold'] as num?)?.toDouble() ?? 50,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'exam_template': _enumToString(examTemplate),
    'current_session': currentSession,
    'current_term': currentTerm,
    'grading_system': gradingSystem.map((e) => e.toJson()).toList(),
    'assessment_types': assessmentTypes.map((e) => e.toJson()).toList(),
    'subject_max_score': subjectMaxScore,
    'show_position': showPosition,
    'show_grade_only': showGradeOnly,
    'date_format': dateFormat,
    'timezone': timezone,
    'principal_name': principalName,
    'result_orientation': _enumToString(resultOrientation),
    'result_paper_size': _enumToString(resultPaperSize),
    'logo_position': _enumToString(logoPosition),
    'show_student_passport_on_result': showStudentPassportOnResult,
    'show_school_stamp': showSchoolStamp,
    'show_barcode': showBarcode,
    'result_header_text': resultHeaderText,
    'result_footer_text': resultFooterText,
    'show_teacher_comment': showTeacherComment,
    'show_principal_comment': showPrincipalComment,
    'show_conduct': showConduct,
    'show_attendance_summary': showAttendanceSummary,
    'show_grading_key': showGradingKey,
    'auto_compute_positions': autoComputePositions,
    'pass_mark': passMark,
    'promote_threshold': promoteThreshold,
  };

  String getGradeForScore(double score) {
    for (final g in gradingSystem) {
      if (score >= g.min && score <= g.max) return g.grade;
    }
    return 'F9';
  }

  String getRemarkForScore(double score) {
    for (final g in gradingSystem) {
      if (score >= g.min && score <= g.max) return g.remark;
    }
    return 'Fail';
  }
}


// =============================================================================
// SETTINGS HELPERS
// =============================================================================

class GradingEntry {
  final double min;
  final double max;
  final String grade;
  final String remark;

  GradingEntry({required this.min, required this.max, required this.grade, required this.remark});

  factory GradingEntry.fromJson(Map<String, dynamic> json) {
    return GradingEntry(
      min: (json['min'] as num?)?.toDouble() ?? 0,
      max: (json['max'] as num?)?.toDouble() ?? 100,
      grade: json['grade'] as String? ?? '',
      remark: json['remark'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'min': min, 'max': max, 'grade': grade, 'remark': remark};
}

class AssessmentType {
  final String id;
  final String name;
  final double max;

  AssessmentType({required this.id, required this.name, required this.max});

  factory AssessmentType.fromJson(Map<String, dynamic> json) {
    return AssessmentType(
      id: json['id'] as String,
      name: json['name'] as String,
      max: (json['max'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'max': max};
}


// =============================================================================
// 2.5 ACADEMIC SESSION
// =============================================================================

class AcademicSession {
  final String id;
  final String schoolId;
  final String name;
  final bool isCurrent;
  final DateTime createdAt;
  final DateTime updatedAt;

  AcademicSession({
    required this.id,
    required this.schoolId,
    required this.name,
    this.isCurrent = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AcademicSession.fromJson(Map<String, dynamic> json) {
    return AcademicSession(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      name: json['name'] as String? ?? '',
      isCurrent: json['is_current'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'name': name,
    'is_current': isCurrent,
  };
}


// =============================================================================
// 2.6 TERM
// =============================================================================

class Term {
  final String id;
  final String schoolId;
  final String sessionId;
  final String name;
  final bool isCurrent;
  final DateTime? termStartDate;
  final DateTime? termEndDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Term({
    required this.id,
    required this.schoolId,
    required this.sessionId,
    required this.name,
    this.isCurrent = false,
    this.termStartDate,
    this.termEndDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Term.fromJson(Map<String, dynamic> json) {
    return Term(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      sessionId: json['session_id'] as String,
      name: json['name'] as String? ?? '',
      isCurrent: json['is_current'] as bool? ?? false,
      termStartDate: json['term_start_date'] != null ? DateTime.parse(json['term_start_date']) : null,
      termEndDate: json['term_end_date'] != null ? DateTime.parse(json['term_end_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'session_id': sessionId,
    'name': name,
    'is_current': isCurrent,
    if (termStartDate != null) 'term_start_date': termStartDate!.toIso8601String().split('T').first,
    if (termEndDate != null) 'term_end_date': termEndDate!.toIso8601String().split('T').first,
  };
}


// =============================================================================
// 2.7 CLASS
// =============================================================================

class SchoolClass {
  final String id;
  final String schoolId;
  final String name;
  final String? section;
  final int studentCount;
  final String? classTeacherId;
  final DateTime createdAt;
  final DateTime updatedAt;

  SchoolClass({
    required this.id,
    required this.schoolId,
    required this.name,
    this.section,
    this.studentCount = 0,
    this.classTeacherId,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayName => section != null && section!.isNotEmpty ? '$name $section' : name;

  factory SchoolClass.fromJson(Map<String, dynamic> json) {
    return SchoolClass(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      name: json['name'] as String? ?? '',
      section: json['section'] as String?,
      studentCount: json['student_count'] as int? ?? 0,
      classTeacherId: json['class_teacher_id'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'name': name,
    if (section != null) 'section': section,
    'student_count': studentCount,
    if (classTeacherId != null) 'class_teacher_id': classTeacherId,
  };
}


// =============================================================================
// 2.8 SUBJECT
// =============================================================================

class Subject {
  final String id;
  final String schoolId;
  final String name;
  final String? code;
  final bool isElective;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subject({
    required this.id,
    required this.schoolId,
    required this.name,
    this.code,
    this.isElective = false,
    this.description = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      isElective: json['is_elective'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'name': name,
    if (code != null) 'code': code,
    'is_elective': isElective,
    'description': description,
  };
}


// =============================================================================
// 2.9 TEACHER
// =============================================================================

class Teacher {
  final String id;
  final String schoolId;
  final String? authUserId;
  final String firstName;
  final String lastName;
  final Gender? gender;
  final String? email;
  final String? phone;
  final String? staffId;
  final String? username;
  final String? password;
  final String? homeAddress;
  final String? department;
  final String qualification;
  final String? passportUrl;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  Teacher({
    required this.id,
    required this.schoolId,
    this.authUserId,
    required this.firstName,
    required this.lastName,
    this.gender,
    this.email,
    this.phone,
    this.staffId,
    this.username,
    this.password,
    this.homeAddress,
    this.department,
    this.qualification = '',
    this.passportUrl,
    this.isActive = true,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName'.trim();
  String get displayName => staffId != null && staffId!.isNotEmpty ? '$fullName ($staffId)' : fullName;

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      authUserId: json['auth_user_id'] as String?,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      gender: _enumFromString(Gender.values, json['gender']),
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      staffId: json['staff_id'] as String?,
      username: json['username'] as String?,
      password: json['password'] as String?,
      homeAddress: json['home_address'] as String?,
      department: json['department'] as String?,
      qualification: json['qualification'] as String? ?? '',
      passportUrl: json['passport_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      lastLogin: json['last_login'] != null ? DateTime.parse(json['last_login']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    if (authUserId != null) 'auth_user_id': authUserId,
    'first_name': firstName,
    'last_name': lastName,
    if (gender != null) 'gender': _enumToString(gender),
    if (email != null) 'email': email,
    if (phone != null) 'phone': phone,
    if (staffId != null) 'staff_id': staffId,
    if (username != null) 'username': username,
    if (password != null) 'password': password,
    if (homeAddress != null) 'home_address': homeAddress,
    if (department != null) 'department': department,
    'qualification': qualification,
    if (passportUrl != null) 'passport_url': passportUrl,
    'is_active': isActive,
  };
}


// =============================================================================
// 2.10 STUDENT
// =============================================================================

class Student {
  final String id;
  final String schoolId;
  final String? classId;
  final String? authUserId;
  final String admissionNo;
  final String firstName;
  final String lastName;
  final String middleName;
  final Gender? gender;
  final DateTime? dateOfBirth;
  final String schoolLevel;
  final String? admissionSession;
  final String? admissionMode;
  final int? classAdmissionYear;
  final String? sportTeam;
  final String? clubSociety;
  final String? passportUrl;
  final String? parentPhone;
  final String parentName;
  final String parentEmail;
  final String parentOccupation;
  final String homeAddress;
  final String? username;
  final String? pin;
  final bool isActive;
  final GraduationStatus graduationStatus;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  Student({
    required this.id,
    required this.schoolId,
    this.classId,
    this.authUserId,
    required this.admissionNo,
    required this.firstName,
    required this.lastName,
    this.middleName = '',
    this.gender,
    this.dateOfBirth,
    this.schoolLevel = 'secondary',
    this.admissionSession,
    this.admissionMode,
    this.classAdmissionYear,
    this.sportTeam,
    this.clubSociety,
    this.passportUrl,
    this.parentPhone,
    this.parentName = '',
    this.parentEmail = '',
    this.parentOccupation = '',
    this.homeAddress = '',
    this.username,
    this.pin,
    this.isActive = true,
    this.graduationStatus = GraduationStatus.active,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName {
    final parts = [firstName, middleName, lastName].where((s) => s != null && s.isNotEmpty);
    return parts.join(' ');
  }

  String get displayName => '$fullName ($admissionNo)';

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      classId: json['class_id'] as String?,
      authUserId: json['auth_user_id'] as String?,
      admissionNo: json['admission_no'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      middleName: json['middle_name'] as String? ?? '',
      gender: _enumFromString(Gender.values, json['gender']),
      dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth']) : null,
      schoolLevel: json['school_level'] as String? ?? 'secondary',
      admissionSession: json['admission_session'] as String?,
      admissionMode: json['admission_mode'] as String?,
      classAdmissionYear: json['class_admission_year'] as int?,
      sportTeam: json['sport_team'] as String?,
      clubSociety: json['club_society'] as String?,
      passportUrl: json['passport_url'] as String?,
      parentPhone: json['parent_phone'] as String?,
      parentName: json['parent_name'] as String? ?? '',
      parentEmail: json['parent_email'] as String? ?? '',
      parentOccupation: json['parent_occupation'] as String? ?? '',
      homeAddress: json['home_address'] as String? ?? '',
      username: json['username'] as String?,
      pin: json['pin'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      graduationStatus: _enumFromString(GraduationStatus.values, json['graduation_status']),
      lastLogin: json['last_login'] != null ? DateTime.parse(json['last_login']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    if (classId != null) 'class_id': classId,
    if (authUserId != null) 'auth_user_id': authUserId,
    'admission_no': admissionNo,
    'first_name': firstName,
    'last_name': lastName,
    'middle_name': middleName,
    if (gender != null) 'gender': _enumToString(gender),
    if (dateOfBirth != null) 'date_of_birth': dateOfBirth!.toIso8601String().split('T').first,
    'school_level': schoolLevel,
    if (admissionSession != null) 'admission_session': admissionSession,
    if (admissionMode != null) 'admission_mode': admissionMode,
    if (classAdmissionYear != null) 'class_admission_year': classAdmissionYear,
    if (sportTeam != null) 'sport_team': sportTeam,
    if (clubSociety != null) 'club_society': clubSociety,
    if (passportUrl != null) 'passport_url': passportUrl,
    if (parentPhone != null) 'parent_phone': parentPhone,
    'parent_name': parentName,
    'parent_email': parentEmail,
    'parent_occupation': parentOccupation,
    'home_address': homeAddress,
    if (username != null) 'username': username,
    if (pin != null) 'pin': pin,
    'is_active': isActive,
    'graduation_status': _enumToString(graduationStatus),
  };
}


// =============================================================================
// 2.11 & 2.12 ASSIGNMENTS (teacher-class)
// =============================================================================

class FormTeacherAssignment {
  final String id;
  final String schoolId;
  final String classId;
  final String teacherId;
  final String sessionId;
  final DateTime createdAt;

  FormTeacherAssignment({
    required this.id,
    required this.schoolId,
    required this.classId,
    required this.teacherId,
    required this.sessionId,
    required this.createdAt,
  });

  factory FormTeacherAssignment.fromJson(Map<String, dynamic> json) {
    return FormTeacherAssignment(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      classId: json['class_id'] as String,
      teacherId: json['teacher_id'] as String,
      sessionId: json['session_id'] as String,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'class_id': classId,
    'teacher_id': teacherId,
    'session_id': sessionId,
  };
}

class SubjectTeacherAssignment {
  final String id;
  final String schoolId;
  final String classId;
  final String subjectId;
  final String teacherId;
  final String sessionId;
  final DateTime createdAt;

  SubjectTeacherAssignment({
    required this.id,
    required this.schoolId,
    required this.classId,
    required this.subjectId,
    required this.teacherId,
    required this.sessionId,
    required this.createdAt,
  });

  factory SubjectTeacherAssignment.fromJson(Map<String, dynamic> json) {
    return SubjectTeacherAssignment(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      classId: json['class_id'] as String,
      subjectId: json['subject_id'] as String,
      teacherId: json['teacher_id'] as String,
      sessionId: json['session_id'] as String,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'class_id': classId,
    'subject_id': subjectId,
    'teacher_id': teacherId,
    'session_id': sessionId,
  };
}


// =============================================================================
// 2.13 SCORE
// =============================================================================

class Score {
  final String id;
  final String schoolId;
  final String studentId;
  final String classId;
  final String subjectId;
  final String sessionId;
  final String termId;
  final Map<String, dynamic> scoresJson;
  final double total;
  final String grade;
  final int? position;
  final int? positionOutOf;
  final String? recordedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Score({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.classId,
    required this.subjectId,
    required this.sessionId,
    required this.termId,
    this.scoresJson = const {},
    this.total = 0,
    this.grade = '',
    this.position,
    this.positionOutOf,
    this.recordedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Score.fromJson(Map<String, dynamic> json) {
    return Score(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      studentId: json['student_id'] as String,
      classId: json['class_id'] as String,
      subjectId: json['subject_id'] as String,
      sessionId: json['session_id'] as String,
      termId: json['term_id'] as String,
      scoresJson: json['scores_json'] as Map<String, dynamic>? ?? {},
      total: (json['total'] as num?)?.toDouble() ?? 0,
      grade: json['grade'] as String? ?? '',
      position: json['position'] as int?,
      positionOutOf: json['position_out_of'] as int?,
      recordedBy: json['recorded_by'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'student_id': studentId,
    'class_id': classId,
    'subject_id': subjectId,
    'session_id': sessionId,
    'term_id': termId,
    'scores_json': scoresJson,
    'total': total,
    'grade': grade,
    if (recordedBy != null) 'recorded_by': recordedBy,
  };
}


// =============================================================================
// 2.14 STUDENT TERM SUMMARY
// =============================================================================

class StudentTermSummary {
  final String id;
  final String schoolId;
  final String studentId;
  final String classId;
  final String sessionId;
  final String termId;
  final double totalScore;
  final int subjectsTaken;
  final double averageScore;
  final String grade;
  final int? position;
  final int? positionOutOf;
  final int daysPresent;
  final int daysAbsent;
  final bool isPublished;
  final DateTime? publishedAt;
  final String? publishedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  StudentTermSummary({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.classId,
    required this.sessionId,
    required this.termId,
    this.totalScore = 0,
    this.subjectsTaken = 0,
    this.averageScore = 0,
    this.grade = '',
    this.position,
    this.positionOutOf,
    this.daysPresent = 0,
    this.daysAbsent = 0,
    this.isPublished = false,
    this.publishedAt,
    this.publishedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudentTermSummary.fromJson(Map<String, dynamic> json) {
    return StudentTermSummary(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      studentId: json['student_id'] as String,
      classId: json['class_id'] as String,
      sessionId: json['session_id'] as String,
      termId: json['term_id'] as String,
      totalScore: (json['total_score'] as num?)?.toDouble() ?? 0,
      subjectsTaken: json['subjects_taken'] as int? ?? 0,
      averageScore: (json['average_score'] as num?)?.toDouble() ?? 0,
      grade: json['grade'] as String? ?? '',
      position: json['position'] as int?,
      positionOutOf: json['position_out_of'] as int?,
      daysPresent: json['days_present'] as int? ?? 0,
      daysAbsent: json['days_absent'] as int? ?? 0,
      isPublished: json['is_published'] as bool? ?? false,
      publishedAt: json['published_at'] != null ? DateTime.parse(json['published_at']) : null,
      publishedBy: json['published_by'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'student_id': studentId,
    'class_id': classId,
    'session_id': sessionId,
    'term_id': termId,
    'total_score': totalScore,
    'subjects_taken': subjectsTaken,
    'average_score': averageScore,
    'grade': grade,
    'days_present': daysPresent,
    'days_absent': daysAbsent,
    'is_published': isPublished,
    if (publishedBy != null) 'published_by': publishedBy,
  };
}


// =============================================================================
// 2.15 ATTENDANCE
// =============================================================================

class Attendance {
  final String id;
  final String schoolId;
  final String studentId;
  final String classId;
  final String sessionId;
  final String termId;
  final DateTime date;
  final AttendanceStatus status;
  final String? remark;
  final String? recordedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Attendance({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.classId,
    required this.sessionId,
    required this.termId,
    required this.date,
    required this.status,
    this.remark,
    this.recordedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      studentId: json['student_id'] as String,
      classId: json['class_id'] as String,
      sessionId: json['session_id'] as String,
      termId: json['term_id'] as String,
      date: DateTime.parse(json['date']),
      status: _enumFromString(AttendanceStatus.values, json['status']),
      remark: json['remark'] as String?,
      recordedBy: json['recorded_by'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'student_id': studentId,
    'class_id': classId,
    'session_id': sessionId,
    'term_id': termId,
    'date': date.toIso8601String().split('T').first,
    'status': _enumToString(status),
    if (remark != null) 'remark': remark,
    if (recordedBy != null) 'recorded_by': recordedBy,
  };
}


// =============================================================================
// 2.16, 2.17, 2.18 CBT
// =============================================================================

class CbtExam {
  final String id;
  final String schoolId;
  final String title;
  final String? subjectId;
  final String? classId;
  final int durationMinutes;
  final int totalQuestions;
  final double passMark;
  final bool isActive;
  final DateTime? startTime;
  final DateTime? endTime;
  final String instructions;
  final bool shuffleQuestions;
  final bool showResultImmediately;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  CbtExam({
    required this.id,
    required this.schoolId,
    required this.title,
    this.subjectId,
    this.classId,
    this.durationMinutes = 60,
    this.totalQuestions = 50,
    this.passMark = 40,
    this.isActive = false,
    this.startTime,
    this.endTime,
    this.instructions = '',
    this.shuffleQuestions = false,
    this.showResultImmediately = true,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CbtExam.fromJson(Map<String, dynamic> json) {
    return CbtExam(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      title: json['title'] as String? ?? '',
      subjectId: json['subject_id'] as String?,
      classId: json['class_id'] as String?,
      durationMinutes: json['duration_minutes'] as int? ?? 60,
      totalQuestions: json['total_questions'] as int? ?? 50,
      passMark: (json['pass_mark'] as num?)?.toDouble() ?? 40,
      isActive: json['is_active'] as bool? ?? false,
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time']) : null,
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      instructions: json['instructions'] as String? ?? '',
      shuffleQuestions: json['shuffle_questions'] as bool? ?? false,
      showResultImmediately: json['show_result_immediately'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'title': title,
    if (subjectId != null) 'subject_id': subjectId,
    if (classId != null) 'class_id': classId,
    'duration_minutes': durationMinutes,
    'total_questions': totalQuestions,
    'pass_mark': passMark,
    'is_active': isActive,
    if (startTime != null) 'start_time': startTime!.toIso8601String(),
    if (endTime != null) 'end_time': endTime!.toIso8601String(),
    'instructions': instructions,
    'shuffle_questions': shuffleQuestions,
    'show_result_immediately': showResultImmediately,
    if (createdBy != null) 'created_by': createdBy,
  };
}

class CbtQuestion {
  final String id;
  final String schoolId;
  final String examId;
  final String questionText;
  final String? optionA;
  final String? optionB;
  final String? optionC;
  final String? optionD;
  final CbtOption correctOption;
  final String? explanation;
  final int marks;
  final int questionOrder;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  CbtQuestion({
    required this.id,
    required this.schoolId,
    required this.examId,
    required this.questionText,
    this.optionA,
    this.optionB,
    this.optionC,
    this.optionD,
    required this.correctOption,
    this.explanation,
    this.marks = 1,
    this.questionOrder = 0,
    this.imageUrl = '',
    required this.createdAt,
    required this.updatedAt,
  });

  String? getOption(String letter) {
    switch (letter.toLowerCase()) {
      case 'a': return optionA;
      case 'b': return optionB;
      case 'c': return optionC;
      case 'd': return optionD;
      default: return null;
    }
  }

  factory CbtQuestion.fromJson(Map<String, dynamic> json) {
    return CbtQuestion(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      examId: json['exam_id'] as String,
      questionText: json['question_text'] as String? ?? '',
      optionA: json['option_a'] as String?,
      optionB: json['option_b'] as String?,
      optionC: json['option_c'] as String?,
      optionD: json['option_d'] as String?,
      correctOption: _enumFromString(CbtOption.values, json['correct_option']),
      explanation: json['explanation'] as String?,
      marks: json['marks'] as int? ?? 1,
      questionOrder: json['question_order'] as int? ?? 0,
      imageUrl: json['image_url'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'exam_id': examId,
    'question_text': questionText,
    'option_a': optionA,
    'option_b': optionB,
    'option_c': optionC,
    'option_d': optionD,
    'correct_option': _enumToString(correctOption),
    if (explanation != null) 'explanation': explanation,
    'marks': marks,
    'question_order': questionOrder,
    'image_url': imageUrl,
  };
}

class CbtAttempt {
  final String id;
  final String schoolId;
  final String examId;
  final String studentId;
  final Map<String, dynamic> answers;
  final double score;
  final int totalMarks;
  final DateTime? timeStarted;
  final DateTime? timeSubmitted;
  final bool isSubmitted;
  final String ipAddress;
  final DateTime createdAt;
  final DateTime updatedAt;

  CbtAttempt({
    required this.id,
    required this.schoolId,
    required this.examId,
    required this.studentId,
    this.answers = const {},
    this.score = 0,
    this.totalMarks = 0,
    this.timeStarted,
    this.timeSubmitted,
    this.isSubmitted = false,
    this.ipAddress = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory CbtAttempt.fromJson(Map<String, dynamic> json) {
    return CbtAttempt(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      examId: json['exam_id'] as String,
      studentId: json['student_id'] as String,
      answers: json['answers'] as Map<String, dynamic>? ?? {},
      score: (json['score'] as num?)?.toDouble() ?? 0,
      totalMarks: json['total_marks'] as int? ?? 0,
      timeStarted: json['time_started'] != null ? DateTime.parse(json['time_started']) : null,
      timeSubmitted: json['time_submitted'] != null ? DateTime.parse(json['time_submitted']) : null,
      isSubmitted: json['is_submitted'] as bool? ?? false,
      ipAddress: json['ip_address'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'exam_id': examId,
    'student_id': studentId,
    'answers': answers,
    'score': score,
    'total_marks': totalMarks,
    if (timeStarted != null) 'time_started': timeStarted!.toIso8601String(),
    if (timeSubmitted != null) 'time_submitted': timeSubmitted!.toIso8601String(),
    'is_submitted': isSubmitted,
    'ip_address': ipAddress,
  };
}


// =============================================================================
// 2.19 TERM COMMENTS
// =============================================================================

class TermComment {
  final String id;
  final String schoolId;
  final String studentId;
  final String sessionId;
  final String termId;
  final String classId;
  final String teacherComment;
  final String principalComment;
  final String conduct;
  final String attitude;
  final String interest;
  final String attendanceRemark;
  final DateTime createdAt;
  final DateTime updatedAt;

  TermComment({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.sessionId,
    required this.termId,
    required this.classId,
    this.teacherComment = '',
    this.principalComment = '',
    this.conduct = '',
    this.attitude = '',
    this.interest = '',
    this.attendanceRemark = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory TermComment.fromJson(Map<String, dynamic> json) {
    return TermComment(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      studentId: json['student_id'] as String,
      sessionId: json['session_id'] as String,
      termId: json['term_id'] as String,
      classId: json['class_id'] as String,
      teacherComment: json['teacher_comment'] as String? ?? '',
      principalComment: json['principal_comment'] as String? ?? '',
      conduct: json['conduct'] as String? ?? '',
      attitude: json['attitude'] as String? ?? '',
      interest: json['interest'] as String? ?? '',
      attendanceRemark: json['attendance_remark'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'student_id': studentId,
    'session_id': sessionId,
    'term_id': termId,
    'class_id': classId,
    'teacher_comment': teacherComment,
    'principal_comment': principalComment,
    'conduct': conduct,
    'attitude': attitude,
    'interest': interest,
    'attendance_remark': attendanceRemark,
  };
}


// =============================================================================
// 2.20 & 2.21 FEES
// =============================================================================

class FeeType {
  final String id;
  final String schoolId;
  final String name;
  final double amount;
  final String? description;
  final bool isActive;
  final bool isCompulsory;
  final FeeFrequency frequency;
  final DateTime createdAt;
  final DateTime updatedAt;

  FeeType({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.amount,
    this.description,
    this.isActive = true,
    this.isCompulsory = true,
    this.frequency = FeeFrequency.termly,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeeType.fromJson(Map<String, dynamic> json) {
    return FeeType(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isCompulsory: json['is_compulsory'] as bool? ?? true,
      frequency: _enumFromString(FeeFrequency.values, json['frequency']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'name': name,
    if (description != null) 'description': description,
    'is_active': isActive,
    'is_compulsory': isCompulsory,
    'frequency': _enumToString(frequency),
  };
}

class FeePayment {
  final String id;
  final String schoolId;
  final String studentId;
  final String feeTypeId;
  final String? sessionId;
  final String? termId;
  final double amountPaid;
  final String? paymentMethod;
  final DateTime paymentDate;
  final String? receiptNo;
  final String? referenceNo;
  final String? recordedBy;
  final String? remark;
  final DateTime createdAt;
  final DateTime updatedAt;

  FeePayment({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.feeTypeId,
    this.sessionId,
    this.termId,
    required this.amountPaid,
    this.paymentMethod,
    required this.paymentDate,
    this.receiptNo,
    this.referenceNo,
    this.recordedBy,
    this.remark,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeePayment.fromJson(Map<String, dynamic> json) {
    return FeePayment(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      studentId: json['student_id'] as String,
      feeTypeId: json['fee_type_id'] as String,
      sessionId: json['session_id'] as String?,
      termId: json['term_id'] as String?,
      amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['payment_method'] as String?,
      paymentDate: DateTime.parse(json['payment_date']),
      receiptNo: json['receipt_no'] as String?,
      referenceNo: json['reference_no'] as String?,
      recordedBy: json['recorded_by'] as String?,
      remark: json['remark'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'student_id': studentId,
    'fee_type_id': feeTypeId,
    if (sessionId != null) 'session_id': sessionId,
    if (termId != null) 'term_id': termId,
    'amount_paid': amountPaid,
    if (paymentMethod != null) 'payment_method': paymentMethod,
    'payment_date': paymentDate.toIso8601String().split('T').first,
    if (receiptNo != null) 'receipt_no': receiptNo,
    if (referenceNo != null) 'reference_no': referenceNo,
    if (recordedBy != null) 'recorded_by': recordedBy,
    if (remark != null) 'remark': remark,
  };
}


// =============================================================================
// 2.22 & 2.23 ASSIGNMENTS (homework)
// =============================================================================

class Assignment {
  final String id;
  final String schoolId;
  final String teacherId;
  final String subjectId;
  final String classId;
  final String sessionId;
  final String? termId;
  final String title;
  final String description;
  final DateTime dueDate;
  final int totalMarks;
  final String? attachmentUrl;
  final bool isPublished;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Assignment({
    required this.id,
    required this.schoolId,
    required this.teacherId,
    required this.subjectId,
    required this.classId,
    required this.sessionId,
    this.termId,
    required this.title,
    this.description = '',
    required this.dueDate,
    this.totalMarks = 20,
    this.attachmentUrl,
    this.isPublished = false,
    this.publishedAt,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      teacherId: json['teacher_id'] as String,
      subjectId: json['subject_id'] as String,
      classId: json['class_id'] as String,
      sessionId: json['session_id'] as String,
      termId: json['term_id'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      dueDate: DateTime.parse(json['due_date']),
      totalMarks: json['total_marks'] as int? ?? 20,
      attachmentUrl: json['attachment_url'] as String?,
      isPublished: json['is_published'] as bool? ?? false,
      publishedAt: json['published_at'] != null ? DateTime.parse(json['published_at']) : null,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'teacher_id': teacherId,
    'subject_id': subjectId,
    'class_id': classId,
    'session_id': sessionId,
    if (termId != null) 'term_id': termId,
    'title': title,
    'description': description,
    'due_date': dueDate.toIso8601String(),
    'total_marks': totalMarks,
    if (attachmentUrl != null) 'attachment_url': attachmentUrl,
    'is_published': isPublished,
  };
}

class AssignmentSubmission {
  final String id;
  final String schoolId;
  final String assignmentId;
  final String studentId;
  final String submissionText;
  final String? attachmentUrl;
  final double? score;
  final String grade;
  final String? teacherRemark;
  final DateTime? submittedAt;
  final DateTime? gradedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  AssignmentSubmission({
    required this.id,
    required this.schoolId,
    required this.assignmentId,
    required this.studentId,
    this.submissionText = '',
    this.attachmentUrl,
    this.score,
    this.grade = '',
    this.teacherRemark,
    this.submittedAt,
    this.gradedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AssignmentSubmission.fromJson(Map<String, dynamic> json) {
    return AssignmentSubmission(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      assignmentId: json['assignment_id'] as String,
      studentId: json['student_id'] as String,
      submissionText: json['submission_text'] as String? ?? '',
      attachmentUrl: json['attachment_url'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      grade: json['grade'] as String? ?? '',
      teacherRemark: json['teacher_remark'] as String?,
      submittedAt: json['submitted_at'] != null ? DateTime.parse(json['submitted_at']) : null,
      gradedAt: json['graded_at'] != null ? DateTime.parse(json['graded_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'assignment_id': assignmentId,
    'student_id': studentId,
    'submission_text': submissionText,
    if (attachmentUrl != null) 'attachment_url': attachmentUrl,
    if (score != null) 'score': score,
    'grade': grade,
    if (teacherRemark != null) 'teacher_remark': teacherRemark,
    if (submittedAt != null) 'submitted_at': submittedAt!.toIso8601String(),
    if (gradedAt != null) 'graded_at': gradedAt!.toIso8601String(),
  };
}


// =============================================================================
// 2.24 ANNOUNCEMENTS
// =============================================================================

class Announcement {
  final String id;
  final String schoolId;
  final String authorId;
  final AuthorType authorType;
  final String title;
  final String content;
  final AnnouncementAudience targetAudience;
  final String? classId;
  final String? attachmentUrl;
  final bool isPinned;
  final bool isPublished;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Announcement({
    required this.id,
    required this.schoolId,
    required this.authorId,
    required this.authorType,
    required this.title,
    required this.content,
    this.targetAudience = AnnouncementAudience.all,
    this.classId,
    this.attachmentUrl,
    this.isPinned = false,
    this.isPublished = true,
    this.publishedAt,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      authorId: json['author_id'] as String,
      authorType: _enumFromString(AuthorType.values, json['author_type']),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      targetAudience: _enumFromString(AnnouncementAudience.values, json['target_audience']),
      classId: json['class_id'] as String?,
      attachmentUrl: json['attachment_url'] as String?,
      isPinned: json['is_pinned'] as bool? ?? false,
      isPublished: json['is_published'] as bool? ?? true,
      publishedAt: json['published_at'] != null ? DateTime.parse(json['published_at']) : null,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'author_id': authorId,
    'author_type': _enumToString(authorType),
    'title': title,
    'content': content,
    'target_audience': _enumToString(targetAudience),
    if (classId != null) 'class_id': classId,
    if (attachmentUrl != null) 'attachment_url': attachmentUrl,
    'is_pinned': isPinned,
    'is_published': isPublished,
  };
}


// =============================================================================
// 2.25 COMPLAINTS
// =============================================================================

class Complaint {
  final String id;
  final String schoolId;
  final String studentId;
  final String subject;
  final ComplaintCategory category;
  final String description;
  final ComplaintStatus status;
  final ComplaintPriority priority;
  final String? attachmentUrl;
  final String? resolvedBy;
  final String resolutionNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  Complaint({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.subject,
    this.category = ComplaintCategory.general,
    required this.description,
    this.status = ComplaintStatus.open,
    this.priority = ComplaintPriority.normal,
    this.attachmentUrl,
    this.resolvedBy,
    this.resolutionNote = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      studentId: json['student_id'] as String,
      subject: json['subject'] as String? ?? '',
      category: _enumFromString(ComplaintCategory.values, json['category']),
      description: json['description'] as String? ?? '',
      status: _enumFromString(ComplaintStatus.values, json['status']),
      priority: _enumFromString(ComplaintPriority.values, json['priority']),
      attachmentUrl: json['attachment_url'] as String?,
      resolvedBy: json['resolved_by'] as String?,
      resolutionNote: json['resolution_note'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'student_id': studentId,
    'subject': subject,
    'category': _enumToString(category),
    'description': description,
    'status': _enumToString(status),
    'priority': _enumToString(priority),
    if (attachmentUrl != null) 'attachment_url': attachmentUrl,
    if (resolvedBy != null) 'resolved_by': resolvedBy,
    'resolution_note': resolutionNote,
  };
}


// =============================================================================
// 2.26 SCHOOL ADMIN INVITES
// =============================================================================

class SchoolAdminInvite {
  final String id;
  final String schoolId;
  final String email;
  final String token;
  final AdminRole role;
  final String? invitedBy;
  final DateTime? acceptedAt;
  final DateTime expiresAt;
  final bool isUsed;
  final DateTime createdAt;
  final DateTime updatedAt;

  SchoolAdminInvite({
    required this.id,
    required this.schoolId,
    required this.email,
    required this.token,
    this.role = AdminRole.admin,
    this.invitedBy,
    this.acceptedAt,
    required this.expiresAt,
    this.isUsed = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SchoolAdminInvite.fromJson(Map<String, dynamic> json) {
    return SchoolAdminInvite(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      email: json['email'] as String? ?? '',
      token: json['token'] as String? ?? '',
      role: _enumFromString(AdminRole.values, json['role']),
      invitedBy: json['invited_by'] as String?,
      acceptedAt: json['accepted_at'] != null ? DateTime.parse(json['accepted_at']) : null,
      expiresAt: DateTime.parse(json['expires_at']),
      isUsed: json['is_used'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'email': email,
    'token': token,
    'role': _enumToString(role),
    if (invitedBy != null) 'invited_by': invitedBy,
    'expires_at': expiresAt.toIso8601String(),
  };
}


// =============================================================================
// 2.27 PASSWORD RESET TOKENS
// =============================================================================

class PasswordResetToken {
  final String id;
  final String? schoolId;
  final String userId;
  final UserType userType;
  final String tokenHash;
  final DateTime expiresAt;
  final bool isUsed;
  final DateTime createdAt;

  PasswordResetToken({
    required this.id,
    this.schoolId,
    required this.userId,
    required this.userType,
    required this.tokenHash,
    required this.expiresAt,
    this.isUsed = false,
    required this.createdAt,
  });

  factory PasswordResetToken.fromJson(Map<String, dynamic> json) {
    return PasswordResetToken(
      id: json['id'] as String,
      schoolId: json['school_id'] as String?,
      userId: json['user_id'] as String,
      userType: _enumFromString(UserType.values, json['user_type']),
      tokenHash: json['token_hash'] as String? ?? '',
      expiresAt: DateTime.parse(json['expires_at']),
      isUsed: json['is_used'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}


// =============================================================================
// 2.28 PUSH NOTIFICATION TOKENS
// =============================================================================

class PushNotificationToken {
  final String id;
  final String? schoolId;
  final String userId;
  final UserType userType;
  final String deviceToken;
  final DeviceType? deviceType;
  final String appVersion;
  final bool isActive;
  final DateTime? lastUsedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  PushNotificationToken({
    required this.id,
    this.schoolId,
    required this.userId,
    required this.userType,
    required this.deviceToken,
    this.deviceType,
    this.appVersion = '',
    this.isActive = true,
    this.lastUsedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PushNotificationToken.fromJson(Map<String, dynamic> json) {
    return PushNotificationToken(
      id: json['id'] as String,
      schoolId: json['school_id'] as String?,
      userId: json['user_id'] as String,
      userType: _enumFromString(UserType.values, json['user_type']),
      deviceToken: json['device_token'] as String? ?? '',
      deviceType: _enumFromString(DeviceType.values, json['device_type']),
      appVersion: json['app_version'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      lastUsedAt: json['last_used_at'] != null ? DateTime.parse(json['last_used_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    if (schoolId != null) 'school_id': schoolId,
    'user_id': userId,
    'user_type': _enumToString(userType),
    'device_token': deviceToken,
    if (deviceType != null) 'device_type': _enumToString(deviceType),
    'app_version': appVersion,
    'is_active': isActive,
  };
}


// =============================================================================
// 2.29 & 2.30 LOGIN HISTORY & AUDIT LOGS
// =============================================================================

class LoginHistory {
  final String id;
  final String schoolId;
  final String? userId;
  final UserType userType;
  final String? username;
  final String ipAddress;
  final String userAgent;
  final bool isSuccessful;
  final String failureReason;
  final DateTime createdAt;

  LoginHistory({
    required this.id,
    required this.schoolId,
    this.userId,
    required this.userType,
    this.username,
    this.ipAddress = '',
    this.userAgent = '',
    this.isSuccessful = true,
    this.failureReason = '',
    required this.createdAt,
  });

  factory LoginHistory.fromJson(Map<String, dynamic> json) {
    return LoginHistory(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      userId: json['user_id'] as String?,
      userType: _enumFromString(UserType.values, json['user_type']),
      username: json['username'] as String?,
      ipAddress: json['ip_address'] as String? ?? '',
      userAgent: json['user_agent'] as String? ?? '',
      isSuccessful: json['is_successful'] as bool? ?? true,
      failureReason: json['failure_reason'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    if (userId != null) 'user_id': userId,
    'user_type': _enumToString(userType),
    if (username != null) 'username': username,
    'ip_address': ipAddress,
    'user_agent': userAgent,
    'is_successful': isSuccessful,
    'failure_reason': failureReason,
  };
}

class AuditLog {
  final String id;
  final String schoolId;
  final String? userId;
  final UserType? userType;
  final String action;
  final String? tableName;
  final String? recordId;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final String ipAddress;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    required this.schoolId,
    this.userId,
    this.userType,
    required this.action,
    this.tableName,
    this.recordId,
    this.oldData,
    this.newData,
    this.ipAddress = '',
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      userId: json['user_id'] as String?,
      userType: _enumFromString(UserType.values, json['user_type']),
      action: json['action'] as String? ?? '',
      tableName: json['table_name'] as String?,
      recordId: json['record_id'] as String?,
      oldData: json['old_data'] as Map<String, dynamic>?,
      newData: json['new_data'] as Map<String, dynamic>?,
      ipAddress: json['ip_address'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}


// =============================================================================
// JOIN/VIEW MODEL: StudentScore
// =============================================================================

class StudentScore {
  final String studentId;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String? admissionNo;
  final String? passportUrl;
  final Map<String, dynamic> scoresJson;
  final double total;
  final String grade;
  final int? position;
  final int? positionOutOf;

  StudentScore({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.admissionNo,
    this.passportUrl,
    this.scoresJson = const {},
    this.total = 0,
    this.grade = '',
    this.position,
    this.positionOutOf,
  });

  String get fullName {
    final parts = [firstName, middleName, lastName].where((s) => s != null && s.isNotEmpty);
    return parts.join(' ');
  }

  factory StudentScore.fromJson(Map<String, dynamic> json) {
    final student = json['students'] as Map<String, dynamic>?;
    
    return StudentScore(
      studentId: json['student_id'] as String,
      firstName: student?['first_name'] as String? ?? json['first_name'] as String? ?? '',
      lastName: student?['last_name'] as String? ?? json['last_name'] as String? ?? '',
      middleName: student?['middle_name'] as String? ?? json['middle_name'] as String?,
      admissionNo: student?['admission_no'] as String? ?? json['admission_no'] as String?,
      passportUrl: student?['passport_url'] as String? ?? json['passport_url'] as String?,
      scoresJson: json['scores_json'] as Map<String, dynamic>? ?? {},
      total: (json['total'] as num?)?.toDouble() ?? 0,
      grade: json['grade'] as String? ?? '',
      position: json['position'] as int?,
      positionOutOf: json['position_out_of'] as int?,
    );
  }
}
