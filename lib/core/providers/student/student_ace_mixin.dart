import 'package:flutter/foundation.dart';
import '../../../core/services/db_proxy.dart';
import 'student_base.dart';

mixin StudentAceMixin on StudentBase {
  List<Map<String, dynamic>> _myPaceScores = [];
  Map<String, dynamic>? _myAceReport;

  List<Map<String, dynamic>> get myPaceScores => _myPaceScores;
  Map<String, dynamic>? get myAceReport => _myAceReport;

  Future<void> loadMyAcePaceScores(String sessionId, String termId) async {
    try {
      final result = await DbProxy.instance
          .from('ace_pace_scores')
          .eq('student_id', studentId)
          .eq('session_id', sessionId)
          .eq('term_id', termId)
          .order('created_at', ascending: true)
          .get();
      _myPaceScores = List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('ACE scores load error: $e');
      _myPaceScores = [];
    }
  }

  Future<void> loadMyAceReport(String sessionId, String termId) async {
    try {
      final result = await DbProxy.instance
          .from('ace_term_reports')
          .eq('student_id', studentId)
          .eq('session_id', sessionId)
          .eq('term_id', termId)
          .get();
      final list = List<Map<String, dynamic>>.from(result);
      _myAceReport = list.where((r) => r['is_published'] == true).firstOrNull;
    } catch (e) {
      debugPrint('ACE report load error: $e');
      _myAceReport = null;
    }
  }

  Map<String, List<Map<String, dynamic>>> getMyPaceScoresBySubject() {
    final Map<String, List<Map<String, dynamic>>> map = {};
    for (final s in _myPaceScores) {
      final sid = s['subject_id'].toString();
      map.putIfAbsent(sid, () => []).add(s);
    }
    return map;
  }
}
