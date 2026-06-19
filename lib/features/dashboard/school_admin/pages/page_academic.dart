import 'package:smartedu/core/services/db_proxy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ==========================================
// File: lib/features/dashboard/school_admin/pages/page_academic.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/providers/school_admin_provider.dart';

class PageAcademic extends StatefulWidget {
  final List<Map<String, dynamic>> classes;
  final List<Map<String, dynamic>> academicYears;
  final void Function(List<Map<String, dynamic>>) onYearsUpdated;

  const PageAcademic({
    super.key,
    required this.classes,
    required this.academicYears,
    required this.onYearsUpdated,
  });

  @override
  State<PageAcademic> createState() => _PageAcademicState();
}

class _PageAcademicState extends State<PageAcademic> {
  List<Map<String, dynamic>> _terms = [];
  bool _loadingTerms = false;
  bool _loadingSessions = false;
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    Future.wait([_loadSessions(), _loadTerms()]);
  }

  // ── Helpers ──────────────────────────────────────────────

  String _currentSessionName() {
    try {
      final cur = _sessions.firstWhere((s) => s['is_current'] == true);
      return cur['name']?.toString() ?? 'Not Set';
    } catch (_) {
      return _sessions.isNotEmpty
          ? _sessions.first['name']?.toString() ?? 'Not Set'
          : 'Not Set';
    }
  }

  String _currentTermName() {
    try {
      final cur = _terms.firstWhere((t) => t['is_current'] == true);
      return cur['name']?.toString() ?? 'Not Set';
    } catch (_) {
      return _terms.isNotEmpty
          ? _terms.first['name']?.toString() ?? 'Not Set'
          : 'Not Set';
    }
  }

  String _getSessionName(String? sessionId) {
    if (sessionId == null) return '—';
    try {
      return _sessions
          .firstWhere((s) => s['id']?.toString() == sessionId)['name']
          ?.toString() ??
          '—';
    } catch (_) {
      return '—';
    }
  }

  String _friendlyError(dynamic e) {
    if (e is PostgrestException) {
      if (e.code == '23505') {
        return 'This name already exists. Please use a different name.';
      }
      if (e.code == '42501') {
        return 'Permission denied. RLS may still be enabled on this table.';
      }
      if (e.code == '23502') {
        return 'A required field is missing. Please check all fields.';
      }
      if (e.code == '23503') {
        return 'Cannot delete — linked to other records (e.g. scores).';
      }
      return e.message ?? 'Database error occurred.';
    }
    return e.toString();
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      ),
    );
  }

  void _showWarning(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE65100),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      ),
    );
  }

  // ─── SESSIONS CRUD ────────────────────────────────────────

  Future<void> _loadSessions() async {
    setState(() => _loadingSessions = true);
    try {
      final provider = context.read<SchoolAdminProvider>();
      final res = await DbProxy.instance.from('academic_sessions').select().eq('school_id', provider.schoolId).order('created_at').get();
      if (mounted) {
        setState(() {
          _sessions = List<Map<String, dynamic>>.from(res);
          _loadingSessions = false;
        });
      }
    } catch (e) {
      debugPrint('Load sessions error: $e');
      if (mounted) {
        setState(() => _loadingSessions = false);
        _showError('Failed to load sessions: ${_friendlyError(e)}');
      }
    }
  }

  Future<void> _addSession(String name) async {
    setState(() => _loadingSessions = true);
    try {
      final provider = context.read<SchoolAdminProvider>();
      final res = await DbProxy.instance.from('academic_sessions').insert({
        'school_id': provider.schoolId,
        'name': name.trim(),
        'is_current': _sessions.isEmpty,
      });
      if (mounted) {
        setState(() {
          _sessions.add(res.first);
          _loadingSessions = false;
        });
        widget.onYearsUpdated(_sessions);
        _showSuccess('Session added successfully');
      }
    } catch (e) {
      debugPrint('Add session error: $e');
      if (mounted) {
        setState(() => _loadingSessions = false);
        _showError('Failed to add session: ${_friendlyError(e)}');
      }
    }
  }

  Future<void> _deleteSession(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F), size: 22),
            SizedBox(width: 10),
            Text('Delete Session',
                style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$name"?\n\nThis will fail if the session has terms or other records linked to it.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _loadingSessions = true);
    try {
      await DbProxy.instance.from('academic_sessions').eq('id', id).delete();
      if (mounted) {
        setState(() {
          _sessions.removeWhere((s) => s['id'] == id);
          _loadingSessions = false;
        });
        widget.onYearsUpdated(_sessions);
        _showSuccess('Session deleted');
      }
    } catch (e) {
      debugPrint('Delete session error: $e');
      if (mounted) {
        setState(() => _loadingSessions = false);
        _showError('Failed to delete session: ${_friendlyError(e)}');
      }
    }
  }

  Future<void> _setCurrentSession(String id) async {
    setState(() => _loadingSessions = true);
    try {
      final provider = context.read<SchoolAdminProvider>();
      await DbProxy.instance.from('academic_sessions').eq('school_id', provider.schoolId).update({'is_current': false});
      await DbProxy.instance.from('academic_sessions').eq('id', id).update({'is_current': true});
      if (mounted) {
        setState(() {
          for (final s in _sessions) {
            s['is_current'] = s['id'] == id;
          }
          _loadingSessions = false;
        });
        widget.onYearsUpdated(_sessions);
        _showSuccess('Active session updated');
      }
    } catch (e) {
      debugPrint('Set current session error: $e');
      if (mounted) {
        setState(() => _loadingSessions = false);
        _showError('Failed to update: ${_friendlyError(e)}');
      }
    }
  }

  // ─── TERMS CRUD ───────────────────────────────────────────

  Future<void> _loadTerms() async {
    setState(() => _loadingTerms = true);
    try {
      final provider = context.read<SchoolAdminProvider>();
      final res = await DbProxy.instance.from('terms').select().eq('school_id', provider.schoolId).order('created_at').get();
      if (mounted) {
        setState(() => _terms = List<Map<String, dynamic>>.from(res));
      }
    } catch (e) {
      debugPrint('Load terms error: $e');
      if (mounted) _showError('Failed to load terms: ${_friendlyError(e)}');
    } finally {
      if (mounted) setState(() => _loadingTerms = false);
    }
  }

  Future<void> _addTerm(String name, String sessionId) async {
    try {
      final provider = context.read<SchoolAdminProvider>();
      final res = await DbProxy.instance.from('terms').insert({
        'school_id': provider.schoolId,
        'session_id': sessionId,
        'name': name.trim(),
        'is_current': _terms.isEmpty,
      });
      if (mounted) {
        setState(() => _terms.add(res.first));
        _showSuccess('Term added successfully');
      }
    } catch (e) {
      debugPrint('Add term error: $e');
      if (mounted) _showError('Failed to add term: ${_friendlyError(e)}');
    }
  }

  Future<void> _deleteTerm(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F), size: 22),
            SizedBox(width: 10),
            Text('Delete Term',
                style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$name"?\n\nThis will fail if the term is linked to any scores or records.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await DbProxy.instance.from('terms').eq('id', id).delete();
      if (mounted) {
        setState(() => _terms.removeWhere((t) => t['id'] == id));
        _showSuccess('Term deleted');
      }
    } catch (e) {
      debugPrint('Delete term error: $e');
      if (mounted) _showError('Failed to delete term: ${_friendlyError(e)}');
    }
  }

  Future<void> _setCurrentTerm(String id) async {
    try {
      final provider = context.read<SchoolAdminProvider>();
      await DbProxy.instance.from('terms').eq('school_id', provider.schoolId).update({'is_current': false});
      await DbProxy.instance.from('terms').eq('id', id).update({'is_current': true});
      if (mounted) {
        setState(() {
          for (final t in _terms) {
            t['is_current'] = t['id'] == id;
          }
        });
        _showSuccess('Active term updated');
      }
    } catch (e) {
      debugPrint('Set current term error: $e');
      if (mounted) _showError('Failed to update: ${_friendlyError(e)}');
    }
  }

  // ─── DIALOGS ──────────────────────────────────────────────

  void _showAddTermDialog() {
    final nameCtrl = TextEditingController();
    String? selectedSessionId;
    if (_sessions.isNotEmpty) {
      try {
        selectedSessionId =
            _sessions.firstWhere((s) => s['is_current'] == true)['id']
                ?.toString();
      } catch (_) {
        selectedSessionId = _sessions.first['id']?.toString();
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.date_range, size: 20, color: Color(0xFFE65100)),
              ),
              const SizedBox(width: 12),
              const Text('Add Term',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Color(0xFF111827),
                      letterSpacing: -0.3)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(fontSize: 15, color: Color(0xFF111827)),
                decoration: InputDecoration(
                  labelText: 'Term Name (e.g. First Term)',
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  border: const OutlineInputBorder(),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE65100)),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              if (_sessions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Color(0xFFE65100)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No sessions exist yet. Please add a session first.',
                          style: TextStyle(color: Color(0xFFE65100), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: selectedSessionId,
                  decoration: InputDecoration(
                    labelText: 'Belongs to Session',
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                    border: const OutlineInputBorder(),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE65100)),
                    ),
                    prefixIcon:
                        const Icon(Icons.calendar_today, color: Color(0xFFE65100)),
                  ),
                  items: _sessions
                      .map((s) => DropdownMenuItem(
                          value: s['id']?.toString(),
                          child: Text(s['name'] ?? 'Unknown',
                              style: const TextStyle(color: Color(0xFF111827)))))
                      .toList(),
                  onChanged: (v) => setDialog(() => selectedSessionId = v),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                if (_sessions.isEmpty) {
                  Navigator.pop(ctx);
                  _showWarning('Create a session first before adding terms');
                  return;
                }
                if (selectedSessionId == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: const Text('Please select a session'),
                      backgroundColor: const Color(0xFFD32F2F),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                _addTerm(name, selectedSessionId!);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Add Term', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSessionDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_today, size: 20, color: Color(0xFF1A237E)),
            ),
            const SizedBox(width: 12),
            const Text('Add Session',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Color(0xFF111827),
                    letterSpacing: -0.3)),
          ],
        ),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: 15, color: Color(0xFF111827)),
          decoration: InputDecoration(
            labelText: 'Session Name (e.g. 2024/2025)',
            labelStyle: TextStyle(color: Colors.grey.shade600),
            border: const OutlineInputBorder(),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF1A237E)),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = ctrl.text.trim();
              if (val.isEmpty) return;
              if (_sessions.any((s) =>
                  s['name']?.toString().trim().toLowerCase() == val.toLowerCase())) {
                Navigator.pop(ctx);
                _showWarning('A session with this name already exists.');
                return;
              }
              Navigator.pop(ctx);
              _addSession(val);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Add Session', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SchoolAdminProvider>();
    final setup = provider.schoolSetup;
    final curSession = _currentSessionName();
    final curTerm = _currentTermName();

    return Container(
      color: const Color(0xFFF7F8FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page Header ──
            const Text(
              'Academic Setup',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage sessions, terms, and view class populations',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),

            // ── Current Active Setup Card ──
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8EAED)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.tune_rounded,
                              size: 20, color: Color(0xFF1A237E)),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Current Active Setup',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _infoRow(Icons.calendar_today, 'Active Session', curSession),
                        const SizedBox(height: 4),
                        _infoRow(Icons.date_range, 'Active Term', curTerm),
                        const SizedBox(height: 4),
                        _infoRow(Icons.quiz_rounded, 'Exam Template',
                            setup['examTemplate'] ?? 'WAEC'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Sessions Section ──
            _sectionHeader(
              icon: Icons.calendar_today,
              iconBg: const Color(0xFFF0F4FF),
              iconColor: const Color(0xFF1A237E),
              title: 'Academic Sessions',
              count: _sessions.length,
              isLoading: _loadingSessions,
              buttonLabel: 'Add Session',
              buttonColor: const Color(0xFF1A237E),
              onButtonPressed:
                  _loadingSessions ? null : _showAddSessionDialog,
            ),
            const SizedBox(height: 12),
            if (_loadingSessions && _sessions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: Color(0xFF1A237E)),
                ),
              )
            else if (_sessions.isEmpty)
              _emptyCard(
                icon: Icons.calendar_today_outlined,
                message: 'No sessions yet. Tap "Add Session" to start.',
              )
            else
              ..._sessions.asMap().entries.map((entry) {
                final index = entry.key;
                final s = entry.value;
                final name = s['name']?.toString() ?? 'Unknown';
                final isCurrent = s['is_current'] == true;
                return _sessionCard(s, name, isCurrent, index);
              }),
            const SizedBox(height: 32),

            // ── Terms Section ──
            _sectionHeader(
              icon: Icons.date_range,
              iconBg: const Color(0xFFFFF3E0),
              iconColor: const Color(0xFFE65100),
              title: 'Terms',
              count: _terms.length,
              isLoading: _loadingTerms,
              buttonLabel: 'Add Term',
              buttonColor: const Color(0xFFE65100),
              onButtonPressed: _loadingTerms ? null : _showAddTermDialog,
            ),
            const SizedBox(height: 12),
            if (_loadingTerms && _terms.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: Color(0xFFE65100)),
                ),
              )
            else if (_terms.isEmpty)
              _emptyCard(
                icon: Icons.date_range_outlined,
                message: _sessions.isEmpty
                    ? 'Create a session first, then add terms here.'
                    : 'No terms yet. Tap "Add Term" to create one.',
              )
            else
              ..._terms.asMap().entries.map((entry) {
                final index = entry.key;
                final t = entry.value;
                final name = t['name']?.toString() ?? 'Unknown';
                final isCurrent = t['is_current'] == true;
                final sessionName =
                    _getSessionName(t['session_id']?.toString());
                return _termCard(t, name, isCurrent, sessionName, index);
              }),
            const SizedBox(height: 32),

            // ── Class Population ──
            _sectionHeader(
              icon: Icons.class_rounded,
              iconBg: const Color(0xFFF3E5F5),
              iconColor: const Color(0xFF7B1FA2),
              title: 'Class Population',
              count: widget.classes.length,
              isLoading: false,
              buttonLabel: null,
              buttonColor: null,
              onButtonPressed: null,
            ),
            const SizedBox(height: 12),
            if (widget.classes.isEmpty)
              _emptyCard(
                icon: Icons.class_outlined,
                message: 'No classes created yet.',
              )
            else
              ...widget.classes.asMap().entries.map((entry) {
                final index = entry.key;
                final c = entry.value;
                return _classCard(c, index);
              }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Reusable Widgets ────────────────────────────────────

  Widget _sectionHeader({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required int count,
    required bool isLoading,
    String? buttonLabel,
    Color? buttonColor,
    VoidCallback? onButtonPressed,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: iconColor.withOpacity(0.3), width: 2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(width: 8),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
              ),
            ),
          const Spacer(),
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          if (buttonLabel != null && buttonColor != null)
            SizedBox(
              height: 34,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 15),
                label: Text(buttonLabel, style: const TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                onPressed: onButtonPressed,
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyCard({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 24, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sessionCard(Map<String, dynamic> s, String name, bool isCurrent, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFFF0FFF4) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? const Color(0xFFA5D6A7) : const Color(0xFFE8EAED),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCurrent
                    ? const Color(0xFFC8E6C9)
                    : const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.calendar_today,
                size: 20,
                color: isCurrent
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF1A237E),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  if (isCurrent)
                    const SizedBox(height: 3),
                  if (isCurrent)
                    Text(
                      'Currently active session',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                      ),
                    ),
                ],
              ),
            ),
            if (isCurrent)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 13, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Current',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              _smallButton(
                icon: Icons.check_circle_outline,
                label: 'Set Active',
                iconColor: const Color(0xFF1A237E),
                textColor: const Color(0xFF1A237E),
                onTap: () => _setCurrentSession(s['id'].toString()),
              ),
              const SizedBox(width: 6),
              _smallButton(
                icon: Icons.delete_outline,
                label: 'Delete',
                iconColor: Colors.red.shade400,
                textColor: Colors.red.shade400,
                onTap: () => _deleteSession(s['id'].toString(), name),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _termCard(Map<String, dynamic> t, String name, bool isCurrent,
      String sessionName, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFFFFF8E1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? const Color(0xFFFFE082) : const Color(0xFFE8EAED),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCurrent
                    ? const Color(0xFFFFE082)
                    : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.date_range,
                size: 20,
                color: isCurrent
                    ? const Color(0xFFE65100)
                    : Colors.orange.shade400,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.link_outlined,
                          size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        sessionName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 10),
                        Icon(Icons.radio_button_checked,
                            size: 12, color: Colors.orange.shade700),
                        const SizedBox(width: 3),
                        Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isCurrent)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE65100),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 13, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Current',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              _smallButton(
                icon: Icons.check_circle_outline,
                label: 'Set Active',
                iconColor: const Color(0xFFE65100),
                textColor: const Color(0xFFE65100),
                onTap: () => _setCurrentTerm(t['id'].toString()),
              ),
              const SizedBox(width: 6),
              _smallButton(
                icon: Icons.delete_outline,
                label: 'Delete',
                iconColor: Colors.red.shade400,
                textColor: Colors.red.shade400,
                onTap: () => _deleteTerm(t['id'].toString(), name),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _classCard(Map<String, dynamic> c, int index) {
    final count = c['studentCount'] ?? 0;
    final tier = (c['tier'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.class_rounded,
                  size: 20, color: Color(0xFF7B1FA2)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                "${c['name']} - ${c['section'] ?? ''}",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            if (tier.isNotEmpty) ...[
              _tierBadge(tier),
              const SizedBox(width: 12),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count student${count != 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7B1FA2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallButton({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: textColor.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tierBadge(String tier) {
    final colorMap = {
      'SSS': const Color(0xFFE3F2FD),
      'JSS': const Color(0xFFFFF3E0),
      'PRIMARY': const Color(0xFFF3E5F5),
    };
    final textMap = {
      'SSS': const Color(0xFF1565C0),
      'JSS': const Color(0xFFE65100),
      'PRIMARY': const Color(0xFF7B1FA2),
    };
    final bg = colorMap[tier] ?? const Color(0xFFF5F5F5);
    final fg = textMap[tier] ?? Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        tier,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
