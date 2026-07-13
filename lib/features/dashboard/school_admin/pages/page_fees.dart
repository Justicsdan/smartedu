import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/services/db_proxy.dart';
import '../../../../core/providers/school_admin_provider.dart';

class PageFees extends StatefulWidget {
  const PageFees({super.key});
  @override
  State<PageFees> createState() => _PageFeesState();
}

class _PageFeesState extends State<PageFees> with TickerProviderStateMixin {
  late final TabController _tabController;
  bool _loading = true;
  bool _saving = false;
  List<Map<String, dynamic>> _feeTypes = [];
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _feeAssignments = [];
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _students = [];
  String? _filterClassId;
  String? _filterStudentId;
  String? _filterFeeTypeId;
  String? _filterStatus;

  String? _rpClassId;
  String? _rpStudentId;
  String? _rpFeeTypeId;
  final _rpAmountCtrl = TextEditingController();
  String _rpMethod = 'Cash';
  DateTime _rpDate = DateTime.now();
  final _rpReceiptCtrl = TextEditingController();
  final _rpRefCtrl = TextEditingController();
  final _rpRemarkCtrl = TextEditingController();
  final _rpStudentSearchCtrl = TextEditingController();
  String _rpStudentSearch = '';
  final _histStudentSearchCtrl = TextEditingController();
  String _histStudentSearch = '';

  String? _postClassId;
  String? _postFeeTypeId;
  DateTime? _postDueDate;
  bool _postSaving = false;
  Set<String> _selectedPostIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _rpReceiptCtrl.text = 'RCP-${DateTime.now().millisecondsSinceEpoch}';
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rpAmountCtrl.dispose();
    _rpReceiptCtrl.dispose();
    _rpRefCtrl.dispose();
    _rpRemarkCtrl.dispose();
    _rpStudentSearchCtrl.dispose();
    _histStudentSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final p = context.read<SchoolAdminProvider>();
    final sid = p.schoolId;
    final results = await Future.wait([
      DbProxy.instance.from('fee_types').select().eq('school_id', sid).order('name').get(),
      DbProxy.instance.from('fee_payments').select().eq('school_id', sid).order('payment_date', ascending: false).get(),
      DbProxy.instance.from('classes').select().eq('school_id', sid).order('name').get(),
      DbProxy.instance.from('students').select('id, first_name, last_name, class_id, admission_no').eq('school_id', sid).order('first_name').get(),
      DbProxy.instance.from('fee_assignments').select('*').eq('school_id', sid).order('assigned_at', ascending: false).get(),
    ]);
    if (!mounted) return;
    setState(() {
      _feeTypes = List<Map<String, dynamic>>.from(results[0]);
      _payments = List<Map<String, dynamic>>.from(results[1]);
      _classes = List<Map<String, dynamic>>.from(results[2]);
      _students = List<Map<String, dynamic>>.from(results[3]);
      _feeAssignments = List<Map<String, dynamic>>.from(results[4]);
      _loading = false;
    });
  }

  String _studentName(String? id) {
    if (id == null) return '\u2014';
    for (final s in _students) {
      if (s['id'] == id) {
        return '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
      }
    }
    return '\u2014';
  }

  String _feeTypeName(String? id) {
    if (id == null) return '\u2014';
    for (final ft in _feeTypes) {
      if (ft['id'] == id) return ft['name'] ?? '\u2014';
    }
    return '\u2014';
  }

  double _getOutstanding(String? studentId, String? feeTypeId) {
    if (studentId == null || feeTypeId == null) return 0;
    final p = context.read<SchoolAdminProvider>();
    final sid = p.currentSession?['id']?.toString() ?? '';
    final tid = p.currentTerm?['id']?.toString() ?? '';
    for (final a in _feeAssignments) {
      if (a['student_id'] == studentId &&
          a['fee_type_id'] == feeTypeId &&
          a['session_id']?.toString() == sid &&
          a['term_id']?.toString() == tid) {
        final owed = (a['amount_owed'] ?? 0).toDouble();
        final paid = (a['amount_paid'] ?? 0).toDouble();
        return (owed - paid).clamp(0.0, double.infinity);
      }
    }
    return 0;
  }

  List<Map<String, dynamic>> get _postableStudents {
    if (_postClassId == null) return [];
    var list = _students.where((s) => s['class_id'] == _postClassId).toList();
    if (_postFeeTypeId != null) {
      final p = context.read<SchoolAdminProvider>();
      final sid = p.currentSession?['id']?.toString() ?? '';
      final tid = p.currentTerm?['id']?.toString() ?? '';
      final assigned = _feeAssignments
          .where((a) =>
              a['fee_type_id'] == _postFeeTypeId &&
              a['session_id']?.toString() == sid &&
              a['term_id']?.toString() == tid)
          .map((a) => a['student_id']?.toString() ?? '')
          .toSet();
      list = list.where((s) => !assigned.contains(s['id']?.toString() ?? '')).toList();
    }
    return list;
  }

  bool get _allPostSelected =>
      _postableStudents.isNotEmpty && _selectedPostIds.length == _postableStudents.length;

  void _toggleAllPost() {
    setState(() {
      if (_allPostSelected) {
        _selectedPostIds.clear();
      } else {
        _selectedPostIds = _postableStudents.map((s) => s['id'] as String).toSet();
      }
    });
  }

  void _togglePostStudent(String id) {
    setState(() {
      if (_selectedPostIds.contains(id)) {
        _selectedPostIds.remove(id);
      } else {
        _selectedPostIds.add(id);
      }
    });
  }

  List<Map<String, dynamic>> get _rpFilteredStudents {
    var list = _rpClassId == null
        ? _students
        : _students.where((s) => s['class_id'] == _rpClassId).toList();
    if (_rpStudentSearch.isNotEmpty) {
      final q = _rpStudentSearch.toLowerCase();
      list = list.where((s) {
        final name = '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.toLowerCase();
        final adm = (s['admission_no'] ?? '').toString().toLowerCase();
        return name.contains(q) || adm.contains(q);
      }).toList();
    }
    return list;
  }

  List<Map<String, dynamic>> get _filteredAssignments {
    var list = _feeAssignments;
    if (_filterClassId != null) {
      final ids = _students
          .where((s) => s['class_id'] == _filterClassId)
          .map((s) => s['id'] as String)
          .toSet();
      list = list.where((a) => ids.contains(a['student_id'])).toList();
    }
    if (_filterStudentId != null) {
      list = list.where((a) => a['student_id'] == _filterStudentId).toList();
    }
    if (_filterFeeTypeId != null) {
      list = list.where((a) => a['fee_type_id'] == _filterFeeTypeId).toList();
    }
    if (_filterStatus != null) {
      list = list.where((a) => a['status'] == _filterStatus).toList();
    }
    return list;
  }

  List<Map<String, dynamic>> get _historyFilteredStudents {
    var list = _filterClassId == null
        ? _students
        : _students.where((s) => s['class_id'] == _filterClassId).toList();
    if (_histStudentSearch.isNotEmpty) {
      final q = _histStudentSearch.toLowerCase();
      list = list.where((s) {
        final name = '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.toLowerCase();
        final adm = (s['admission_no'] ?? '').toString().toLowerCase();
        return name.contains(q) || adm.contains(q);
      }).toList();
    }
    return list;
  }

  void _onFeeTypeSelected(String? feeTypeId) {
    setState(() => _rpFeeTypeId = feeTypeId);
    if (feeTypeId != null) {
      final outstanding = _getOutstanding(_rpStudentId, feeTypeId);
      if (outstanding > 0) {
        _rpAmountCtrl.text = outstanding.toStringAsFixed(0);
      } else {
        for (final ft in _feeTypes) {
          if (ft['id'] == feeTypeId) {
            _rpAmountCtrl.text = (ft['amount'] ?? 0).toString();
            break;
          }
        }
      }
    }
  }

  Future<void> _savePayment() async {
    if (_rpStudentId == null || _rpFeeTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Select student and fee type'),
        backgroundColor: Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: StadiumBorder(),
      ));
      return;
    }
    final amt = double.tryParse(_rpAmountCtrl.text.trim()) ?? 0;
    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter a valid amount'),
        backgroundColor: Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: StadiumBorder(),
      ));
      return;
    }
    setState(() => _saving = true);
    final p = context.read<SchoolAdminProvider>();
    try {
      String? assignmentId;
      final sessionId = p.currentSession?['id']?.toString() ?? '';
      final termId = p.currentTerm?['id']?.toString() ?? '';
      for (final a in _feeAssignments) {
        if (a['student_id'] == _rpStudentId &&
            a['fee_type_id'] == _rpFeeTypeId &&
            a['session_id']?.toString() == sessionId &&
            a['term_id']?.toString() == termId) {
          assignmentId = a['id']?.toString();
          break;
        }
      }
      await DbProxy.instance.from('fee_payments').insert({
        'school_id': p.schoolId,
        'student_id': _rpStudentId,
        'fee_type_id': _rpFeeTypeId,
        'session_id': sessionId,
        'term_id': termId,
        'amount_paid': amt,
        'payment_method': _rpMethod,
        'payment_date': _rpDate.toIso8601String().split('T').first,
        'receipt_no': _rpReceiptCtrl.text.trim(),
        'reference_no': _rpRefCtrl.text.trim(),
        'recorded_by': p.schoolId,
        'remark': _rpRemarkCtrl.text.trim(),
        'fee_assignment_id': assignmentId,
      });
      if (assignmentId != null) {
        final assignment = _feeAssignments.firstWhere((a) => a['id']?.toString() == assignmentId);
        final currentPaid = ((assignment['amount_paid'] ?? 0) as num).toDouble() + amt;
        final owed = ((assignment['amount_owed'] ?? 0) as num).toDouble();
        String newStatus = currentPaid >= owed ? 'paid' : (currentPaid > 0 ? 'partial' : 'pending');
        await DbProxy.instance.from('fee_assignments').eq('id', assignmentId).update({
          'amount_paid': currentPaid,
          'status': newStatus,
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Payment recorded successfully'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: StadiumBorder(),
        ));
        _resetPaymentForm();
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
          shape: const StadiumBorder(),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _postFees() async {
    if (_postClassId == null || _postFeeTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Select class and fee type'),
        backgroundColor: Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: StadiumBorder(),
      ));
      return;
    }
    if (_selectedPostIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Select at least one student'),
        backgroundColor: Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: StadiumBorder(),
      ));
      return;
    }
    setState(() => _postSaving = true);
    final p = context.read<SchoolAdminProvider>();
    final sid = p.schoolId;
    final sessionId = p.currentSession?['id']?.toString() ?? '';
    final termId = p.currentTerm?['id']?.toString() ?? '';
    double amount = 0;
    for (final ft in _feeTypes) {
      if (ft['id'] == _postFeeTypeId) {
        amount = (ft['amount'] ?? 0).toDouble();
        break;
      }
    }
    int posted = 0;
    try {
      for (final studentId in _selectedPostIds) {
        await DbProxy.instance.from('fee_assignments').insert({
          'school_id': sid,
          'student_id': studentId,
          'fee_type_id': _postFeeTypeId,
          'session_id': sessionId,
          'term_id': termId,
          'amount_owed': amount,
          'amount_paid': 0,
          'status': 'pending',
          'due_date': _postDueDate?.toIso8601String().split('T').first,
          'assigned_by': p.schoolId,
        });
        posted++;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Fees posted for $posted student${posted != 1 ? 's' : ''}'),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: const StadiumBorder(),
        ));
        _resetPostForm();
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
          shape: const StadiumBorder(),
        ));
      }
    } finally {
      if (mounted) setState(() => _postSaving = false);
    }
  }

  void _resetPaymentForm() {
    setState(() {
      _rpClassId = null;
      _rpStudentId = null;
      _rpFeeTypeId = null;
      _rpMethod = 'Cash';
      _rpDate = DateTime.now();
    });
    _rpAmountCtrl.clear();
    _rpReceiptCtrl.text = 'RCP-${DateTime.now().millisecondsSinceEpoch}';
    _rpRefCtrl.clear();
    _rpRemarkCtrl.clear();
  }

  void _resetPostForm() {
    setState(() {
      _postClassId = null;
      _postFeeTypeId = null;
      _postDueDate = null;
      _selectedPostIds.clear();
    });
  }

  Future<void> _showAddFeeTypeDialog() async {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String frequency = 'termly';
    bool compulsory = true;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: Color(0xFFF57F17), size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Add Fee Type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(nameCtrl, 'Fee Name', 'e.g. Tuition Fee'),
                const SizedBox(height: 12),
                _field(amountCtrl, 'Amount', '0', keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _field(descCtrl, 'Description (optional)', ''),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: frequency,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                    filled: true,
                    fillColor: Color(0xFFFAFBFC),
                  ),
                  items: ['termly', 'sessionly', 'once', 'monthly', 'weekly']
                      .map((f) => DropdownMenuItem(
                            value: f,
                            child: Text(f, style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDlg(() => frequency = v);
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Compulsory', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                  value: compulsory,
                  activeColor: const Color(0xFF1A237E),
                  onChanged: (v) => setDlg(() => compulsory = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF111827))),
            ),
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('Fee name is required'),
                      backgroundColor: Color(0xFFD32F2F),
                      behavior: SnackBarBehavior.floating,
                      shape: StadiumBorder(),
                    ));
                    return;
                  }
                  if (amountCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('Amount is required'),
                      backgroundColor: Color(0xFFD32F2F),
                      behavior: SnackBarBehavior.floating,
                      shape: StadiumBorder(),
                    ));
                    return;
                  }
                  final p = context.read<SchoolAdminProvider>();
                  await DbProxy.instance.from('fee_types').insert({
                    'school_id': p.schoolId,
                    'name': nameCtrl.text.trim(),
                    'amount': double.tryParse(amountCtrl.text.trim().replaceAll(',', '')) ?? 0,
                    'description': descCtrl.text.trim(),
                    'is_active': true,
                    'is_compulsory': compulsory,
                    'frequency': frequency,
                    'currency_code': p.schoolSettings?['currency_code'] ?? 'NGN',
                  });
                  Navigator.pop(ctx, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                child: const Text('Add Fee Type'),
              ),
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
    amountCtrl.dispose();
    descCtrl.dispose();
    if (saved == true) {
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Fee type added'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: StadiumBorder(),
        ));
      }
    }
  }

  Future<void> _showEditFeeTypeDialog(Map<String, dynamic> ft) async {
    final nameCtrl = TextEditingController(text: ft['name'] ?? '');
    final amountCtrl = TextEditingController(text: (ft['amount'] ?? 0).toString());
    final descCtrl = TextEditingController(text: ft['description'] ?? '');
    String frequency = ft['frequency'] ?? 'termly';
    bool compulsory = ft['is_compulsory'] == true;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_outlined, color: Color(0xFFF57F17), size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Edit Fee Type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(nameCtrl, 'Fee Name', 'e.g. Tuition Fee'),
                const SizedBox(height: 12),
                _field(amountCtrl, 'Amount', '0', keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _field(descCtrl, 'Description (optional)', ''),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: frequency,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                    filled: true,
                    fillColor: Color(0xFFFAFBFC),
                  ),
                  items: ['termly', 'sessionly', 'once', 'monthly', 'weekly']
                      .map((f) => DropdownMenuItem(
                            value: f,
                            child: Text(f, style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDlg(() => frequency = v);
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Compulsory', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                  value: compulsory,
                  activeColor: const Color(0xFF1A237E),
                  onChanged: (v) => setDlg(() => compulsory = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF111827))),
            ),
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('Fee name is required'),
                      backgroundColor: Color(0xFFD32F2F),
                      behavior: SnackBarBehavior.floating,
                      shape: StadiumBorder(),
                    ));
                    return;
                  }
                  await DbProxy.instance.from('fee_types').eq('id', ft['id']).update({
                    'name': nameCtrl.text.trim(),
                    'amount': double.tryParse(amountCtrl.text.trim().replaceAll(',', '')) ?? 0,
                    'description': descCtrl.text.trim(),
                    'is_compulsory': compulsory,
                    'frequency': frequency,
                  });
                  Navigator.pop(ctx, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
    amountCtrl.dispose();
    descCtrl.dispose();
    if (saved == true) {
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Fee type updated'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: StadiumBorder(),
        ));
      }
    }
  }

  Future<void> _toggleFeeType(Map<String, dynamic> ft) async {
    final newVal = ft['is_active'] != true;
    await DbProxy.instance.from('fee_types').eq('id', ft['id']).update({'is_active': newVal});
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(newVal ? 'Fee type activated' : 'Fee type deactivated'),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: const StadiumBorder(),
      ));
    }
  }

  Future<void> _deleteFeeType(Map<String, dynamic> ft) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline, color: Color(0xFFD32F2F), size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Delete Fee Type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          ],
        ),
        content: Text('Delete "${ft['name']}"? This cannot be undone.', style: const TextStyle(fontSize: 14, color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF111827))),
          ),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              child: const Text('Delete'),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DbProxy.instance.from('fee_types').eq('id', ft['id']).delete();
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Fee type deleted'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: StadiumBorder(),
        ));
      }
    }
  }

  Widget _field(TextEditingController ctrl, String label, String hint, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        filled: true,
        fillColor: const Color(0xFFFAFBFC),
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 32, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            const Text('Fee Management', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            const SizedBox(height: 6),
            Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade500), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    IconData icon;
    String label;
    switch (status) {
      case 'paid':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        icon = Icons.check_circle;
        label = 'Paid';
        break;
      case 'partial':
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFFE65100);
        icon = Icons.access_time;
        label = 'Partial';
        break;
      default:
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFD32F2F);
        icon = Icons.schedule;
        label = 'Pending';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SchoolAdminProvider>();
    final currency = (p.schoolSettings?['currency_symbol'] as String?) ?? '\u20A6';
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: Color(0xFFF57F17), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Fee Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: -0.5)),
                        Text('${_feeTypes.length} fee types \u00B7 ${_feeAssignments.length} assignments \u00B7 ${_payments.length} payments', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF1A237E),
                  unselectedLabelColor: Colors.grey.shade500,
                  indicatorColor: const Color(0xFF1A237E),
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorWeight: 2.5,
                  tabs: const [
                    Tab(text: 'Fee Types'),
                    Tab(text: 'Post Fees'),
                    Tab(text: 'Record Payment'),
                    Tab(text: 'History'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFeeTypesTab(currency),
                      _buildPostFeesTab(currency),
                      _buildRecordPaymentTab(currency),
                      _buildHistoryTab(currency),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _showAddFeeTypeDialog,
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              icon: const Icon(Icons.add),
              label: const Text('Add Fee Type'),
            )
          : null,
    );
  }

  Widget _buildFeeTypesTab(String currency) {
    if (_feeTypes.isEmpty) {
      return _emptyState(Icons.receipt_long_rounded, 'No Fee Types', 'Tap the button below to add your first fee type');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 100),
      itemCount: _feeTypes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final ft = _feeTypes[i];
        final active = ft['is_active'] == true;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: active ? Colors.white : const Color(0xFFFAFBFC),
            border: Border.all(color: active ? const Color(0xFFE8EAED) : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: Color(0xFFF57F17), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(ft['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                        const SizedBox(width: 8),
                        if (ft['is_compulsory'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F4FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Compulsory', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1A237E))),
                          ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(ft['frequency'] ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFE65100))),
                        ),
                        if (!active) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Inactive', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFD32F2F))),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('$currency${(ft['amount'] ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2E7D32))),
                    if ((ft['description'] ?? '').toString().isNotEmpty)
                      Text(ft['description'], style: TextStyle(fontSize: 12, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') _showEditFeeTypeDialog(ft);
                  if (v == 'toggle') _toggleFeeType(ft);
                  if (v == 'delete') _deleteFeeType(ft);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18, color: Color(0xFF1A237E)), SizedBox(width: 8), Text('Edit')])),
                  PopupMenuItem(value: 'toggle', child: Row(children: [Icon(active ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: Colors.orange), const SizedBox(width: 8), Text(active ? 'Deactivate' : 'Activate')])),
                  PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Color(0xFFD32F2F)), SizedBox(width: 8), Text('Delete', style: const TextStyle(color: Color(0xFFD32F2F)))])),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostFeesTab(String currency) {
    final postable = _postableStudents;
    final ftAmount = _postFeeTypeId != null
        ? (() {
            for (final ft in _feeTypes) {
              if (ft['id'] == _postFeeTypeId) return (ft['amount'] ?? 0).toDouble();
            }
            return 0.0;
          })()
        : 0.0;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 100),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE8EAED)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FFF4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.post_add, color: Color(0xFF2E7D32), size: 22),
                ),
                const SizedBox(width: 12),
                const Text('Post Fees', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
              ],
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _postClassId,
              decoration: const InputDecoration(
                labelText: 'Select Class',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                filled: true,
                fillColor: Color(0xFFFAFBFC),
                prefixIcon: Icon(Icons.class_outlined, color: Color(0xFF1A237E), size: 20),
              ),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('Choose a class')),
                for (final c in _classes)
                  DropdownMenuItem<String>(
                    value: c['id'] as String?,
                    child: Text('${c['name']}${(c['section'] ?? '').toString().isNotEmpty ? ' - ${c['section']}' : ''}'),
                  ),
              ],
              onChanged: (v) => setState(() {
                _postClassId = v;
                _postFeeTypeId = null;
                _selectedPostIds.clear();
              }),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _postFeeTypeId,
              decoration: const InputDecoration(
                labelText: 'Fee Type',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                filled: true,
                fillColor: Color(0xFFFAFBFC),
                prefixIcon: Icon(Icons.receipt_long_rounded, color: Color(0xFFF57F17), size: 20),
              ),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('Choose fee type')),
                for (final ft in _feeTypes)
                  if (ft['is_active'] == true)
                    DropdownMenuItem<String>(
                      value: ft['id'] as String?,
                      child: Text('${ft['name']} \u2014 $currency${(ft['amount'] ?? 0).toStringAsFixed(0)}'),
                    ),
              ],
              onChanged: (v) => setState(() {
                _postFeeTypeId = v;
                _selectedPostIds.clear();
              }),
            ),
            const SizedBox(height: 14),
            if (postable.isEmpty && (_postClassId != null && _postFeeTypeId != null)) ...[
              const SizedBox(height: 16),
              _emptyState(Icons.check_circle_outline, 'All Fees Posted', 'All students in this class already have this fee assigned for the current term'),
            ] else if (postable.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Color(0xFF1A237E)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${postable.length} student${postable.length != 1 ? 's' : ''} available \u00B7 $currency${ftAmount.toStringAsFixed(0)} each',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A237E)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _toggleAllPost,
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(value: _allPostSelected, onChanged: (_) => _toggleAllPost()),
                    ),
                    const SizedBox(width: 8),
                    const Text('Select All', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ...postable.map((s) => ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFF0F4FF),
                      child: Text(
                        '${(s['first_name'] ?? '')[0]}${(s['last_name'] ?? '')[0]}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1A237E)),
                      ),
                    ),
                    title: Text(
                      '${s['first_name']} ${s['last_name']}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      s['admission_no'] ?? '',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                    ),
                    trailing: Checkbox(
                      value: _selectedPostIds.contains(s['id'] as String),
                      onChanged: (_) => _togglePostStudent(s['id'] as String),
                    ),
                  )),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _postDueDate == null
                        ? () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setState(() => _postDueDate = picked);
                          }
                        : () => setState(() => _postDueDate = null),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE8EAED)),
                    ),
                    child: Text(
                      _postDueDate != null ? 'Due: ${_postDueDate!.toIso8601String().split('T').first}' : 'Set Due Date (optional)',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _postSaving ? null : _postFees,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _postSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Post Fees', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordPaymentTab(String currency) {
    final outstanding = _getOutstanding(_rpStudentId, _rpFeeTypeId);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 100),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE8EAED)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FFF4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.payment, color: Color(0xFF2E7D32), size: 22),
                ),
                const SizedBox(width: 12),
                const Text('Record Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
              ],
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _rpClassId,
              decoration: const InputDecoration(
                labelText: 'Select Class',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                filled: true,
                fillColor: Color(0xFFFAFBFC),
                prefixIcon: Icon(Icons.class_outlined, color: Color(0xFF1A237E), size: 20),
              ),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('All Classes')),
                for (final c in _classes)
                  DropdownMenuItem<String>(
                    value: c['id'] as String?,
                    child: Text('${c['name']}${(c['section'] ?? '').toString().isNotEmpty ? ' - ${c['section']}' : ''}'),
                  ),
              ],
              onChanged: (v) => setState(() {
                _rpClassId = v;
                _rpStudentId = null;
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _rpStudentSearchCtrl,
              decoration: const InputDecoration(
                labelText: 'Search Student',
                hintText: 'Name or admission no...',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                filled: true,
                fillColor: Color(0xFFFAFBFC),
                prefixIcon: Icon(Icons.search, color: Color(0xFF1A237E), size: 20),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              onChanged: (v) => setState(() => _rpStudentSearch = v.trim()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _rpStudentId,
              decoration: const InputDecoration(
                labelText: 'Select Student',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                filled: true,
                fillColor: Color(0xFFFAFBFC),
                prefixIcon: Icon(Icons.person_outline, color: Color(0xFF1A237E), size: 20),
              ),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('Choose a student')),
                for (final s in _rpFilteredStudents)
                  DropdownMenuItem<String>(
                    value: s['id'] as String?,
                    child: Text('${s['first_name']} ${s['last_name']} (${s['admission_no']})'),
                  ),
              ],
              onChanged: (v) {
                setState(() => _rpStudentId = v);
                if (v != null) _onFeeTypeSelected(_rpFeeTypeId);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _rpFeeTypeId,
              decoration: const InputDecoration(
                labelText: 'Fee Type',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                filled: true,
                fillColor: Color(0xFFFAFBFC),
                prefixIcon: Icon(Icons.receipt_long_rounded, color: Color(0xFFF57F17), size: 20),
              ),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('Choose fee type')),
                for (final ft in _feeTypes)
                  if (ft['is_active'] == true)
                    DropdownMenuItem<String>(
                      value: ft['id'] as String?,
                      child: Text('${ft['name']} \u2014 $currency${(ft['amount'] ?? 0).toStringAsFixed(0)}'),
                    ),
              ],
              onChanged: _onFeeTypeSelected,
            ),
            if (_rpStudentId != null && _rpFeeTypeId != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: outstanding > 0 ? const Color(0xFFFFF8E1) : const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: outstanding > 0 ? const Color(0xFFE65100) : const Color(0xFFE8EAED)),
                ),
                child: Row(
                  children: [
                    Icon(
                      outstanding > 0 ? Icons.warning_amber : Icons.info_outline,
                      size: 18,
                      color: outstanding > 0 ? const Color(0xFFE65100) : const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        outstanding > 0 ? 'Outstanding: $currency${outstanding.toStringAsFixed(0)}' : 'No outstanding fee for this student',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: outstanding > 0 ? FontWeight.w700 : FontWeight.w400,
                          color: outstanding > 0 ? const Color(0xFFE65100) : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _rpAmountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount Paid',
                prefixText: '$currency ',
                border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                filled: true,
                fillColor: const Color(0xFFFAFBFC),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _rpMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                filled: true,
                fillColor: Color(0xFFFAFBFC),
              ),
              items: ['Cash', 'Transfer', 'POS', 'Cheque', 'Online']
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m, style: const TextStyle(fontSize: 13)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _rpMethod = v);
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _rpDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _rpDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Payment Date',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  filled: true,
                  fillColor: Color(0xFFFAFBFC),
                ),
                child: Text(
                  _rpDate.toIso8601String().split('T').first,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _rpReceiptCtrl,
              decoration: const InputDecoration(
                labelText: 'Receipt No',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                filled: true,
                fillColor: Color(0xFFFAFBFC),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _rpRefCtrl,
              decoration: const InputDecoration(
                labelText: 'Reference No (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                filled: true,
                fillColor: Color(0xFFFAFBFC),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _rpRemarkCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Remark (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                filled: true,
                fillColor: Color(0xFFFAFBFC),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _savePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Record Payment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(String currency) {
    final filtered = _filteredAssignments;
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterClassId,
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                    filled: true,
                    fillColor: Color(0xFFFAFBFC),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('All Classes', style: TextStyle(fontSize: 12))),
                    for (final c in _classes)
                      DropdownMenuItem<String>(
                        value: c['id'] as String?,
                        child: Text('${c['name']}${(c['section'] ?? '').toString().isNotEmpty ? ' - ${c['section']}' : ''}', style: const TextStyle(fontSize: 12)),
                      ),
                  ],
                  onChanged: (v) => setState(() {
                    _filterClassId = v;
                    _filterStudentId = null;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _histStudentSearchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    hintText: 'Name...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                    filled: true,
                    fillColor: Color(0xFFFAFBFC),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (v) => setState(() => _histStudentSearch = v.trim()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterStudentId,
                  decoration: const InputDecoration(
                    labelText: 'Student',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                    filled: true,
                    fillColor: Color(0xFFFAFBFC),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('All Students', style: TextStyle(fontSize: 12))),
                    for (final s in _historyFilteredStudents)
                      DropdownMenuItem<String>(
                        value: s['id'] as String?,
                        child: Text('${s['first_name']} ${s['last_name']}', style: const TextStyle(fontSize: 12)),
                      ),
                  ],
                  onChanged: (v) => setState(() => _filterStudentId = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterFeeTypeId,
                  decoration: const InputDecoration(
                    labelText: 'Fee Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                    filled: true,
                    fillColor: Color(0xFFFAFBFC),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('All Types', style: TextStyle(fontSize: 12))),
                    for (final ft in _feeTypes)
                      DropdownMenuItem<String>(
                        value: ft['id'] as String?,
                        child: Text(ft['name'] ?? '', style: const TextStyle(fontSize: 12)),
                      ),
                  ],
                  onChanged: (v) => setState(() => _filterFeeTypeId = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                    filled: true,
                    fillColor: Color(0xFFFAFBFC),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: [
                    DropdownMenuItem<String>(value: null, child: Text('All Status', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem<String>(value: 'pending', child: Text('Pending', style: TextStyle(fontSize: 12, color: Color(0xFFD32F2F)))),
                    DropdownMenuItem<String>(value: 'partial', child: Text('Partial', style: TextStyle(fontSize: 12, color: Color(0xFFE65100)))),
                    DropdownMenuItem<String>(value: 'paid', child: Text('Paid', style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32)))),
                  ],
                  onChanged: (v) => setState(() => _filterStatus = v),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _emptyState(Icons.receipt_long_rounded, 'No Fee Assignments', 'Post fees for students first')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (ctx, i) {
                    final a = filtered[i];
                    final sName = _studentName(a['student_id'] as String?);
                    final ft = a['fee_types'] as Map<String, dynamic>? ?? {};
                    final ftName = ft['name'] ?? _feeTypeName(a['fee_type_id']);
                    final owed = (a['amount_owed'] ?? 0).toDouble();
                    final paid = (a['amount_paid'] ?? 0).toDouble();
                    final balance = (owed - paid).clamp(0.0, double.infinity);
                    final status = (a['status'] ?? 'pending').toString();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: i.isEven ? const Color(0xFFFAFBFC) : Colors.white,
                        border: Border.all(color: balance == 0 ? const Color(0xFFE8F5E9) : const Color(0xFFE8EAED)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: status == 'paid'
                                  ? const Color(0xFFE8F5E9)
                                  : status == 'partial'
                                      ? const Color(0xFFFFF8E1)
                                      : const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              status == 'paid' ? Icons.check_circle : status == 'partial' ? Icons.adjust : Icons.schedule,
                              size: 18,
                              color: status == 'paid'
                                  ? const Color(0xFF2E7D32)
                                  : status == 'partial'
                                      ? const Color(0xFFE65100)
                                      : const Color(0xFFD32F2F),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(sName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                                const SizedBox(height: 2),
                                Text(ftName, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                const SizedBox(height: 2),
                                Text('Paid: $currency${paid.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                                if (balance > 0) ...[
                                  const SizedBox(height: 2),
                                  Text('Bal: $currency${balance.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: Color(0xFFD32F2F), fontWeight: FontWeight.w600)),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _statusBadge(status),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
