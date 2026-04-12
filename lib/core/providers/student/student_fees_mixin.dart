import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_base.dart';

mixin StudentFeesMixin on StudentBase {

  List<Map<String, dynamic>> _lastFeeBalanceCache = [];

  Future<List<Map<String, dynamic>>> getMyFees({String? sessionId, String? termId}) async {
    try {
      var q = supabase
          .from('fee_payments')
          .select('''
            id, fee_type_id, amount_paid, payment_date, payment_method, receipt_no,
            reference_no, remark,
            fee_types(name, amount, frequency, currency_code),
            academic_sessions(name),
            terms(name)
          ''')
          .eq('school_id', schoolId)
          .eq('student_id', studentId);

      if (sessionId != null && sessionId.isNotEmpty) {
        q = q.eq('session_id', sessionId);
      }
      if (termId != null && termId.isNotEmpty) {
        q = q.eq('term_id', termId);
      }

      final response = await q.order('payment_date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading student fees: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getFeesForCurrentTerm() async {
    if (currentTermId == null) return [];
    return getMyFees(termId: currentTermId);
  }

  Future<List<Map<String, dynamic>>> getFeesForCurrentSession() async {
    if (currentSessionId == null) return [];
    return getMyFees(sessionId: currentSessionId);
  }

  Future<List<Map<String, dynamic>>> getRecentPayments({int limit = 10}) async {
    if (schoolId.isEmpty || studentId.isEmpty) return [];
    try {
      return List<Map<String, dynamic>>.from(
        await supabase
            .from('fee_payments')
            .select('''
              id, fee_type_id, amount_paid, payment_date, payment_method, receipt_no,
              reference_no, remark,
              fee_types(name, amount, frequency, currency_code),
              academic_sessions(name),
              terms(name)
            ''')
            .eq('school_id', schoolId)
            .eq('student_id', studentId)
            .order('payment_date', ascending: false)
            .limit(limit),
      );
    } catch (e) {
      debugPrint('Error loading recent payments: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getFeeBalance({String? sessionId, String? termId}) async {
    if (schoolId.isEmpty || studentId.isEmpty) return [];

    try {
      final feeTypes = await supabase
          .from('fee_types')
          .select('id, name, amount, frequency, currency_code')
          .eq('school_id', schoolId)
          .eq('is_active', true);

      final payments = await getMyFees(sessionId: sessionId, termId: termId);

      final balances = <String, Map<String, dynamic>>{};

      for (final ft in feeTypes) {
        final ftId = ft['id']?.toString() ?? '';
        final ftName = ft['name']?.toString() ?? '';
        final totalOwed = (ft['amount'] as num?)?.toDouble() ?? 0;

        double totalPaid = 0;
        for (final p in payments) {
          if ((p['fee_type_id']?.toString() ?? '') == ftId) {
            totalPaid += (p['amount_paid'] as num?)?.toDouble() ?? 0;
          }
        }

        balances[ftId] = {
          'fee_type_id': ftId,
          'fee_name': ftName,
          'total_owed': totalOwed,
          'total_paid': totalPaid,
          'balance': totalOwed - totalPaid,
          'is_paid': totalPaid >= totalOwed,
          'is_overdue': totalPaid < totalOwed,
          'currency': currencySymbol,
        };
      }

      final result = balances.values.toList();
      result.sort((a, b) {
        final aOverdue = a['is_overdue'] == true ? 1 : 0;
        final bOverdue = b['is_overdue'] == true ? 1 : 0;
        return bOverdue - aOverdue;
      });
      return result;
    } catch (e) {
      debugPrint('Error calculating fee balance: $e');
      return [];
    }
  }

  bool get hasOutstandingFees {
    if (_lastFeeBalanceCache.isEmpty) return false;
    return _lastFeeBalanceCache.any((b) => b['is_overdue'] == true);
  }

  double getTotalOwed(List<Map<String, dynamic>> balances) {
    double total = 0;
    for (final b in balances) {
      final balance = b['balance'] as num? ?? 0;
      if (balance > 0) total += balance;
    }
    return total;
  }

  double getTotalPaid(List<Map<String, dynamic>> balances) {
    double total = 0;
    for (final b in balances) {
      final paid = b['total_paid'] as num? ?? 0;
      total += paid;
    }
    return total;
  }

  int getOverdueCount(List<Map<String, dynamic>> balances) {
    return balances.where((b) => b['is_overdue'] == true).length;
  }

  String getOutstandingSummary(List<Map<String, dynamic>> balances) {
    final overdue = getOverdueCount(balances);
    if (overdue == 0) return 'No outstanding fees';
    final total = getTotalOwed(balances);
    return 'You owe $currencySymbol${total.toStringAsFixed(0)} ($overdue fee type${overdue > 1 ? 's' : ''})';
  }

  Future<void> loadFeeBalance({String? sessionId, String? termId}) async {
    _lastFeeBalanceCache = await getFeeBalance(sessionId: sessionId, termId: termId);
  }

  Future<Map<String, dynamic>?> getPaymentByReceiptNo(String receiptNo) async {
    if (receiptNo.isEmpty) return null;
    if (schoolId.isEmpty || studentId.isEmpty) return null;

    try {
      return await supabase
          .from('fee_payments')
          .select('''
            id, fee_type_id, amount_paid, payment_date, payment_method, receipt_no,
            reference_no, remark,
            fee_types(name, amount, frequency, currency_code),
            academic_sessions(name),
            terms(name)
          ''')
          .eq('school_id', schoolId)
          .eq('student_id', studentId)
          .eq('receipt_no', receiptNo)
          .maybeSingle();
    } catch (e) {
      debugPrint('Error finding receipt: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getPaymentSummary({String? sessionId, String? termId}) async {
    if (schoolId.isEmpty || studentId.isEmpty) {
      return {
        'total_paid': 0, 'total_owed': 0, 'fee_types_count': 0,
        'paid_count': 0, 'unpaid_count': 0, 'currency': currencySymbol,
      };
    }

    try {
      final balances = await getFeeBalance(sessionId: sessionId, termId: termId);
      final totalOwed = getTotalOwed(balances);
      final totalPaid = getTotalPaid(balances);
      final paidCount = balances.where((b) => b['is_paid'] == true).length;
      final unpaidCount = getOverdueCount(balances);

      return {
        'total_paid': totalPaid,
        'total_owed': totalOwed,
        'fee_types_count': balances.length,
        'paid_count': paidCount,
        'unpaid_count': unpaidCount,
        'currency': currencySymbol,
      };
    } catch (e) {
      debugPrint('Error calculating payment summary: $e');
      return {
        'total_paid': 0, 'total_owed': 0, 'fee_types_count': 0,
        'paid_count': 0, 'unpaid_count': 0, 'currency': currencySymbol,
      };
    }
  }

  Future<String> getPaymentSummaryString({String? sessionId, String? termId}) async {
    final summary = await getPaymentSummary(sessionId: sessionId, termId: termId);
    final paid = summary['paid_count'] ?? 0;
    final total = summary['fee_types_count'] ?? 0;
    if (total == 0) return 'No fees for this term';
    return 'Paid $paid of $total fees this term';
  }

  void clearFees() {
    _lastFeeBalanceCache = [];
  }
}
