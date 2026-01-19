import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/employee_model.dart';
import '../config/supabase_config.dart';
import 'auth_service.dart';

class EmployeeService extends GetxService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ✅ 재직중 직원만 조회 (기존 getEmployees 수정)
  Future<List<Employee>> getEmployees(String workplaceId) async {
    try {
      print('재직중 직원 조회 시작: $workplaceId');

      final response = await _supabase
          .from(SupabaseConfig.employeesTable)
          .select()
          .eq('workplace_id', workplaceId)
          .eq('employment_status', 'active') // ✅ 재직중만
          .order('created_at', ascending: true);

      print('조회된 재직중 직원 수: ${response.length}');

      final employees = (response as List)
          .map((json) => Employee.fromJson(json as Map<String, dynamic>))
          .toList();

      return employees;
    } catch (e) {
      print('직원 조회 오류: $e');
      throw Exception('직원 목록 조회 실패: $e');
    }
  }

// ✅ 퇴사 직원 조회 (새로 추가)
  Future<List<Employee>> getResignedEmployees(String workplaceId) async {
    try {
      print('퇴사 직원 조회 시작: $workplaceId');

      final response = await _supabase
          .from(SupabaseConfig.employeesTable)
          .select()
          .eq('workplace_id', workplaceId)
          .eq('employment_status', 'resigned')
          .order('resigned_at', ascending: false);

      print('조회된 퇴사 직원 수: ${response.length}');

      final employees = (response as List)
          .map((json) => Employee.fromJson(json as Map<String, dynamic>))
          .toList();

      return employees;
    } catch (e) {
      print('퇴사 직원 조회 오류: $e');
      throw Exception('퇴사 직원 목록 조회 실패: $e');
    }
  }

// ✅ 퇴사 처리 (새로 추가)
  Future<void> resignEmployee(String employeeId) async {
    try {
      print('직원 퇴사 처리 시작: $employeeId');

      await _supabase
          .from(SupabaseConfig.employeesTable)
          .update({
        'employment_status': 'resigned',
        'resigned_at': DateTime.now().toIso8601String(),
      })
          .eq('id', employeeId);

      print('직원 퇴사 처리 완료');
    } catch (e) {
      print('직원 퇴사 처리 오류: $e');
      throw Exception('직원 퇴사 처리 실패: $e');
    }
  }

// ✅ 복직 처리 (새로 추가)
  Future<void> rehireEmployee(String employeeId) async {
    try {
      print('직원 복직 처리 시작: $employeeId');

      await _supabase
          .from(SupabaseConfig.employeesTable)
          .update({
        'employment_status': 'active',
        'resigned_at': null,
      })
          .eq('id', employeeId);

      print('직원 복직 처리 완료');
    } catch (e) {
      print('직원 복직 처리 오류: $e');
      throw Exception('직원 복직 처리 실패: $e');
    }
  }

// ✅ 완전 삭제 (기존 deleteEmployee 그대로 유지)
  Future<void> deleteEmployee(String employeeId) async {
    try {
      print('직원 완전 삭제 시작: $employeeId');

      // CASCADE 설정으로 관련 스케줄도 자동 삭제됨
      await _supabase
          .from(SupabaseConfig.employeesTable)
          .delete()
          .eq('id', employeeId);

      print('직원 완전 삭제 완료');
    } catch (e) {
      print('직원 삭제 오류: $e');
      throw Exception('직원 삭제 실패: $e');
    }
  }

// ✅ 재직중 직원 수 조회 (기존 수정)
  Future<int> getEmployeeCount(String workplaceId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.employeesTable)
          .select('id')
          .eq('workplace_id', workplaceId)
          .eq('employment_status', 'active') // ✅ 재직중만 카운트
          .count();

      return response.count;
    } catch (e) {
      print('직원 수 조회 오류: $e');
      return 0;
    }
  }

  /// 직원 추가
  Future<Employee> addEmployee({
    required String workplaceId,
    required String name,
    required String phoneNumber,
    required int hourlyWage,
    String? contractImageUrl,
    String? bankName,
    String? accountNumber,
  }) async {
    try {
      print('직원 추가 시작: $name');

      final response = await _supabase
          .from(SupabaseConfig.employeesTable)
          .insert({
        'workplace_id': workplaceId,
        'name': name.trim(),
        'phone_number': phoneNumber.trim(),
        'hourly_wage': hourlyWage,
        'contract_image_url': contractImageUrl,
        'bank_name': bankName?.trim(),
        'account_number': accountNumber?.trim(),
      })
          .select()
          .single();

      print('직원 추가 완료');

      return Employee.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('직원 추가 오류: $e');
      throw Exception('직원 추가 실패: $e');
    }
  }

  /// 직원 정보 수정
  Future<void> updateEmployee({
    required String employeeId,
    required String name,
    required String phoneNumber,
    required int hourlyWage,
    String? contractImageUrl,
    String? bankName,
    String? accountNumber,
  }) async {
    try {
      print('직원 수정 시작: $employeeId');

      await _supabase
          .from(SupabaseConfig.employeesTable)
          .update({
        'name': name.trim(),
        'phone_number': phoneNumber.trim(),
        'hourly_wage': hourlyWage,
        'contract_image_url': contractImageUrl,
        'bank_name': bankName?.trim(),
        'account_number': accountNumber?.trim(),
      })
          .eq('id', employeeId);

      print('직원 수정 완료');
    } catch (e) {
      print('직원 수정 오류: $e');
      throw Exception('직원 정보 수정 실패: $e');
    }
  }

  /// 특정 직원 정보 조회
  Future<Employee?> getEmployee(String employeeId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.employeesTable)
          .select()
          .eq('id', employeeId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Employee.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('직원 조회 오류: $e');
      return null;
    }
  }
}