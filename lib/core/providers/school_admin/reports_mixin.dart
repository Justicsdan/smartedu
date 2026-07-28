import 'package:flutter/foundation.dart';
import '../../../core/services/db_proxy.dart';
import '../base_provider.dart';
import '../../../utils/grading_utils.dart';

double _r1(num v) => double.parse(v.toStringAsFixed(1));

mixin ReportsMixin on BaseProvider {
  bool get _isAce => schoolSettings?['curriculum_mode'] == 'ace';
  num get _passMark {
    if (_isAce) return 80;
    return num.tryParse((schoolSettings?['pass_mark'] ?? '').toString()) ?? 50;
  }

  String _teacherName(dynamic teacherId) {
    if (teacherId == null) return 'Unknown';
    final tid = teacherId.toString();
    final t = teachers.firstWhere((t) => t['id']?.toString() == tid, orElse: () => <String, dynamic>{});
    final fn = (t['first_name'] ?? '').toString();
    final ln = (t['last_name'] ?? '').toString();
    final name = '$fn $ln'.trim();
    return name.isEmpty ? 'Unknown' : name;
  }

  Map<String, String> _getStudentNames(List<String> studentIds) {
    final map = <String, String>{};
    for (final id in studentIds) {
      final s = students.firstWhere(
        (s) => s['id']?.toString() == id,
        orElse: () => <String, dynamic>{},
      );
      final fn = (s['first_name'] ?? '').toString();
      final ln = (s['last_name'] ?? '').toString();
      map[id] = '$fn $ln'.trim();
    }
    return map;
  }

  double _numVal(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return num.tryParse(v)?.toDouble() ?? 0.0;
    return 0.0;
  }

  String _ordinal(int n) {
    if (n <= 0) return n.toString();
    final lastTwo = n % 100;
    if (lastTwo >= 11 && lastTwo <= 13) return n.toString() + 'th';
    switch (n % 10) {
      case 1: return n.toString() + 'st';
      case 2: return n.toString() + 'nd';
      case 3: return n.toString() + 'rd';
      default: return n.toString() + 'th';
    }
  }

  String _getGrade(double score, String classId) {
    final cls = classes.firstWhere((c) => c['id']?.toString() == classId, orElse: () => <String, dynamic>{});
    final tier = (cls['tier'] ?? '').toString();
    final system = GradingUtils.getGradingSystemForTier(tier, schoolSettings ?? {});
    final g = GradingUtils.getGradeFromSystem(score, system);
    return g?.toString() ?? '';
  }

  Future<List<Map<String, dynamic>>> _loadStudentCumulatives(String classId, String sessionId, List<String> termIds) async {
    if (_isAce) {
      final rows = await DbProxy.instance.from('ace_term_reports').eq('class_id', classId).eq('session_id', sessionId).inFilter('term_id', termIds).get();
      final byStudent = <String, List<Map<String, dynamic>>>{};
      for (final r in rows) {
        final sid = r['student_id']?.toString() ?? '';
        byStudent.putIfAbsent(sid, () => []).add(r);
      }
      final results = <Map<String, dynamic>>[];
      for (final entry in byStudent.entries) {
        final terms = entry.value;
        final hacs = terms.map((t) => _numVal(t['hacs_score'])).where((v) => v > 0).toList();
        final nces = terms.map((t) => _numVal(t['nce_score'])).where((v) => v > 0).toList();
        final paces = terms.map((t) => _numVal(t['paces_completed'])).toList();
        results.add({
          'student_id': entry.key,
          'cumulative_hacs': hacs.isNotEmpty ? hacs.reduce((a, b) => a + b) / hacs.length : 0.0,
          'cumulative_nce': nces.isNotEmpty ? nces.reduce((a, b) => a + b) / nces.length : 0.0,
          'cumulative_paces': paces.isNotEmpty ? paces.reduce((a, b) => a + b) / paces.length : 0.0,
          'terms_count': terms.length,
        });
      }
      return results;
    } else {
      final rows = await DbProxy.instance.from('student_term_summaries').eq('class_id', classId).eq('session_id', sessionId).inFilter('term_id', termIds).get();
      final byStudent = <String, List<Map<String, dynamic>>>{};
      for (final r in rows) {
        final sid = r['student_id']?.toString() ?? '';
        byStudent.putIfAbsent(sid, () => []).add(r);
      }
      final results = <Map<String, dynamic>>[];
      for (final entry in byStudent.entries) {
        final terms = entry.value;
        final totals = terms.map((t) => _numVal(t['total_score'])).toList();
        results.add({
          'student_id': entry.key,
          'cumulative_score': totals.isNotEmpty ? totals.reduce((a, b) => a + b) / totals.length : 0.0,
          'terms_count': terms.length,
        });
      }
      return results;
    }
  }

  // ═══ 1. CLASS TERM SUMMARY ═══
  Future<Map<String, dynamic>> loadClassTermSummary(String classId, String sessionId, String termId) async {
    if (_isAce) return _aceClassSummary(classId, sessionId, termId);
    return _traditionalClassSummary(classId, sessionId, termId);
  }

  Future<Map<String, dynamic>> _traditionalClassSummary(String classId, String sessionId, String termId) async {
    final rows = await DbProxy.instance.from('student_term_summaries').eq('class_id', classId).eq('session_id', sessionId).eq('term_id', termId).get();
    if (rows.isEmpty) return {'total_students': 0};
    final n = rows.length;
    final pm = _passMark.toDouble();
    final scores = rows.map((r) => _numVal(r['total_score'])).toList();
    final avg = scores.reduce((a, b) => a + b) / n;
    final passCount = scores.where((s) => s >= pm).length;
    final distCount = scores.where((s) => s >= 75).length;
    rows.sort((a, b) => _numVal(a['position']).compareTo(_numVal(b['position'])));
    final studentList = rows.map((r) {
      final sid = r['student_id']?.toString() ?? '';
      final stu = students.firstWhere((x) => x['id']?.toString() == sid, orElse: () => <String, dynamic>{});
      final pos = _numVal(r['position']).toInt();
      return {
        'student_name': ((stu['first_name'] ?? '').toString() + ' ' + (stu['last_name'] ?? '').toString()).trim(),
        'total_score': _r1(_numVal(r['total_score'])),
        'average_score': _r1(_numVal(r['average_score'])),
        'position': _ordinal(pos) + ' / ' + (r['position_out_of'] ?? '-').toString(),
      };
    }).toList();
    return {
      'total_students': n, 'avg_score': _r1(avg), 'pass_rate': _r1((passCount / n) * 100),
      'distinction_count': distCount, 'highest_score': _r1(scores.reduce((a, b) => a > b ? a : b)),
      'lowest_score': _r1(scores.reduce((a, b) => a < b ? a : b)), 'at_risk_count': n - passCount,
      'student_list': studentList,
    };
  }

  Future<Map<String, dynamic>> _aceClassSummary(String classId, String sessionId, String termId) async {
    final rows = await DbProxy.instance.from('ace_term_reports').eq('class_id', classId).eq('session_id', sessionId).eq('term_id', termId).get();
    if (rows.isEmpty) return {'total_students': 0};
    final n = rows.length;
    final hacs = rows.map((r) => _numVal(r['hacs_score'])).where((v) => v > 0).toList();
    final nces = rows.map((r) => _numVal(r['nce_score'])).where((v) => v > 0).toList();
    final paces = rows.map((r) => _numVal(r['paces_completed'])).toList();
    final avgH = hacs.isNotEmpty ? hacs.reduce((a, b) => a + b) / hacs.length : 0.0;
    final avgN = nces.isNotEmpty ? nces.reduce((a, b) => a + b) / nces.length : 0.0;
    final avgP = paces.isNotEmpty ? paces.reduce((a, b) => a + b) / paces.length : 0.0;
    final passC = hacs.where((h) => h >= 80).length;
    final distC = hacs.where((h) => h >= 95).length;
    final studentList = rows.map((r) {
      final sid = r['student_id']?.toString() ?? '';
      final stu = students.firstWhere((x) => x['id']?.toString() == sid, orElse: () => <String, dynamic>{});
      return {
        'student_name': ((stu['first_name'] ?? '').toString() + ' ' + (stu['last_name'] ?? '').toString()).trim(),
        'hacs_score': _r1(_numVal(r['hacs_score'])),
        'nce_score': _r1(_numVal(r['nce_score'])),
        'paces_completed': _numVal(r['paces_completed']).toInt(),
      };
    }).toList();
    studentList.sort((a, b) => _numVal(b['hacs_score']).compareTo(_numVal(a['hacs_score'])));
    return {
      'total_students': n, 'avg_hacs': _r1(avgH), 'avg_nce': _r1(avgN), 'avg_paces': _r1(avgP),
      'pass_rate': _r1(hacs.isNotEmpty ? (passC / hacs.length) * 100 : 0.0),
      'distinction_count': distC,
      'highest_hacs': _r1(hacs.isNotEmpty ? hacs.reduce((a, b) => a > b ? a : b) : 0.0),
      'lowest_hacs': _r1(hacs.isNotEmpty ? hacs.reduce((a, b) => a < b ? a : b) : 0.0),
      'at_risk_count': hacs.length - passC,
      'student_list': studentList,
    };
  }

  // ═══ 2. SUBJECT TERM SUMMARY ═══
  Future<List<Map<String, dynamic>>> loadSubjectTermSummaries(String classId, String sessionId, String termId, {String? subjectId}) async {
    if (subjectId != null && subjectId.isNotEmpty) {
      if (_isAce) return _aceSubjectStudentList(classId, sessionId, termId, subjectId);
      return _traditionalSubjectStudentList(classId, sessionId, termId, subjectId);
    }
    if (_isAce) return _aceSubjectSummaries(classId, sessionId, termId);
    return _traditionalSubjectSummaries(classId, sessionId, termId);
  }

  Future<List<Map<String, dynamic>>> _traditionalSubjectStudentList(String classId, String sessionId, String termId, String subjectId) async {
    final scores = await DbProxy.instance.from('scores').eq('class_id', classId).eq('session_id', sessionId).eq('term_id', termId).eq('subject_id', subjectId).get();
    if (scores.isEmpty) return [];
    final results = <Map<String, dynamic>>[];
    for (final s in scores) {
      final sid = s['student_id']?.toString() ?? '';
      final stu = students.firstWhere((x) => x['id']?.toString() == sid, orElse: () => <String, dynamic>{});
      final total = _numVal(s['total']);
      results.add({
        'student_id': sid,
        'student_name': ((stu['first_name'] ?? '').toString() + ' ' + (stu['last_name'] ?? '').toString()).trim(),
        'total_score': _r1(total), 'grade': _getGrade(total, classId), 'is_student_format': true,
      });
    }
    results.sort((a, b) => _numVal(b['total_score']).compareTo(_numVal(a['total_score'])));
    for (var i = 0; i < results.length; i++) { results[i]['position'] = _ordinal(i + 1); }
    return results;
  }

  Future<List<Map<String, dynamic>>> _aceSubjectStudentList(String classId, String sessionId, String termId, String subjectId) async {
    final cStuIds = students.where((s) => s['class_id']?.toString() == classId).map((s) => s['id']!.toString()).toList();
    if (cStuIds.isEmpty) return [];
    final scores = await DbProxy.instance.from('ace_pace_scores').inFilter('student_id', cStuIds).eq('session_id', sessionId).eq('term_id', termId).eq('subject_id', subjectId).get();
    if (scores.isEmpty) return [];
    final byStudent = <String, List<Map<String, dynamic>>>{};
    for (final s in scores) {
      final sid = s['student_id']?.toString() ?? '';
      byStudent.putIfAbsent(sid, () => []).add(s);
    }
    final results = <Map<String, dynamic>>[];
    for (final entry in byStudent.entries) {
      final stuScores = entry.value;
      final pts = stuScores.map((s) => _numVal(s['pt_score'])).toList();
      final avg = pts.isNotEmpty ? pts.reduce((a, b) => a + b) / pts.length : 0.0;
      final paceNos = stuScores.map((s) => (s['pace_no'] ?? '').toString()).where((p) => p.isNotEmpty).toList()..sort();
      final paceRange = paceNos.isNotEmpty ? paceNos.join(' - ') : '--';
      final sid = entry.key;
      final stu = students.firstWhere((x) => x['id']?.toString() == sid, orElse: () => <String, dynamic>{});
      results.add({
        'student_id': sid,
        'student_name': ((stu['first_name'] ?? '').toString() + ' ' + (stu['last_name'] ?? '').toString()).trim(),
        'paces_completed': stuScores.length, 'term_average': _r1(avg), 'pace_range': paceRange,
        'is_student_format': true,
      });
    }
    results.sort((a, b) => _numVal(b['term_average']).compareTo(_numVal(a['term_average'])));
    for (var i = 0; i < results.length; i++) { results[i]['position'] = _ordinal(i + 1); }
    return results;
  }

  Future<List<Map<String, dynamic>>> _traditionalSubjectSummaries(String classId, String sessionId, String termId) async {
    final scores = await DbProxy.instance.from('scores').eq('class_id', classId).eq('session_id', sessionId).eq('term_id', termId).get();
    if (scores.isEmpty) return [];
    final pm = _passMark.toDouble();
    final bySub = <String, List<double>>{};
    for (final s in scores) {
      final sid = s['subject_id']?.toString() ?? '';
      bySub.putIfAbsent(sid, () => []).add(_numVal(s['total']));
    }
    final results = <Map<String, dynamic>>[];
    for (final entry in bySub.entries) {
      final vals = entry.value;
      final avg = vals.reduce((a, b) => a + b) / vals.length;
      final passC = vals.where((s) => s >= pm).length;
      final sub = subjects.firstWhere((s) => s['id']?.toString() == entry.key, orElse: () => <String, dynamic>{});
      results.add({
        'subject_id': entry.key, 'subject_name': (sub['name'] ?? '').toString(), 'subject_code': (sub['code'] ?? '').toString(),
        'avg_score': _r1(avg), 'pass_rate': _r1((passC / vals.length) * 100),
        'highest_avg': _r1(vals.reduce((a, b) => a > b ? a : b)),
        'lowest_avg': _r1(vals.reduce((a, b) => a < b ? a : b)), 'students_count': vals.length,
      });
    }
    results.sort((a, b) => (a['subject_name'] as String).compareTo(b['subject_name'] as String));
    return results;
  }

  Future<List<Map<String, dynamic>>> _aceSubjectSummaries(String classId, String sessionId, String termId) async {
    final cStuIds = students.where((s) => s['class_id']?.toString() == classId).map((s) => s['id']!.toString()).toList();
    if (cStuIds.isEmpty) return [];
    final scores = await DbProxy.instance.from('ace_pace_scores').inFilter('student_id', cStuIds).eq('session_id', sessionId).eq('term_id', termId).get();
    if (scores.isEmpty) return [];
    final bySub = <String, List<double>>{};
    for (final s in scores) {
      final sid = s['subject_id']?.toString() ?? '';
      bySub.putIfAbsent(sid, () => []).add(_numVal(s['pt_score']));
    }
    final results = <Map<String, dynamic>>[];
    for (final entry in bySub.entries) {
      final vals = entry.value;
      final avg = vals.reduce((a, b) => a + b) / vals.length;
      final passC = vals.where((v) => v >= 80).length;
      final sub = subjects.firstWhere((s) => s['id']?.toString() == entry.key, orElse: () => <String, dynamic>{});
      results.add({
        'subject_id': entry.key, 'subject_name': (sub['name'] ?? '').toString(), 'subject_code': (sub['code'] ?? '').toString(),
        'avg_pt': _r1(avg), 'pass_rate': _r1((passC / vals.length) * 100),
        'highest_pt': _r1(vals.reduce((a, b) => a > b ? a : b)),
        'lowest_pt': _r1(vals.reduce((a, b) => a < b ? a : b)),
        'total_paces': scores.where((s) => s['subject_id']?.toString() == entry.key).length,
        'students_count': scores.where((s) => s['subject_id']?.toString() == entry.key).map((s) => s['student_id']).toSet().length,
      });
    }
    results.sort((a, b) => (a['subject_name'] as String).compareTo(b['subject_name'] as String));
    return results;
  }

  // ═══ 3. CUMULATIVE CLASS SUMMARY ═══
  Future<Map<String, dynamic>> loadClassCumulativeSummary(String classId, String sessionId, List<String> termIds) async {
    final cumData = await _loadStudentCumulatives(classId, sessionId, termIds);
    if (cumData.isEmpty) return {'total_students': 0};
    final n = cumData.length;
    for (final item in cumData) {
      final sid = item['student_id']?.toString() ?? '';
      final stu = students.firstWhere((x) => x['id']?.toString() == sid, orElse: () => <String, dynamic>{});
      item['student_name'] = ((stu['first_name'] ?? '').toString() + ' ' + (stu['last_name'] ?? '').toString()).trim();
    }
    if (_isAce) {
      cumData.sort((a, b) => _numVal(b['cumulative_hacs']).compareTo(_numVal(a['cumulative_hacs'])));
      final hacs = cumData.map((s) => _numVal(s['cumulative_hacs'])).toList();
      final nces = cumData.map((s) => _numVal(s['cumulative_nce'])).toList();
      final paces = cumData.map((s) => _numVal(s['cumulative_paces'])).toList();
      final avgH = hacs.reduce((a, b) => a + b) / n;
      final avgN = nces.reduce((a, b) => a + b) / n;
      final avgP = paces.reduce((a, b) => a + b) / n;
      final passC = hacs.where((h) => h >= 80).length;
      final distC = hacs.where((h) => h >= 95).length;
      return {
        'total_students': n, 'avg_hacs': _r1(avgH), 'avg_nce': _r1(avgN), 'avg_paces': _r1(avgP),
        'pass_rate': _r1((passC / n) * 100), 'distinction_count': distC,
        'highest_hacs': _r1(hacs.reduce((a, b) => a > b ? a : b)),
        'lowest_hacs': _r1(hacs.reduce((a, b) => a < b ? a : b)),
        'at_risk_count': n - passC, 'terms_count': termIds.length,
        'student_list': List<Map<String, dynamic>>.from(cumData),
      };
    } else {
      cumData.sort((a, b) => _numVal(b['cumulative_score']).compareTo(_numVal(a['cumulative_score'])));
      final sc = cumData.map((s) => _numVal(s['cumulative_score'])).toList();
      final pm = _passMark.toDouble();
      final avg = sc.reduce((a, b) => a + b) / n;
      final passC = sc.where((s) => s >= pm).length;
      final distC = sc.where((s) => s >= 75).length;
      return {
        'total_students': n, 'avg_score': _r1(avg), 'pass_rate': _r1((passC / n) * 100),
        'distinction_count': distC, 'highest_score': _r1(sc.reduce((a, b) => a > b ? a : b)),
        'lowest_score': _r1(sc.reduce((a, b) => a < b ? a : b)), 'at_risk_count': n - passC, 'terms_count': termIds.length,
        'student_list': List<Map<String, dynamic>>.from(cumData),
      };
    }
  }

  // ═══ 4. CUMULATIVE SUBJECT SUMMARY ═══
  Future<List<Map<String, dynamic>>> loadSubjectCumulativeSummaries(String classId, String sessionId, List<String> termIds, {String? subjectId}) async {
    if (subjectId != null && subjectId.isNotEmpty) {
      if (_isAce) return _aceCumulativeSubjectStudentList(classId, sessionId, termIds, subjectId);
      return _traditionalCumulativeSubjectStudentList(classId, sessionId, termIds, subjectId);
    }
    if (_isAce) return _aceSubjectCumulative(classId, sessionId, termIds);
    return _traditionalSubjectCumulative(classId, sessionId, termIds);
  }

  Future<List<Map<String, dynamic>>> _traditionalCumulativeSubjectStudentList(String classId, String sessionId, List<String> termIds, String subjectId) async {
    final scores = await DbProxy.instance.from('scores').eq('class_id', classId).eq('session_id', sessionId).eq('subject_id', subjectId).inFilter('term_id', termIds).get();
    if (scores.isEmpty) return [];
    final byStuTerm = <String, Map<String, Map<String, dynamic>>>{};
    for (final s in scores) {
      final sid = s['student_id']?.toString() ?? '';
      final tid = s['term_id']?.toString() ?? '';
      byStuTerm.putIfAbsent(sid, () => {});
      byStuTerm[sid]!.putIfAbsent(tid, () => {'total': 0.0, 'count': 0});
      byStuTerm[sid]![tid]!['total'] = _numVal(byStuTerm[sid]![tid]!['total']) + _numVal(s['total']);
      byStuTerm[sid]![tid]!['count'] = _numVal(byStuTerm[sid]![tid]!['count']) + 1;
    }
    final results = <Map<String, dynamic>>[];
    for (final entry in byStuTerm.entries) {
      final sid = entry.key;
      final stu = students.firstWhere((x) => x['id']?.toString() == sid, orElse: () => <String, dynamic>{});
      final termData = <Map<String, dynamic>>[];
      var cumTotal = 0.0;
      var scoredTerms = 0;
      for (final tid in termIds) {
        final tInfo = entry.value[tid];
        if (tInfo != null && _numVal(tInfo['count']) > 0) {
          final total = _numVal(tInfo['total']);
          cumTotal += total;
          scoredTerms++;
          final term = termsList.firstWhere((t) => t['id']?.toString() == tid, orElse: () => <String, dynamic>{});
          termData.add({'term_name': (term['name'] ?? '').toString(), 'term_id': tid, 'total': _r1(total), 'grade': _getGrade(total, classId)});
        } else {
          final term = termsList.firstWhere((t) => t['id']?.toString() == tid, orElse: () => <String, dynamic>{});
          termData.add({'term_name': (term['name'] ?? '').toString(), 'term_id': tid, 'total': '--', 'grade': ''});
        }
      }
      final cumAvg = scoredTerms > 0 ? cumTotal / scoredTerms : 0.0;
      results.add({
        'student_id': sid,
        'student_name': ((stu['first_name'] ?? '').toString() + ' ' + (stu['last_name'] ?? '').toString()).trim(),
        'term_data': termData, 'cumulative_total': _r1(cumTotal), 'cumulative_avg': _r1(cumAvg),
        'is_student_format': true, 'is_cumulative': true,
      });
    }
    results.sort((a, b) => _numVal(b['cumulative_avg']).compareTo(_numVal(a['cumulative_avg'])));
    for (var i = 0; i < results.length; i++) { results[i]['position'] = _ordinal(i + 1); }
    return results;
  }

  Future<List<Map<String, dynamic>>> _aceCumulativeSubjectStudentList(String classId, String sessionId, List<String> termIds, String subjectId) async {
    final cStuIds = students.where((s) => s['class_id']?.toString() == classId).map((s) => s['id']!.toString()).toList();
    if (cStuIds.isEmpty) return [];
    final scores = await DbProxy.instance.from('ace_pace_scores').inFilter('student_id', cStuIds).eq('session_id', sessionId).eq('subject_id', subjectId).inFilter('term_id', termIds).get();
    if (scores.isEmpty) return [];
    final byStuTerm = <String, Map<String, List<Map<String, dynamic>>>>{};
    for (final s in scores) {
      final sid = s['student_id']?.toString() ?? '';
      final tid = s['term_id']?.toString() ?? '';
      byStuTerm.putIfAbsent(sid, () => {});
      byStuTerm[sid]!.putIfAbsent(tid, () => []);
      byStuTerm[sid]![tid]!.add(s);
    }
    final results = <Map<String, dynamic>>[];
    for (final entry in byStuTerm.entries) {
      final sid = entry.key;
      final stu = students.firstWhere((x) => x['id']?.toString() == sid, orElse: () => <String, dynamic>{});
      final termData = <Map<String, dynamic>>[];
      var totalPaces = 0; var totalPts = 0.0; var ptCount = 0;
      for (final tid in termIds) {
        final tScores = entry.value[tid];
        if (tScores != null && tScores.isNotEmpty) {
          final pts = tScores.map((s) => _numVal(s['pt_score'])).toList();
          final avg = pts.reduce((a, b) => a + b) / pts.length;
          totalPaces += tScores.length; totalPts += avg; ptCount++;
          final term = termsList.firstWhere((t) => t['id']?.toString() == tid, orElse: () => <String, dynamic>{});
          termData.add({'term_name': (term['name'] ?? '').toString(), 'term_id': tid, 'avg_pt': _r1(avg), 'paces': tScores.length});
        } else {
          final term = termsList.firstWhere((t) => t['id']?.toString() == tid, orElse: () => <String, dynamic>{});
          termData.add({'term_name': (term['name'] ?? '').toString(), 'term_id': tid, 'avg_pt': '--', 'paces': 0});
        }
      }
      final cumAvg = ptCount > 0 ? totalPts / ptCount : 0.0;
      results.add({
        'student_id': sid,
        'student_name': ((stu['first_name'] ?? '').toString() + ' ' + (stu['last_name'] ?? '').toString()).trim(),
        'term_data': termData, 'total_paces': totalPaces, 'cumulative_avg': _r1(cumAvg),
        'is_student_format': true, 'is_cumulative': true,
      });
    }
    results.sort((a, b) => _numVal(b['cumulative_avg']).compareTo(_numVal(a['cumulative_avg'])));
    for (var i = 0; i < results.length; i++) { results[i]['position'] = _ordinal(i + 1); }
    return results;
  }

  Future<List<Map<String, dynamic>>> _traditionalSubjectCumulative(String classId, String sessionId, List<String> termIds) async {
    final scores = await DbProxy.instance.from('scores').eq('class_id', classId).eq('session_id', sessionId).inFilter('term_id', termIds).get();
    if (scores.isEmpty) return [];
    final pm = _passMark.toDouble();
    final bySubStu = <String, List<double>>{};
    for (final s in scores) {
      final key = '${s['subject_id']}_${s['student_id']}';
      bySubStu.putIfAbsent(key, () => []).add(_numVal(s['total']));
    }
    final bySub = <String, List<double>>{};
    for (final entry in bySubStu.entries) {
      final subId = (entry.key as String).split('_')[0];
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      bySub.putIfAbsent(subId, () => []).add(avg);
    }
    final results = <Map<String, dynamic>>[];
    for (final entry in bySub.entries) {
      final vals = entry.value;
      final avg = vals.reduce((a, b) => a + b) / vals.length;
      final passC = vals.where((v) => v >= pm).length;
      final sub = subjects.firstWhere((s) => s['id']?.toString() == entry.key, orElse: () => <String, dynamic>{});
      results.add({
        'subject_id': entry.key, 'subject_name': (sub['name'] ?? '').toString(), 'subject_code': (sub['code'] ?? '').toString(),
        'avg_score': _r1(avg), 'pass_rate': _r1((passC / vals.length) * 100),
        'highest_avg': _r1(vals.reduce((a, b) => a > b ? a : b)),
        'lowest_avg': _r1(vals.reduce((a, b) => a < b ? a : b)), 'students_count': vals.length,
      });
    }
    results.sort((a, b) => (a['subject_name'] as String).compareTo(b['subject_name'] as String));
    return results;
  }

  Future<List<Map<String, dynamic>>> _aceSubjectCumulative(String classId, String sessionId, List<String> termIds) async {
    final cStuIds = students.where((s) => s['class_id']?.toString() == classId).map((s) => s['id']!.toString()).toList();
    if (cStuIds.isEmpty) return [];
    final scores = await DbProxy.instance.from('ace_pace_scores').inFilter('student_id', cStuIds).eq('session_id', sessionId).inFilter('term_id', termIds).get();
    if (scores.isEmpty) return [];
    final bySubStu = <String, List<double>>{};
    for (final s in scores) {
      final key = '${s['subject_id']}_${s['student_id']}';
      bySubStu.putIfAbsent(key, () => []).add(_numVal(s['pt_score']));
    }
    final bySub = <String, List<double>>{};
    for (final entry in bySubStu.entries) {
      final subId = (entry.key as String).split('_')[0];
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      bySub.putIfAbsent(subId, () => []).add(avg);
    }
    final results = <Map<String, dynamic>>[];
    for (final entry in bySub.entries) {
      final vals = entry.value;
      final avg = vals.reduce((a, b) => a + b) / vals.length;
      final passC = vals.where((v) => v >= 80).length;
      final sub = subjects.firstWhere((s) => s['id']?.toString() == entry.key, orElse: () => <String, dynamic>{});
      results.add({
        'subject_id': entry.key, 'subject_name': (sub['name'] ?? '').toString(), 'subject_code': (sub['code'] ?? '').toString(),
        'avg_pt': _r1(avg), 'pass_rate': _r1((passC / vals.length) * 100),
        'highest_pt': _r1(vals.reduce((a, b) => a > b ? a : b)),
        'lowest_pt': _r1(vals.reduce((a, b) => a < b ? a : b)),
        'total_paces': scores.where((s) => s['subject_id']?.toString() == entry.key).length,
        'students_count': scores.where((s) => s['subject_id']?.toString() == entry.key).map((s) => s['student_id']).toSet().length,
      });
    }
    results.sort((a, b) => (a['subject_name'] as String).compareTo(b['subject_name'] as String));
    return results;
  }

  // ═══ 5. CLASS COMPARISON ═══
  Future<List<Map<String, dynamic>>> loadClassComparison(String sessionId, List<String> termIds, String classLevel) async {
    final levelClasses = classes.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final level = (c['class_level'] ?? '').toString().toLowerCase();
      final tier = (c['tier'] ?? '').toString().toLowerCase();
      return name.startsWith(classLevel.toLowerCase()) || level == classLevel.toLowerCase() || tier == classLevel.toLowerCase();
    }).toList();
    if (levelClasses.isEmpty) return [];
    final results = <Map<String, dynamic>>[];
    for (final cls in levelClasses) {
      final cid = cls['id']?.toString() ?? '';
      if (cid.isEmpty) continue;
      try {
        final summary = await loadClassCumulativeSummary(cid, sessionId, termIds);
        summary['class_id'] = cid;
        final sec = (cls['section'] ?? '').toString();
        summary['class_name'] = sec.isNotEmpty ? '${cls['name']} $sec' : (cls['name'] ?? '').toString();
        results.add(summary);
      } catch (e) {
        debugPrint('Class comparison error for $cid: $e');
      }
    }
    if (_isAce) {
      results.sort((a, b) => _numVal(b['avg_hacs']).compareTo(_numVal(a['avg_hacs'])));
    } else {
      results.sort((a, b) => _numVal(b['avg_score']).compareTo(_numVal(a['avg_score'])));
    }
    return results;
  }

  // ═══ 6. TOP STUDENTS ═══
  Future<List<Map<String, dynamic>>> loadTopStudents(String sessionId, List<String> termIds, {String? classId, String? classLevel, int limit = 10}) async {
    List<Map<String, dynamic>> cumData;
    if (classId != null && classId.isNotEmpty) {
      cumData = await _loadStudentCumulatives(classId, sessionId, termIds);
    } else {
      final targetClasses = classLevel != null
          ? classes.where((c) {
              final name = (c['name'] ?? '').toString().toLowerCase();
              final level = (c['class_level'] ?? '').toString().toLowerCase();
              return name.startsWith(classLevel.toLowerCase()) || level == classLevel.toLowerCase();
            })
          : classes;
      final allData = <Map<String, dynamic>>[];
      for (final cls in targetClasses) {
        final cid = cls['id']?.toString() ?? '';
        if (cid.isEmpty) continue;
        try { allData.addAll(await _loadStudentCumulatives(cid, sessionId, termIds)); } catch (_) {}
      }
      cumData = allData;
    }
    final ids = cumData.map((s) => s['student_id'] as String).toList();
    final names = _getStudentNames(ids);
    for (final s in cumData) {
      s['student_name'] = names[s['student_id'] as String] ?? 'Unknown';
    }
    if (_isAce) {
      cumData.sort((a, b) => _numVal(b['cumulative_hacs']).compareTo(_numVal(a['cumulative_hacs'])));
    } else {
      cumData.sort((a, b) => _numVal(b['cumulative_score']).compareTo(_numVal(a['cumulative_score'])));
    }
    return cumData.take(limit).toList();
  }

  // ═══ 7. PROMOTION READINESS ═══
  Future<List<Map<String, dynamic>>> loadPromotionReadiness(String sessionId, List<String> termIds, {String? classId, num? threshold}) async {
    final th = (threshold ?? _passMark).toDouble();
    List<Map<String, dynamic>> cumData;
    if (classId != null && classId.isNotEmpty) {
      cumData = await _loadStudentCumulatives(classId, sessionId, termIds);
    } else {
      final allData = <Map<String, dynamic>>[];
      for (final cls in classes) {
        final cid = cls['id']?.toString() ?? '';
        if (cid.isEmpty) continue;
        try { allData.addAll(await _loadStudentCumulatives(cid, sessionId, termIds)); } catch (_) {}
      }
      cumData = allData;
    }
    final ids = cumData.map((s) => s['student_id'] as String).toList();
    final names = _getStudentNames(ids);
    final atRisk = <Map<String, dynamic>>[];
    for (final s in cumData) {
      final val = _isAce ? _numVal(s['cumulative_hacs']) : _numVal(s['cumulative_score']);
      if (val < th) {
        s['student_name'] = names[s['student_id'] as String] ?? 'Unknown';
        s['cumulative_value'] = val;
        atRisk.add(s);
      }
    }
    if (_isAce) {
      atRisk.sort((a, b) => _numVal(a['cumulative_hacs']).compareTo(_numVal(b['cumulative_hacs'])));
    } else {
      atRisk.sort((a, b) => _numVal(a['cumulative_score']).compareTo(_numVal(b['cumulative_score'])));
    }
    return atRisk;
  }

  // ═══════════════════════════════════════════════════════════
  // PHASE 2 — EXPANDED REPORTS
  // ═══════════════════════════════════════════════════════════

  // ═══ 8. STUDENT INDIVIDUAL SUMMARY ═══
  Future<Map<String, dynamic>> loadStudentIndividualSummary(String studentId, String sessionId, List<String> termIds) async {
    final stu = students.firstWhere((s) => s['id']?.toString() == studentId, orElse: () => <String, dynamic>{});
    final result = <String, dynamic>{
      'student_name': '${stu['first_name'] ?? ''} ${stu['last_name'] ?? ''}'.trim(),
      'admission_no': stu['admission_no'] ?? '',
      'terms': <Map<String, dynamic>>[],
      'subjects': <Map<String, dynamic>>[],
    };
    if (_isAce) {
      final scores = await DbProxy.instance.from('ace_pace_scores').eq('student_id', studentId).eq('session_id', sessionId).inFilter('term_id', termIds).get();
      final bySub = <String, List<Map<String, dynamic>>>{};
      for (final s in scores) { final sid = s['subject_id']?.toString() ?? ''; bySub.putIfAbsent(sid, () => []).add(s); }
      final subjectResults = <Map<String, dynamic>>[];
      for (final entry in bySub.entries) {
        final paces = entry.value;
        final pts = paces.map((p) => _numVal(p['pt_score'])).toList();
        final avg = pts.isNotEmpty ? pts.reduce((a, b) => a + b) / pts.length : 0.0;
        final sub = subjects.firstWhere((s) => s['id']?.toString() == entry.key, orElse: () => <String, dynamic>{});
        subjectResults.add({
          'subject_name': (sub['name'] ?? '').toString(), 'subject_code': (sub['code'] ?? '').toString(),
          'total_paces': paces.length, 'avg_pt': _r1(avg),
          'highest_pt': _r1(pts.isNotEmpty ? pts.reduce((a, b) => a > b ? a : b) : 0.0),
          'lowest_pt': _r1(pts.isNotEmpty ? pts.reduce((a, b) => a < b ? a : b) : 0.0),
        });
      }
      result['subjects'] = subjectResults;
      final reports = await DbProxy.instance.from('ace_term_reports').eq('student_id', studentId).eq('session_id', sessionId).inFilter('term_id', termIds).get();
      final termResults = <Map<String, dynamic>>[];
      for (final r in reports) {
        final tid = r['term_id']?.toString() ?? '';
        final term = termsList.firstWhere((t) => t['id']?.toString() == tid, orElse: () => <String, dynamic>{});
        termResults.add({'term_name': (term['name'] ?? '').toString(), 'hacs_score': _r1(_numVal(r['hacs_score'])), 'nce_score': _r1(_numVal(r['nce_score'])), 'paces_completed': _numVal(r['paces_completed']).toInt()});
      }
      result['terms'] = termResults;
    } else {
      final scores = await DbProxy.instance.from('scores').eq('student_id', studentId).eq('session_id', sessionId).inFilter('term_id', termIds).get();
      final bySub = <String, List<Map<String, dynamic>>>{};
      for (final s in scores) { final sid = s['subject_id']?.toString() ?? ''; bySub.putIfAbsent(sid, () => []).add(s); }
      final subjectResults = <Map<String, dynamic>>[];
      for (final entry in bySub.entries) {
        final termScores = entry.value;
        final totals = termScores.map((s) => _numVal(s['total'])).toList();
        final avg = totals.isNotEmpty ? totals.reduce((a, b) => a + b) / totals.length : 0.0;
        final sub = subjects.firstWhere((s) => s['id']?.toString() == entry.key, orElse: () => <String, dynamic>{});
        subjectResults.add({'subject_name': (sub['name'] ?? '').toString(), 'subject_code': (sub['code'] ?? '').toString(), 'avg_score': _r1(avg), 'highest': _r1(totals.isNotEmpty ? totals.reduce((a, b) => a > b ? a : b) : 0.0), 'lowest': _r1(totals.isNotEmpty ? totals.reduce((a, b) => a < b ? a : b) : 0.0), 'terms_scored': termScores.length});
      }
      result['subjects'] = subjectResults;
      final summaries = await DbProxy.instance.from('student_term_summaries').eq('student_id', studentId).eq('session_id', sessionId).inFilter('term_id', termIds).get();
      final termResults = <Map<String, dynamic>>[];
      for (final s in summaries) {
        final tid = s['term_id']?.toString() ?? '';
        final term = termsList.firstWhere((t) => t['id']?.toString() == tid, orElse: () => <String, dynamic>{});
        termResults.add({'term_name': (term['name'] ?? '').toString(), 'total_score': _r1(_numVal(s['total_score'])), 'average_score': _r1(_numVal(s['average_score'])), 'position': '${s['position'] ?? '-'} / ${s['position_out_of'] ?? '-'}', 'grade': s['grade'] ?? ''});
      }
      result['terms'] = termResults;
    }
    return result;
  }

  // ═══ 9. ATTENDANCE SUMMARY ═══
  Future<Map<String, dynamic>> loadAttendanceSummary(String classId, String sessionId, String termId, {String? fromDate, String? toDate}) async {
    var query = DbProxy.instance.from('attendance').eq('class_id', classId).eq('session_id', sessionId).eq('term_id', termId);
    if (fromDate != null && fromDate.isNotEmpty) query = query.gte('date', fromDate);
    if (toDate != null && toDate.isNotEmpty) query = query.lte('date', toDate);
    final rows = await query.get();
    if (rows.isEmpty) return {'total_students': 0, 'students': <Map<String, dynamic>>[]};
    final byStu = <String, List<Map<String, dynamic>>>{};
    for (final r in rows) { final sid = r['student_id']?.toString() ?? ''; byStu.putIfAbsent(sid, () => []).add(r); }
    final ids = byStu.keys.toList();
    final names = _getStudentNames(ids);
    final studentRows = <Map<String, dynamic>>[];
    double totalRate = 0;
    int lowestPresent = -1; String? mostAbsentName;
    int highestPresent = -1; String? mostPresentName;
    for (final entry in byStu.entries) {
      final recs = entry.value;
      final present = recs.where((r) => r['status']?.toString().toLowerCase() == 'present').length;
      final absent = recs.length - present;
      final rate = recs.isNotEmpty ? (present / recs.length) * 100 : 0.0;
      totalRate += rate;
      if (lowestPresent == -1 || present < lowestPresent) { lowestPresent = present; mostAbsentName = names[entry.key]; }
      if (present > highestPresent) { highestPresent = present; mostPresentName = names[entry.key]; }
      studentRows.add({'student_id': entry.key, 'student_name': names[entry.key] ?? 'Unknown', 'days_present': present, 'days_absent': absent, 'total_days': recs.length, 'attendance_rate': _r1(rate)});
    }
    studentRows.sort((a, b) => _numVal(a['attendance_rate']).compareTo(_numVal(b['attendance_rate'])));
    return {'total_students': byStu.length, 'avg_attendance_rate': _r1(byStu.isNotEmpty ? totalRate / byStu.length : 0), 'most_absent_student': mostAbsentName ?? 'N/A', 'most_present_student': mostPresentName ?? 'N/A', 'students': studentRows};
  }

  // ═══ 10. FEE PAYMENT STATUS ═══
  Future<List<Map<String, dynamic>>> loadFeePaymentStatus({String? classId, required String sessionId, required String termId, String? feeTypeId}) async {
    var query = DbProxy.instance.from('fee_payments').eq('session_id', sessionId).eq('term_id', termId);
    if (classId != null && classId.isNotEmpty) {
      final classStudents = students.where((s) => s['class_id']?.toString() == classId).map((s) => s['id']?.toString()).where((id) => id != null).toList();
      if (classStudents.isEmpty) return [];
      query = query.inFilter('student_id', classStudents);
    }
    if (feeTypeId != null && feeTypeId.isNotEmpty) query = query.eq('fee_type_id', feeTypeId);
    final payments = await query.get();
    final byStu = <String, List<Map<String, dynamic>>>{};
    for (final p in payments) { final sid = p['student_id']?.toString() ?? ''; byStu.putIfAbsent(sid, () => []).add(p); }
    final ids = byStu.keys.toList();
    final names = _getStudentNames(ids);
    final results = <Map<String, dynamic>>[];
    for (final entry in byStu.entries) {
      final pays = entry.value;
      final totalPaid = pays.map((p) => _numVal(p['amount_paid'])).reduce((a, b) => a + b);
      final totalExpected = pays.map((p) => _numVal(p['amount'])).reduce((a, b) => a + b);
      final balance = totalExpected - totalPaid;
      String status;
      if (balance <= 0) status = 'Paid'; else if (totalPaid > 0) status = 'Partial'; else status = 'Unpaid';
      results.add({'student_id': entry.key, 'student_name': names[entry.key] ?? 'Unknown', 'total_expected': _r1(totalExpected), 'total_paid': _r1(totalPaid), 'balance': _r1(balance), 'status': status});
    }
    results.sort((a, b) => (a['student_name'] as String).compareTo(b['student_name'] as String));
    return results;
  }

  // ═══ 11. FEE COLLECTION SUMMARY ═══
  Future<List<Map<String, dynamic>>> loadFeeCollectionSummary({required String sessionId, required String termId}) async {
    final payments = await DbProxy.instance.from('fee_payments').eq('session_id', sessionId).eq('term_id', termId).get();
    if (payments.isEmpty) return [];
    final feeTypeIds = payments.map((p) => p['fee_type_id']?.toString()).where((id) => id != null).toSet().toList();
    final results = <Map<String, dynamic>>[];
    for (final ftId in feeTypeIds) {
      final ftPayments = payments.where((p) => p['fee_type_id']?.toString() == ftId).toList();
      final totalExpected = ftPayments.map((p) => _numVal(p['amount'])).reduce((a, b) => a + b);
      final totalPaid = ftPayments.map((p) => _numVal(p['amount_paid'])).reduce((a, b) => a + b);
      final outstanding = totalExpected - totalPaid;
      final rate = totalExpected > 0 ? (totalPaid / totalExpected) * 100 : 0.0;
      final ftList = await DbProxy.instance.from('fee_types').eq('school_id', schoolId).get();
      final ft = ftList.firstWhere((f) => f['id']?.toString() == ftId, orElse: () => <String, dynamic>{});
      results.add({'fee_type_id': ftId, 'fee_type_name': (ft['name'] ?? 'Unknown').toString(), 'total_expected': _r1(totalExpected), 'total_paid': _r1(totalPaid), 'outstanding': _r1(outstanding), 'collection_rate': _r1(rate), 'students_count': ftPayments.map((p) => p['student_id']).toSet().length});
    }
    results.sort((a, b) => (a['fee_type_name'] as String).compareTo(b['fee_type_name'] as String));
    return results;
  }

  // ═══ 12. TEACHER PERFORMANCE ═══
  Future<List<Map<String, dynamic>>> loadTeacherPerformance(String sessionId, List<String> termIds, {String? subjectId}) async {
    final allCS = await DbProxy.instance.from('class_subjects').eq('school_id', schoolId).get();
    final byTeacher = <String, List<Map<String, dynamic>>>{};
    for (final cs in allCS) {
      final tid = cs['teacher_id']?.toString() ?? '';
      if (tid.isEmpty) continue;
      if (subjectId != null && subjectId.isNotEmpty && cs['subject_id']?.toString() != subjectId) continue;
      byTeacher.putIfAbsent(tid, () => []).add(cs);
    }
    final results = <Map<String, dynamic>>[];
    for (final entry in byTeacher.entries) {
      final tid = entry.key;
      final assignments = entry.value;
      final cids = assignments.map((a) => a['class_id']?.toString()).where((id) => id != null).toSet().toList();
      final sids = assignments.map((a) => a['subject_id']?.toString()).where((id) => id != null).toSet().toList();
      final subNames = sids.map((sid) { final s = subjects.firstWhere((s) => s['id']?.toString() == sid, orElse: () => <String, dynamic>{}); return (s['name'] ?? '').toString(); }).join(', ');
      if (_isAce) {
        var q = DbProxy.instance.from('ace_pace_scores').eq('session_id', sessionId).inFilter('term_id', termIds);
        if (cids.isNotEmpty) q = q.inFilter('class_id', cids);
        if (sids.isNotEmpty) q = q.inFilter('subject_id', sids);
        final sc = await q.get();
        final pts = sc.map((s) => _numVal(s['pt_score'])).toList();
        final avg = pts.isNotEmpty ? pts.reduce((a, b) => a + b) / pts.length : 0.0;
        final passC = pts.where((p) => p >= 80).length;
        results.add({'teacher_id': tid, 'teacher_name': _teacherName(tid), 'subjects': subNames, 'classes_count': cids.length, 'total_paces': sc.length, 'avg_pt': _r1(avg), 'pass_rate': _r1(pts.isNotEmpty ? (passC / pts.length) * 100 : 0), 'students_count': sc.map((s) => s['student_id']).toSet().length});
      } else {
        var q = DbProxy.instance.from('scores').eq('session_id', sessionId).inFilter('term_id', termIds);
        if (cids.isNotEmpty) q = q.inFilter('class_id', cids);
        if (sids.isNotEmpty) q = q.inFilter('subject_id', sids);
        final sc = await q.get();
        final vals = sc.map((s) => _numVal(s['total'])).toList();
        final avg = vals.isNotEmpty ? vals.reduce((a, b) => a + b) / vals.length : 0.0;
        final pm = _passMark.toDouble();
        final passC = vals.where((s) => s >= pm).length;
        results.add({'teacher_id': tid, 'teacher_name': _teacherName(tid), 'subjects': subNames, 'classes_count': cids.length, 'avg_score': _r1(avg), 'pass_rate': _r1(vals.isNotEmpty ? (passC / vals.length) * 100 : 0), 'students_count': sc.map((s) => s['student_id']).toSet().length});
      }
    }
    results.sort((a, b) => (a['teacher_name'] as String).compareTo(b['teacher_name'] as String));
    return results;
  }

  // ═══ 13. CBT PERFORMANCE ═══
  Future<List<Map<String, dynamic>>> loadCbtPerformance(String sessionId, List<String> termIds, {String? classId, String? subjectId}) async {
    final exams = await DbProxy.instance.from('cbt_exams').eq('school_id', schoolId).eq('session_id', sessionId).inFilter('term_id', termIds).get();
    if (exams.isEmpty) return [];
    var filtered = exams;
    if (classId != null && classId.isNotEmpty) filtered = filtered.where((e) => e['class_id']?.toString() == classId).toList();
    if (subjectId != null && subjectId.isNotEmpty) filtered = filtered.where((e) => e['subject_id']?.toString() == subjectId).toList();
    final results = <Map<String, dynamic>>[];
    for (final exam in filtered) {
      final eid = exam['id']?.toString() ?? '';
      final attempts = await DbProxy.instance.from('cbt_attempts').eq('exam_id', eid).get();
      if (attempts.isEmpty) { results.add({'exam_title': exam['title'] ?? '', 'subject_name': '', 'total_students': 0, 'avg_score': 0.0, 'pass_rate': 0.0, 'highest': 0.0, 'lowest': 0.0}); continue; }
      final sc = attempts.map((a) => _numVal(a['score'])).toList();
      final avg = sc.reduce((a, b) => a + b) / sc.length;
      final pm = _passMark.toDouble();
      final passC = sc.where((s) => s >= pm).length;
      final sub = subjects.firstWhere((s) => s['id']?.toString() == exam['subject_id'].toString(), orElse: () => <String, dynamic>{});
      results.add({'exam_title': exam['title'] ?? '', 'subject_name': (sub['name'] ?? '').toString(), 'total_students': attempts.length, 'avg_score': _r1(avg), 'pass_rate': _r1((passC / attempts.length) * 100), 'highest': _r1(sc.reduce((a, b) => a > b ? a : b)), 'lowest': _r1(sc.reduce((a, b) => a < b ? a : b))});
    }
    return results;
  }

  // ═══ 14. SUBJECT TREND OVER TIME ═══
  Future<List<Map<String, dynamic>>> loadSubjectTrend(String classId, String subjectId, String sessionId, List<String> termIds) async {
    if (_isAce) {
      final cStuIds = students.where((s) => s['class_id']?.toString() == classId).map((s) => s['id']!.toString()).toList();
      if (cStuIds.isEmpty) return [];
      final scores = await DbProxy.instance.from('ace_pace_scores').inFilter('student_id', cStuIds).eq('session_id', sessionId).eq('subject_id', subjectId).inFilter('term_id', termIds).get();
      final byTerm = <String, List<double>>{};
      for (final s in scores) { final tid = s['term_id']?.toString() ?? ''; byTerm.putIfAbsent(tid, () => []).add(_numVal(s['pt_score'])); }
      final results = <Map<String, dynamic>>[];
      double prevAvg = -1;
      for (final tid in termIds) {
        final vals = byTerm[tid] ?? [];
        final avg = vals.isNotEmpty ? vals.reduce((a, b) => a + b) / vals.length : 0.0;
        final passC = vals.where((v) => v >= 80).length;
        String trend;
        if (prevAvg < 0) trend = '';
        else if (avg > prevAvg + 1) trend = '↑ Improving';
        else if (avg < prevAvg - 1) trend = '↓ Declining';
        else trend = '→ Stable';
        final term = termsList.firstWhere((t) => t['id']?.toString() == tid, orElse: () => <String, dynamic>{});
        results.add({'term_id': tid, 'term_name': (term['name'] ?? '').toString(), 'avg_pt': _r1(avg), 'pass_rate': _r1(vals.isNotEmpty ? (passC / vals.length) * 100 : 0), 'students_count': vals.length, 'total_paces': vals.length, 'trend': trend});
        prevAvg = avg;
      }
      return results;
    } else {
      final scores = await DbProxy.instance.from('scores').eq('class_id', classId).eq('subject_id', subjectId).eq('session_id', sessionId).inFilter('term_id', termIds).get();
      final byTerm = <String, List<double>>{};
      for (final s in scores) { final tid = s['term_id']?.toString() ?? ''; byTerm.putIfAbsent(tid, () => []).add(_numVal(s['total'])); }
      final results = <Map<String, dynamic>>[];
      double prevAvg = -1;
      for (final tid in termIds) {
        final vals = byTerm[tid] ?? [];
        final avg = vals.isNotEmpty ? vals.reduce((a, b) => a + b) / vals.length : 0.0;
        final pm = _passMark.toDouble();
        final passC = vals.where((v) => v >= pm).length;
        String trend;
        if (prevAvg < 0) trend = '';
        else if (avg > prevAvg + 1) trend = '↑ Improving';
        else if (avg < prevAvg - 1) trend = '↓ Declining';
        else trend = '→ Stable';
        final term = termsList.firstWhere((t) => t['id']?.toString() == tid, orElse: () => <String, dynamic>{});
        results.add({'term_id': tid, 'term_name': (term['name'] ?? '').toString(), 'avg_score': _r1(avg), 'pass_rate': _r1(vals.isNotEmpty ? (passC / vals.length) * 100 : 0), 'students_count': vals.length, 'trend': trend});
        prevAvg = avg;
      }
      return results;
    }
  }

  // ═══ 15. NCE DISTRIBUTION (ACE only) ═══
  Future<List<Map<String, dynamic>>> loadNceDistribution(String classId, String sessionId, List<String> termIds) async {
    final rows = await DbProxy.instance.from('ace_term_reports').eq('class_id', classId).eq('session_id', sessionId).inFilter('term_id', termIds).get();
    final bands = [
      {'label': '1-10', 'min': 1, 'max': 10}, {'label': '11-20', 'min': 11, 'max': 20},
      {'label': '21-30', 'min': 21, 'max': 30}, {'label': '31-40', 'min': 31, 'max': 40},
      {'label': '41-50', 'min': 41, 'max': 50}, {'label': '51-60', 'min': 51, 'max': 60},
      {'label': '61-70', 'min': 61, 'max': 70}, {'label': '71-80', 'min': 71, 'max': 80},
      {'label': '81-90', 'min': 81, 'max': 90}, {'label': '91-99', 'min': 91, 'max': 99},
    ];
    final ids = rows.map((r) => r['student_id']?.toString() ?? '').where((id) => id.isNotEmpty).toSet().toList();
    final names = _getStudentNames(ids);
    final byStu = <String, List<double>>{};
    for (final r in rows) {
      final sid = r['student_id']?.toString() ?? '';
      final nce = _numVal(r['nce_score']);
      if (nce > 0) byStu.putIfAbsent(sid, () => []).add(nce);
    }
    final studentAvgs = <String, double>{};
    for (final entry in byStu.entries) {
      studentAvgs[entry.key] = entry.value.reduce((a, b) => a + b) / entry.value.length;
    }
    final total = studentAvgs.length;
    final results = <Map<String, dynamic>>[];
    for (final band in bands) {
      final inBand = studentAvgs.entries.where((e) => e.value >= (band['min'] as num) && e.value <= (band['max'] as num)).toList();
      final studentNames = inBand.map((e) => names[e.key] ?? 'Unknown').toList();
      results.add({'band': band['label'], 'count': inBand.length, 'percentage': total > 0 ? _r1((inBand.length / total) * 100) : '0.0', 'students': studentNames});
    }
    return results;
  }

  // ═══ 16. PACE COMPLETION RATE (ACE only) ═══
  Future<List<Map<String, dynamic>>> loadPaceCompletionRate(String classId, String sessionId, List<String> termIds) async {
    final cStuIds = students.where((s) => s['class_id']?.toString() == classId).map((s) => s['id']!.toString()).toList();
    if (cStuIds.isEmpty) return [];
    final scores = await DbProxy.instance.from('ace_pace_scores').inFilter('student_id', cStuIds).eq('session_id', sessionId).inFilter('term_id', termIds).get();
    if (scores.isEmpty) return [];
    final bySub = <String, List<Map<String, dynamic>>>{};
    for (final s in scores) {
      final sid = s['subject_id']?.toString() ?? '';
      bySub.putIfAbsent(sid, () => []).add(s);
    }
    final results = <Map<String, dynamic>>[];
    for (final entry in bySub.entries) {
      final paces = entry.value;
      final pts = paces.map((p) => _numVal(p['pt_score'])).toList();
      final avg = pts.isNotEmpty ? pts.reduce((a, b) => a + b) / pts.length : 0.0;
      final passC = pts.where((p) => p >= 80).length;
      final sub = subjects.firstWhere((s) => s['id']?.toString() == entry.key, orElse: () => <String, dynamic>{});
      final studentCount = paces.map((p) => p['student_id']?.toString()).where((id) => id != null).toSet().length;
      results.add({
        'subject_id': entry.key, 'subject_name': (sub['name'] ?? '').toString(), 'subject_code': (sub['code'] ?? '').toString(),
        'total_paces': paces.length, 'avg_pt': _r1(avg), 'pass_rate': _r1(pts.isNotEmpty ? (passC / pts.length) * 100 : 0),
        'highest_pt': _r1(pts.isNotEmpty ? pts.reduce((a, b) => a > b ? a : b) : 0.0),
        'lowest_pt': _r1(pts.isNotEmpty ? pts.reduce((a, b) => a < b ? a : b) : 0.0),
        'students_count': studentCount,
      });
    }
    results.sort((a, b) => (a['subject_name'] as String).compareTo(b['subject_name'] as String));
    return results;
  }
}
