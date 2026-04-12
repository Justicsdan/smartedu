// ==========================================
// File: lib/core/providers/fee_mixin.dart
// ==========================================
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_provider.dart';

/// Mixin for fee type management, payment recording, and reporting.
///
/// MASTER PLAN V4:
/// - Every operation filters by schoolId — tenant isolation
/// - V4: Uses supabase getter from BaseProvider (consistent pattern)
/// - V4: Uses debugPrint instead of print
/// - V4: Fixed PostgrestTransformBuilder chain errors — .order()/.limit()
///   must come AFTER all .eq() filters, not before
/// - V4: Added currency support per school
/// - V4: Added receipt number generation
/// - V4: Added utility methods for fee lookups

mixin FeeMixin on BaseProvider {
  List<Map<String, dynamic>> _feeTypes = [];
  List<Map<String, dynamic>> _feePayments = [];

  List<Map<String, dynamic>> get feeTypes => _feeTypes;
  List<Map<String, dynamic>> get feePayments => _feePayments;

  /// Total number of active fee types.
  int get feeTypeCount => _feeTypes.length;

  /// Total number of payments loaded.
  int get paymentCount => _feePayments.length;

  // ==========================================
  // FEE TYPES CRUD
  // ==========================================

  Future<void> loadFeeTypes() async {
    try {
      final r = await supabase
          .from('fee_types')
          .select()
          .eq('school_id', schoolId)
          .eq('is_active', true)
          .order('name');
      _feeTypes = List<Map<String, dynamic>>.from(r);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading fee types: $e');
    }
  }

  /// Add a new fee type.
  /// V4: Supports currency_code, frequency fields from schema.
  Future<Map<String, dynamic>?> addFeeType({
    required String name,
    required double amount,
    String? description,
    bool isCompulsory = true,
    String frequency = 'termly',
  }) async {
    try {
      final r = await supabase.from('fee_types').insert({
        'school_id': schoolId,
        'name': name.trim(),
        'amount': amount,
        'description': description ?? '',
        'is_compulsory': isCompulsory,
        'frequency': frequency,
        'currency_code': currencyCode, // V4: per-school currency
      }).select().single();

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

      final r = await supabase
          .from('fee_types')
          .update(u)
          .eq('id', id)
          .eq('school_id', schoolId)
          .select()
          .single();

      final i = _feeTypes.indexWhere((f) => f['id']?.toString() == id);
      if (i != -1) {
        _feeTypes[i] = Map<String, dynamic>.from(r);
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
      await supabase
          .from('fee_types')
          .update({'is_active': false})
          .eq('id', id)
          .eq('school_id', schoolId);

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

  /// Record a new fee payment.
  /// V4: Auto-generates receipt number if not provided.
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
      final r = await supabase.from('fee_payments').insert({
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
      }).select().single();

      _feePayments.insert(0, Map<String, dynamic>.from(r));

      logAudit(
        action: 'create',
        tableName: 'fee_payments',
        recordId: r['id']?.toString(),
        newData: {'student_id': studentId, 'fee_type_id': feeTypeId, 'amount_paid': amountPaid},
      );
      notifyListeners();
      return r;
    } catch (e) {
      debugPrint('Error recording payment: $e');
      return null;
    }
  }

  /// Get payment history for a student.
  /// [FIX] Moved .order() AFTER conditional .eq() calls.
  /// .order() returns PostgrestTransformBuilder which doesn't have .eq().
  Future<List<Map<String, dynamic>>> getPaymentHistory({
    required String studentId,
    String? sessionId,
    String? termId,
  }) async {
    try {
      // Build filter chain first (all return PostgrestFilterBuilder)
      var q = supabase
          .from('fee_payments')
          .select('*, fee_types(name, amount)')
          .eq('school_id', schoolId)
          .eq('student_id', studentId);

      if (sessionId != null) q = q.eq('session_id', sessionId);
      if (termId != null) q = q.eq('term_id', termId);

      // .order() LAST — returns PostgrestTransformBuilder (no more .eq() needed)
      final r = await q.order('payment_date', ascending: false);
      return List<Map<String, dynamic>>.from(r);
    } catch (e) {
      debugPrint('Error fetching payment history: $e');
      return [];
    }
  }

  /// Get outstanding fees for a student.
  /// Compares fee_type amounts against sum of payments.
  Future<List<Map<String, dynamic>>> getOutstandingFees({
    required String studentId,
    String? sessionId,
    String? termId,
  }) async {
    try {
      // Build filter chain first
      var pq = supabase
          .from('fee_payments')
          .select('fee_type_id, amount_paid')
          .eq('school_id', schoolId)
          .eq('student_id', studentId);

      if (sessionId != null) pq = pq.eq('session_id', sessionId);
      if (termId != null) pq = pq.eq('term_id', termId);

      final payments = List<Map<String, dynamic>>.from(await pq);
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

  /// Get fee balance for a student (all fee types, including fully paid).
  /// Used by student portal to show payment status.
  Future<List<Map<String, dynamic>>> getFeeBalance({
    required String studentId,
    String? sessionId,
    String? termId,
  }) async {
    try {
      var pq = supabase
          .from('fee_payments')
          .select('fee_type_id, amount_paid')
          .eq('school_id', schoolId)
          .eq('student_id', studentId);

      if (sessionId != null) pq = pq.eq('session_id', sessionId);
      if (termId != null) pq = pq.eq('term_id', termId);

      final payments = List<Map<String, dynamic>>.from(await pq);
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

  /// Get fee summary for an entire class.
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
      final outstanding = await getOutstandingFees(
        studentId: sid,
        sessionId: sessionId,
        termId: termId,
      );
      final totalOutstanding = outstanding.fold<double>(
        0,
        (s, f) => s + ((f['outstanding'] as double?) ?? 0),
      );
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
    summary.sort((a, b) =>
        ((b['total_outstanding'] as double?) ?? 0).compareTo((a['total_outstanding'] as double?) ?? 0));
    return summary;
  }

  /// Get total collected across all fee types.
  /// [FIX] Moved .eq() conditionals before any .order() call.
  Future<Map<String, dynamic>> getCollectionSummary({String? sessionId, String? termId}) async {
    try {
      // Build filter chain first
      var q = supabase
          .from('fee_payments')
          .select('amount_paid, fee_types(name)')
          .eq('school_id', schoolId);

      if (sessionId != null) q = q.eq('session_id', sessionId);
      if (termId != null) q = q.eq('term_id', termId);

      final payments = List<Map<String, dynamic>>.from(await q);
      double totalCollected = 0;
      final byFeeType = <String, double>{};

      for (final p in payments) {
        final amt = (p['amount_paid'] as num?)?.toDouble() ?? 0;
        totalCollected += amt;
        final feeData = p['fee_types'];
        final name = (feeData is Map<String, dynamic>) ? (feeData['name'] ?? 'Unknown') : 'Unknown';
        byFeeType[name] = (byFeeType[name] ?? 0) + amt;
      }

      return {
        'total_collected': totalCollected,
        'total_transactions': payments.length,
        'by_fee_type': byFeeType,
        'currency': currencySymbol,
      };
    } catch (e) {
      debugPrint('Error fetching collection summary: $e');
      return {
        'total_collected': 0,
        'total_transactions': 0,
        'by_fee_type': <String, double>{},
        'currency': currencySymbol,
      };
    }
  }

  /// Load payments list for display.
  /// [FIX] Moved .order() and .limit() AFTER conditional .eq() calls.
  Future<void> loadPayments({String? sessionId, String? termId, String? studentId}) async {
    try {
      // Build filter chain first
      var q = supabase
          .from('fee_payments')
          .select('*, fee_types(name), students(first_name, last_name, admission_no)')
          .eq('school_id', schoolId);

      if (sessionId != null) q = q.eq('session_id', sessionId);
      if (termId != null) q = q.eq('term_id', termId);
      if (studentId != null) q = q.eq('student_id', studentId);

      // .order() and .limit() LAST
      final r = await q.order('payment_date', ascending: false).limit(200);
      _feePayments = List<Map<String, dynamic>>.from(r);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading payments: $e');
    }
  }

  // ==========================================
  // UTILITY METHODS
  // ==========================================

  /// Get a single fee type by ID.
  Map<String, dynamic>? getFeeTypeById(String feeTypeId) {
    try {
      return _feeTypes.cast<Map<String, dynamic>?>().firstWhere(
            (f) => f?['id']?.toString() == feeTypeId,
            orElse: () => null,
          );
    } catch (e) {
      return null;
    }
  }

  /// Get fee type name by ID.
  String getFeeTypeName(String? feeTypeId) {
    if (feeTypeId == null || feeTypeId.isEmpty) return '';
    final ft = getFeeTypeById(feeTypeId);
    return (ft?['name'] ?? '').toString();
  }

  /// Get fee type amount by ID.
  double getFeeTypeAmount(String? feeTypeId) {
    if (feeTypeId == null || feeTypeId.isEmpty) return 0;
    final ft = getFeeTypeById(feeTypeId);
    return (ft?['amount'] as num?)?.toDouble() ?? 0;
  }

  /// Check if a fee type name already exists.
  Future<bool> feeTypeNameExists(String name) async {
    if (schoolId.isEmpty || name.trim().isEmpty) return false;
    try {
      final existing = await supabase
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

  /// Generate a formatted amount string with currency symbol.
  String formatAmount(double amount) {
    return '$currencySymbol${amount.toStringAsFixed(2)}';
  }

  /// Generate a simple receipt number.
  /// Format: RCP-YYYYMMDD-XXXX (date-based for easy sorting).
  String _generateReceiptNo() {
    final now = DateTime.now();
    final date = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final rand = secureRandomString(4).toUpperCase();
    return 'RCP-$date-$rand';
  }

  /// Clear payments from local state (no DB change).
  void clearPayments() {
    _feePayments.clear();
    notifyListeners();
  }
}
