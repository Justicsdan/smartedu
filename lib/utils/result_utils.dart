/// Pure utility functions for result computation.
/// No state, no DB calls — just math on in-memory data.
///
/// MASTER PLAN: Every computation returns isolated school data.
/// Zero platform branding. All outputs carry school identity only.
/// Optimized for global scale (O(N log N) sorting, strict type safety).

class ResultUtils {

  // =========================================================
  // SHARED HELPERS
  // =========================================================

  /// Extract standardized school info block from any school data map.
  /// DRY — used by every method that returns school_info.
  static Map<String, dynamic> _extractSchoolInfo(Map<String, dynamic>? schoolInfo) {
    if (schoolInfo == null) return {};
    final settings = schoolInfo['school_settings'] as Map<String, dynamic>?;
    return {
      'name': (schoolInfo['name'] ?? '').toString(),
      'logo_url': (schoolInfo['logo_url'] ?? '').toString(),
      'address': (schoolInfo['address'] ?? schoolInfo['location'] ?? '').toString(),
      'city': (schoolInfo['city'] ?? '').toString(),
      'state': (schoolInfo['state'] ?? '').toString(),
      'country': (schoolInfo['country'] ?? '').toString(),
      'motto': (schoolInfo['motto'] ?? settings?['motto'] ?? '').toString(),
      'email': (schoolInfo['email'] ?? '').toString(),
      'phone': (schoolInfo['whatsapp'] ?? schoolInfo['phone'] ?? '').toString(),
      'principal_name': (schoolInfo['principal_name'] ?? settings?['principal_name'] ?? '').toString(),
    };
  }

  /// Extract behavioral ratings from a term_comments record.
  static Map<String, dynamic> _extractBehavioral(Map<String, dynamic>? termComment) {
    if (termComment == null) return {};
    return {
      'conduct': (termComment['conduct'] ?? '').toString(),
      'attitude': (termComment['attitude'] ?? '').toString(),
      'interest': (termComment['interest'] ?? '').toString(),
      'punctuality': (termComment['punctuality'] ?? '').toString(),
      'teacher_comment': (termComment['teacher_comment'] ?? '').toString(),
      'principal_comment': (termComment['principal_comment'] ?? '').toString(),
    };
  }

  // =========================================================
  // ORDINAL HELPER
  // Used by student_results_page.dart for display like "1st", "3rd", etc.
  // =========================================================

  /// Convert a number to its ordinal string (1 → "1st", 2 → "2nd", etc.)
  static String ordinal(int number) {
    if (number <= 0) return '$number';
    final mod100 = number % 100;
    if (mod100 >= 11 && mod100 <= 13) return '${number}th';
    switch (number % 10) {
      case 1: return '${number}st';
      case 2: return '${number}nd';
      case 3: return '${number}rd';
      default: return '${number}th';
    }
  }

  // =========================================================
  // GRADE COMPUTATION
  // =========================================================

  /// Compute grade from score using grading system.
  /// Returns grade string only.
  static String computeGrade(double score, List<Map<String, dynamic>> gradingSystem) {
    for (final g in gradingSystem) {
      final min = (g['min'] as num?)?.toDouble() ?? 0.0;
      final max = (g['max'] as num?)?.toDouble() ?? 0.0;
      if (score >= min && score <= max) return (g['grade'] ?? '').toString();
    }
    return 'F';
  }

  /// Compute grade AND remark from score.
  static Map<String, String> computeGradeWithRemark(double score, List<Map<String, dynamic>> gradingSystem) {
    for (final g in gradingSystem) {
      final min = (g['min'] as num?)?.toDouble() ?? 0.0;
      final max = (g['max'] as num?)?.toDouble() ?? 0.0;
      if (score >= min && score <= max) {
        return {
          'grade': (g['grade'] ?? '').toString(),
          'remark': (g['remark'] ?? '').toString(),
        };
      }
    }
    return {'grade': 'F', 'remark': 'Fail'};
  }

  // =========================================================
  // POSITION COMPUTATION
  // =========================================================

  /// Calculate positions for a list of student totals.
  /// Handles ties: same score = same position, next position skips.
  /// Returns map keyed by student_id with position and position_out_of.
  static Map<String, Map<String, int>> calculatePositions(List<Map<String, dynamic>> studentTotals) {
    if (studentTotals.isEmpty) return {};

    // Sort descending by total
    final sorted = List<Map<String, dynamic>>.from(studentTotals)
      ..sort((a, b) {
        final tA = (a['total_score'] as num?)?.toDouble() ?? 0.0;
        final tB = (b['total_score'] as num?)?.toDouble() ?? 0.0;
        return tB.compareTo(tA);
      });

    final totalStudents = sorted.length;
    final result = <String, Map<String, int>>{};
    int currentPosition = 1;

    for (int i = 0; i < sorted.length; i++) {
      final currentTotal = (sorted[i]['total_score'] as num?)?.toDouble() ?? 0.0;
      if (i > 0) {
        final prevTotal = (sorted[i - 1]['total_score'] as num?)?.toDouble() ?? 0.0;
        if (currentTotal != prevTotal) currentPosition = i + 1;
      }
      final sid = (sorted[i]['student_id'] ?? '').toString();
      result[sid] = {
        'position': currentPosition,
        'position_out_of': totalStudents,
      };
    }

    return result;
  }

  // =========================================================
  // BROADSHEET BUILDER
  // =========================================================

  /// Build a broadsheet: one row per student, one column per subject.
  ///
  /// IMPORTANT: Students with NO scores still appear on the broadsheet
  /// (marked with zeros) — this is required for accurate positioning
  /// and complete class lists on printed sheets.
  static Map<String, dynamic> buildBroadsheet({
    required List<Map<String, dynamic>> scores,
    required List<Map<String, dynamic>> students,
    required List<Map<String, dynamic>> subjects,
    required List<Map<String, dynamic>> gradingSystem,
    bool showPosition = true,
    Map<String, dynamic>? schoolInfo,
  }) {
    // Build lookups
    final subjectMap = <String, Map<String, dynamic>>{};
    for (final s in subjects) {
      subjectMap[s['id'].toString()] = s;
    }

    final studentMap = <String, Map<String, dynamic>>{};
    for (final s in students) {
      studentMap[s['id'].toString()] = s;
    }

    // Group scores by student
    final studentScores = <String, List<Map<String, dynamic>>>{};
    for (final score in scores) {
      final sid = score['student_id']?.toString() ?? '';
      if (sid.isEmpty) continue;
      studentScores.putIfAbsent(sid, () => []);
      studentScores[sid]!.add(score);
    }

    // Build rows — include ALL students, even those with no scores
    final rows = <Map<String, dynamic>>[];

    for (final studentEntry in studentMap.entries) {
      final studentId = studentEntry.key;
      final student = studentEntry.value;
      final studentScoreList = studentScores[studentId] ?? [];

      double totalScore = 0.0;
      int subjectsWithScores = 0;
      final subjectDetails = <String, Map<String, dynamic>>{};

      for (final score in studentScoreList) {
        final subjectId = score['subject_id']?.toString() ?? '';
        final total = (score['total'] as num?)?.toDouble() ?? 0.0;

        totalScore += total;
        subjectsWithScores++;

        // Include scores_json breakdown for detailed broadsheet columns
        final scoresJson = score['scores_json'] as Map<String, dynamic>? ?? {};
        final gradeWithRemark = computeGradeWithRemark(total, gradingSystem);

        subjectDetails[subjectId] = {
          'subject_id': subjectId,
          'subject_name': subjectMap[subjectId]?['name'] ?? '',
          'subject_code': subjectMap[subjectId]?['code'] ?? '',
          'total': total,
          'grade': gradeWithRemark['grade'],
          'remark': gradeWithRemark['remark'],
          'scores_json': scoresJson,
          'position': showPosition ? score['position'] : null,
          'position_out_of': showPosition ? score['position_out_of'] : null,
        };
      }

      final average = subjectsWithScores > 0 ? totalScore / subjectsWithScores : 0.0;
      final overallGrade = computeGrade(average, gradingSystem);

      rows.add({
        'student_id': studentId,
        'admission_no': student['admission_no'] ?? '',
        'first_name': student['first_name'] ?? '',
        'last_name': student['last_name'] ?? '',
        'student_name': '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'.trim(),
        'total_score': totalScore,
        'subjects_taken': subjectsWithScores,
        'average': average,
        'overall_grade': overallGrade,
        'subjects': subjectDetails,
      });
    }

    // Calculate class positions based on total_score
    if (showPosition && rows.isNotEmpty) {
      rows.sort((a, b) =>
        ((b['total_score'] as num?)?.toDouble() ?? 0.0).compareTo((a['total_score'] as num?)?.toDouble() ?? 0.0),
      );
      final totalStudents = rows.length;
      int currentPosition = 1;

      for (int i = 0; i < rows.length; i++) {
        final currentTotal = (rows[i]['total_score'] as num?)?.toDouble() ?? 0.0;
        if (i > 0) {
          final prevTotal = (rows[i - 1]['total_score'] as num?)?.toDouble() ?? 0.0;
          if (currentTotal != prevTotal) currentPosition = i + 1;
        }
        rows[i]['class_position'] = currentPosition;
        rows[i]['class_position_out_of'] = totalStudents;
      }

      // Null-safe sort by last_name
      rows.sort((a, b) {
        final aName = (a['last_name'] as String?) ?? '';
        final bName = (b['last_name'] as String?) ?? '';
        return aName.compareTo(bName);
      });
    }

    // Class statistics (Fixed: removed unused parameters to prevent type mismatch)
    final classStats = _computeClassStatistics(rows, gradingSystem);

    return {
      'rows': rows,
      'class_statistics': classStats,
      'total_students': students.length,
      'students_with_scores': rows.where((r) => (r['subjects_taken'] as int) > 0).length,
      'school_info': _extractSchoolInfo(schoolInfo),
    };
  }

  // =========================================================
  // STUDENT RESULT CARD BUILDER
  // =========================================================

  /// Build a single student's result card data.
  /// Includes behavioral ratings, grade remarks, and school info.
  static Map<String, dynamic> buildStudentResultCard({
    required Map<String, dynamic> student,
    required List<Map<String, dynamic>> scores,
    required List<Map<String, dynamic>> subjects,
    required List<Map<String, dynamic>> gradingSystem,
    Map<String, dynamic>? termComments,
    bool showPosition = true,
    String? className,
    String? sessionName,
    String? termName,
    Map<String, dynamic>? schoolInfo,
    int? position,
    int? positionOutOf,
  }) {
    final subjectMap = <String, Map<String, dynamic>>{};
    for (final s in subjects) {
      subjectMap[s['id'].toString()] = s;
    }

    double totalScore = 0.0;
    int subjectsTaken = 0;
    final subjectResults = <Map<String, dynamic>>[];

    for (final score in scores) {
      final subjectId = score['subject_id']?.toString() ?? '';
      final total = (score['total'] as num?)?.toDouble() ?? 0.0;
      totalScore += total;
      subjectsTaken++;

      final scoresJson = score['scores_json'] as Map<String, dynamic>? ?? {};
      final gradeWithRemark = computeGradeWithRemark(total, gradingSystem);

      subjectResults.add({
        'subject_id': subjectId,
        'subject_name': subjectMap[subjectId]?['name'] ?? '',
        'subject_code': subjectMap[subjectId]?['code'] ?? '',
        'total': total,
        'grade': gradeWithRemark['grade'],
        'remark': gradeWithRemark['remark'],
        'scores_json': scoresJson,
        'position': showPosition ? score['position'] : null,
        'position_out_of': showPosition ? score['position_out_of'] : null,
      });
    }

    // Sort subjects by name for consistent display
    subjectResults.sort((a, b) =>
      ((a['subject_name'] as String?) ?? '').compareTo((b['subject_name'] as String?) ?? ''),
    );

    final average = subjectsTaken > 0 ? totalScore / subjectsTaken : 0.0;
    final overallGradeWithRemark = computeGradeWithRemark(average, gradingSystem);

    return {
      'student': student,
      'class_name': className ?? '',
      'session_name': sessionName ?? '',
      'term_name': termName ?? '',
      'subjects_taken': subjectsTaken,
      'total_score': totalScore,
      'average': average,
      'overall_grade': overallGradeWithRemark['grade'],
      'overall_remark': overallGradeWithRemark['remark'],
      'position': position,
      'position_out_of': positionOutOf,
      'subjects': subjectResults,
      'behavioral': _extractBehavioral(termComments),
      'term_comments': termComments,
      'school_info': _extractSchoolInfo(schoolInfo),
    };
  }

  // =========================================================
  // CUMULATIVE SESSION RESULT BUILDER
  // =========================================================

  /// Build cumulative result across multiple terms for a session.
  /// Returns per-term breakdown + session aggregate.
  static Map<String, dynamic> buildCumulativeResult({
    required Map<String, dynamic> student,
    required List<Map<String, dynamic>> allTermResults, // List of buildStudentResultCard outputs
    required List<Map<String, dynamic>> gradingSystem,
    Map<String, dynamic>? schoolInfo,
  }) {
    double sessionTotal = 0.0;
    int totalSubjectsAcrossTerms = 0;
    final termBreakdown = <Map<String, dynamic>>[];

    for (final termResult in allTermResults) {
      final termTotal = (termResult['total_score'] as num?)?.toDouble() ?? 0.0;
      final subjectsTaken = (termResult['subjects_taken'] as int?) ?? 0;
      sessionTotal += termTotal;
      totalSubjectsAcrossTerms += subjectsTaken;

      termBreakdown.add({
        'term_name': termResult['term_name'] ?? '',
        'total_score': termTotal,
        'average': termResult['average'],
        'overall_grade': termResult['overall_grade'],
        'subjects_taken': subjectsTaken,
      });
    }

    final termCount = allTermResults.isNotEmpty ? allTermResults.length : 1;
    final sessionAverage = sessionTotal / termCount;
    final sessionGrade = computeGrade(sessionAverage, gradingSystem);

    return {
      'student': student,
      'session_average': sessionAverage,
      'session_grade': sessionGrade,
      'term_breakdown': termBreakdown,
      'total_terms': allTermResults.length,
      'school_info': _extractSchoolInfo(schoolInfo),
    };
  }

  // =========================================================
  // SUBJECT ANALYSIS BUILDER
  // =========================================================

  /// Build per-subject statistics for a class.
  /// Used for teacher gradebook analysis and broadsheet footer.
  static List<Map<String, dynamic>> buildSubjectAnalysis({
    required List<Map<String, dynamic>> scores,
    required List<Map<String, dynamic>> subjects,
    required List<Map<String, dynamic>> gradingSystem,
    int classStudentCount = 0,
  }) {
    final subjectMap = <String, Map<String, dynamic>>{};
    for (final s in subjects) {
      subjectMap[s['id'].toString()] = s;
    }

    // Group scores by subject
    final subjectScoreGroups = <String, List<double>>{};
    for (final score in scores) {
      final subjectId = score['subject_id']?.toString() ?? '';
      final total = (score['total'] as num?)?.toDouble() ?? 0.0;
      subjectScoreGroups.putIfAbsent(subjectId, () => []);
      subjectScoreGroups[subjectId]!.add(total);
    }

    final analysis = <Map<String, dynamic>>[];

    for (final entry in subjectScoreGroups.entries) {
      final subjectId = entry.key;
      final scoreList = entry.value;
      scoreList.sort((a, b) => b.compareTo(a));

      final totalStudents = classStudentCount > 0 ? classStudentCount : scoreList.length;
      final highest = scoreList.isNotEmpty ? scoreList.first : 0.0;
      final lowest = scoreList.isNotEmpty ? scoreList.last : 0.0;
      final sum = scoreList.fold<double>(0.0, (a, b) => a + b);
      final average = scoreList.isNotEmpty ? sum / scoreList.length : 0.0;

      // Count pass/fail based on grading system (pass = grade not F9 or not F)
      int passCount = 0;
      int failCount = 0;
      for (final s in scoreList) {
        final grade = computeGrade(s, gradingSystem);
        if (grade == 'F9' || grade == 'F') {
          failCount++;
        } else {
          passCount++;
        }
      }

      final passPercentage = totalStudents > 0 ? (passCount / totalStudents) * 100 : 0.0;

      // Grade distribution
      final gradeDistribution = <String, int>{};
      for (final s in scoreList) {
        final grade = computeGrade(s, gradingSystem);
        gradeDistribution[grade] = (gradeDistribution[grade] ?? 0) + 1;
      }

      analysis.add({
        'subject_id': subjectId,
        'subject_name': subjectMap[subjectId]?['name'] ?? '',
        'subject_code': subjectMap[subjectId]?['code'] ?? '',
        'total_scored': sum,
        'highest': highest,
        'lowest': lowest,
        'average': average,
        'students_scored': scoreList.length,
        'total_students': totalStudents,
        'pass_count': passCount,
        'fail_count': failCount,
        'pass_percentage': passPercentage,
        'grade_distribution': gradeDistribution,
      });
    }

    // Sort by subject name
    analysis.sort((a, b) =>
      ((a['subject_name'] as String?) ?? '').compareTo((b['subject_name'] as String?) ?? ''),
    );

    return analysis;
  }

  // =========================================================
  // BEHAVIORAL RATING HELPERS
  // =========================================================

  /// Validate behavioral rating value against allowed options.
  static bool isValidBehavioralRating(String value, {List<String>? allowedValues}) {
    if (value.trim().isEmpty) return true; // Empty is allowed (optional field)
    final defaults = ['Excellent', 'Very Good', 'Good', 'Fair', 'Poor'];
    final allowed = allowedValues ?? defaults;
    return allowed.contains(value.trim());
  }

  /// Get default behavioral rating options.
  static List<String> get defaultBehavioralOptions => [
    'Excellent',
    'Very Good',
    'Good',
    'Fair',
    'Poor',
  ];

  /// Get all behavioral rating field keys.
  static List<String> get behavioralFieldKeys => [
    'conduct',
    'attitude',
    'interest',
    'punctuality',
  ];

  // =========================================================
  // PRIVATE HELPERS
  // =========================================================

  /// Compute class-level statistics from broadsheet rows.
  static Map<String, dynamic> _computeClassStatistics(
    List<Map<String, dynamic>> rows,
    List<Map<String, dynamic>> gradingSystem,
  ) {
    if (rows.isEmpty) {
      return {
        'class_highest': 0.0,
        'class_lowest': 0.0,
        'class_average': 0.0,
        'total_students': 0,
        'pass_count': 0,
        'fail_count': 0,
        'pass_percentage': 0.0,
      };
    }

    final totals = rows.map((r) => (r['total_score'] as num?)?.toDouble() ?? 0.0).toList()
      ..sort((a, b) => b.compareTo(a));

    final highest = totals.first;
    final lowest = totals.last;
    final sum = totals.fold<double>(0.0, (a, b) => a + b);
    final average = sum / totals.length;

    // Pass = overall grade not F9 or F
    int passCount = 0;
    int failCount = 0;
    for (final t in totals) {
      final grade = computeGrade(t, gradingSystem);
      if (grade == 'F9' || grade == 'F') {
        failCount++;
      } else {
        passCount++;
      }
    }

    return {
      'class_highest': highest,
      'class_lowest': lowest,
      'class_average': average,
      'total_students': rows.length,
      'pass_count': passCount,
      'fail_count': failCount,
      'pass_percentage': rows.length > 0 ? (passCount / rows.length) * 100 : 0.0,
    };
  }
}
