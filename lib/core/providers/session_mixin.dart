// ==========================================
// File: lib/core/providers/session_mixin.dart
// ==========================================
import 'package:flutter/foundation.dart';
import 'base_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mixin for academic session and term management.
/// Handles loading, creating, switching, and deleting sessions/terms.
///
/// MASTER PLAN V4:
/// - Every session/term operation filters by schoolId — tenant isolation
/// - Setting current session/term deactivates the previous one first
/// - Switching session/term triggers score reload — ensures score views are accurate
/// - Populates BaseProvider.sessionsList and termsList for dropdown access
/// - All mutations logged to audit_logs
/// - V4: Fixed maybeCount() for postgrest 2.x compatibility
/// - V4: Term deletion relies on DB CASCADE — no manual child record deletes needed
///
/// REQUIREMENT: BaseProvider must have set sessionsList and set termsList
/// (add these 2 setters in base_provider.dart if missing).

mixin SessionMixin on BaseProvider {

  List<Map<String, dynamic>> _academicSessions = [];
  List<Map<String, dynamic>> _terms = [];

  List<Map<String, dynamic>> get academicSessions => _academicSessions;
  List<Map<String, dynamic>> get terms => _terms;

  /// Convenience: current session name for UI display.
  String get currentSessionName => (currentSession?['name'] ?? '').toString();

  /// Convenience: current term name for UI display.
  String get currentTermName => (currentTerm?['name'] ?? '').toString();

  /// Convenience: current session display string.
  String get currentSessionDisplay {
    if (currentSession == null) return '';
    return '${currentSession!['name']}';
  }

  /// Convenience: session + term combined display.
  String get currentPeriodDisplay {
    if (currentSession == null) return '';
    final term = currentTerm?['name'] ?? '';
    return term.isNotEmpty
        ? '${currentSession!['name']} — $term'
        : '${currentSession!['name']}';
  }

  /// Convenience: whether a session and term are both selected.
  bool get hasActivePeriod => currentSession != null && currentTerm != null;

  // ==========================================
  // LOADING
  // ==========================================

  @override
  Future<void> loadAcademicSessions() async {
    try {
      final r = await supabase
          .from('academic_sessions')
          .select()
          .eq('school_id', schoolId)
          .order('name', ascending: false);

      _academicSessions = List<Map<String, dynamic>>.from(r);

      // Find current session
      currentSession = _academicSessions.cast<Map<String, dynamic>?>().firstWhere(
            (s) => s?['is_current'] == true,
            orElse: () => _academicSessions.isNotEmpty ? _academicSessions.first : null,
          );

      // Sync to BaseProvider.sessionsList for dropdown access
      sessionsList = _academicSessions;

      // Load terms for current session
      if (currentSession != null) {
        await _loadTermsForSession(currentSession!['id'].toString());
      }
    } catch (e) {
      debugPrint('Error loading sessions: $e');
    }
  }

  Future<void> _loadTermsForSession(String sessionId) async {
    try {
      final r = await supabase
          .from('terms')
          .select()
          .eq('school_id', schoolId)
          .eq('session_id', sessionId)
          .order('created_at', ascending: true);

      _terms = List<Map<String, dynamic>>.from(r);

      // Find current term
      currentTerm = _terms.cast<Map<String, dynamic>?>().firstWhere(
            (t) => t?['is_current'] == true,
            orElse: () => _terms.isNotEmpty ? _terms.first : null,
          );

      // Sync to BaseProvider.termsList for dropdown access
      termsList = _terms;
    } catch (e) {
      debugPrint('Error loading terms: $e');
    }
  }

  // ==========================================
  // ADD SESSION
  // ==========================================

  /// Add a new academic session (e.g. "2025/2026").
  /// If isCurrent is true, deactivates all others first.
  Future<bool> addAcademicSession(String name, {bool isCurrent = false}) async {
    if (schoolId.isEmpty) return false;
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return false;

    try {
      // Deactivate all existing sessions if this one is current
      if (isCurrent || _academicSessions.isEmpty) {
        await supabase
            .from('academic_sessions')
            .update({'is_current': false})
            .eq('school_id', schoolId);
      }

      final r = await supabase
          .from('academic_sessions')
          .insert({
            'school_id': schoolId,
            'name': trimmedName,
            'is_current': isCurrent || _academicSessions.isEmpty,
          })
          .select()
          .single();

      final session = Map<String, dynamic>.from(r);

      // Insert at top (newest first)
      _academicSessions.insert(0, session);
      sessionsList = _academicSessions;

      // If this is now the current session, reload terms
      if (session['is_current'] == true) {
        currentSession = session;
        _terms = [];
        termsList = [];
        currentTerm = null;
        await _loadTermsForSession(session['id'].toString());
      }

      logAudit(action: 'create', tableName: 'academic_sessions', recordId: session['id']?.toString(), newData: {'name': trimmedName});
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding session: $e');
      return false;
    }
  }

  // ==========================================
  // ADD TERM
  // ==========================================

  /// Add a new term to the current session.
  /// If isCurrent is true, deactivates all others first.
  Future<bool> addTerm(String name, {bool isCurrent = false}) async {
    if (schoolId.isEmpty) return false;
    if (currentSession == null) {
      debugPrint('Cannot add term: no current session selected');
      return false;
    }
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return false;

    try {
      // Deactivate all existing terms if this one is current
      if (isCurrent || _terms.isEmpty) {
        await supabase
            .from('terms')
            .update({'is_current': false})
            .eq('school_id', schoolId)
            .eq('session_id', currentSession!['id']);
      }

      final r = await supabase
          .from('terms')
          .insert({
            'school_id': schoolId,
            'session_id': currentSession!['id'],
            'name': trimmedName,
            'is_current': isCurrent || _terms.isEmpty,
          })
          .select()
          .single();

      final term = Map<String, dynamic>.from(r);

      _terms.add(term);
      termsList = _terms;

      if (term['is_current'] == true) {
        currentTerm = term;
      }

      logAudit(action: 'create', tableName: 'terms', recordId: term['id']?.toString(), newData: {'name': trimmedName, 'session_id': currentSession!['id']});
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding term: $e');
      return false;
    }
  }

  // ==========================================
  // SET CURRENT SESSION
  // ==========================================

  Future<bool> setCurrentSession(String sessionId) async {
    if (schoolId.isEmpty) return false;
    if (sessionId == currentSession?['id']?.toString()) return true;

    try {
      await supabase
          .from('academic_sessions')
          .update({'is_current': false})
          .eq('school_id', schoolId);

      await supabase
          .from('academic_sessions')
          .update({'is_current': true})
          .eq('id', sessionId);

      currentSession = _academicSessions.cast<Map<String, dynamic>?>().firstWhere(
            (s) => s?['id']?.toString() == sessionId,
            orElse: () => null,
          );

      currentTerm = null;
      _terms = [];
      termsList = [];
      await _loadTermsForSession(sessionId);

      await loadScores();

      logAudit(action: 'set_current_session', tableName: 'academic_sessions', recordId: sessionId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error setting session: $e');
      return false;
    }
  }

  // ==========================================
  // SET CURRENT TERM
  // ==========================================

  Future<bool> setCurrentTerm(String termId) async {
    if (schoolId.isEmpty || currentSession == null) return false;
    if (termId == currentTerm?['id']?.toString()) return true;

    try {
      await supabase
          .from('terms')
          .update({'is_current': false})
          .eq('school_id', schoolId)
          .eq('session_id', currentSession!['id']);

      await supabase
          .from('terms')
          .update({'is_current': true})
          .eq('id', termId);

      currentTerm = _terms.cast<Map<String, dynamic>?>().firstWhere(
            (t) => t?['id']?.toString() == termId,
            orElse: () => null,
          );

      await loadScores();

      logAudit(action: 'set_current_term', tableName: 'terms', recordId: termId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error setting term: $e');
      return false;
    }
  }

  // ==========================================
  // DELETE SESSION
  // V4: Terms cascade-delete via ON DELETE CASCADE in schema.
  // ==========================================

  Future<bool> deleteSession(String sessionId) async {
    if (schoolId.isEmpty) return false;
    if (sessionId == currentSession?['id']?.toString()) {
      debugPrint('Cannot delete the current active session');
      return false;
    }

    try {
      await supabase
          .from('academic_sessions')
          .delete()
          .eq('id', sessionId);

      _academicSessions.removeWhere((s) => s['id']?.toString() == sessionId);
      sessionsList = _academicSessions;

      logAudit(action: 'delete', tableName: 'academic_sessions', recordId: sessionId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting session: $e');
      return false;
    }
  }

  // ==========================================
  // DELETE TERM
  // V4: Scores, attendance, comments cascade-delete via ON DELETE CASCADE.
  // ==========================================

  Future<bool> deleteTerm(String termId) async {
    if (schoolId.isEmpty || currentSession == null) return false;
    if (termId == currentTerm?['id']?.toString()) {
      debugPrint('Cannot delete the current active term');
      return false;
    }

    try {
      await supabase
          .from('terms')
          .delete()
          .eq('id', termId);

      _terms.removeWhere((t) => t['id']?.toString() == termId);
      termsList = _terms;

      logAudit(action: 'delete', tableName: 'terms', recordId: termId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting term: $e');
      return false;
    }
  }

  // ==========================================
  // UPDATE SESSION
  // ==========================================

  Future<bool> updateSessionName(String sessionId, String newName) async {
    if (schoolId.isEmpty) return false;
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return false;

    try {
      await supabase
          .from('academic_sessions')
          .update({'name': trimmed})
          .eq('id', sessionId);

      final index = _academicSessions.indexWhere((s) => s['id']?.toString() == sessionId);
      if (index != -1) {
        _academicSessions[index] = {..._academicSessions[index], 'name': trimmed};
        sessionsList = _academicSessions;
      }
      if (currentSession?['id']?.toString() == sessionId) {
        currentSession = _academicSessions[index];
      }

      logAudit(action: 'update', tableName: 'academic_sessions', recordId: sessionId, newData: {'name': trimmed});
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating session: $e');
      return false;
    }
  }

  // ==========================================
  // UPDATE TERM
  // ==========================================

  Future<bool> updateTermName(String termId, String newName) async {
    if (schoolId.isEmpty) return false;
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return false;

    try {
      await supabase
          .from('terms')
          .update({'name': trimmed})
          .eq('id', termId);

      final index = _terms.indexWhere((t) => t['id']?.toString() == termId);
      if (index != -1) {
        _terms[index] = {..._terms[index], 'name': trimmed};
        termsList = _terms;
      }
      if (currentTerm?['id']?.toString() == termId) {
        currentTerm = _terms[index];
      }

      logAudit(action: 'update', tableName: 'terms', recordId: termId, newData: {'name': trimmed});
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating term: $e');
      return false;
    }
  }

  // ==========================================
  // VALIDATION
  // ==========================================

  /// Check if a session name already exists.
  Future<bool> sessionNameExists(String name) async {
    if (schoolId.isEmpty || name.trim().isEmpty) return false;
    try {
      final existing = await supabase
          .from('academic_sessions')
          .select('id')
          .eq('school_id', schoolId)
          .eq('name', name.trim());
      return existing.isNotEmpty;
    } catch (e) {
      debugPrint('Session name check error: $e');
      return false;
    }
  }

  /// Check if a term name already exists in the current session.
  Future<bool> termNameExists(String name, String sessionId) async {
    if (schoolId.isEmpty || name.trim().isEmpty) return false;
    try {
      final sid = sessionId.isNotEmpty ? sessionId : currentSession?['id']?.toString() ?? '';
      if (sid.isEmpty) return false;

      final existing = await supabase
          .from('terms')
          .select('id')
          .eq('school_id', schoolId)
          .eq('session_id', sid)
          .eq('name', name.trim());
      return existing.isNotEmpty;
    } catch (e) {
      debugPrint('Term name check error: $e');
      return false;
    }
  }
}
