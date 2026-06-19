// ==========================================
// File: lib/core/providers/fee_mixin.dart
// ==========================================
import 'package:flutter/foundation.dart';
import '../services/db_proxy.dart';
import 'base_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

mixin FeeMixin on BaseProvider {
  List<Map<String, dynamic>> _feeTypes = [];
  List<Map<String, dynamic>> _feePayments = [];

  List<Map<String, dynamic>> get feeTypes => _feeTypes;
  List<Map<String, dynamic>> get feePayments => _feePayments;
  int get feeTypeCount => _feeTypes.length;
  int get paymentCount => _feePayments.length;

  // ==========================================
  // FEE TYPES CRUD
  // ==========================================

  Future<void> loadFeeTypes() async {
    try {
      final r = await DbProxy.instance
          .from('fee_types')
          .select()
          .eq('school_id', schoolId)
          .eq('is_active', true)
          .order('name')
          .get();
      _feeTypes = r;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading fee types: $e');
    }
  }

  Future<Map<String, dynamic>?> addFeeType({
    required String name,
    required double amount,
    String? description,
    bool isCompulsory = true,
    String frequency = 'termly',
  }) async {
    try {
      final result = await DbProxy.instance.from('fee_types').insert({
        'school_id': schoolId,
        'name': name.trim(),
        'amount': amount,
        'description': description ?? '',
        'is_compulsory': isCompulsory,
        'frequency': frequency,
        'currency_code': currencyCode,
      });
      final r = result is List && result.isNotEmpty ? Map<String, dynamic>.from(result.first) : <String, dynamic>{};
      _feeTypes.add(Map<String, dynamic>.from(r));
      logAudit(action: 'create', tableName: 'fee_types', recordId: r['id']?.toString(), newData: {'name': name, 'amount': amount});
      notifyListeners();
      return r;
    } catch (e) {
      debugPrint('Error adding fee type: $e');
      return null;
    }
  }

  Future<bool> updateFeeType(String id, Map<String, dynamic> updates) async {
    try {
      final u = Map<String, dynamic>.from(updates)
        ..remove('id')
        ..remove('school_id')
        ..remove('created_at')
        ..remove('updated_at');
      if (u.containsKey('amount')) {
        u['amount'] = double.tryParse(u['amount'].toString()) ?? 0;
      }
      if (u.isEmpty) return false;
      await DbProxy.instance.from('fee_types').eq('id', id).eq('school_id', schoolId).update(u);
      final i = _feeTypes.indexWhere((f) => f['id']?.toString() == id);
      if (i != -1) {
        _feeTypes[i] = Map<String, dynamic>.from(_feeTypes[i])..addAll(u);
      }
      logAudit(action: 'update', tableName: 'fee_types', recordId: id, newData: u);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating fee type: $e');
      return false;
    }
  }

  Future<bool> deactivateFeeType(String id) async {
    try {
      await DbProxy.instance.from('fee_types').eq('id', id).eq('school_id', schoolId).update({'is_active': false});
      _feeTypes.removeWhere((f) => f['id']?.toString() == id);
      logAudit(action: 'deactivate', tableName: 'fee_types', recordId: id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deactivating fee type: $e');
      return false;
    }
  }

  // ==========================================
  // PAYMENTS
  // ==========================================

  Future<Map<String, dynamic>?> recordPayment({
    required String studentId,
    required String feeTypeId,
    required double amountPaid,
    String? sessionId,
    String? termId,
    String? paymentMethod,
    String? receiptNo,
    String? referenceNo,
    String? remark,
    String? recordedBy,
  }) async {
    try {
      final result = await DbProxy.instance.from('fee_payments').insert({
        'school_id': schoolId,
        'student_id': studentId,
        'fee_type_id': feeTypeId,
        'session_id': sessionId,
        'term_id': termId,
        'amount_paid': amountPaid,
        'payment_method': paymentMethod,
        'receipt_no': receiptNo ?? _generateReceiptNo(),
        'reference_no': referenceNo,
        'remark': remark,
        'recorded_by': recordedBy,
      });
      final r = result is List && result.isNotEmpty ? Map<String, dynamic>.from(result.first) : <String, dynamic>{};
      _feePayments.insert(0, Map<String, dynamic>.from(r));
      logAudit(action: 'create', tableName: 'fee_payments', recordId: r['id']?.toString(), newData: {'student_id': studentId, 'fee_type_id': feeTypeId, 'amount_paid': amountPaid});
      notifyListeners();
      return r;
    } catch (e) {
      debugPrint('Error recording payment: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getPaymentHistory({
    required String studentId,
    String? sessionId,
    String? termId,
  }) async {
    try {
      var q = DbProxy.instance
          .from('fee_payments')
          .select('*, fee_types(name, amount)')
          .eq('school_id', schoolId)
          .eq('student_id', studentId);
      if (sessionId != null) q = q.eq('session_id', sessionId);
      if (termId != null) q = q.eq('term_id', termId);
      final r = await q.order('payment_date', ascending: false).get();
      return r;
    } catch (e) {
      debugPrint('Error fetching payment history: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getOutstandingFees({
    required String studentId,
    String? sessionId,
    String? termId,
  }) async {
    try {
      var pq = DbProxy.instance
          .from('fee_payments')
          .select('fee_type_id, amount_paid')
          .eq('school_id', schoolId)
          .eq('student_id', studentId);
      if (sessionId != null) pq = pq.eq('session_id', sessionId);
      if (termId != null) pq = pq.eq('term_id', termId);
      final payments = await pq.get();
      final paidMap = <String, double>{};
      for (final p in payments) {
        final fid = p['fee_type_id']?.toString() ?? '';
        paidMap[fid] = (paidMap[fid] ?? 0) + ((p['amount_paid'] as num?)?.toDouble() ?? 0);
      }
      return _feeTypes.map((ft) {
        final fid = ft['id'].toString();
        final feeAmount = (ft['amount'] as num?)?.toDouble() ?? 0;
        final paid = paidMap[fid] ?? 0;
        final outstanding = (feeAmount - paid).clamp(0.0, double.infinity);
        return {
          'fee_type_id': fid,
          'fee_name': ft['name'],
          'fee_amount': feeAmount,
          'amount_paid': paid,
          'outstanding': outstanding,
          'is_fully_paid': paid >= feeAmount,
          'is_overdue': paid < feeAmount,
          'currency': ft['currency_code'] ?? currencySymbol,
        };
      }).where((f) => (f['outstanding'] as double) > 0).toList();
    } catch (e) {
      debugPrint('Error fetching outstanding fees: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getFeeBalance({
    required String studentId,
    String? sessionId,
    String? termId,
  }) async {
    try {
      var pq = DbProxy.instance
          .from('fee_payments')
          .select('fee_type_id, amount_paid')
          .eq('school_id', schoolId)
          .eq('student_id', studentId);
      if (sessionId != null) pq = pq.eq('session_id', sessionId);
      if (termId != null) pq = pq.eq('term_id', termId);
      final payments = await pq.get();
      final paidMap = <String, double>{};
      for (final p in payments) {
        final fid = p['fee_type_id']?.toString() ?? '';
        paidMap[fid] = (paidMap[fid] ?? 0) + ((p['amount_paid'] as num?)?.toDouble() ?? 0);
      }
      return _feeTypes.map((ft) {
        final fid = ft['id'].toString();
        final feeAmount = (ft['amount'] as num?)?.toDouble() ?? 0;
        final paid = paidMap[fid] ?? 0;
        return {
          'fee_type_id': fid,
          'fee_name': ft['name'],
          'fee_amount': feeAmount,
          'amount_paid': paid,
          'balance': (feeAmount - paid).clamp(0.0, double.infinity),
          'is_paid': paid >= feeAmount,
          'is_overdue': paid < feeAmount,
          'currency': currencySymbol,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching fee balance: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getClassFeeSummary({
    required String classId,
    required List<Map<String, dynamic>> studentsInClass,
    String? sessionId,
    String? termId,
  }) async {
    final summary = <Map<String, dynamic>>[];
    for (final student in studentsInClass) {
      final sid = student['id']?.toString() ?? '';
      if (sid.isEmpty) continue;
      final outstanding = await getOutstandingFees(studentId: sid, sessionId: sessionId, termId: termId);
      final totalOutstanding = outstanding.fold<double>(0, (s, f) => s + ((f['outstanding'] as double?) ?? 0));
      if (totalOutstanding > 0) {
        summary.add({
          'student_id': sid,
          'student_name': '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'.trim(),
          'admission_no': student['admission_no'] ?? '',
          'total_outstanding': totalOutstanding,
          'fee_breakdown': outstanding,
          'currency': currencySymbol,
        });
      }
    }
    summary.sort((a, b) => ((b['total_outstanding'] as double?) ?? 0).compareTo((a['total_outstanding'] as double?) ?? 0));
    return summary;
  }

  Future<Map<String, dynamic>> getCollectionSummary({String? sessionId, String? termId}) async {
    try {
      var q = DbProxy.instance
          .from('fee_payments')
          .select('amount_paid, fee_types(name)')
          .eq('school_id', schoolId);
      if (sessionId != null) q = q.eq('session_id', sessionId);
      if (termId != null) q = q.eq('term_id', termId);
      final payments = await q.get();
      double totalCollected = 0;
      final byFeeType = <String, double>{};
      for (final p in payments) {
        final amt = (p['amount_paid'] as num?)?.toDouble() ?? 0;
        totalCollected += amt;
        final feeData = p['fee_types'];
        final name = (feeData is Map<String, dynamic>) ? (feeData['name'] ?? 'Unknown') : 'Unknown';
        byFeeType[name] = (byFeeType[name] ?? 0) + amt;
      }
      return {'total_collected': totalCollected, 'total_transactions': payments.length, 'by_fee_type': byFeeType, 'currency': currencySymbol};
    } catch (e) {
      debugPrint('Error fetching collection summary: $e');
      return {'total_collected': 0, 'total_transactions': 0, 'by_fee_type': <String, double>{}, 'currency': currencySymbol};
    }
  }

  Future<void> loadPayments({String? sessionId, String? termId, String? studentId}) async {
    try {
      var q = DbProxy.instance
          .from('fee_payments')
          .select('*, fee_types(name), students(first_name, last_name, admission_no)')
          .eq('school_id', schoolId);
      if (sessionId != null) q = q.eq('session_id', sessionId);
      if (termId != null) q = q.eq('term_id', termId);
      if (studentId != null) q = q.eq('student_id', studentId);
      final r = await q.order('payment_date', ascending: false).limit(200).get();
      _feePayments = r;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading payments: $e');
    }
  }

  // ==========================================
  // UTILITY METHODS
  // ==========================================

  Map<String, dynamic>? getFeeTypeById(String feeTypeId) {
    try {
      return _feeTypes.cast<Map<String, dynamic>?>().firstWhere((f) => f?['id']?.toString() == feeTypeId, orElse: () => null);
    } catch (e) {
      return null;
    }
  }

  String getFeeTypeName(String? feeTypeId) {
    if (feeTypeId == null || feeTypeId.isEmpty) return '';
    final ft = getFeeTypeById(feeTypeId);
    return (ft?['name'] ?? '').toString();
  }

  double getFeeTypeAmount(String? feeTypeId) {
    if (feeTypeId == null || feeTypeId.isEmpty) return 0;
    final ft = getFeeTypeById(feeTypeId);
    return (ft?['amount'] as num?)?.toDouble() ?? 0;
  }

  Future<bool> feeTypeNameExists(String name) async {
    if (schoolId.isEmpty || name.trim().isEmpty) return false;
    try {
      final existing = await DbProxy.instance
          .from('fee_types')
          .select('id')
          .eq('school_id', schoolId)
          .eq('name', name.trim())
          .eq('is_active', true)
          .maybeSingle();
      return existing != null;
    } catch (e) {
      return false;
    }
  }

  String formatAmount(double amount) => '$currencySymbol${amount.toStringAsFixed(2)}';

  String _generateReceiptNo() {
    final now = DateTime.now();
    final date = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final rand = secureRandomString(4).toUpperCase();
    return 'RCP-$date-$rand';
  }

  void clearPayments() {
    _feePayments.clear();
    notifyListeners();
  }
}
