// TODO: Migrate to DbProxy once cbt_exams and cbt_questions are added to teacher whitelist in db-proxy Edge Function.
import 'package:supabase_flutter/supabase_flutter.dart';
import 'teacher_base.dart';

mixin TeacherCbtMixin on TeacherBase {
  List<Map<String, dynamic>> _myCbtExams = [];
  List<Map<String, dynamic>> _myCbtQuestions = [];
  List<Map<String, dynamic>> get myCbtExams => _myCbtExams;
  List<Map<String, dynamic>> get myCbtQuestions => _myCbtQuestions;

  Future<void> loadMyCbtExams() async {
    try {
      final r = await Supabase.instance.client
          .from('cbt_exams')
          .select('*, subjects(name, code), classes(name, section)')
          .eq('school_id', schoolId)
          .eq('created_by', teacherId)
          .order('created_at', ascending: false);
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
      final r = await Supabase.instance.client
          .from('cbt_exams')
          .insert({
            'school_id': schoolId,
            'title': title,
            'subject_id': subjectId,
            'class_id': classId,
            'duration_minutes': durationMinutes,
            'total_questions': totalQuestions,
            'is_active': false,
            'created_by': teacherId,
          })
          .select('*, subjects(name, code), classes(name, section)')
          .single();
      _myCbtExams.insert(0, r);
      notifyListeners();
      return r;
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
      await Supabase.instance.client
          .from('cbt_exams')
          .update({'is_active': ns})
          .eq('id', id)
          .eq('school_id', schoolId);
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
      await Supabase.instance.client
          .from('cbt_exams')
          .delete()
          .eq('id', id)
          .eq('school_id', schoolId);
      _myCbtExams.removeWhere((e) => e['id'].toString() == id);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> loadQuestions(String examId) async {
    try {
      final r = await Supabase.instance.client
          .from('cbt_questions')
          .select()
          .eq('school_id', schoolId)
          .eq('exam_id', examId)
          .order('created_at');
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
  }) async {
    try {
      final r = await Supabase.instance.client
          .from('cbt_questions')
          .insert({
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
          })
          .select()
          .single();
      _myCbtQuestions.add(r);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error adding question: $e');
      return false;
    }
  }

  Future<bool> deleteQuestion(String qId) async {
    try {
      await Supabase.instance.client
          .from('cbt_questions')
          .delete()
          .eq('id', qId)
          .eq('school_id', schoolId);
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
          }).toList();
      for (int i = 0; i < rows.length; i += 50) {
        final end = i + 50 > rows.length ? rows.length : i + 50;
        await Supabase.instance.client
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
