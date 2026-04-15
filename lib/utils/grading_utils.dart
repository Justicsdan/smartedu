/// Pure utility functions for grading computation.
/// No state, no DB calls — just grading logic on in-memory data.
///
/// Supports both static templates (WAEC, BECE, etc.) and dynamic
/// grading systems loaded from school_settings.grading_system JSONB.

class GradingUtils {

  // =========================================================
  // BEHAVIORAL RATING FIELDS (Nigerian Standard — 11 Ratings)
  // Used on report cards per student per term (NOT per-subject).
  // Entered by form teacher when publishing results.
  // =========================================================

  /// DB column names for the 11 Nigerian standard behavioral ratings.
  static const List<String> behavioralFieldKeys = [
    'punctuality',
    'relationship_with_others',
    'attendance_in_class',
    'games_sports',
    'attentiveness_in_class',
    'handling_tools_lab_workshops',
    'carrying_out_assignments',
    'participation_in_school_activities',
    'neatness',
    'honesty',
    'self_control',
  ];

  /// Rating options for each behavioral field.
  static const List<Map<String, dynamic>> defaultBehavioralOptions = [
    {'value': 'Excellent', 'label': 'Excellent'},
    {'value': 'Very Good', 'label': 'Very Good'},
    {'value': 'Good', 'label': 'Good'},
    {'value': 'Fair', 'label': 'Fair'},
    {'value': 'Poor', 'label': 'Poor'},
  ];

  /// Human-readable labels for display on result sheets.
  /// Keys match the DB column names exactly.
  static const Map<String, String> behavioralFieldLabels = {
    'punctuality': 'Punctuality',
    'relationship_with_others': 'Relationship with Others',
    'attendance_in_class': 'Attendance in Class',
    'games_sports': 'Games/Sports',
    'attentiveness_in_class': 'Attentiveness in Class',
    'handling_tools_lab_workshops': 'Handling of Tools, Lab. & Workshops',
    'carrying_out_assignments': 'Carrying out Assignments',
    'participation_in_school_activities': 'Participation in School Activities',
    'neatness': 'Neatness',
    'honesty': 'Honesty',
    'self_control': 'Self-Control',
  };

  /// Get the display label for a behavioral field key.
  static String getBehavioralFieldLabel(String key) {
    return behavioralFieldLabels[key] ?? key;
  }

  // =========================================================
  // STATIC TEMPLATES (Hardcoded, backward compatible)
  // =========================================================

  /// WAEC Grading Logic (Senior Secondary)
  static Map<String, dynamic> getWaecGrade(int score) {
    if (score >= 75) return {"grade": "A1", "meaning": "Excellent", "isCredit": true};
    if (score >= 70) return {"grade": "B2", "meaning": "Very Good", "isCredit": true};
    if (score >= 65) return {"grade": "B3", "meaning": "Good", "isCredit": true};
    if (score >= 60) return {"grade": "C4", "meaning": "Credit", "isCredit": true};
    if (score >= 55) return {"grade": "C5", "meaning": "Credit", "isCredit": true};
    if (score >= 50) return {"grade": "C6", "meaning": "Credit", "isCredit": true};
    if (score >= 45) return {"grade": "D7", "meaning": "Pass", "isCredit": false};
    if (score >= 40) return {"grade": "E8", "meaning": "Pass", "isCredit": false};
    return {"grade": "F9", "meaning": "Fail", "isCredit": false};
  }

  /// BECE Grading Logic (Junior Secondary)
  static Map<String, dynamic> getBeceGrade(int score) {
    if (score >= 70) return {"grade": "A", "meaning": "Distinction", "isCredit": true};
    if (score >= 60) return {"grade": "B", "meaning": "Upper Credit", "isCredit": true};
    if (score >= 50) return {"grade": "C", "meaning": "Lower Credit", "isCredit": true};
    if (score >= 45) return {"grade": "P", "meaning": "Pass", "isCredit": false};
    return {"grade": "F", "meaning": "Fail", "isCredit": false};
  }

  /// NECO Grading Logic (Senior Secondary — alternative)
  static Map<String, dynamic> getNecoGrade(int score) {
    if (score >= 75) return {"grade": "A1", "meaning": "Excellent", "isCredit": true};
    if (score >= 70) return {"grade": "B2", "meaning": "Very Good", "isCredit": true};
    if (score >= 65) return {"grade": "B3", "meaning": "Good", "isCredit": true};
    if (score >= 60) return {"grade": "C4", "meaning": "Credit", "isCredit": true};
    if (score >= 55) return {"grade": "C5", "meaning": "Credit", "isCredit": true};
    if (score >= 50) return {"grade": "C6", "meaning": "Credit", "isCredit": true};
    if (score >= 45) return {"grade": "D7", "meaning": "Pass", "isCredit": false};
    if (score >= 40) return {"grade": "E8", "meaning": "Pass", "isCredit": false};
    return {"grade": "F9", "meaning": "Fail", "isCredit": false};
  }

  /// Cambridge IGCSE Grading Logic
  static Map<String, dynamic> getIgcseGrade(int score) {
    if (score >= 90) return {"grade": "A*", "meaning": "Outstanding", "isCredit": true};
    if (score >= 80) return {"grade": "A", "meaning": "Excellent", "isCredit": true};
    if (score >= 70) return {"grade": "B", "meaning": "Very Good", "isCredit": true};
    if (score >= 60) return {"grade": "C", "meaning": "Good", "isCredit": true};
    if (score >= 50) return {"grade": "D", "meaning": "Satisfactory", "isCredit": false};
    if (score >= 40) return {"grade": "E", "meaning": "Weak", "isCredit": false};
    if (score >= 30) return {"grade": "F", "meaning": "Poor", "isCredit": false};
    return {"grade": "G", "meaning": "Very Poor", "isCredit": false};
  }

  /// Primary School Grading Logic (Simple 5-point)
  static Map<String, dynamic> getPrimaryGrade(int score) {
    if (score >= 90) return {"grade": "5", "meaning": "Excellent", "isCredit": true};
    if (score >= 80) return {"grade": "4", "meaning": "Very Good", "isCredit": true};
    if (score >= 70) return {"grade": "3", "meaning": "Good", "isCredit": true};
    if (score >= 50) return {"grade": "2", "meaning": "Fair", "isCredit": false};
    return {"grade": "1", "meaning": "Poor", "isCredit": false};
  }

  /// American Grading Logic (GPA-style letter grades)
  static Map<String, dynamic> getAmericanGrade(int score) {
    if (score >= 93) return {"grade": "A", "meaning": "Excellent", "isCredit": true, "point": 4.0};
    if (score >= 90) return {"grade": "A-", "meaning": "Excellent", "isCredit": true, "point": 3.7};
    if (score >= 87) return {"grade": "B+", "meaning": "Very Good", "isCredit": true, "point": 3.3};
    if (score >= 83) return {"grade": "B", "meaning": "Very Good", "isCredit": true, "point": 3.0};
    if (score >= 80) return {"grade": "B-", "meaning": "Good", "isCredit": true, "point": 2.7};
    if (score >= 77) return {"grade": "C+", "meaning": "Good", "isCredit": true, "point": 2.3};
    if (score >= 73) return {"grade": "C", "meaning": "Satisfactory", "isCredit": true, "point": 2.0};
    if (score >= 70) return {"grade": "C-", "meaning": "Satisfactory", "isCredit": true, "point": 1.7};
    if (score >= 67) return {"grade": "D+", "meaning": "Poor", "isCredit": false, "point": 1.3};
    if (score >= 63) return {"grade": "D", "meaning": "Poor", "isCredit": false, "point": 1.0};
    if (score >= 60) return {"grade": "D-", "meaning": "Poor", "isCredit": false, "point": 0.7};
    return {"grade": "F", "meaning": "Fail", "isCredit": false, "point": 0.0};
  }

  // =========================================================
  // DEFAULT GRADING SYSTEMS (For new school setup)
  // =========================================================

  /// Get the full grading system list for a given template name.
  /// Returns list of maps matching the school_settings.grading_system JSONB format.
  static List<Map<String, dynamic>> getDefaultGradingSystem(String template) {
    switch (template.toUpperCase()) {
      case 'WAEC':
        return [
          {"min": 75, "max": 100, "grade": "A1", "remark": "Excellent"},
          {"min": 70, "max": 74, "grade": "B2", "remark": "Very Good"},
          {"min": 65, "max": 69, "grade": "B3", "remark": "Good"},
          {"min": 60, "max": 64, "grade": "C4", "remark": "Credit"},
          {"min": 55, "max": 59, "grade": "C5", "remark": "Credit"},
          {"min": 50, "max": 54, "grade": "C6", "remark": "Credit"},
          {"min": 45, "max": 49, "grade": "D7", "remark": "Pass"},
          {"min": 40, "max": 44, "grade": "E8", "remark": "Pass"},
          {"min": 0, "max": 39, "grade": "F9", "remark": "Fail"},
        ];
      case 'BECE':
        return [
          {"min": 70, "max": 100, "grade": "A", "remark": "Distinction"},
          {"min": 60, "max": 69, "grade": "B", "remark": "Upper Credit"},
          {"min": 50, "max": 59, "grade": "C", "remark": "Lower Credit"},
          {"min": 45, "max": 49, "grade": "P", "remark": "Pass"},
          {"min": 0, "max": 44, "grade": "F", "remark": "Fail"},
        ];
      case 'NECO':
        return [
          {"min": 75, "max": 100, "grade": "A1", "remark": "Excellent"},
          {"min": 70, "max": 74, "grade": "B2", "remark": "Very Good"},
          {"min": 65, "max": 69, "grade": "B3", "remark": "Good"},
          {"min": 60, "max": 64, "grade": "C4", "remark": "Credit"},
          {"min": 55, "max": 59, "grade": "C5", "remark": "Credit"},
          {"min": 50, "max": 54, "grade": "C6", "remark": "Credit"},
          {"min": 45, "max": 49, "grade": "D7", "remark": "Pass"},
          {"min": 40, "max": 44, "grade": "E8", "remark": "Pass"},
          {"min": 0, "max": 39, "grade": "F9", "remark": "Fail"},
        ];
      case 'IGCSE':
        return [
          {"min": 90, "max": 100, "grade": "A*", "remark": "Outstanding"},
          {"min": 80, "max": 89, "grade": "A", "remark": "Excellent"},
          {"min": 70, "max": 79, "grade": "B", "remark": "Very Good"},
          {"min": 60, "max": 69, "grade": "C", "remark": "Good"},
          {"min": 50, "max": 59, "grade": "D", "remark": "Satisfactory"},
          {"min": 40, "max": 49, "grade": "E", "remark": "Weak"},
          {"min": 30, "max": 39, "grade": "F", "remark": "Poor"},
          {"min": 0, "max": 29, "grade": "G", "remark": "Very Poor"},
        ];
      case 'PRIMARY':
        return [
          {"min": 90, "max": 100, "grade": "5", "remark": "Excellent"},
          {"min": 80, "max": 89, "grade": "4", "remark": "Very Good"},
          {"min": 70, "max": 79, "grade": "3", "remark": "Good"},
          {"min": 50, "max": 69, "grade": "2", "remark": "Fair"},
          {"min": 0, "max": 49, "grade": "1", "remark": "Poor"},
        ];
      case 'AMERICAN':
        return [
          {"min": 93, "max": 100, "grade": "A", "remark": "Excellent", "point": 4.0},
          {"min": 90, "max": 92, "grade": "A-", "remark": "Excellent", "point": 3.7},
          {"min": 87, "max": 89, "grade": "B+", "remark": "Very Good", "point": 3.3},
          {"min": 83, "max": 86, "grade": "B", "remark": "Very Good", "point": 3.0},
          {"min": 80, "max": 82, "grade": "B-", "remark": "Good", "point": 2.7},
          {"min": 77, "max": 79, "grade": "C+", "remark": "Good", "point": 2.3},
          {"min": 73, "max": 76, "grade": "C", "remark": "Satisfactory", "point": 2.0},
          {"min": 70, "max": 72, "grade": "C-", "remark": "Satisfactory", "point": 1.7},
          {"min": 67, "max": 69, "grade": "D+", "remark": "Poor", "point": 1.3},
          {"min": 63, "max": 66, "grade": "D", "remark": "Poor", "point": 1.0},
          {"min": 60, "max": 62, "grade": "D-", "remark": "Poor", "point": 0.7},
          {"min": 0, "max": 59, "grade": "F", "remark": "Fail", "point": 0.0},
        ];
      default:
        return getDefaultGradingSystem('WAEC');
    }
  }

  /// Get list of all available template names.
  static List<String> get availableTemplates => [
    'WAEC',
    'BECE',
    'NECO',
    'IGCSE',
    'PRIMARY',
    'AMERICAN',
  ];

  /// Get a human-readable label for a template.
  static String getTemplateLabel(String template) {
    switch (template.toUpperCase()) {
      case 'WAEC': return 'WAEC (Senior Secondary)';
      case 'BECE': return 'BECE (Junior Secondary)';
      case 'NECO': return 'NECO (Senior Secondary)';
      case 'IGCSE': return 'Cambridge IGCSE';
      case 'PRIMARY': return 'Primary School (5-Point)';
      case 'AMERICAN': return 'American GPA System';
      default: return template;
    }
  }

  // =========================================================
  // DYNAMIC GRADING (From school_settings JSONB)
  // =========================================================

  /// Compute grade from a dynamic grading system list.
  /// This is the PRIMARY method used by ResultUtils and score entry.
  /// gradingSystem format: [{"min":75,"max":100,"grade":"A1","remark":"Excellent"}, ...]
  static Map<String, dynamic> getGradeFromSystem(double score, List<Map<String, dynamic>> gradingSystem) {
    if (gradingSystem.isEmpty) {
      // Fallback to WAEC if no system configured
      return getWaecGrade(score.round());
    }

    for (final g in gradingSystem) {
      final min = (g['min'] as num?)?.toDouble() ?? 0;
      final max = (g['max'] as num?)?.toDouble() ?? 0;
      if (score >= min && score <= max) {
        return {
          'grade': (g['grade'] ?? '').toString(),
          'meaning': (g['remark'] ?? g['meaning'] ?? '').toString(),
          'remark': (g['remark'] ?? g['meaning'] ?? '').toString(),
          'isCredit': _isCreditGrade((g['grade'] ?? '').toString(), gradingSystem),
          'point': g['point'], // For GPA systems, null otherwise
        };
      }
    }

    // Score below all ranges — return lowest grade
    if (gradingSystem.isNotEmpty) {
      final lowest = gradingSystem.last;
      return {
        'grade': (lowest['grade'] ?? 'F').toString(),
        'meaning': (lowest['remark'] ?? 'Fail').toString(),
        'remark': (lowest['remark'] ?? 'Fail').toString(),
        'isCredit': false,
        'point': lowest['point'],
      };
    }

    return getWaecGrade(score.round());
  }

  /// Grade string only from dynamic system.
  static String getGradeOnly(double score, List<Map<String, dynamic>> gradingSystem) {
    final result = getGradeFromSystem(score, gradingSystem);
    return result['grade'] as String;
  }

  /// Remark string only from dynamic system.
  static String getRemarkOnly(double score, List<Map<String, dynamic>> gradingSystem) {
    final result = getGradeFromSystem(score, gradingSystem);
    return result['remark'] as String;
  }

  // =========================================================
  // TIER-AWARE GETTERS (Per class tier: SSS, JSS, PRIMARY)
  // =========================================================

  /// Get the correct grading system for a class tier.
  /// Checks school_settings for tier-specific override first,
  /// then falls back to the default grading_system column,
  /// then falls back to hardcoded template defaults.
  ///
  /// schoolSettings = the school_settings row as a Map.
  /// tier = 'SSS', 'JSS', or 'PRIMARY'.
  static List<Map<String, dynamic>> getGradingSystemForTier(
    String tier,
    Map<String, dynamic> schoolSettings,
  ) {
    // Grading standard override: American uses same grades for all tiers
    final standard = (schoolSettings['grading_standard'] ?? '').toString().toLowerCase();
    if (standard == 'american') {
      return getDefaultGradingSystem('AMERICAN');
    }
    // Nigerian standard: tier-based
    switch (tier.toUpperCase()) {
      case 'JSS':
        final override = schoolSettings['grading_system_jss'];
        if (override is List && override.isNotEmpty) {
          return List<Map<String, dynamic>>.from(override);
        }
        return getDefaultGradingSystem('BECE');
      case 'PRIMARY':
        final override = schoolSettings['grading_system_primary'];
        if (override is List && override.isNotEmpty) {
          return List<Map<String, dynamic>>.from(override);
        }
        return getDefaultGradingSystem('PRIMARY');
      case 'SSS':
      default:
        final base = schoolSettings['grading_system'];
        if (base is List && base.isNotEmpty) {
          return List<Map<String, dynamic>>.from(base);
        }
        return getDefaultGradingSystem('WAEC');
    }
  }

  /// Get the correct assessment types for a class tier.
  /// Same override → base → fallback pattern as grading system.
  static List<Map<String, dynamic>> getAssessmentTypesForTier(
    String tier,
    Map<String, dynamic> schoolSettings,
  ) {
    // Grading standard override: American uses same assessment for all tiers
    final standard = (schoolSettings['grading_standard'] ?? '').toString().toLowerCase();
    if (standard == 'american') {
      return getDefaultAssessmentTypes('AMERICAN');
    }
    // Nigerian standard: tier-based
    switch (tier.toUpperCase()) {
      case 'JSS':
        final override = schoolSettings['assessment_types_jss'];
        if (override is List && override.isNotEmpty) {
          return List<Map<String, dynamic>>.from(override);
        }
        return getDefaultAssessmentTypes('BECE');
      case 'PRIMARY':
        final override = schoolSettings['assessment_types_primary'];
        if (override is List && override.isNotEmpty) {
          return List<Map<String, dynamic>>.from(override);
        }
        return getDefaultAssessmentTypes('PRIMARY');
      case 'SSS':
      default:
        final base = schoolSettings['assessment_types'];
        if (base is List && base.isNotEmpty) {
          return List<Map<String, dynamic>>.from(base);
        }
        return getDefaultAssessmentTypes('WAEC');
    }
  }

  /// Get the grading template name for a tier.
  /// Used when you need the template string (not the full system).
  static String getTemplateForTier(String tier) {
    switch ((tier ?? '').toUpperCase()) {
      case 'JSS':
      case 'JUNIOR':
        return 'BECE';
      case 'SSS':
      case 'SENIOR':
        return 'WAEC';
      case 'PRIMARY':
        return 'PRIMARY';
      default:
        return 'WAEC';
    }
  }

  // =========================================================
  // SUMMARY COMPUTATION (Pure functions, no DB)
  // =========================================================

  /// Compute a student's term summary from their subject scores.
  /// 
  /// [studentScores] = list of score rows for this student (one per subject).
  ///   Each row must have 'total' (num) and 'grade' (String).
  /// [gradingSystem] = the grading system to use for the overall grade.
  ///
  /// Returns: {total_score, subjects_taken, average_score, grade}
  static Map<String, dynamic> computeStudentSummary({
    required List<Map<String, dynamic>> studentScores,
    required List<Map<String, dynamic>> gradingSystem,
  }) {
    if (studentScores.isEmpty) {
      return {
        'total_score': 0,
        'subjects_taken': 0,
        'average_score': 0.0,
        'grade': '',
      };
    }

    double totalScore = 0;
    for (final sc in studentScores) {
      totalScore += (sc['total'] as num?)?.toDouble() ?? 0;
    }

    final subjectsTaken = studentScores.length;
    final averageScore = subjectsTaken > 0 ? totalScore / subjectsTaken : 0.0;
    final gradeResult = getGradeFromSystem(averageScore, gradingSystem);

    return {
      'total_score': totalScore,
      'subjects_taken': subjectsTaken,
      'average_score': averageScore,
      'grade': gradeResult['grade'] ?? '',
    };
  }

  /// Compute class positions from a list of student summaries.
  /// 
  /// [studentSummaries] = list of maps, each must have:
  ///   'student_id' (String) and 'average_score' (num).
  ///
  /// Returns the same list with 'position' and 'position_out_of' added.
  /// Ties get the same position, next rank skips (1, 2, 2, 4).
  static List<Map<String, dynamic>> computeClassPositions(
    List<Map<String, dynamic>> studentSummaries,
  ) {
    if (studentSummaries.isEmpty) return studentSummaries;

    final sorted = List<Map<String, dynamic>>.from(studentSummaries)
      ..sort((a, b) => ((b['average_score'] as num?)?.toDouble() ?? 0)
          .compareTo((a['average_score'] as num?)?.toDouble() ?? 0));

    final total = sorted.length;
    int pos = 0;
    double? prevAvg;

    for (int i = 0; i < sorted.length; i++) {
      final avg = (sorted[i]['average_score'] as num?)?.toDouble() ?? 0;
      if (avg != prevAvg) {
        pos = i + 1;
        prevAvg = avg;
      }
      sorted[i]['position'] = pos;
      sorted[i]['position_out_of'] = total;
    }

    return sorted;
  }

  /// Count passing and failing subjects from a student's scores.
  /// Returns {passed: int, failed: int, total: int}.
  static Map<String, dynamic> countPassFail(
    List<Map<String, dynamic>> studentScores,
    List<Map<String, dynamic>> gradingSystem,
  ) {
    int passed = 0;
    int failed = 0;
    for (final sc in studentScores) {
      final grade = (sc['grade'] ?? '').toString();
      if (grade.isEmpty) continue;
      if (isPassingGrade(grade, gradingSystem)) {
        passed++;
      } else {
        failed++;
      }
    }
    return {'passed': passed, 'failed': failed, 'total': passed + failed};
  }

  // =========================================================
  // VALIDATION
  // =========================================================

  /// Validate a grading system configuration.
  /// Returns list of error messages. Empty list = valid.
  static List<String> validateGradingSystem(List<Map<String, dynamic>> gradingSystem) {
    final errors = <String>[];

    if (gradingSystem.isEmpty) {
      errors.add('Grading system cannot be empty');
      return errors;
    }

    // Check required fields
    for (int i = 0; i < gradingSystem.length; i++) {
      final g = gradingSystem[i];
      final index = 'Row ${i + 1}';

      if (g['min'] == null) errors.add('$index: Missing minimum score');
      if (g['max'] == null) errors.add('$index: Missing maximum score');
      if ((g['grade'] ?? '').toString().trim().isEmpty) {
        errors.add('$index: Missing grade label');
      }

      // Check types
      if (g['min'] != null && g['min'] is! num) {
        errors.add('$index: Min must be a number');
      }
      if (g['max'] != null && g['max'] is! num) {
        errors.add('$index: Max must be a number');
      }

      // Check ranges
      final min = (g['min'] as num?)?.toDouble() ?? 0;
      final max = (g['max'] as num?)?.toDouble() ?? 0;
      if (min > max) {
        errors.add('$index: Min ($min) cannot be greater than Max ($max)');
      }
      if (min < 0) {
        errors.add('$index: Min cannot be negative');
      }
      if (max > 100) {
        errors.add('$index: Max cannot exceed 100');
      }
    }

    // Check for gaps and overlaps between ranges
    final sorted = List<Map<String, dynamic>>.from(gradingSystem)
      ..sort((a, b) => ((a['min'] as num?)?.toDouble() ?? 0).compareTo((b['min'] as num?)?.toDouble() ?? 0));

    for (int i = 1; i < sorted.length; i++) {
      final prevMax = (sorted[i - 1]['max'] as num?)?.toDouble() ?? 0;
      final currMin = (sorted[i]['min'] as num?)?.toDouble() ?? 0;

      if (currMin > prevMax + 1) {
        errors.add('Gap between ${sorted[i - 1]['grade']} and ${sorted[i]['grade']}: no grades for scores ${prevMax + 1} to ${currMin - 1}');
      }
      if (currMin <= prevMax) {
        errors.add('Overlap between ${sorted[i - 1]['grade']} and ${sorted[i]['grade']}: ranges overlap at $currMin');
      }
    }

    // Check first row starts at 0
    final firstMin = (sorted.first['min'] as num?)?.toDouble() ?? 0;
    if (firstMin > 0) {
      errors.add('No grade defined for scores 0 to ${firstMin - 1}');
    }

    // Check last row ends at 100
    final lastMax = (sorted.last['max'] as num?)?.toDouble() ?? 0;
    if (lastMax < 100) {
      errors.add('No grade defined for scores ${lastMax + 1} to 100');
    }

    // Check for duplicate grade labels
    final grades = gradingSystem.map((g) => (g['grade'] ?? '').toString().trim()).toList();
    final seen = <String>{};
    for (final grade in grades) {
      if (grade.isNotEmpty && seen.contains(grade)) {
        errors.add('Duplicate grade label: "$grade"');
      }
      seen.add(grade);
    }

    return errors;
  }

  // =========================================================
  // GPA & POINT SYSTEMS
  // =========================================================

  /// Calculate GPA from a list of grades using a grading system with points.
  /// Returns GPA on 4.0 scale (or whatever scale the system uses).
  static double calculateGpa(List<Map<String, dynamic>> gradesWithPoints) {
    if (gradesWithPoints.isEmpty) return 0.0;
    double totalPoints = 0;
    int count = 0;
    for (final g in gradesWithPoints) {
      final point = (g['point'] as num?)?.toDouble() ?? 0;
      totalPoints += point;
      count++;
    }
    return count > 0 ? totalPoints / count : 0.0;
  }

  /// Calculate weighted GPA (subjects can have different credit units).
  static double calculateWeightedGpa(List<Map<String, dynamic>> gradesWithPointsAndUnits) {
    double totalWeightedPoints = 0;
    double totalUnits = 0;
    for (final g in gradesWithPointsAndUnits) {
      final point = (g['point'] as num?)?.toDouble() ?? 0;
      final unit = (g['credit_unit'] as num?)?.toDouble() ?? 1;
      totalWeightedPoints += point * unit;
      totalUnits += unit;
    }
    return totalUnits > 0 ? totalWeightedPoints / totalUnits : 0.0;
  }

  // =========================================================
  // GRADE HELPERS
  // =========================================================

  /// Determine if a grade is a passing grade.
  /// Pass = grade is not F9, F, G, or 1 (depending on system).
  static bool isPassingGrade(String grade, List<Map<String, dynamic>> gradingSystem) {
    if (grade.isEmpty) return false;

    // For systems with explicit isCredit/pass thresholds
    final failGrades = _getFailGrades(gradingSystem);
    return !failGrades.contains(grade);
  }

  /// Get the passing threshold score from a grading system.
  /// Returns the minimum score of the lowest passing grade.
  static int getPassingThreshold(List<Map<String, dynamic>> gradingSystem) {
    if (gradingSystem.isEmpty) return 50; // Default fallback

    final failGrades = _getFailGrades(gradingSystem);

    for (final g in gradingSystem) {
      final grade = (g['grade'] ?? '').toString();
      if (!failGrades.contains(grade)) {
        return (g['min'] as num?)?.toInt() ?? 50;
      }
    }

    return 50;
  }

  /// Sort a list of grades by value (highest first).
  /// Useful for determining class position by grade.
  static List<String> sortGradesDescending(List<String> grades, List<Map<String, dynamic>> gradingSystem) {
    final gradeValue = <String, int>{};
    for (int i = 0; i < gradingSystem.length; i++) {
      final grade = (gradingSystem[i]['grade'] ?? '').toString();
      gradeValue[grade] = gradingSystem.length - i; // Higher index = lower value
    }

    final sorted = List<String>.from(grades)
      ..sort((a, b) => (gradeValue[b] ?? 0).compareTo(gradeValue[a] ?? 0));
    return sorted;
  }

  /// Get all distinct grade labels from a grading system.
  static List<String> getAllGradeLabels(List<Map<String, dynamic>> gradingSystem) {
    return gradingSystem.map((g) => (g['grade'] ?? '').toString()).toList();
  }

  // =========================================================
  // ASSESSMENT TYPE HELPERS
  // =========================================================

  /// Default assessment types for common templates.
  /// BECE uses CA + Exam (40/60 split), WAEC uses CA1 + CA2 + Assignment + Mid-term + Exam (10+10+10+20+50 split).
  static List<Map<String, dynamic>> getDefaultAssessmentTypes(String template) {
    switch (template.toUpperCase()) {
      case 'BECE':
        return [
          {"id": "ca", "name": "CA", "max": 40},
          {"id": "exam", "name": "Exam", "max": 60},
        ];
      case 'PRIMARY':
        return [
          {"id": "ca1", "name": "CA1", "max": 20},
          {"id": "ca2", "name": "CA2", "max": 20},
          {"id": "exam", "name": "Exam", "max": 60},
        ];
      case 'AMERICAN':
        return [
          {"id": "assignment", "name": "Assignments", "max": 15},
          {"id": "quiz", "name": "Quizzes", "max": 15},
          {"id": "midterm", "name": "Mid-term", "max": 20},
          {"id": "participation", "name": "Participation", "max": 10},
          {"id": "exam", "name": "Final Exam", "max": 40},
        ];
      case 'WAEC':
      case 'NECO':
      case 'IGCSE':
      default:
        return [
          {"id": "ca1", "name": "CA1", "max": 10},
          {"id": "ca2", "name": "CA2", "max": 10},
          {"id": "assignment", "name": "Assignment", "max": 10},
          {"id": "midterm", "name": "Mid-term", "max": 20},
          {"id": "exam", "name": "Exam", "max": 50},
        ];
    }
  }

  /// Validate that assessment type max scores add up to expected total.
  static Map<String, dynamic> validateAssessmentTypes(
    List<Map<String, dynamic>> assessmentTypes, {
    int expectedTotal = 100,
  }) {
    int sum = 0;
    final errors = <String>[];

    if (assessmentTypes.isEmpty) {
      return {'valid': false, 'sum': 0, 'errors': ['Assessment types cannot be empty']};
    }

    for (int i = 0; i < assessmentTypes.length; i++) {
      final at = assessmentTypes[i];
      final max = (at['max'] as num?)?.toInt() ?? 0;
      final name = (at['name'] ?? at['id'] ?? 'Item ${i + 1}').toString();

      if (max <= 0) {
        errors.add('$name: Max score must be greater than 0');
      }
      if (name.trim().isEmpty) {
        errors.add('Item ${i + 1}: Missing name');
      }
      sum += max;
    }

    if (sum != expectedTotal) {
      errors.add('Total of all assessments ($sum) does not equal $expectedTotal');
    }

    return {
      'valid': errors.isEmpty,
      'sum': sum,
      'errors': errors,
    };
  }

  // =========================================================
  // PRIVATE HELPERS
  // =========================================================

  /// Determine if a grade is a credit/pass grade within a system.
  static bool _isCreditGrade(String grade, List<Map<String, dynamic>> gradingSystem) {
    // Heuristic: last 1-2 grades in the system are usually fail
    if (gradingSystem.isEmpty) return true;
    final failGrades = _getFailGrades(gradingSystem);
    return !failGrades.contains(grade);
  }

  /// Get all fail-grade labels from a grading system.
  /// Assumes the last grade in the sorted system is always a fail,
  /// and any grade with "Fail" or "Very Poor" in its remark is also a fail.
  static List<String> _getFailGrades(List<Map<String, dynamic>> gradingSystem) {
    if (gradingSystem.isEmpty) return ['F', 'F9', 'G', '1'];

    final fails = <String>[];
    for (final g in gradingSystem) {
      final remark = (g['remark'] ?? g['meaning'] ?? '').toString().toLowerCase();
      final grade = (g['grade'] ?? '').toString();
      if (remark.contains('fail') || remark.contains('very poor')) {
        fails.add(grade);
      }
    }

    // Always include the last grade as fail if no fail was detected
    if (fails.isEmpty) {
      fails.add((gradingSystem.last['grade'] ?? 'F').toString());
    }

    return fails;
  }
}
