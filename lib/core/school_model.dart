/// Immutable data model for a School entity.
/// Represents a row from the `schools` table + joined `school_settings`.
///
/// MASTER PLAN: This model carries ALL school identity fields needed
/// for UI display, export, and print. Zero platform branding.
/// Every printed document uses exportIdentity — never shows SmartEdu.

class School {
  // =========================================================
  // CORE FIELDS (from schools table)
  // =========================================================

  final String id;
  final String name;
  final String? location;
  final String? logoUrl;
  final String? whatsapp;
  final String schoolType;
  final bool isActive;
  final DateTime? deactivatedAt;
  final String? inactiveReason; // [V4] from schema
  final DateTime createdAt;
  final DateTime updatedAt;

  // =========================================================
  // LEGACY ADMIN CREDENTIALS (DEPRECATED — use school_admins table)
  // Kept for backward compatibility during migration.
  // =========================================================

  final String? adminUsername;
  final String? adminPassword;

  // =========================================================
  // BRANDING & IDENTITY (for print/export isolation)
  // These fields ensure every printed document shows ONLY
  // the school's own branding — never the platform's.
  // =========================================================

  final String motto;
  final String address;
  final String officialPhone;
  final String officialEmail;
  final String website;
  final String? principalSignatureUrl;
  final String? schoolStampUrl;

  // =========================================================
  // SUBSCRIPTION & BILLING
  // =========================================================

  final String subscriptionPlan;
  final String subscriptionStatus;
  final DateTime? trialEndsAt;
  final DateTime? subscriptionExpiresAt;
  final int maxStudents;
  final int maxTeachers;

  // [ADD] Payment status — from login RPC, not stored in DB
  final bool hasPaidCurrentTerm;

  // =========================================================
  // GLOBAL SUPPORT (country, state, city, timezone)
  // =========================================================

  final String country;
  final String state;
  final String city;
  final String timezone;

  // =========================================================
  // COUNT FIELDS (from aggregate queries, not in DB)
  // =========================================================

  final int studentCount;
  final int teacherCount;
  final int classCount;

  // =========================================================
  // SETTINGS FIELDS (joined from school_settings)
  // =========================================================

  final String examTemplate;
  final bool showPosition;
  final bool showGradeOnly;
  final String dateFormat;
  final String currentSession;
  final String currentTerm;
  final String principalName;
  final int subjectMaxScore;

  // Result sheet layout settings
  final String resultOrientation;
  final String resultPaperSize;
  final String logoPosition;
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

  // Academic settings
  final bool autoComputePositions;
  final double passMark;
  final double promoteThreshold;

  // [V4] Cumulative session average display
  final bool showCumulative;

  // [V4] Locale & currency for international schools
  final String locale;
  final String currencyCode;
  final String currencySymbol;

  // [V4] Branding colors for school-independent printing
  final String primaryColor;
  final String secondaryColor;
  final String accentColor;
  final String textColor;
  final String headerBgColor;
  final String headerTextColor;
  final String fontFamily;
  final String resultWatermarkText;

  // =========================================================
  // CONSTRUCTOR
  // =========================================================

  School({
    required this.id,
    required this.name,
    this.location,
    this.logoUrl,
    this.whatsapp,
    this.schoolType = 'secondary',
    this.isActive = true,
    this.deactivatedAt,
    this.inactiveReason,
    required this.createdAt,
    required this.updatedAt,
    this.adminUsername,
    this.adminPassword,
    this.motto = '',
    this.address = '',
    this.officialPhone = '',
    this.officialEmail = '',
    this.website = '',
    this.principalSignatureUrl,
    this.schoolStampUrl,
    this.subscriptionPlan = 'free',
    this.subscriptionStatus = 'trial',
    this.trialEndsAt,
    this.subscriptionExpiresAt,
    this.maxStudents = 100,
    this.maxTeachers = 20,
    this.hasPaidCurrentTerm = false,
    this.country = '',
    this.state = '',
    this.city = '',
    this.timezone = 'UTC',
    this.studentCount = 0,
    this.teacherCount = 0,
    this.classCount = 0,
    this.examTemplate = 'WAEC',
    this.showPosition = true,
    this.showGradeOnly = false,
    this.dateFormat = 'dd/MM/yyyy',
    this.currentSession = '',
    this.currentTerm = '',
    this.principalName = '',
    this.subjectMaxScore = 100,
    this.resultOrientation = 'portrait',
    this.resultPaperSize = 'A4',
    this.logoPosition = 'left',
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
    this.showCumulative = false,
    this.locale = 'en',
    this.currencyCode = 'NGN',
    this.currencySymbol = '₦',
    this.primaryColor = '#1a237e',
    this.secondaryColor = '#ffffff',
    this.accentColor = '#ff6f00',
    this.textColor = '#212121',
    this.headerBgColor = '#1a237e',
    this.headerTextColor = '#ffffff',
    this.fontFamily = 'default',
    this.resultWatermarkText = '',
  });

  // =========================================================
  // FROM MAP — handles both plain school rows and joined data
  // =========================================================

  factory School.fromMap(Map<String, dynamic> map) {
    // Extract nested school_settings if joined via Supabase
    final settings = map['school_settings'] as Map<String, dynamic>?;

    return School(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      location: map['location'] as String?,
      logoUrl: map['logo_url'] as String?,
      whatsapp: map['whatsapp'] as String?,
      schoolType: map['school_type'] as String? ?? 'secondary',
      isActive: map['is_active'] as bool? ?? true,
      deactivatedAt: map['deactivated_at'] != null ? DateTime.tryParse(map['deactivated_at']) : null,
      inactiveReason: map['inactive_reason'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
      adminUsername: map['admin_username'] as String?,
      adminPassword: map['admin_password'] as String?,

      // Branding fields
      motto: map['motto'] as String? ?? '',
      address: map['address'] as String? ?? '',
      officialPhone: map['official_phone'] as String? ?? '',
      officialEmail: map['official_email'] as String? ?? '',
      website: map['website'] as String? ?? '',
      principalSignatureUrl: map['principal_signature_url'] as String?,
      schoolStampUrl: map['school_stamp_url'] as String?,

      // Subscription fields
      subscriptionPlan: map['subscription_plan'] as String? ?? 'free',
      subscriptionStatus: map['subscription_status'] as String? ?? 'trial',
      trialEndsAt: map['trial_ends_at'] != null ? DateTime.tryParse(map['trial_ends_at']) : null,
      subscriptionExpiresAt: map['subscription_expires_at'] != null ? DateTime.tryParse(map['subscription_expires_at']) : null,
      maxStudents: map['max_students'] as int? ?? 100,
      maxTeachers: map['max_teachers'] as int? ?? 20,
      hasPaidCurrentTerm: map['has_paid_current_term'] as bool? ?? false,

      // Global fields
      country: map['country'] as String? ?? '',
      state: map['state'] as String? ?? '',
      city: map['city'] as String? ?? '',
      timezone: map['timezone'] as String? ?? settings?['timezone'] as String? ?? 'UTC',

      // Count fields (from aggregate queries)
      studentCount: map['student_count'] as int? ?? 0,
      teacherCount: map['teacher_count'] as int? ?? 0,
      classCount: map['class_count'] as int? ?? 0,

      // Settings fields (from join or direct)
      examTemplate: map['exam_template'] as String? ?? settings?['exam_template'] as String? ?? 'WAEC',
      showPosition: map['show_position'] as bool? ?? settings?['show_position'] as bool? ?? true,
      showGradeOnly: map['show_grade_only'] as bool? ?? settings?['show_grade_only'] as bool? ?? false,
      dateFormat: map['date_format'] as String? ?? settings?['date_format'] as String? ?? 'dd/MM/yyyy',
      currentSession: map['current_session'] as String? ?? settings?['current_session'] as String? ?? '',
      currentTerm: map['current_term'] as String? ?? settings?['current_term'] as String? ?? '',
      principalName: map['principal_name'] as String? ?? settings?['principal_name'] as String? ?? '',
      subjectMaxScore: map['subject_max_score'] as int? ?? settings?['subject_max_score'] as int? ?? 100,

      // Result layout settings
      resultOrientation: map['result_orientation'] as String? ?? settings?['result_orientation'] as String? ?? 'portrait',
      resultPaperSize: map['result_paper_size'] as String? ?? settings?['result_paper_size'] as String? ?? 'A4',
      logoPosition: map['logo_position'] as String? ?? settings?['logo_position'] as String? ?? 'left',
      showStudentPassportOnResult: map['show_student_passport_on_result'] as bool? ?? settings?['show_student_passport_on_result'] as bool? ?? true,
      showSchoolStamp: map['show_school_stamp'] as bool? ?? settings?['show_school_stamp'] as bool? ?? false,
      showBarcode: map['show_barcode'] as bool? ?? settings?['show_barcode'] as bool? ?? false,
      resultHeaderText: map['result_header_text'] as String? ?? settings?['result_header_text'] as String? ?? '',
      resultFooterText: map['result_footer_text'] as String? ?? settings?['result_footer_text'] as String? ?? '',
      showTeacherComment: map['show_teacher_comment'] as bool? ?? settings?['show_teacher_comment'] as bool? ?? true,
      showPrincipalComment: map['show_principal_comment'] as bool? ?? settings?['show_principal_comment'] as bool? ?? true,
      showConduct: map['show_conduct'] as bool? ?? settings?['show_conduct'] as bool? ?? true,
      showAttendanceSummary: map['show_attendance_summary'] as bool? ?? settings?['show_attendance_summary'] as bool? ?? true,
      showGradingKey: map['show_grading_key'] as bool? ?? settings?['show_grading_key'] as bool? ?? true,

      // Academic settings
      autoComputePositions: map['auto_compute_positions'] as bool? ?? settings?['auto_compute_positions'] as bool? ?? true,
      passMark: (map['pass_mark'] as num?)?.toDouble() ?? (settings?['pass_mark'] as num?)?.toDouble() ?? 40,
      promoteThreshold: (map['promote_threshold'] as num?)?.toDouble() ?? (settings?['promote_threshold'] as num?)?.toDouble() ?? 50,

      // [V4] Cumulative
      showCumulative: map['show_cumulative'] as bool? ?? settings?['show_cumulative'] as bool? ?? false,

      // [V4] Locale & currency
      locale: map['locale'] as String? ?? settings?['locale'] as String? ?? 'en',
      currencyCode: map['currency_code'] as String? ?? settings?['currency_code'] as String? ?? 'NGN',
      currencySymbol: map['currency_symbol'] as String? ?? settings?['currency_symbol'] as String? ?? '₦',

      // [V4] Branding colors
      primaryColor: map['primary_color'] as String? ?? settings?['primary_color'] as String? ?? '#1a237e',
      secondaryColor: map['secondary_color'] as String? ?? settings?['secondary_color'] as String? ?? '#ffffff',
      accentColor: map['accent_color'] as String? ?? settings?['accent_color'] as String? ?? '#ff6f00',
      textColor: map['text_color'] as String? ?? settings?['text_color'] as String? ?? '#212121',
      headerBgColor: map['header_bg_color'] as String? ?? settings?['header_bg_color'] as String? ?? '#1a237e',
      headerTextColor: map['header_text_color'] as String? ?? settings?['header_text_color'] as String? ?? '#ffffff',
      fontFamily: map['font_family'] as String? ?? settings?['font_family'] as String? ?? 'default',
      resultWatermarkText: map['result_watermark_text'] as String? ?? settings?['result_watermark_text'] as String? ?? '',
    );
  }

  // =========================================================
  // COPY WITH
  // =========================================================

  School copyWith({
    String? id,
    String? name,
    String? location,
    String? logoUrl,
    String? whatsapp,
    String? schoolType,
    bool? isActive,
    DateTime? deactivatedAt,
    String? inactiveReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? adminUsername,
    String? adminPassword,
    String? motto,
    String? address,
    String? officialPhone,
    String? officialEmail,
    String? website,
    String? principalSignatureUrl,
    String? schoolStampUrl,
    String? subscriptionPlan,
    String? subscriptionStatus,
    DateTime? trialEndsAt,
    DateTime? subscriptionExpiresAt,
    int? maxStudents,
    int? maxTeachers,
    bool? hasPaidCurrentTerm,
    String? country,
    String? state,
    String? city,
    String? timezone,
    int? studentCount,
    int? teacherCount,
    int? classCount,
    String? examTemplate,
    bool? showPosition,
    bool? showGradeOnly,
    String? dateFormat,
    String? currentSession,
    String? currentTerm,
    String? principalName,
    int? subjectMaxScore,
    String? resultOrientation,
    String? resultPaperSize,
    String? logoPosition,
    bool? showStudentPassportOnResult,
    bool? showSchoolStamp,
    bool? showBarcode,
    String? resultHeaderText,
    String? resultFooterText,
    bool? showTeacherComment,
    bool? showPrincipalComment,
    bool? showConduct,
    bool? showAttendanceSummary,
    bool? showGradingKey,
    bool? autoComputePositions,
    double? passMark,
    double? promoteThreshold,
    bool? showCumulative,
    String? locale,
    String? currencyCode,
    String? currencySymbol,
    String? primaryColor,
    String? secondaryColor,
    String? accentColor,
    String? textColor,
    String? headerBgColor,
    String? headerTextColor,
    String? fontFamily,
    String? resultWatermarkText,
  }) {
    return School(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      logoUrl: logoUrl ?? this.logoUrl,
      whatsapp: whatsapp ?? this.whatsapp,
      schoolType: schoolType ?? this.schoolType,
      isActive: isActive ?? this.isActive,
      deactivatedAt: deactivatedAt ?? this.deactivatedAt,
      inactiveReason: inactiveReason ?? this.inactiveReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adminUsername: adminUsername ?? this.adminUsername,
      adminPassword: adminPassword ?? this.adminPassword,
      motto: motto ?? this.motto,
      address: address ?? this.address,
      officialPhone: officialPhone ?? this.officialPhone,
      officialEmail: officialEmail ?? this.officialEmail,
      website: website ?? this.website,
      principalSignatureUrl: principalSignatureUrl ?? this.principalSignatureUrl,
      schoolStampUrl: schoolStampUrl ?? this.schoolStampUrl,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      maxStudents: maxStudents ?? this.maxStudents,
      maxTeachers: maxTeachers ?? this.maxTeachers,
      hasPaidCurrentTerm: hasPaidCurrentTerm ?? this.hasPaidCurrentTerm,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      timezone: timezone ?? this.timezone,
      studentCount: studentCount ?? this.studentCount,
      teacherCount: teacherCount ?? this.teacherCount,
      classCount: classCount ?? this.classCount,
      examTemplate: examTemplate ?? this.examTemplate,
      showPosition: showPosition ?? this.showPosition,
      showGradeOnly: showGradeOnly ?? this.showGradeOnly,
      dateFormat: dateFormat ?? this.dateFormat,
      currentSession: currentSession ?? this.currentSession,
      currentTerm: currentTerm ?? this.currentTerm,
      principalName: principalName ?? this.principalName,
      subjectMaxScore: subjectMaxScore ?? this.subjectMaxScore,
      resultOrientation: resultOrientation ?? this.resultOrientation,
      resultPaperSize: resultPaperSize ?? this.resultPaperSize,
      logoPosition: logoPosition ?? this.logoPosition,
      showStudentPassportOnResult: showStudentPassportOnResult ?? this.showStudentPassportOnResult,
      showSchoolStamp: showSchoolStamp ?? this.showSchoolStamp,
      showBarcode: showBarcode ?? this.showBarcode,
      resultHeaderText: resultHeaderText ?? this.resultHeaderText,
      resultFooterText: resultFooterText ?? this.resultFooterText,
      showTeacherComment: showTeacherComment ?? this.showTeacherComment,
      showPrincipalComment: showPrincipalComment ?? this.showPrincipalComment,
      showConduct: showConduct ?? this.showConduct,
      showAttendanceSummary: showAttendanceSummary ?? this.showAttendanceSummary,
      showGradingKey: showGradingKey ?? this.showGradingKey,
      autoComputePositions: autoComputePositions ?? this.autoComputePositions,
      passMark: passMark ?? this.passMark,
      promoteThreshold: promoteThreshold ?? this.promoteThreshold,
      showCumulative: showCumulative ?? this.showCumulative,
      locale: locale ?? this.locale,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      textColor: textColor ?? this.textColor,
      headerBgColor: headerBgColor ?? this.headerBgColor,
      headerTextColor: headerTextColor ?? this.headerTextColor,
      fontFamily: fontFamily ?? this.fontFamily,
      resultWatermarkText: resultWatermarkText ?? this.resultWatermarkText,
    );
  }

  // =========================================================
  // TO MAP — for DB inserts/updates (schools table only)
  // =========================================================

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (location != null) 'location': location,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (whatsapp != null) 'whatsapp': whatsapp,
      'school_type': schoolType,
      'is_active': isActive,
      if (adminUsername != null) 'admin_username': adminUsername,
      if (adminPassword != null) 'admin_password': adminPassword,
      'motto': motto,
      'address': address,
      'official_phone': officialPhone,
      'official_email': officialEmail,
      'website': website,
      'subscription_plan': subscriptionPlan,
      'subscription_status': subscriptionStatus,
      'max_students': maxStudents,
      'max_teachers': maxTeachers,
    };
  }

  /// To map for school_settings table updates.
  Map<String, dynamic> toSettingsMap() {
    return {
      'exam_template': examTemplate,
      'show_position': showPosition,
      'show_grade_only': showGradeOnly,
      'date_format': dateFormat,
      'current_session': currentSession,
      'current_term': currentTerm,
      'principal_name': principalName,
      'subject_max_score': subjectMaxScore,
      'result_orientation': resultOrientation,
      'result_paper_size': resultPaperSize,
      'logo_position': logoPosition,
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
      'show_cumulative': showCumulative,
      'locale': locale,
      'currency_code': currencyCode,
      'currency_symbol': currencySymbol,
      'primary_color': primaryColor,
      'secondary_color': secondaryColor,
      'accent_color': accentColor,
      'text_color': textColor,
      'header_bg_color': headerBgColor,
      'header_text_color': headerTextColor,
      'font_family': fontFamily,
      'result_watermark_text': resultWatermarkText,
      if (timezone.isNotEmpty) 'timezone': timezone,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // =========================================================
  // EXPORT IDENTITY MAP
  // Used by DataExport and print services.
  // This is what goes on every printed document — school ONLY.
  // NEVER includes any platform (SmartEdu) branding.
  // =========================================================

  Map<String, dynamic> get exportIdentity {
    return {
      'id': id,
      'name': name,
      'logo_url': logoUrl ?? '',
      'address': fullAddress,
      'location': safeLocation,
      'city': city,
      'state': state,
      'country': country,
      'phone': officialPhone.isNotEmpty ? officialPhone : safeWhatsApp,
      'whatsapp': safeWhatsApp,
      'email': officialEmail,
      'website': website,
      'motto': motto,
      'principal_name': principalName,
      'principal_signature_url': principalSignatureUrl ?? '',
      'school_stamp_url': schoolStampUrl ?? '',
      'exam_template': examTemplate,
      'school_type': schoolType,
      'school_type_label': schoolTypeLabel,
      'formatted_type': formattedType,
      'timezone': timezone,
      'date_format': dateFormat,
      'subject_max_score': subjectMaxScore,
      'show_position': showPosition,
      'result_orientation': resultOrientation,
      'result_paper_size': resultPaperSize,
      'logo_position': logoPosition,
      'show_student_passport': showStudentPassportOnResult,
      'show_school_stamp': showSchoolStamp,
      'show_teacher_comment': showTeacherComment,
      'show_principal_comment': showPrincipalComment,
      'show_conduct': showConduct,
      'show_attendance_summary': showAttendanceSummary,
      'show_grading_key': showGradingKey,
      'show_cumulative': showCumulative,
      'result_header_text': resultHeaderText,
      'result_footer_text': resultFooterText,
      'locale': locale,
      'currency_code': currencyCode,
      'currency_symbol': currencySymbol,
      'primary_color': primaryColor,
      'secondary_color': secondaryColor,
      'accent_color': accentColor,
      'text_color': textColor,
      'header_bg_color': headerBgColor,
      'header_text_color': headerTextColor,
      'font_family': fontFamily,
      'result_watermark_text': resultWatermarkText,
    };
  }

  // =========================================================
  // NULL-SAFE CONVENIENCE GETTERS
  // UI files call these instead of manual null checks.
  // Eliminates "String? can't be assigned to String" errors.
  // =========================================================

  /// Safe location — never null for UI display.
  String get safeLocation => location ?? '';

  /// Safe logo URL — never null for Image widgets.
  String get safeLogoUrl => logoUrl ?? '';

  /// Safe whatsapp — never null for display/text.
  String get safeWhatsApp => whatsapp ?? '';

  /// Safe admin username — never null for display.
  String get safeAdminUsername => adminUsername ?? '';

  /// Safe admin password — never null for display.
  String get safeAdminPassword => adminPassword ?? '';

  // =========================================================
  // DISPLAY GETTERS
  // =========================================================

  String get schoolTypeLabel {
    switch (schoolType) {
      case 'primary':
        return 'Primary';
      case 'secondary':
        return 'Secondary';
      case 'tertiary':
        return 'Tertiary';
      case 'vocational':
        return 'Vocational';
      case 'montessori':
        return 'Montessori';
      case 'creche':
        return 'Creche';
      case 'special_needs':
        return 'Special Needs';
      default:
        return 'Secondary';
    }
  }

  String get formattedType {
    switch (schoolType) {
      case 'primary':
        return 'Primary School';
      case 'secondary':
        return 'Secondary School';
      case 'tertiary':
        return 'Tertiary Institution';
      case 'vocational':
        return 'Vocational School';
      case 'montessori':
        return 'Montessori School';
      case 'creche':
        return 'Creche';
      case 'special_needs':
        return 'Special Needs School';
      default:
        return schoolType.isNotEmpty ? schoolType : 'Secondary School';
    }
  }

  String get statusBadge {
    if (!isActive) return 'inactive';
    if (subscriptionStatus == 'expired') return 'expired';
    if (subscriptionStatus == 'trial') return 'trial';
    return 'active';
  }

  String get initials {
    if (name.isEmpty) return 'S';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length > 2 ? 2 : name.length).toUpperCase();
  }

  // =========================================================
  // ADDRESS HELPERS
  // =========================================================

  /// Full formatted address for print/export.
  /// [FIX] Uses safeLocation instead of location! to avoid
  /// "field promotion unavailable" error on public nullable fields.
  String get fullAddress {
    if (address.isNotEmpty) return address;
    final parts = <String>[
      if (safeLocation.isNotEmpty) safeLocation,
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (country.isNotEmpty) country,
    ];
    return parts.isEmpty ? 'Address not set' : parts.join(', ');
  }

  /// Short address for compact displays.
  String get shortAddress {
    if (address.isNotEmpty) {
      return address.split(',').first.trim();
    }
    if (safeLocation.isNotEmpty) return safeLocation;
    final parts = <String>[
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
    ];
    return parts.isEmpty ? '' : parts.join(', ');
  }

  /// Primary phone display: official_phone first, then whatsapp.
  String get displayPhone {
    if (officialPhone.isNotEmpty) return officialPhone;
    return safeWhatsApp.isNotEmpty ? safeWhatsApp : 'Not set';
  }

  /// WhatsApp display.
  String get displayWhatsApp {
    return safeWhatsApp.isNotEmpty ? safeWhatsApp : 'Not set';
  }

  /// Email display.
  String get displayEmail {
    return officialEmail.isNotEmpty ? officialEmail : 'Not set';
  }

  // =========================================================
  // BRANDING HELPERS
  // =========================================================

  bool get hasLogo => logoUrl != null && logoUrl!.isNotEmpty;

  bool get hasCompleteBranding {
    return name.isNotEmpty && hasLogo && fullAddress != 'Address not set';
  }

  bool get hasMotto => motto.isNotEmpty;

  bool get hasPrincipalSignature => principalSignatureUrl != null && principalSignatureUrl!.isNotEmpty;

  bool get hasStamp => schoolStampUrl != null && schoolStampUrl!.isNotEmpty;

  // =========================================================
  // SUBSCRIPTION HELPERS
  // =========================================================

  bool get isSubscriptionActive {
    if (!isActive) return false;
    if (subscriptionStatus == 'expired') return false;
    if (subscriptionStatus == 'cancelled') return false;
    return true;
  }

  bool get isOnTrial => subscriptionStatus == 'trial';

  bool get isTrialExpired {
    if (subscriptionStatus != 'trial' || trialEndsAt == null) return false;
    return trialEndsAt!.isBefore(DateTime.now());
  }

  int? get trialDaysRemaining {
    if (trialEndsAt == null) return null;
    return trialEndsAt!.difference(DateTime.now()).inDays;
  }

  int? get subscriptionDaysRemaining {
    if (subscriptionExpiresAt == null) return null;
    return subscriptionExpiresAt!.difference(DateTime.now()).inDays;
  }

  bool get isOverStudentLimit => studentCount > maxStudents;

  bool get isOverTeacherLimit => teacherCount > maxTeachers;

  String get subscriptionStatusLabel {
    if (!isActive) return 'Deactivated';
    if (subscriptionStatus == 'expired') return 'Expired';
    if (subscriptionStatus == 'cancelled') return 'Cancelled';
    if (subscriptionStatus == 'trial') {
      if (isTrialExpired) return 'Trial Expired';
      final days = trialDaysRemaining;
      if (days != null && days <= 7) return 'Trial ($days days left)';
      return 'Free Trial';
    }
    if (subscriptionStatus == 'active') {
      final days = subscriptionDaysRemaining;
      if (days != null && days <= 7) return 'Expiring Soon ($days days)';
      return 'Active';
    }
    return subscriptionStatus;
  }

  String get subscriptionPlanLabel {
    switch (subscriptionPlan) {
      case 'free':
        return 'Free';
      case 'basic':
        return 'Basic';
      case 'premium':
        return 'Premium';
      case 'enterprise':
        return 'Enterprise';
      default:
        return subscriptionPlan.isNotEmpty
            ? subscriptionPlan[0].toUpperCase() + subscriptionPlan.substring(1)
            : 'Free';
    }
  }

  String? get subscriptionWarning {
    if (subscriptionStatus == 'expired') {
      return 'Your subscription has expired. Please renew.';
    }
    if (subscriptionStatus == 'trial' && isTrialExpired) {
      return 'Your free trial has ended. Please upgrade.';
    }
    if (subscriptionStatus == 'trial') {
      final days = trialDaysRemaining;
      if (days != null && days <= 7) {
        return 'Trial ends in $days day(s). Upgrade now.';
      }
    }
    if (subscriptionStatus == 'active') {
      final days = subscriptionDaysRemaining;
      if (days != null && days <= 7 && days > 0) {
        return 'Subscription expires in $days day(s).';
      }
    }
    return null;
  }

  // =========================================================
  // GLOBAL / REGION HELPERS
  // =========================================================

  bool get hasCountry => country.isNotEmpty;

  String get displayCountry => country.isNotEmpty ? country : 'Not specified';

  String get displayTimezone => timezone.isNotEmpty ? timezone : 'UTC';

  // =========================================================
  // VALIDATION
  // =========================================================

  List<String> validate() {
    final errors = <String>[];

    if (name.trim().isEmpty) errors.add('School name is required');
    if (name.trim().length < 2) errors.add('School name must be at least 2 characters');
    if (location == null || location!.trim().isEmpty) errors.add('Location is required');

    if (officialEmail.isNotEmpty && !_isValidEmail(officialEmail)) {
      errors.add('Invalid email address');
    }

    if (officialPhone.isNotEmpty && !_isValidPhone(officialPhone)) {
      errors.add('Invalid phone number');
    }

    if (whatsapp != null && whatsapp!.isNotEmpty && !_isValidPhone(whatsapp!)) {
      errors.add('Invalid WhatsApp number');
    }

    if (website.isNotEmpty && !_isValidUrl(website)) {
      errors.add('Invalid website URL');
    }

    return errors;
  }

  List<String> validateCredentials() {
    final errors = <String>[];

    if (adminUsername == null || adminUsername!.trim().isEmpty) {
      errors.add('Admin username is required');
    } else if (adminUsername!.trim().length < 3) {
      errors.add('Admin username must be at least 3 characters');
    } else if (adminUsername!.contains(' ')) {
      errors.add('Admin username cannot contain spaces');
    }

    if (adminPassword == null || adminPassword!.trim().isEmpty) {
      errors.add('Admin password is required');
    } else if (adminPassword!.trim().length < 6) {
      errors.add('Admin password must be at least 6 characters');
    }

    return errors;
  }

  // =========================================================
  // SERIALIZATION
  // =========================================================

  String toJson() {
    return '{"id":"$id",'
        '"name":"${_escape(name)}",'
        '"location":"${_escape(safeLocation)}",'
        '"logo_url":"${_escape(safeLogoUrl)}",'
        '"whatsapp":"${_escape(safeWhatsApp)}",'
        '"school_type":"$schoolType",'
        '"is_active":$isActive,'
        '"motto":"${_escape(motto)}",'
        '"address":"${_escape(address)}",'
        '"official_phone":"${_escape(officialPhone)}",'
        '"official_email":"${_escape(officialEmail)}",'
        '"website":"${_escape(website)}",'
        '"subscription_plan":"$subscriptionPlan",'
        '"subscription_status":"$subscriptionStatus",'
        '"max_students":$maxStudents,'
        '"max_teachers":$maxTeachers,'
        '"has_paid_current_term":$hasPaidCurrentTerm,'
        '"country":"${_escape(country)}",'
        '"state":"${_escape(state)}",'
        '"city":"${_escape(city)}",'
        '"timezone":"$timezone",'
        '"exam_template":"$examTemplate",'
        '"show_position":$showPosition,'
        '"show_grade_only":$showGradeOnly,'
        '"student_count":$studentCount,'
        '"teacher_count":$teacherCount,'
        '"class_count":$classCount,'
        '"current_session":"${_escape(currentSession)}",'
        '"current_term":"${_escape(currentTerm)}",'
        '"principal_name":"${_escape(principalName)}",'
        '"subject_max_score":$subjectMaxScore,'
        '"locale":"$locale",'
        '"currency_code":"$currencyCode",'
        '"currency_symbol":"${_escape(currencySymbol)}",'
        '"primary_color":"$primaryColor",'
        '"secondary_color":"$secondaryColor",'
        '"created_at":"${createdAt.toIso8601String()}",'
        '"updated_at":"${updatedAt.toIso8601String()}"}';
  }

  // =========================================================
  // PRIVATE HELPERS
  // =========================================================

  static bool _isValidEmail(String email) {
    return RegExp(r'^[\w\.\-\+]+@[\w\.\-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  static bool _isValidPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
    return cleaned.length >= 7 && cleaned.length <= 15 && RegExp(r'^\d+$').hasMatch(cleaned);
  }

  static bool _isValidUrl(String url) {
    return RegExp(r'^https?://[^\s/$.?#].[^\s]*$').hasMatch(url) || url.startsWith('www.');
  }

  static String _escape(String value) {
    return value.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
  }
}
