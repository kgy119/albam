import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/schedule_model.dart';
import '../config/supabase_config.dart';

class ScheduleService extends GetxService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 특정 사업장의 월별 스케줄 조회
  Future<List<Schedule>> getMonthlySchedules({
    required String workplaceId,
    required int year,
    required int month,
  }) async {
    try {
      print('월별 스케줄 조회: $year-$month');

      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 1);

      final response = await _supabase
          .from(SupabaseConfig.schedulesTable)
          .select()
          .eq('workplace_id', workplaceId)
          .gte('date', startOfMonth.toIso8601String())
          .lt('date', endOfMonth.toIso8601String())
          .order('date', ascending: true);

      print('조회된 스케줄 수: ${response.length}');

      final schedules = (response as List)
          .map((json) => Schedule.fromJson(json as Map<String, dynamic>))
          .toList();

      return schedules;
    } catch (e) {
      print('월별 스케줄 조회 오류: $e');
      throw Exception('스케줄 조회 실패: $e');
    }
  }

  /// 특정 날짜의 스케줄 조회
  Future<List<Schedule>> getDaySchedules({
    required String workplaceId,
    required DateTime date,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from(SupabaseConfig.schedulesTable)
          .select()
          .eq('workplace_id', workplaceId)
          .gte('date', startOfDay.toIso8601String())
          .lt('date', endOfDay.toIso8601String())
          .order('start_time', ascending: true);

      return (response as List)
          .map((json) => Schedule.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('일별 스케줄 조회 오류: $e');
      throw Exception('스케줄 조회 실패: $e');
    }
  }

  /// 스케줄 추가
  Future<Schedule> addSchedule({
    required String workplaceId,
    required String employeeId,
    required String employeeName,
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime,
    required int totalMinutes,
    bool isSubstitute = false,
  }) async {
    try {
      print('스케줄 추가 시작');

      final response = await _supabase
          .from(SupabaseConfig.schedulesTable)
          .insert({
        'workplace_id': workplaceId,
        'employee_id': employeeId,
        'employee_name': employeeName,
        'date': date.toIso8601String(),
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'total_minutes': totalMinutes,
        'is_substitute': isSubstitute,
      })
          .select()
          .single();

      print('스케줄 추가 완료');

      return Schedule.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('스케줄 추가 오류: $e');
      throw Exception('스케줄 추가 실패: $e');
    }
  }

  /// 스케줄 수정
  Future<void> updateSchedule({
    required String scheduleId,
    required String employeeId,
    required String employeeName,
    required DateTime startTime,
    required DateTime endTime,
    required int totalMinutes,
    bool isSubstitute = false,
  }) async {
    try {
      print('스케줄 수정 시작: $scheduleId');

      await _supabase
          .from(SupabaseConfig.schedulesTable)
          .update({
        'employee_id': employeeId,
        'employee_name': employeeName,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'total_minutes': totalMinutes,
        'is_substitute': isSubstitute,
      })
          .eq('id', scheduleId);

      print('스케줄 수정 완료');
    } catch (e) {
      print('스케줄 수정 오류: $e');
      throw Exception('스케줄 수정 실패: $e');
    }
  }

  /// 스케줄 삭제
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      print('스케줄 삭제 시작: $scheduleId');

      await _supabase
          .from(SupabaseConfig.schedulesTable)
          .delete()
          .eq('id', scheduleId);

      print('스케줄 삭제 완료');
    } catch (e) {
      print('스케줄 삭제 오류: $e');
      throw Exception('스케줄 삭제 실패: $e');
    }
  }

  /// 여러 스케줄 일괄 삭제 (✅ 수정됨)
  Future<void> deleteSchedules(List<String> scheduleIds) async {
    try {
      print('스케줄 일괄 삭제 시작: ${scheduleIds.length}개');

      // ✅ in_ → inFilter 변경
      await _supabase
          .from(SupabaseConfig.schedulesTable)
          .delete()
          .inFilter('id', scheduleIds);

      print('스케줄 일괄 삭제 완료');
    } catch (e) {
      print('스케줄 일괄 삭제 오류: $e');
      throw Exception('스케줄 삭제 실패: $e');
    }
  }

  /// 특정 직원의 월별 스케줄 조회
  Future<List<Schedule>> getEmployeeMonthlySchedules({
    required String employeeId,
    required int year,
    required int month,
  }) async {
    try {
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 1);

      final response = await _supabase
          .from(SupabaseConfig.schedulesTable)
          .select()
          .eq('employee_id', employeeId)
          .gte('date', startOfMonth.toIso8601String())
          .lt('date', endOfMonth.toIso8601String())
          .order('date', ascending: true);

      return (response as List)
          .map((json) => Schedule.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('직원 월별 스케줄 조회 오류: $e');
      throw Exception('스케줄 조회 실패: $e');
    }
  }
}