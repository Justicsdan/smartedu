// ==========================================
// File: lib/core/providers/attendance_mixin.dart
// ==========================================
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_provider.dart';

/// Mixin for attendance marking and reporting.
/// Handles marking, querying summaries, and history retrieval.
///
/// MASTER PLAN V4:
/// - Every operation filters by schoolId + session_id + term_id — tenant isolation
/// - V4: Uses supabase getter from BaseProvider (consistent pattern)
/// - V4: Uses debugPrint instead of print
/// - V4: Fixed dynamic type arithmetic in class summary (caused runtime crash)
/// - V4: Added null safety for student joins
/// - V4: Added utility methods for attendance lookups
/// - V4: Added percentage-based attendance rate calculation
/// - V4: Fixed Map<String, int> type constraint that blocked String values

mixin AttendanceMixin on BaseProvider {

  // ==========================================
  // MARK ATTENDANCE
  // ==========================================

  /// Mark attendance for a class on a specific date.
  /// Uses upsert so re-marking the same date updates rather than duplicates.
  Future<bool> markAttendance({
    required String classId,
    required String date,
    required List<Map<String, dynamic>> records,
    String? recordedBy,
  }) async {
    if (currentSession == null || currentTerm == null) return false;

    const validStatuses = {'present', 'absent', 'late', 'excused'};

    // Validate all records before any DB write
    for (int i = 0; i < records.length; i++) {
      final status = (records[i]['status'] ?? '').toString().toLowerCase();
      if (!validStatuses.contains(status)) {
        debugPrint('Invalid attendance status at row $i: ${records[i]['status']}');
        return false;
      }
    }

    try {
      final rows = records.map((r) => {
        'school_id': schoolId,
        'student_id': r['student_id'],
        'class_id': classId,
        'session_id': currentSession!['id'],
        'term_id': currentTerm!['id'],
        'date': date,
        'status': (r['status'] ?? '').toString().toLowerCase(),
        'remark': r['remark'] ?? '',
        'recorded_by': recordedBy,
      }).toList();

      await supabase
          .from('attendance')
          .upsert(rows, onConflict: 'student_id,class_id,session_id,term_id,date');

      logAudit(
        action: 'mark_attendance',
        tableName: 'attendance',
        newData: {'class_id': classId, 'date': date, 'count': records.length},
      );
      return true;
    } catch (e) {
      debugPrint('Error marking attendance: $e');
      return false;
    }
  }

  // ==========================================
  // QUERIES
  // ==========================================

  /// Get attendance records for a class on a specific date.
  /// Returns records with student info joined.
  Future<List<Map<String, dynamic>>> getAttendanceForClass({
    required String classId,
    required String date,
  }) async {
    if (currentSession == null || currentTerm == null) return [];

    try {
      final r = await supabase
          .from('attendance')
          .select('*, students(id, first_name, last_name, admission_no, passport_url)')
          .eq('school_id', schoolId)
          .eq('class_id', classId)
          .eq('session_id', currentSession!['id'])
          .eq('term_id', currentTerm!['id'])
          .eq('date', date);

      return List<Map<String, dynamic>>.from(r);
    } catch (e) {
      debugPrint('Error fetching class attendance: $e');
      return [];
    }
  }

  /// Get attendance summary counts for a single student.
  /// Returns {present: X, absent: X, late: X, excused: X, total_days: X}.
  Future<Map<String, int>> getAttendanceSummaryForStudent({
    required String studentId,
  }) async {
    if (currentSession == null || currentTerm == null) {
      return _emptySummary();
    }

    try {
      final r = await supabase
          .from('attendance')
          .select('status')
          .eq('school_id', schoolId)
          .eq('student_id', studentId)
          .eq('session_id', currentSession!['id'])
          .eq('term_id', currentTerm!['id']);

      final summary = _emptySummary();
      summary['total_days'] = r.length;

      for (final x in r) {
        final status = (x['status'] as String?)?.toLowerCase() ?? '';
        if (summary.containsKey(status)) {
          summary[status] = summary[status]! + 1;
        }
      }

      return summary;
    } catch (e) {
      debugPrint('Error fetching student attendance summary: $e');
      return _emptySummary();
    }
  }

  /// Get attendance history (date + status) for a single student.
  Future<List<Map<String, dynamic>>> getAttendanceHistoryForStudent({
    required String studentId,
  }) async {
    if (currentSession == null || currentTerm == null) return [];

    try {
      final r = await supabase
          .from('attendance')
          .select('date, status, remark')
          .eq('school_id', schoolId)
          .eq('student_id', studentId)
          .eq('session_id', currentSession!['id'])
          .eq('term_id', currentTerm!['id'])
          .order('date');

      return List<Map<String, dynamic>>.from(r);
    } catch (e) {
      debugPrint('Error fetching student attendance history: $e');
      return [];
    }
  }

  /// Get attendance summary for ALL students in a class.
  /// Returns one row per student with present/absent/late/excused counts.
  /// [FIX] Old code had dynamic type arithmetic crash on `m[sid]!['total_days'] + 1`
  Future<List<Map<String, dynamic>>> getClassAttendanceSummary({
    required String classId,
  }) async {
    if (currentSession == null || currentTerm == null) return [];

    try {
      final r = await supabase
          .from('attendance')
          .select('student_id, status, students(first_name, last_name, admission_no)')
          .eq('school_id', schoolId)
          .eq('class_id', classId)
          .eq('session_id', currentSession!['id'])
          .eq('term_id', currentTerm!['id']);

      // [FIX] Changed from Map<String, Map<String, int>> to Map<String, Map<String, dynamic>>
      // to prevent crash when assigning String values (student_id, names) to an int-only map.
      final Map<String, Map<String, dynamic>> studentMap = {};

      for (final x in r) {
        final sid = (x['student_id'] ?? '').toString();
        final status = (x['status'] as String?)?.toLowerCase() ?? '';

        // Safely extract student info from join
        final studentData = x['students'];
        String firstName = '';
        String lastName = '';
        String admNo = '';
        if (studentData is Map<String, dynamic>) {
          firstName = (studentData['first_name'] ?? '').toString();
          lastName = (studentData['last_name'] ?? '').toString();
          admNo = (studentData['admission_no'] ?? '').toString();
        }

        if (!studentMap.containsKey(sid)) {
          studentMap[sid] = {
            'student_id': sid,
            'first_name': firstName,
            'last_name': lastName,
            'admission_no': admNo,
            'present': 0,
            'absent': 0,
            'late': 0,
            'excused': 0,
            'total_days': 0,
          };
        }

        studentMap[sid]!['total_days'] = (studentMap[sid]!['total_days'] as int) + 1;
        if (studentMap[sid]!.containsKey(status)) {
          studentMap[sid]![status] = (studentMap[sid]![status] as int) + 1;
        }
      }

      // Convert to list and sort by last name
      final result = studentMap.values.map((m) {
        return Map<String, dynamic>.from(m);
      }).toList();

      result.sort((a, b) {
        return (a['last_name'] as String? ?? '')
            .compareTo(b['last_name'] as String? ?? '');
      });

      return result;
    } catch (e) {
      debugPrint('Error fetching class attendance summary: $e');
      return [];
    }
  }

  /// Get attendance for a date range.
  Future<List<Map<String, dynamic>>> getAttendanceForDateRange({
    required String classId,
    required String startDate,
    required String endDate,
  }) async {
    if (currentSession == null || currentTerm == null) return [];

    try {
      final r = await supabase
          .from('attendance')
          .select('*, students(first_name, last_name, admission_no)')
          .eq('school_id', schoolId)
          .eq('class_id', classId)
          .eq('session_id', currentSession!['id'])
          .eq('term_id', currentTerm!['id'])
          .gte('date', startDate)
          .lte('date', endDate)
          .order('date');

      return List<Map<String, dynamic>>.from(r);
    } catch (e) {
      debugPrint('Error fetching date range attendance: $e');
      return [];
    }
  }

  /// Check if attendance has been marked for a class on a specific date.
  Future<bool> isAttendanceMarked({required String classId, required String date}) async {
    if (currentSession == null || currentTerm == null) return false;

    try {
      final r = await supabase
          .from('attendance')
          .select('id')
          .eq('school_id', schoolId)
          .eq('class_id', classId)
          .eq('session_id', currentSession!['id'])
          .eq('term_id', currentTerm!['id'])
          .eq('date', date)
          .limit(1);

      return r.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get list of dates attendance was marked for a class this term.
  Future<List<String>> getMarkedDates({required String classId}) async {
    if (currentSession == null || currentTerm == null) return [];

    try {
      final r = await supabase
          .from('attendance')
          .select('date')
          .eq('school_id', schoolId)
          .eq('class_id', classId)
          .eq('session_id', currentSession!['id'])
          .eq('term_id', currentTerm!['id']);

      return r
          .map((x) => (x['date'] ?? '').toString())
          .toSet()
          .toList()
        ..sort();
    } catch (e) {
      return [];
    }
  }

  // ==========================================
  // UTILITY METHODS
  // ==========================================

  /// Calculate attendance percentage for a student.
  /// Present + Late count as "attended", divided by total days.
  double getAttendanceRate(Map<String, int> summary) {
    final total = summary['total_days'] ?? 0;
    if (total == 0) return 0.0;
    final attended = (summary['present'] ?? 0) + (summary['late'] ?? 0);
    return (attended / total) * 100;
  }

  /// Get attendance status display text with color hint.
  /// Returns map with 'text', 'color' keys for UI rendering.
  Map<String, dynamic> getAttendanceStatusDisplay(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'present':
        return {'text': 'Present', 'color': '#4CAF50', 'icon': 'check_circle'};
      case 'absent':
        return {'text': 'Absent', 'color': '#F44336', 'icon': 'cancel'};
      case 'late':
        return {'text': 'Late', 'color': '#FF9800', 'icon': 'schedule'};
      case 'excused':
        return {'text': 'Excused', 'color': '#2196F3', 'icon': 'info'};
      default:
        return {'text': 'Not Marked', 'color': '#9E9E9E', 'icon': 'help_outline'};
    }
  }

  /// Format attendance rate as percentage string.
  String formatAttendanceRate(double rate) {
    return '${rate.toStringAsFixed(1)}%';
  }

  /// Empty summary map for fallback returns.
  Map<String, int> _emptySummary() {
    return {
      'present': 0,
      'absent': 0,
      'late': 0,
      'excused': 0,
      'total_days': 0,
    };
  }
}
