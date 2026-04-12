/// Pure utility for exporting data to CSV format.
/// Returns CSV string — the UI layer handles saving/sharing.
///
/// MASTER PLAN V5:
/// - Never prints "SmartEdu" or generic platform names
/// - Student names use full_name/name fields first (consistent with mixin fixes)
/// - Added credentials export (teachers + students)
/// - All map access is null-safe
/// - School branding from multi-source pattern

class DataExport {

  static String withBom(String csv) => '\uFEFF$csv';

  // =========================================================
  // SCHOOL BRANDING — NEVER prints platform name
  // =========================================================

  static String _getSchoolName(Map<String, dynamic>? schoolInfo) {
    if (schoolInfo == null) return 'School';
    final name = (schoolInfo['name'] ?? '').toString().trim();
    return name.isNotEmpty ? name : 'School';
  }

  static void _appendSchoolBranding(StringBuffer buffer, Map<String, dynamic>? schoolInfo) {
    if (schoolInfo == null) return;
    final schoolName = _getSchoolName(schoolInfo).toUpperCase();
    buffer.writeln('$schoolName REPORT');
    buffer.writeln('=========================================');
    final address = schoolInfo['location'] ?? schoolInfo['address'];
    if (address != null && address.toString().trim().isNotEmpty) {
      buffer.writeln('Address: $address');
    }
    final phone = schoolInfo['whatsapp'] ?? schoolInfo['phone'];
    if (phone != null && phone.toString().trim().isNotEmpty) {
      buffer.writeln('Phone: $phone');
    }
    final email = schoolInfo['email'];
    if (email != null && email.toString().trim().isNotEmpty) {
      buffer.writeln('Email: $email');
    }
    final motto = schoolInfo['motto'];
    if (motto != null && motto.toString().trim().isNotEmpty) {
      buffer.writeln('Motto: "$motto"');
    }
    buffer.writeln('Generated on: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');
  }

  static void _appendSchoolFooter(StringBuffer buffer, Map<String, dynamic>? schoolInfo) {
    if (schoolInfo == null) return;
    final schoolName = _getSchoolName(schoolInfo).toUpperCase();
    buffer.writeln('');
    buffer.writeln('=========================================');
    buffer.writeln('END OF $schoolName REPORT');
    buffer.writeln('=========================================');
  }

  // =========================================================
  // STUDENT NAME HELPER — uses full_name/name first
  // =========================================================

  /// V5 FIX: Consistent with mixin pattern — full_name/name → build from parts
  static String _studentName(Map<String, dynamic> student) {
    final full = (student['full_name'] ?? student['name'] ?? '').toString().trim();
    if (full.isNotEmpty) return full;
    final parts = [
      student['first_name'] ?? '',
      student['middle_name'] ?? '',
      student['last_name'] ?? '',
    ].where((s) => (s as String).isNotEmpty).join(' ');
    return parts.isNotEmpty ? parts : 'Unknown';
  }

  /// Name without middle name (for shorter displays)
  static String _studentNameShort(Map<String, dynamic> student) {
    final full = (student['full_name'] ?? student['name'] ?? '').toString().trim();
    if (full.isNotEmpty) return full;
    final parts = [
      student['first_name'] ?? '',
      student['last_name'] ?? '',
    ].where((s) => (s as String).isNotEmpty).join(' ');
    return parts.isNotEmpty ? parts : 'Unknown';
  }

  static String _teacherName(Map<String, dynamic> teacher) {
    final full = (teacher['full_name'] ?? teacher['name'] ?? '').toString().trim();
    if (full.isNotEmpty) return full;
    final parts = [
      teacher['first_name'] ?? '',
      teacher['last_name'] ?? '',
    ].where((s) => (s as String).isNotEmpty).join(' ');
    return parts.isNotEmpty ? parts : 'Unknown';
  }

  static String _className(Map<String, dynamic>? classesMap) {
    if (classesMap == null) return '';
    final name = (classesMap['name'] ?? '').toString().trim();
    final section = (classesMap['section'] ?? '').toString().trim();
    if (name.isEmpty) return '';
    return section.isNotEmpty ? '$name $section' : name;
  }

  // =========================================================
  // STUDENT LIST EXPORT
  // =========================================================

  static String studentsToCsv(List<Map<String, dynamic>> students, {Map<String, dynamic>? schoolInfo}) {
    final buffer = StringBuffer();
    _appendSchoolBranding(buffer, schoolInfo);

    buffer.writeln('Admission No,Full Name,Gender,Parent Phone,Parent Name,Class');
    for (final s in students) {
      final cls = s['classes'];
      final className = cls is Map<String, dynamic> ? _className(cls) : '';
      buffer.writeln(
        '${_csv(s['admission_no'])},${_csv(_studentName(s))},'
        '${_csv(s['gender'])},${_csv(s['parent_phone'])},'
        '${_csv(s['parent_name'])},${_csv(className)}',
      );
    }

    _appendSchoolFooter(buffer, schoolInfo);
    return buffer.toString();
  }

  // =========================================================
  // CREDENTIALS EXPORT — TEACHERS
  // =========================================================

  /// V5 NEW: Export teacher login credentials to CSV for printing
  static String teacherCredentialsToCsv(List<Map<String, dynamic>> credentials, {Map<String, dynamic>? schoolInfo}) {
    final buffer = StringBuffer();
    _appendSchoolBranding(buffer, schoolInfo);
    buffer.writeln('TEACHER LOGIN CREDENTIALS');
    buffer.writeln('=========================================');
    buffer.writeln('');

    buffer.writeln('S/N,Name,Staff ID,Username,Password,Status');
    int rowNum = 1;
    for (final c in credentials) {
      final name = (c['name'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      final staffId = _s(c['staff_id'] ?? c['staffId']);
      final username = _s(c['username']);
      final password = _s(c['password']);
      final status = c['existing'] == true ? 'Existing' : 'New';
      buffer.writeln('$rowNum,$_csv(name),$_csv(staffId),$_csv(username),$_csv(password),$status');
      rowNum++;
    }

    if (rowNum == 1) {
      buffer.writeln('No credentials generated yet.');
    }

    buffer.writeln('');
    buffer.writeln('IMPORTANT: Distribute securely. Change passwords after first login.');
    _appendSchoolFooter(buffer, schoolInfo);
    return buffer.toString();
  }

  // =========================================================
  // CREDENTIALS EXPORT — STUDENTS
  // =========================================================

  /// V5 NEW: Export student login credentials to CSV for printing
  static String studentCredentialsToCsv(List<Map<String, dynamic>> credentials, {Map<String, dynamic>? schoolInfo}) {
    final buffer = StringBuffer();
    _appendSchoolBranding(buffer, schoolInfo);
    buffer.writeln('STUDENT LOGIN CREDENTIALS');
    buffer.writeln('=========================================');
    buffer.writeln('');

    buffer.writeln('S/N,Name,Admission No,Class,Username,PIN,Status');
    int rowNum = 1;
    for (final c in credentials) {
      final name = (c['name'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      final admNo = _s(c['admission_no'] ?? c['admissionNo']);
      final className = _s(c['class_name'] ?? c['className']);
      final username = _s(c['username']);
      final pin = _s(c['pin']);
      final status = c['existing'] == true ? 'Existing' : 'New';
      buffer.writeln('$rowNum,$_csv(name),$_csv(admNo),$_csv(className),$_csv(username),$_csv(pin),$status');
      rowNum++;
    }

    if (rowNum == 1) {
      buffer.writeln('No credentials generated yet.');
    }

    buffer.writeln('');
    buffer.writeln('IMPORTANT: Distribute securely. Students should change PIN after first login.');
    _appendSchoolFooter(buffer, schoolInfo);
    return buffer.toString();
  }

  // =========================================================
  // BROADSHEET EXPORT
  // =========================================================

  static String broadsheetToCsv({
    required List<Map<String, dynamic>> broadsheetRows,
    required List<Map<String, dynamic>> subjects,
    bool showPosition = true,
    Map<String, dynamic>? schoolInfo,
    Map<String, Map<String, dynamic>>? behavioralData,
  }) {
    final buffer = StringBuffer();
    _appendSchoolBranding(buffer, schoolInfo);

    final header = <String>['#', 'Admission No', 'Student Name'];
    for (final s in subjects) {
      final code = _s(s['code']);
      final name = _s(s['name']);
      header.add(code.isNotEmpty ? '$name ($code)' : name);
    }
    header.add('Total');
    header.add('Average');
    header.add('Grade');
    if (showPosition) header.add('Position');
    if (behavioralData != null) {
      header.add('Conduct');
      header.add('Attitude');
      header.add('Teacher Comment');
    }
    buffer.writeln(header.map(_csv).join(','));

    int rowNum = 1;
    for (final row in broadsheetRows) {
      final cells = <String>[
        (rowNum++).toString(),
        _csv(row['admission_no']),
        // V5 FIX: Use student_name if available, else build
        _csv(row['student_name'] ?? row['name'] ?? ''),
      ];

      final subjectData = row['subjects'] as Map<String, dynamic>?;
      if (subjectData != null) {
        for (final s in subjects) {
          final sid = s['id'].toString();
          final sd = subjectData[sid] as Map<String, dynamic>? ?? {};
          cells.add(_csv(sd['total']));
        }
      }

      cells.add(_csv(row['total_score']));
      cells.add(_csv(_safeDoubleStr(row['average'])));
      cells.add(_csv(row['overall_grade']));
      if (showPosition) {
        cells.add('${row['class_position'] ?? ''}/${row['class_position_out_of'] ?? ''}');
      }

      if (behavioralData != null) {
        final key = (row['student_id'] ?? row['admission_no'])?.toString();
        final bh = key != null ? behavioralData[key] : null;
        cells.add(_csv(bh?['conduct'] ?? ''));
        cells.add(_csv(bh?['attitude'] ?? ''));
        cells.add(_csv(bh?['teacher_comment'] ?? ''));
      }

      buffer.writeln(cells.join(','));
    }

    _appendSchoolFooter(buffer, schoolInfo);
    return buffer.toString();
  }

  // =========================================================
  // ATTENDANCE EXPORTS
  // =========================================================

  static String attendanceSummaryToCsv(List<Map<String, dynamic>> summary, {Map<String, dynamic>? schoolInfo}) {
    final buffer = StringBuffer();
    _appendSchoolBranding(buffer, schoolInfo);

    buffer.writeln('Admission No,Student Name,Present,Absent,Late,Excused,Total Days');
    for (final row in summary) {
      final name = _studentNameShort(row);
      buffer.writeln(
        '${_csv(row['admission_no'])},$_csv(name),'
        '${row['present'] ?? 0},${row['absent'] ?? 0},${row['late'] ?? 0},${row['excused'] ?? 0},${row['total_days'] ?? 0}',
      );
    }

    _appendSchoolFooter(buffer, schoolInfo);
    return buffer.toString();
  }

  static String attendanceRegisterToCsv({
    required List<Map<String, dynamic>> students,
    required List<String> dates,
    required Map<String, Map<String, String>> attendanceMap,
    Map<String, dynamic>? schoolInfo,
    String? className,
  }) {
    final buffer = StringBuffer();
    _appendSchoolBranding(buffer, schoolInfo);
    if (className != null && className.isNotEmpty) {
      buffer.writeln('Class: $className');
      buffer.writeln('');
    }

    final header = <String>['#', 'Admission No', 'Student Name'];
    header.addAll(dates);
    header.add('Total Present');
    header.add('Total Absent');
    buffer.writeln(header.map(_csv).join(','));

    int rowNum = 1;
    for (final s in students) {
      final sid = _s(s['id'] ?? s['admission_no']);
      final name = _studentNameShort(s);
      final cells = <String>[
        (rowNum++).toString(),
        _csv(s['admission_no']),
        _csv(name),
      ];

      int presentCount = 0;
      int absentCount = 0;
      for (final date in dates) {
        final key = '${sid}_$date';
        // Safely convert to String before toUpperCase
        final status = (attendanceMap[key] ?? '').toString();
        cells.add(_csv(status.toUpperCase()));
        if (status.toLowerCase() == 'present') presentCount++;
        else if (status.toLowerCase() == 'absent') absentCount++;
      }
      cells.add(presentCount.toString());
      cells.add(absentCount.toString());

      buffer.writeln(cells.join(','));
    }

    _appendSchoolFooter(buffer, schoolInfo);
    return buffer.toString();
  }

  // =========================================================
  // PAYMENT EXPORTS
  // =========================================================

  static String paymentsToCsv(List<Map<String, dynamic>> payments, {Map<String, dynamic>? schoolInfo}) {
    final buffer = StringBuffer();
    _appendSchoolBranding(buffer, schoolInfo);

    buffer.writeln('Date,Receipt No,Student Name,Admission No,Fee Type,Amount Paid,Method,Reference,Remark');
    for (final p in payments) {
      final student = p['students'];
      final studentName = student is Map<String, dynamic> ? _studentNameShort(student) : '';
      final admNo = student is Map<String, dynamic> ? _s(student['admission_no']) : '';
      final feeType = p['fee_types'];
      final feeName = feeType is Map<String, dynamic> ? _s(feeType['name']) : '';
      buffer.writeln(
        '${_csv(p['payment_date'])},${_csv(p['receipt_no'])},'
        '$_csv(studentName),$_csv(admNo),$_csv(feeName),'
        '${_csv(p['amount_paid'])},${_csv(p['payment_method'])},${_csv(p['reference_no'])},${_csv(p['remark'])}',
      );
    }

    _appendSchoolFooter(buffer, schoolInfo);
    return buffer.toString();
  }

  static String outstandingFeesToCsv(List<Map<String, dynamic>> outstanding, {Map<String, dynamic>? schoolInfo}) {
    final buffer = StringBuffer();
    _appendSchoolBranding(buffer, schoolInfo);

    buffer.writeln('Admission No,Student Name,Fee Name,Total Amount,Amount Paid,Outstanding');
    for (final row in outstanding) {
      final breakdown = row['fee_breakdown'];
      if (breakdown is List) {
        for (final fb in breakdown) {
          if (fb is Map<String, dynamic>) {
            buffer.writeln(
              '${_csv(row['admission_no'])},${_csv(row['student_name'])},'
              '${_csv(fb['fee_name'])},${fb['fee_amount'] ?? 0},${fb['amount_paid'] ?? 0},${fb['outstanding'] ?? 0}',
            );
          }
        }
      }
    }

    _appendSchoolFooter(buffer, schoolInfo);
    return buffer.toString();
  }

  static String feeReceiptToCsv({
    required Map<String, dynamic> payment,
    required Map<String, dynamic> student,
    required Map<String, dynamic> feeType,
    Map<String, dynamic>? schoolInfo,
    Map<String, dynamic>? session,
    Map<String, dynamic>? term,
  }) {
    final buffer = StringBuffer();
    final schoolName = _getSchoolName(schoolInfo).toUpperCase();

    buffer.writeln(schoolName);
    buffer.writeln('=========================================');
    final address = schoolInfo?['location'] ?? schoolInfo?['address'];
    if (address != null && address.toString().trim().isNotEmpty) buffer.writeln('Address: $address');
    final phone = schoolInfo?['whatsapp'] ?? schoolInfo?['phone'];
    if (phone != null && phone.toString().trim().isNotEmpty) buffer.writeln('Phone: $phone');
    buffer.writeln('');

    buffer.writeln('OFFICIAL RECEIPT');
    buffer.writeln('=========================================');
    buffer.writeln('Receipt No: ${_csv(payment['receipt_no'])}');
    buffer.writeln('Date: ${_csv(payment['payment_date'])}');
    if (session != null) buffer.writeln('Session: ${_csv(session['name'])}');
    if (term != null) buffer.writeln('Term: ${_csv(term['name'])}');
    buffer.writeln('');
    buffer.writeln('Student Name: ${_csv(_studentNameShort(student))}');
    buffer.writeln('Admission No: ${_csv(student['admission_no'])}');
    buffer.writeln('Class: ${_csv(student['class_name'] ?? student['class'])}');
    buffer.writeln('');
    buffer.writeln('Fee Type: ${_csv(feeType['name'])}');
    buffer.writeln('Amount Paid: ${_csv(payment['amount_paid'])}');
    buffer.writeln('Payment Method: ${_csv(payment['payment_method'])}');
    final ref = payment['reference_no'];
    if (ref != null && ref.toString().trim().isNotEmpty) {
      buffer.writeln('Reference No: ${_csv(ref)}');
    }
    final remark = payment['remark'];
    if (remark != null && remark.toString().trim().isNotEmpty) {
      buffer.writeln('Remark: ${_csv(remark)}');
    }
    buffer.writeln('');
    buffer.writeln('=========================================');
    buffer.writeln('Thank you for your payment.');

    return buffer.toString();
  }

  // =========================================================
  // RESULT SHEET EXPORT (INDIVIDUAL STUDENT)
  // =========================================================

  static String resultSheetToCsv({
    required Map<String, dynamic> student,
    required Map<String, dynamic> schoolInfo,
    required Map<String, dynamic> classInfo,
    required Map<String, dynamic> session,
    required Map<String, dynamic> term,
    required List<Map<String, dynamic>> subjectScores,
    Map<String, dynamic>? termComment,
    List<Map<String, dynamic>>? gradingSystem,
    List<Map<String, dynamic>>? assessmentTypes,
    int? totalScore,
    double? average,
    String? overallGrade,
    int? position,
    int? positionOutOf,
    bool showPosition = true,
  }) {
    final buffer = StringBuffer();
    final schoolName = _getSchoolName(schoolInfo).toUpperCase();
    final studentName = _studentName(student);
    final className = _className(classInfo);
    final principalName = _s(schoolInfo['principal_name']);

    buffer.writeln(schoolName);
    final address = schoolInfo['location'] ?? schoolInfo['address'];
    if (address != null && address.toString().trim().isNotEmpty) buffer.writeln(address.toString());
    final phone = schoolInfo['whatsapp'] ?? schoolInfo['phone'];
    if (phone != null && phone.toString().trim().isNotEmpty) buffer.writeln('Tel: $phone');
    final motto = schoolInfo['motto'];
    if (motto != null && motto.toString().trim().isNotEmpty) buffer.writeln('Motto: "$motto"');
    buffer.writeln('=========================================');
    buffer.writeln('STUDENT RESULT SHEET');
    buffer.writeln('=========================================');

    buffer.writeln('Name: $studentName');
    buffer.writeln('Admission No: ${_s(student['admission_no'])}');
    buffer.writeln('Class: $className');
    buffer.writeln('Session: ${_s(session['name'])}');
    buffer.writeln('Term: ${_s(term['name'])}');
    final gender = student['gender'];
    if (gender != null && gender.toString().trim().isNotEmpty) buffer.writeln('Gender: $gender');
    final dob = student['date_of_birth'];
    if (dob != null && dob.toString().trim().isNotEmpty) buffer.writeln('Date of Birth: $dob');
    buffer.writeln('');

    final assessLabels = <String>[];
    if (assessmentTypes != null && assessmentTypes.isNotEmpty) {
      for (final at in assessmentTypes) {
        assessLabels.add(_s(at['name'] ?? at['id']).toUpperCase());
      }
    } else {
      assessLabels.addAll(['CA1', 'CA2', 'ASSIGNMENT', 'MID-TERM', 'EXAM']);
    }

    final scoreHeader = <String>['S/N', 'SUBJECT'];
    scoreHeader.addAll(assessLabels);
    scoreHeader.addAll(['TOTAL', 'GRADE', 'REMARK']);
    buffer.writeln(scoreHeader.join(','));

    int sn = 1;
    for (final ss in subjectScores) {
      final row = <String>[
        (sn++).toString(),
        _csv(ss['subject_name'] ?? ss['name'] ?? ''),
      ];

      final scoresJson = ss['scores_json'] as Map<String, dynamic>?;
      if (scoresJson != null && assessmentTypes != null && assessmentTypes.isNotEmpty) {
        for (final at in assessmentTypes) {
          final key = _s(at['id']).toLowerCase();
          row.add(_csv(scoresJson[key] ?? ''));
        }
      } else if (scoresJson != null) {
        row.add(_csv(scoresJson['ca1'] ?? ''));
        row.add(_csv(scoresJson['ca2'] ?? ''));
        row.add(_csv(scoresJson['assignment'] ?? ''));
        row.add(_csv(scoresJson['midterm'] ?? ''));
        row.add(_csv(scoresJson['exam'] ?? ''));
      } else {
        // Direct field access fallback
        row.add(_csv(ss['ca1'] ?? ''));
        row.add(_csv(ss['ca2'] ?? ''));
        row.add(_csv(ss['exam'] ?? ''));
      }

      row.add(_csv(ss['total']));
      row.add(_csv(ss['grade']));
      row.add(_csv(ss['remark'] ?? _gradeRemark(_s(ss['grade']), gradingSystem)));

      buffer.writeln(row.join(','));
    }

    buffer.writeln('');
    buffer.writeln('Total Score: ${totalScore ?? 0}');
    if (average != null) buffer.writeln('Average: ${average.toStringAsFixed(1)}');
    if (overallGrade != null) buffer.writeln('Overall Grade: $overallGrade');
    if (showPosition && position != null && positionOutOf != null) {
      buffer.writeln('Position in Class: ${_ordinal(position)} out of $positionOutOf');
    }
    buffer.writeln('');

    if (termComment != null) {
      buffer.writeln('=========================================');
      buffer.writeln('BEHAVIORAL RATING');
      buffer.writeln('=========================================');
      final conduct = termComment['conduct'];
      if (conduct != null && conduct.toString().trim().isNotEmpty) buffer.writeln('Conduct: $conduct');
      final attitude = termComment['attitude'];
      if (attitude != null && attitude.toString().trim().isNotEmpty) buffer.writeln('Attitude: $attitude');
      final interest = termComment['interest'];
      if (interest != null && interest.toString().trim().isNotEmpty) buffer.writeln('Interest in Studies: $interest');
      final punctuality = termComment['punctuality'];
      if (punctuality != null && punctuality.toString().trim().isNotEmpty) buffer.writeln('Punctuality: $punctuality');
      buffer.writeln('');

      buffer.writeln('=========================================');
      buffer.writeln('COMMENTS');
      buffer.writeln('=========================================');
      final tc = termComment['teacher_comment'];
      if (tc != null && tc.toString().trim().isNotEmpty) {
        buffer.writeln('Class Teacher Comment: $tc');
      }
      final pc = termComment['principal_comment'];
      if (pc != null && pc.toString().trim().isNotEmpty) {
        buffer.writeln('Principal Comment: $pc');
      } else if (principalName.isNotEmpty) {
        buffer.writeln('Principal Comment: ');
      }
      buffer.writeln('');
    }

    if (gradingSystem != null && gradingSystem.isNotEmpty) {
      buffer.writeln('=========================================');
      buffer.writeln('GRADING KEY');
      buffer.writeln('=========================================');
      buffer.writeln('Grade,Range,Remark');
      for (final g in gradingSystem) {
        buffer.writeln('${_csv(g['grade'])},${_csv('${g['min']}-${g['max']}')},${_csv(g['remark'])}');
      }
      buffer.writeln('');
    }

    buffer.writeln('=========================================');
    buffer.writeln('');
    buffer.writeln('_______________________          _______________________');
    buffer.writeln('   Class Teacher                    Principal');
    if (principalName.isNotEmpty) {
      buffer.writeln('                                  ($principalName)');
    }
    buffer.writeln('');
    buffer.writeln('=========================================');
    buffer.writeln('END OF $schoolName RESULT SHEET');
    buffer.writeln('=========================================');

    return buffer.toString();
  }

  // =========================================================
  // CBT RESULTS EXPORT
  // =========================================================

  static String cbtResultsToCsv({
    required Map<String, dynamic> exam,
    required List<Map<String, dynamic>> attempts,
    Map<String, dynamic>? schoolInfo,
  }) {
    final buffer = StringBuffer();
    _appendSchoolBranding(buffer, schoolInfo);
    buffer.writeln('CBT EXAM RESULTS');
    buffer.writeln('Exam: ${_s(exam['title'])}');
    buffer.writeln('Duration: ${exam['duration_minutes'] ?? 60} minutes');
    buffer.writeln('Total Questions: ${exam['total_questions'] ?? 0}');
    buffer.writeln('');

    buffer.writeln('#,Admission No,Student Name,Score,Total Marks,Percentage,Time Started,Time Submitted');
    int rowNum = 1;
    for (final a in attempts) {
      final student = a['students'];
      final name = student is Map<String, dynamic> ? _studentNameShort(student) : 'Unknown';
      final admNo = student is Map<String, dynamic> ? _s(student['admission_no']) : '';
      final score = (a['score'] ?? 0).toDouble();
      final total = (a['total_marks'] ?? 1).toDouble();
      final pct = total > 0 ? ((score / total) * 100).toStringAsFixed(1) : '0.0';

      buffer.writeln(
        '$rowNum,$_csv(admNo),$_csv(name),'
        '${_csv(score)},${_csv(total)},$pct%,'
        '${_csv(a['time_started'])},${_csv(a['time_submitted'])}',
      );
      rowNum++;
    }

    _appendSchoolFooter(buffer, schoolInfo);
    return buffer.toString();
  }

  // =========================================================
  // GRADING KEY EXPORT
  // =========================================================

  static String gradingKeyToCsv(List<Map<String, dynamic>> gradingSystem, {Map<String, dynamic>? schoolInfo}) {
    final buffer = StringBuffer();
    final schoolName = _getSchoolName(schoolInfo);

    buffer.writeln('$schoolName - GRADING SYSTEM');
    buffer.writeln('=========================================');
    buffer.writeln('');

    buffer.writeln('Grade,Min Score,Max Score,Remark');
    for (final g in gradingSystem) {
      buffer.writeln('${_csv(g['grade'])},${g['min'] ?? 0},${g['max'] ?? 100},${_csv(g['remark'])}');
    }

    return buffer.toString();
  }

  // =========================================================
  // TEACHER SCORE SUMMARY EXPORT
  // =========================================================

  static String teacherScoreSummaryToCsv({
    required String teacherName,
    required String subjectName,
    required String className,
    required List<Map<String, dynamic>> studentScores,
    List<Map<String, dynamic>>? assessmentTypes,
    Map<String, dynamic>? schoolInfo,
  }) {
    final buffer = StringBuffer();
    _appendSchoolBranding(buffer, schoolInfo);
    buffer.writeln('TEACHER SCORE SUMMARY');
    buffer.writeln('Teacher: $teacherName');
    buffer.writeln('Subject: $subjectName');
    buffer.writeln('Class: $className');
    buffer.writeln('');

    final assessLabels = <String>[];
    if (assessmentTypes != null && assessmentTypes.isNotEmpty) {
      for (final at in assessmentTypes) {
        assessLabels.add(_s(at['name'] ?? at['id']).toUpperCase());
      }
    } else {
      assessLabels.addAll(['CA1', 'CA2', 'ASSIGNMENT', 'MID-TERM', 'EXAM']);
    }

    final header = <String>['#', 'Admission No', 'Student Name'];
    header.addAll(assessLabels);
    header.addAll(['Total', 'Grade']);
    buffer.writeln(header.join(','));

    int rowNum = 1;
    for (final ss in studentScores) {
      final student = ss['students'];
      final name = student is Map<String, dynamic> ? _studentNameShort(student) : 'Unknown';
      final admNo = student is Map<String, dynamic> ? _s(student['admission_no']) : '';

      final row = <String>[
        (rowNum++).toString(),
        _csv(admNo),
        _csv(name),
      ];

      final scoresJson = ss['scores_json'] as Map<String, dynamic>?;
      if (scoresJson != null && assessmentTypes != null && assessmentTypes.isNotEmpty) {
        for (final at in assessmentTypes) {
          final key = _s(at['id']).toLowerCase();
          row.add(_csv(scoresJson[key] ?? ''));
        }
      } else if (scoresJson != null) {
        row.add(_csv(scoresJson['ca1'] ?? ''));
        row.add(_csv(scoresJson['ca2'] ?? ''));
        row.add(_csv(scoresJson['assignment'] ?? ''));
        row.add(_csv(scoresJson['midterm'] ?? ''));
        row.add(_csv(scoresJson['exam'] ?? ''));
      } else {
        row.add(_csv(ss['ca1'] ?? ''));
        row.add(_csv(ss['ca2'] ?? ''));
        row.add(_csv(ss['exam'] ?? ''));
      }

      row.add(_csv(ss['total']));
      row.add(_csv(ss['grade']));

      buffer.writeln(row.join(','));
    }

    _appendSchoolFooter(buffer, schoolInfo);
    return buffer.toString();
  }

  // =========================================================
  // LOW-LEVEL HELPERS
  // =========================================================

  static String _csv(dynamic value) {
    if (value == null) return '';
    final str = value.toString();
    if (str.contains(',') || str.contains('\n') || str.contains('"')) {
      return '"${str.replaceAll('"', '""')}"';
    }
    return str;
  }

  static String _s(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static String _safeDoubleStr(dynamic value) {
    if (value == null) return '';
    if (value is double) return value.toStringAsFixed(1);
    if (value is num) return value.toDouble().toStringAsFixed(1);
    return value.toString();
  }

  static String _ordinal(int n) {
    if (n <= 0) return '$n';
    final lastTwo = n % 100;
    if (lastTwo >= 11 && lastTwo <= 13) return '${n}th';
    switch (n % 10) {
      case 1: return '${n}st';
      case 2: return '${n}nd';
      case 3: return '${n}rd';
      default: return '${n}th';
    }
  }

  static String _gradeRemark(String grade, List<Map<String, dynamic>>? gradingSystem) {
    if (grade.isEmpty || gradingSystem == null || gradingSystem.isEmpty) return '';
    for (final g in gradingSystem) {
      if (_s(g['grade']) == grade) return _s(g['remark']);
    }
    return '';
  }
}
