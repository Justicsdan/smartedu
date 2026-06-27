import 'base_provider.dart';
import 'package:smartedu/core/services/db_proxy.dart';

mixin CbtQuestionMixin on BaseProvider {
  List<Map<String, dynamic>> _cbtQuestions = [];
  List<Map<String, dynamic>> get cbtQuestions => _cbtQuestions;

  Future<List<Map<String, dynamic>>> loadCbtQuestions(String examId) async {
    try {
      final r = await DbProxy.instance.from('cbt_questions').select().eq('school_id', schoolId).eq('exam_id', examId).order('created_at').get();
      _cbtQuestions = List<Map<String, dynamic>>.from(r);
      notifyListeners();
      return _cbtQuestions;
    } catch (e) {
      print('Error loading CBT questions: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> addCbtQuestion({
    required String examId,
    required String questionText,
    String? optionA,
    String? optionB,
    String? optionC,
    String? optionD,
    required String correctOption,
    String? explanation,
    int marks = 1,
    int timeAllocation = 0,
  }) async {
    try {
      final valid = {'a', 'b', 'c', 'd'};
      if (!valid.contains(correctOption.toLowerCase())) {
        throw Exception('correct_option must be a, b, c, or d');
      }
      final r = await DbProxy.instance.from('cbt_questions').insert({
        'school_id': schoolId,
        'exam_id': examId,
        'question_text': questionText,
        'option_a': optionA,
        'option_b': optionB,
        'option_c': optionC,
        'option_d': optionD,
        'correct_option': correctOption.toLowerCase(),
        'explanation': explanation,
        'marks': marks,
        'time_allocation': timeAllocation,
      });
      await loadCbtQuestions(examId);
      logAudit(action: 'create', tableName: 'cbt_questions', recordId: '');
      notifyListeners();
      return null;
    } catch (e) {
      print('Error adding CBT question: $e');
      return null;
    }
  }

  Future<bool> updateCbtQuestion(String questionId, Map<String, dynamic> updates) async {
    try {
      final u = Map<String, dynamic>.from(updates)..remove('id')..remove('school_id')..remove('exam_id')..remove('created_at');
      if (u.containsKey('correct_option')) { u['correct_option'] = u['correct_option'].toString().toLowerCase(); }
      if (u.isEmpty) return false;
      await DbProxy.instance.from('cbt_questions').eq('id', questionId).eq('school_id', schoolId).update(u);
      final existing = _cbtQuestions.cast<Map<String, dynamic>?>().firstWhere((x) => x?['id'].toString() == questionId, orElse: () => null);
      if (existing != null) await loadCbtQuestions(existing['exam_id'].toString());
      logAudit(action: 'update', tableName: 'cbt_questions', recordId: questionId, newData: u);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating CBT question: $e');
      return false;
    }
  }

  Future<bool> deleteCbtQuestion(String questionId) async {
    try {
      await DbProxy.instance.from('cbt_questions').eq('id', questionId).eq('school_id', schoolId).delete();
      _cbtQuestions.removeWhere((q) => q['id'].toString() == questionId);
      logAudit(action: 'delete', tableName: 'cbt_questions', recordId: questionId);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting CBT question: $e');
      return false;
    }
  }

  Future<bool> deleteAllCbtQuestions(String examId) async {
    try {
      await DbProxy.instance.from('cbt_questions').eq('exam_id', examId).eq('school_id', schoolId).delete();
      _cbtQuestions.removeWhere((q) => q['exam_id'].toString() == examId);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting all CBT questions: $e');
      return false;
    }
  }

  Future<bool> bulkImportCbtQuestions(String examId, List<Map<String, dynamic>> data) async {
    try {
      final rows = data.map((q) => {
        'school_id': schoolId, 'exam_id': examId, 'question_text': q['question_text'] ?? '',
        'option_a': q['option_a'], 'option_b': q['option_b'], 'option_c': q['option_c'], 'option_d': q['option_d'],
        'correct_option': (q['correct_option'] ?? 'a').toString().toLowerCase(),
        'explanation': q['explanation'], 'marks': q['marks'] ?? 1, 'time_allocation': q['time_allocation'] ?? 0,
      }).toList();
      int inserted = 0;
      for (int i = 0; i < rows.length; i++) {
        try { rows[i]['question_order'] = i + 1; await DbProxy.instance.from('cbt_questions').insert(rows[i]); inserted++; }
        catch (e) { print('Bulk insert failed at row ' + i.toString() + ': ' + e.toString()); }
      }
      await loadCbtQuestions(examId);
      logAudit(action: 'bulk_import', tableName: 'cbt_questions', newData: {'exam_id': examId, 'count': data.length});
      return true;
    } catch (e) {
      print('Error bulk importing CBT questions: $e');
      return false;
    }
  }

  List<Map<String, dynamic>> getShuffledCbtQuestions() {
    final safe = _cbtQuestions.map((q) => {
      'id': q['id'], 'question_text': q['question_text'], 'option_a': q['option_a'], 'option_b': q['option_b'],
      'option_c': q['option_c'], 'option_d': q['option_d'], 'marks': q['marks'], 'time_allocation': q['time_allocation'] ?? 0,
    }).toList();
    safe.shuffle();
    return safe;
  }

  Map<String, dynamic> calculateCbtScore(Map<String, String> answers) {
    int correct = 0, wrong = 0, unanswered = 0, totalMarks = 0;
    final details = <Map<String, dynamic>>[];
    for (final q in _cbtQuestions) {
      final qId = q['id'].toString();
      final submitted = answers[qId] ?? '';
      final correctOpt = (q['correct_option'] as String?) ?? '';
      if (submitted.isEmpty) { unanswered++; }
      else if (submitted == correctOpt) { correct++; totalMarks += (q['marks'] as int?) ?? 1; }
      else { wrong++; }
      details.add({'question_id': qId, 'submitted': submitted, 'correct': correctOpt, 'is_correct': submitted == correctOpt, 'marks_obtained': submitted == correctOpt ? (q['marks'] as int?) ?? 1 : 0});
    }
    return {
      'total_questions': _cbtQuestions.length, 'correct': correct, 'wrong': wrong, 'unanswered': unanswered, 'total_marks': totalMarks,
      'percentage': _cbtQuestions.isNotEmpty ? (totalMarks / _cbtQuestions.fold<int>(0, (s, q) => s + ((q['marks'] as int?) ?? 1))) * 100 : 0,
      'details': details,
    };
  }

  int get cbtQuestionCount => _cbtQuestions.length;
  int get cbtTotalMarks => _cbtQuestions.fold<int>(0, (sum, q) => sum + ((q['marks'] as int?) ?? 1));
}
