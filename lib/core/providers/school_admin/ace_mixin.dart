import '../../../../core/services/db_proxy.dart';
import '../base_provider.dart';

mixin AceMixin on BaseProvider {
  List<Map<String, dynamic>> _acePaceScores = [];

  List<Map<String, dynamic>> get acePaceScores => _acePaceScores;

  Future<void> loadAcePaceScoresForStudent(String studentId, String sessionId, String termId) async {
    try {
      final result = await DbProxy.instance
          .from('ace_pace_scores')
          .eq('student_id', studentId)
          .eq('session_id', sessionId)
          .eq('term_id', termId)
          .order('created_at', ascending: true)
          .get();
      _acePaceScores = List<Map<String, dynamic>>.from(result);
    } catch (_) {
      _acePaceScores = [];
    }
  }

  Future<void> savePaceScore({
    required String studentId,
    required String subjectId,
    required String sessionId,
    required String termId,
    required String paceNo,
    required double ptScore,
  }) async {
    final existing = _acePaceScores.where((s) =>
        s['student_id'].toString() == studentId &&
        s['subject_id'].toString() == subjectId &&
        s['pace_no'] == paceNo &&
        s['term_id'].toString() == termId).toList();

    if (existing.isNotEmpty) {
      await DbProxy.instance
          .from('ace_pace_scores')
          .eq('id', existing.first['id'].toString())
          .update({'pace_no': paceNo, 'pt_score': ptScore});
      existing.first['pace_no'] = paceNo;
      existing.first['pt_score'] = ptScore;
    } else {
      final result = await DbProxy.instance.from('ace_pace_scores').insert({
        'school_id': schoolId,
        'student_id': studentId,
        'subject_id': subjectId,
        'session_id': sessionId,
        'term_id': termId,
        'pace_no': paceNo,
        'pt_score': ptScore,
      });
      if (result.isNotEmpty) {
        _acePaceScores.add(Map<String, dynamic>.from(result.first));
      }
    }
  }

  Future<void> deletePaceScore(String scoreId) async {
    await DbProxy.instance.from('ace_pace_scores').eq('id', scoreId).delete();
    _acePaceScores.removeWhere((s) => s['id'].toString() == scoreId);
  }

  double calculateHacs(List<Map<String, dynamic>> scores) {
    final valid = scores.where((s) => s['pt_score'] != null).toList();
    if (valid.isEmpty) return 0;
    final sum = valid.fold<double>(0, (a, s) => a + (s['pt_score'] as num).toDouble());
    return sum / valid.length;
  }

  double calculateNce(double hacs) {
    return ((hacs - 80) / 20 * 21 + 50).clamp(1.0, 99.0);
  }

  Future<Map<String, dynamic>?> generateAceReport({
    required String studentId,
    required String classId,
    required String sessionId,
    required String termId,
    String? teacherComment,
    String? readingProgress,
    double? readingWpm,
    double? readingComposite,
    double? readingComprehension,
    int? daysAbsent,
    String? supervisorComment,
    String? principalComment,
    int? dayInTerm,
  }) async {
    await loadAcePaceScoresForStudent(studentId, sessionId, termId);
    final hacs = calculateHacs(_acePaceScores);
    final nce = calculateNce(hacs);
    final validScores = _acePaceScores.where((s) => s['pt_score'] != null).toList();
    final calcPacesAvg = validScores.isNotEmpty ? validScores.fold<double>(0, (a, s) => a + (s['pt_score'] as num).toDouble()) / validScores.length : 0;
    final calcPacesTotal = validScores.isNotEmpty ? validScores.fold<double>(0, (a, s) => a + (s['pt_score'] as num).toDouble()) : 0;

    final existing = await DbProxy.instance
        .from('ace_term_reports')
        .eq('student_id', studentId)
        .eq('session_id', sessionId)
        .eq('term_id', termId)
        .maybeSingle();

    final data = {
      'school_id': schoolId,
      'student_id': studentId,
      'class_id': classId,
      'session_id': sessionId,
      'term_id': termId,
      'day_in_term': dayInTerm ?? 0,
      'days_absent': daysAbsent ?? 0,
      'teacher_comment': teacherComment,
      'reading_progress': readingProgress,
      'reading_wpm': readingWpm ?? 0,
      'reading_composite': readingComposite ?? 0,
      'reading_comprehension': readingComprehension ?? 0,
      'paces_completed': validScores.length,
      'paces_avg': calcPacesAvg,
      'paces_total': calcPacesTotal,
      'hacs_score': hacs,
      'nce_score': nce,
      'total_score': hacs,
      'supervisor_comment': supervisorComment,
      'principal_comment': principalComment,
    };

    if (existing != null) {
      final r = await DbProxy.instance.from('ace_term_reports').eq('id', existing['id'].toString()).update(data);
      return r.isNotEmpty ? r.first : null;
    } else {
      final r = await DbProxy.instance.from('ace_term_reports').insert(data);
      return r.isNotEmpty ? r.first : null;
    }
  }

  Future<void> publishAceReport(String studentId, String sessionId, String termId) async {
    await DbProxy.instance
        .from('ace_term_reports')
        .eq('student_id', studentId)
        .eq('session_id', sessionId)
        .eq('term_id', termId)
        .update({'is_published': true, 'published_at': DateTime.now().toIso8601String()});
  }

  Future<Map<String, dynamic>?> getAceReport(String studentId, String sessionId, String termId) async {
    return await DbProxy.instance
        .from('ace_term_reports')
        .eq('student_id', studentId)
        .eq('session_id', sessionId)
        .eq('term_id', termId)
        .maybeSingle();
  }

  Map<String, List<Map<String, dynamic>>> getPaceScoresBySubject() {
    final Map<String, List<Map<String, dynamic>>> map = {};
    for (final s in _acePaceScores) {
      final sid = s['subject_id'].toString();
      map.putIfAbsent(sid, () => []).add(s);
    }
    return map;
  }
}
