import 'teacher_base.dart';
import 'teacher_classes_mixin.dart';
import 'teacher_scores_mixin.dart';
import 'teacher_attendance_mixin.dart';
import 'teacher_cbt_mixin.dart';

class TeacherProvider extends TeacherBase
    with
        TeacherClassesMixin,
        TeacherScoresMixin,
        TeacherAttendanceMixin,
        TeacherCbtMixin {

  @override
  Future<void> loadTeacherData() async {
    await super.loadTeacherData();
    await loadMyScores();
  }

  /// Returns the current active academic session ID.
  String? get currentSessionId {
    final t = terms;
    if (t.isNotEmpty) {
      final current = t.cast<Map<String, dynamic>>().where((term) => term['is_current'] == true);
      if (current.isNotEmpty) return current.first['id']?.toString();
    }
    if (t.isNotEmpty) return t.first['id']?.toString();
    return null;
  }
}
