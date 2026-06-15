import 'teacher_base.dart';
import '../../services/db_proxy.dart';

mixin TeacherScoresMixin on TeacherBase {
  List<Map<String, dynamic>> _myScores = [];
  List<Map<String, dynamic>> get myScores => _myScores;
  List<Map<String, dynamic>> get scores => _myScores;

  Future<void> loadMyScores() async {
    if (currentSession == null || currentTerm == null) {
      _myScores = [];
      return;
    }
    try {
      final assignments = assignedSubjects;
      if (assignments.isEmpty) {
        _myScores = [];
        return;
      }

      final classIds = <String>{};
      final subjectIds = <String>{};
      for (final a in assignments) {
        final cid = a['class_id']?.toString() ?? '';
        final sid = a['subject_id']?.toString() ?? '';
        if (cid.isNotEmpty) classIds.add(cid);
        if (sid.isNotEmpty) subjectIds.add(sid);
      }

      final r = await DbProxy.instance
          .from('scores')
          .select('*, students(id, first_name, last_name, admission_no), subjects(name, code)')
          .eq('school_id', schoolId)
          .eq('session_id', currentSession!['id'])
          .eq('term_id', currentTerm!['id'])
          .inFilter('class_id', classIds.toList())
          .inFilter('subject_id', subjectIds.toList())
          .get();

      _myScores = r;
      notifyListeners();
    } catch (e) {
      print('Error loading scores: $e');
      _myScores = [];
    }
  }

  Future<bool> saveScore(Map<String, dynamic> data) async {
    try {
      final row = Map<String, dynamic>.from(data);
      row['school_id'] = schoolId;
      row['recorded_by'] = teacherId;
      await DbProxy.instance.from('scores').upsert(row);
      await loadMyScores();
      return true;
    } catch (e) {
      print('Error saving score: $e');
      return false;
    }
  }

  @override
  Map<String, dynamic>? getExistingScore(String studentId, String subjectId) {
    if (currentSession == null || currentTerm == null) return null;
    try {
      return _myScores.firstWhere(
        (s) =>
            s['student_id']?.toString() == studentId &&
            s['subject_id']?.toString() == subjectId &&
            s['session_id']?.toString() == currentSession!['id']?.toString() &&
            s['term_id']?.toString() == currentTerm!['id']?.toString(),
        orElse: () => <String, dynamic>{},
      );
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> getScoresForClassSubject(String classId, String subjectId) {
    return _myScores.where((s) =>
        s['class_id']?.toString() == classId &&
        s['subject_id']?.toString() == subjectId).toList();
  }
}
