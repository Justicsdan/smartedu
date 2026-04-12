import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_base.dart';

/// Student attendance mixin.
/// Provides attendance data for the logged-in student.
/// All queries are scoped by schoolId + studentId + session + term.
///
/// MASTER PLAN:
/// - Student can ONLY see their own attendance (RLS enforces this)
/// - Uses parsed UUID strings from StudentBase, not nested map access
/// - Provides summaries, percentages, and breakdowns for result sheets
/// - No platform branding — attendance belongs to the school
/// - V4: Fixed Postgrest v2 `var query` type constraint crash

mixin StudentAttendanceMixin on StudentBase {

  // ==========================================
  // ATTENDANCE SUMMARY
  // ==========================================

  Future<Map<String, int>> getMyAttendanceSummary() async {
    if (currentSessionId == null || currentTermId == null) {
      return {'present': 0, 'absent': 0, 'late': 0, 'excused': 0, 'total_days': 0};
    }

    try {
      final r = await supabase
          .from('attendance')
          .select('status')
          .eq('school_id', schoolId)
          .eq('student_id', studentId)
          .eq('session_id', currentSessionId!)
          .eq('term_id', currentTermId!);

      final summary = <String, int>{
        'present': 0, 'absent': 0, 'late': 0, 'excused': 0, 'total_days': r.length,
      };

      for (final x in r) {
        final status = (x['status'] as String?)?.toLowerCase() ?? '';
        if (summary.containsKey(status)) {
          summary[status] = summary[status]! + 1;
        }
      }
      return summary;
    } catch (e) {
      debugPrint('Error fetching attendance summary: $e');
      return {'present': 0, 'absent': 0, 'late': 0, 'excused': 0, 'total_days': 0};
    }
  }

  double getAttendancePercentage(Map<String, int> summary) {
    final total = summary['total_days'] ?? 0;
    if (total == 0) return 0.0;
    final present = (summary['present'] ?? 0) + (summary['late'] ?? 0);
    return (present / total) * 100;
  }

  String getAttendanceDisplay() => '${(0.0).toStringAsFixed(0)}% (0/0 days)';

  Future<String> getAttendanceDisplayAsync() async {
    final summary = await getMyAttendanceSummary();
    final total = summary['total_days'] ?? 0;
    if (total == 0) return 'No attendance data';
    final pct = getAttendancePercentage(summary);
    final attended = (summary['present'] ?? 0) + (summary['late'] ?? 0);
    return '$pct% ($attended/$total days)';
  }

  // ==========================================
  // ATTENDANCE HISTORY
  // ==========================================

  Future<List<Map<String, dynamic>>> getMyAttendanceHistory() async {
    if (currentSessionId == null || currentTermId == null) return [];

    try {
      final response = await supabase
          .from('attendance')
          .select('id, date, status, remark')
          .eq('school_id', schoolId)
          .eq('student_id', studentId)
          .eq('session_id', currentSessionId!)
          .eq('term_id', currentTermId!)
          .order('date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching attendance history: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getAttendanceForDate(String date) async {
    if (currentSessionId == null || currentTermId == null || date.isEmpty) return null;

    try {
      return await supabase
          .from('attendance')
          .select('id, date, status, remark, recorded_by')
          .eq('school_id', schoolId)
          .eq('student_id', studentId)
          .eq('session_id', currentSessionId!)
          .eq('term_id', currentTermId!)
          .eq('date', date)
          .maybeSingle();
    } catch (e) {
      debugPrint('Error fetching attendance for date: $e');
      return null;
    }
  }

  /// Get attendance for a date range.
  /// [FIX] Postgrest v2: Changed `var query` to `dynamic query`.
  /// `.order()` returns PostgrestTransformBuilder, but `var` locked the type 
  /// to PostgrestFilterBuilder, causing a strict type crash in Dart.
  Future<List<Map<String, dynamic>>> getAttendanceByDateRange(
    DateTime startDate,
    DateTime endDate, {
    List<String>? statuses,
  }) async {
    if (currentSessionId == null || currentTermId == null) return [];

    try {
      dynamic query = supabase
          .from('attendance')
          .select('id, date, status, remark')
          .eq('school_id', schoolId)
          .eq('student_id', studentId)
          .eq('session_id', currentSessionId!)
          .eq('term_id', currentTermId!)
          .gte('date', startDate.toIso8601String().split('T').first)
          .lte('date', endDate.toIso8601String().split('T').first);

      if (statuses != null && statuses.isNotEmpty) {
        query = query.inFilter('status', statuses);
      }

      query = query.order('date', ascending: false);

      return List<Map<String, dynamic>>.from(await query);
    } catch (e) {
      debugPrint('Error fetching attendance by date range: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMonthlyBreakdown() async {
    if (currentSessionId == null || currentTermId == null) return [];

    try {
      final response = await supabase
          .from('attendance')
          .select('date, status')
          .eq('school_id', schoolId)
          .eq('student_id', studentId)
          .eq('session_id', currentSessionId!)
          .eq('term_id', currentTermId!)
          .order('date', ascending: false);

      final monthlyMap = <String, Map<String, dynamic>>{};

      for (final row in response) {
        final dateStr = row['date'] as String?;
        if (dateStr == null) continue;
        final date = DateTime.tryParse(dateStr);
        if (date == null) continue;

        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        if (!monthlyMap.containsKey(monthKey)) {
          monthlyMap[monthKey] = {
            'month': monthKey,
            'year': date.year,
            'month_num': date.month,
            'month_name': _monthName(date.month),
            'present': 0, 'absent': 0, 'late': 0, 'excused': 0, 'total': 0,
          };
        }

        final status = (row['status'] as String?)?.toLowerCase() ?? '';
        final month = monthlyMap[monthKey]!;
        month['total'] = (month['total'] as int) + 1;
        if (month.containsKey(status)) {
          month[status] = (month[status] as int) + 1;
        }
      }

      final result = monthlyMap.values.toList()
        ..sort((a, b) => (a['month'] as String).compareTo(b['month'] as String));

      return result.map((m) => Map<String, dynamic>.from(m)).toList();
    } catch (e) {
      debugPrint('Error fetching monthly breakdown: $e');
      return [];
    }
  }

  Future<int> getConsecutiveAbsences() async {
    if (currentSessionId == null || currentTermId == null) return 0;

    try {
      final response = await supabase
          .from('attendance')
          .select('date, status')
          .eq('school_id', schoolId)
          .eq('student_id', studentId)
          .eq('session_id', currentSessionId!)
          .eq('term_id', currentTermId!)
          .eq('status', 'absent')
          .order('date', ascending: false);

      if (response.isEmpty) return 0;

      int streak = 1;
      for (int i = 0; i < response.length - 1; i++) {
        final current = DateTime.tryParse(response[i]['date'] as String);
        final next = DateTime.tryParse(response[i + 1]['date'] as String);
        if (current == null || next == null) break;
        if (current.difference(next).inDays == 1) {
          streak++;
        } else {
          break;
        }
      }
      return streak;
    } catch (e) {
      debugPrint('Error calculating absence streak: $e');
      return 0;
    }
  }

  String _monthName(int month) {
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return (month >= 1 && month <= 12) ? months[month] : '';
  }
}
