import 'package:smartedu/core/services/db_proxy.dart';
import 'teacher_base.dart';

mixin TeacherCbtMixin on TeacherBase {
  List<Map<String, dynamic>> _myCbtExams = [];
  List<Map<String, dynamic>> _myCbtQuestions = [];
  List<Map<String, dynamic>> get myCbtExams => _myCbtExams;
  List<Map<String, dynamic>> get myCbtQuestions => _myCbtQuestions;

  Future<void> loadMyCbtExams() async {
    try {
      final r = await DbProxy.instance
          .from('cbt_exams')
          .select('*, subjects(name, code), classes(name, section)')
          .eq('created_by', teacherId)
          .order('created_at', ascending: false)
          .get();
      _myCbtExams = List<Map<String, dynamic>>.from(r);
      notifyListeners();
    } catch (e) {
      print('Error loading CBT exams: $e');
    }
  }

  Future<Map<String, dynamic>?> createCbtExam({
    required String title,
    required String subjectId,
    required String classId,
    int durationMinutes = 60,
    int totalQuestions = 50,
  }) async {
    final isAssigned = assignedSubjects.any((a) =>
        a['class_id']?.toString() == classId &&
        a['subject_id']?.toString() == subjectId);
    if (!isAssigned) {
      print('CBT blocked: teacher not assigned to class $classId subject $subjectId');
      return null;
    }
    try {
      await DbProxy.instance.from('cbt_exams').insert({
            'school_id': schoolId,
            'title': title,
            'subject_id': subjectId,
            'class_id': classId,
            'duration_minutes': durationMinutes,
            'total_questions': totalQuestions,
            'is_active': false,
            'created_by': teacherId,
          });
      await loadMyCbtExams();
      return _myCbtExams.isNotEmpty ? _myCbtExams.first : null;
    } catch (e) {
      print('Error creating CBT exam: $e');
      return null;
    }
  }

  Future<bool> toggleCbtExam(String id) async {
    try {
      final e = _myCbtExams.firstWhere(
          (e) => e['id'].toString() == id, orElse: () => {});
      if (e.isEmpty) return false;
      final ns = !(e['is_active'] as bool? ?? false);
      await DbProxy.instance.from('cbt_exams').eq('id', id).update({'is_active': ns});
      final i = _myCbtExams.indexWhere((e) => e['id'].toString() == id);
      if (i != -1) {
        _myCbtExams[i] = Map<String, dynamic>.from(_myCbtExams[i]);
        _myCbtExams[i]['is_active'] = ns;
      }
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCbtExam(String id) async {
    try {
      await DbProxy.instance.from('cbt_exams').eq('id', id).delete();
      _myCbtExams.removeWhere((e) => e['id'].toString() == id);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> loadQuestions(String examId) async {
    try {
      final r = await DbProxy.instance
          .from('cbt_questions')
          .select()
          .eq('exam_id', examId)
          .order('created_at')
          .get();
      _myCbtQuestions = List<Map<String, dynamic>>.from(r);
      return _myCbtQuestions;
    } catch (e) {
      return [];
    }
  }

  Future<bool> addQuestion({
    required String examId,
    required String questionText,
    required String correctOption,
    String? optionA,
    String? optionB,
    String? optionC,
    String? optionD,
    String? explanation,
    int marks = 1,
    int timeAllocation = 0,
  }) async {
    try {
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
      _myCbtQuestions.add(r.first);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error adding question: $e');
      return false;
    }
  }

  Future<bool> updateQuestion({
    required String questionId,
    required String questionText,
    required String correctOption,
    String? optionA,
    String? optionB,
    String? optionC,
    String? optionD,
    String? explanation,
    int marks = 1,
    int timeAllocation = 0,
  }) async {
    try {
      await DbProxy.instance.from('cbt_questions').eq('id', questionId).update({
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
      final i = _myCbtQuestions.indexWhere((q) => q['id'].toString() == questionId);
      if (i != -1) {
        _myCbtQuestions[i] = Map<String, dynamic>.from(_myCbtQuestions[i]);
        _myCbtQuestions[i]['question_text'] = questionText;
        _myCbtQuestions[i]['option_a'] = optionA;
        _myCbtQuestions[i]['option_b'] = optionB;
        _myCbtQuestions[i]['option_c'] = optionC;
        _myCbtQuestions[i]['option_d'] = optionD;
        _myCbtQuestions[i]['correct_option'] = correctOption.toLowerCase();
        _myCbtQuestions[i]['explanation'] = explanation;
        _myCbtQuestions[i]['marks'] = marks;
        _myCbtQuestions[i]['time_allocation'] = timeAllocation;
      }
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating question: $e');
      return false;
    }
  }

  Future<bool> deleteQuestion(String qId) async {
    try {
      await DbProxy.instance.from('cbt_questions').eq('id', qId).delete();
      _myCbtQuestions.removeWhere((q) => q['id'].toString() == qId);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> bulkImportQuestions(
      String examId, List<Map<String, dynamic>> data) async {
    try {
      final rows = data.map((q) => {
            'school_id': schoolId,
            'exam_id': examId,
            'question_text': q['question_text'] ?? '',
            'option_a': q['option_a'],
            'option_b': q['option_b'],
            'option_c': q['option_c'],
            'option_d': q['option_d'],
            'correct_option':
                (q['correct_option'] ?? 'a').toString().toLowerCase(),
            'explanation': q['explanation'],
            'marks': q['marks'] ?? 1,
            'time_allocation': q['time_allocation'] ?? 0,
          }).toList();
      for (int i = 0; i < rows.length; i += 50) {
        final end = i + 50 > rows.length ? rows.length : i + 50;
        await DbProxy.instance
            .from('cbt_questions')
            .insert(rows.sublist(i, end));
      }
      await loadQuestions(examId);
      return true;
    } catch (e) {
      print('Error bulk importing: $e');
      return false;
    }
  }
}
