import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_provider.dart';

mixin AdminAuthMixin on BaseProvider {
  Future<bool> changeAdminPassword(String currentPassword, String newPassword) async {
    try {
      final r = await Supabase.instance.client.from('schools')
          .select('id, admin_password')
          .eq('id', schoolId)
          .eq('admin_password', currentPassword)
          .maybeSingle();

      if (r == null) {
        throw Exception('Current password is incorrect');
      }

      await Supabase.instance.client.from('schools')
          .update({'admin_password': newPassword})
          .eq('id', schoolId);

      logAudit(action: 'change_password', tableName: 'schools', recordId: schoolId);

      return true;
    } catch (e) {
      print('Error changing admin password: $e');
      return false;
    }
  }

  Future<bool> resetTeacherPassword(String teacherId, String newPassword) async {
    try {
      await Supabase.instance.client.from('teachers')
          .update({'password': newPassword})
          .eq('id', teacherId)
          .eq('school_id', schoolId);

      final i = teachers.indexWhere((t) => t['id'].toString() == teacherId);
      if (i != -1) {
        teachers[i] = Map<String, dynamic>.from(teachers[i]);
        teachers[i]['password'] = newPassword;
      }

      logAudit(action: 'reset_password', tableName: 'teachers', recordId: teacherId);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error resetting teacher password: $e');
      return false;
    }
  }

  Future<bool> resetStudentPin(String studentId, String newPin) async {
    try {
      await Supabase.instance.client.from('students')
          .update({'pin': newPin})
          .eq('id', studentId)
          .eq('school_id', schoolId);

      final i = students.indexWhere((s) => s['id'].toString() == studentId);
      if (i != -1) {
        students[i] = Map<String, dynamic>.from(students[i]);
        students[i]['pin'] = newPin;
      }

      logAudit(action: 'reset_pin', tableName: 'students', recordId: studentId);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error resetting student PIN: $e');
      return false;
    }
  }
}
