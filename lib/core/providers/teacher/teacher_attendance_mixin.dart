// ==========================================
// File: lib/core/providers/teacher/teacher_attendance_mixin.dart
// ==========================================
import 'package:supabase_flutter/supabase_flutter.dart';
import 'teacher_base.dart';

mixin TeacherAttendanceMixin on TeacherBase {

  /// Guard: only allow attendance operations for classes this teacher is assigned to.
  bool _canAccessClass(String classId) {
    return assignedClassIds.contains(classId);
  }

  Future<bool> markAttendance({
    required String classId,
    required String date,
    required List<Map<String, dynamic>> records,
  }) async {
    if (currentSession == null || currentTerm == null) return false;
    if (!_canAccessClass(classId)) {
      print('Attendance blocked: teacher not assigned to class $classId');
      return false;
    }
    const valid = {'present', 'absent', 'late', 'excused'};
    for (final r in records) {
      if (!valid.contains((r['status'] ?? '').toString().toLowerCase())) {
        throw Exception('Invalid status: ${r['status']}');
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
        'status': r['status'].toString().toLowerCase(),
        'remark': r['remark'],
        'recorded_by': teacherId,
      }).toList();
      await Supabase.instance.client
          .from('attendance')
          .upsert(rows, onConflict: 'student_id,class_id,session_id,term_id,date');
      return true;
    } catch (e) {
      print('Error marking attendance: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceForClass({
    required String classId,
    required String date,
  }) async {
    if (currentSession == null || currentTerm == null) return [];
    if (!_canAccessClass(classId)) return [];
    try {
      return List<Map<String, dynamic>>.from(
        await Supabase.instance.client
            .from('attendance')
            .select('*, students(id, first_name, last_name, admission_no)')
            .eq('school_id', schoolId)
            .eq('class_id', classId)
            .eq('session_id', currentSession!['id'])
            .eq('term_id', currentTerm!['id'])
            .eq('date', date),
      );
    } catch (e) {
      print('Error fetching attendance: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getClassAttendanceSummary({
    required String classId,
  }) async {
    if (currentSession == null || currentTerm == null) return [];
    if (!_canAccessClass(classId)) return [];
    try {
      final r = await Supabase.instance.client
          .from('attendance')
          .select('student_id, status, students(first_name, last_name, admission_no)')
          .eq('school_id', schoolId)
          .eq('class_id', classId)
          .eq('session_id', currentSession!['id'])
          .eq('term_id', currentTerm!['id']);

      final m = <String, Map<String, dynamic>>{};
      for (final x in r) {
        final sid = x['student_id']?.toString() ?? '';
        final st = x['students'] as Map<String, dynamic>? ?? {};
        final status = (x['status'] as String?)?.toLowerCase() ?? '';
        if (!m.containsKey(sid)) {
          m[sid] = {
            'student_id': sid,
            'first_name': st['first_name'] ?? '',
            'last_name': st['last_name'] ?? '',
            'admission_no': st['admission_no'] ?? '',
            'present': 0,
            'absent': 0,
            'late': 0,
            'excused': 0,
            'total_days': 0,
          };
        }
        m[sid]!['total_days'] = m[sid]!['total_days'] + 1;
        if (m[sid]!.containsKey(status)) {
          m[sid]![status] = m[sid]![status] + 1;
        }
      }
      return m.values.toList()
        ..sort((a, b) => (a['last_name'] as String).compareTo(b['last_name'] as String));
    } catch (e) {
      print('Error fetching attendance summary: $e');
      return [];
    }
  }
}
