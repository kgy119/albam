import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/payment_record_model.dart';

class PaymentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 급여 지급 기록 추가
  Future<PaymentRecord> recordPayment({
    required String employeeId,
    required int year,
    required int month,
    required double amount,
  }) async {
    try {
      final response = await _supabase
          .from('payment_records')
          .insert({
        'employee_id': employeeId,
        'year': year,
        'month': month,
        'amount': amount,
      })
          .select()
          .single();

      return PaymentRecord.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('급여 지급 기록 추가 오류: $e');
      throw Exception('급여 지급 기록 추가 실패: $e');
    }
  }

  /// 특정 직원의 급여 지급 기록 조회
  Future<PaymentRecord?> getPaymentRecord({
    required String employeeId,
    required int year,
    required int month,
  }) async {
    try {
      final response = await _supabase
          .from('payment_records')
          .select()
          .eq('employee_id', employeeId)
          .eq('year', year)
          .eq('month', month)
          .maybeSingle();

      if (response == null) return null;

      return PaymentRecord.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('급여 지급 기록 조회 오류: $e');
      return null;
    }
  }

  /// 여러 직원의 급여 지급 기록 일괄 조회
  Future<Map<String, PaymentRecord>> getPaymentRecordsByMonth({
    required List<String> employeeIds,
    required int year,
    required int month,
  }) async {
    try {
      if (employeeIds.isEmpty) return {};

      final response = await _supabase
          .from('payment_records')
          .select()
          .inFilter('employee_id', employeeIds)
          .eq('year', year)
          .eq('month', month);

      final Map<String, PaymentRecord> records = {};
      for (var json in response as List) {
        final record = PaymentRecord.fromJson(json as Map<String, dynamic>);
        records[record.employeeId] = record;
      }

      return records;
    } catch (e) {
      print('급여 지급 기록 일괄 조회 오류: $e');
      return {};
    }
  }

  /// 급여 지급 취소
  Future<void> cancelPayment({
    required String employeeId,
    required int year,
    required int month,
  }) async {
    try {
      await _supabase
          .from('payment_records')
          .delete()
          .eq('employee_id', employeeId)
          .eq('year', year)
          .eq('month', month);
    } catch (e) {
      print('급여 지급 취소 오류: $e');
      throw Exception('급여 지급 취소 실패: $e');
    }
  }
}