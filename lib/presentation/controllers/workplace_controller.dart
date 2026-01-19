import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/schedule_service.dart';
import '../../core/services/workplace_service.dart';
import '../../core/services/employee_service.dart';
import '../../core/services/subscription_limit_service.dart';
import '../../core/utils/salary_calculator.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/schedule_model.dart';
import '../../data/models/workplace_model.dart';

class WorkplaceController extends GetxController {
  final WorkplaceService _workplaceService = WorkplaceService();
  final EmployeeService _employeeService = EmployeeService();
  final SubscriptionLimitService _limitService = SubscriptionLimitService();

  RxList<Workplace> workplaces = <Workplace>[].obs;
  RxBool isLoading = false.obs;
  RxBool isAdding = false.obs;

  @override
  void onReady() {
    super.onReady();
    loadWorkplaces();
  }

  Future<void> loadWorkplaces() async {
    isLoading.value = true;

    try {
      workplaces.value = await _workplaceService.getWorkplaces();
      print('사업장 로드 완료: ${workplaces.length}개');

      await loadAllEmployeeCounts();
    } catch (e) {
      print('사업장 로드 오류: $e');
      SnackbarHelper.showError('사업장 목록을 불러오는데 실패했습니다.');
    } finally {
      isLoading.value = false;
    }
  }

  /// 사업장 추가 (한도 체크 포함)
  Future<void> addWorkplace(String name) async {
    if (isAdding.value) return;

    try {
      isAdding.value = true;

      // ✅ 최신 구독 상태를 다시 가져옴
      print('🔄 사업장 추가 전 구독 상태 확인');
      await _limitService.getUserSubscriptionLimits();

      // 1. 사업장 추가 가능 여부 확인
      final canAdd = await _limitService.canAddWorkplace();

      if (!canAdd) {
        _showSubscriptionLimitDialog();
        return;
      }

      // 2. 사업장 추가
      final newWorkplace = await _workplaceService.addWorkplace(name);
      workplaces.add(newWorkplace);  // ✅ insert(0, ...) → add(...)

      await loadAllEmployeeCounts();

      SnackbarHelper.showSuccess('사업장이 추가되었습니다.');
    } catch (e) {
      print('사업장 추가 오류: $e');
      SnackbarHelper.showError(e.toString());
    } finally {
      isAdding.value = false;
    }
  }

  /// 구독 한도 초과 다이얼로그
  void _showSubscriptionLimitDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber[700]),
            const SizedBox(width: 8),
            const Text('사업장 추가 제한'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '무료 회원은 최대 1개의 사업장만 등록할 수 있습니다.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.amber[700], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        '프리미엄 혜택',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildBenefitItem('사업장 등록 무제한'),
                  _buildBenefitItem('직원 등록 무제한'),
                  _buildBenefitItem('광고제거'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.toNamed('/account-settings');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('프리미엄 구독하기'),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check, color: Colors.amber[700], size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// 사업장 삭제
  Future<void> deleteWorkplace(String workplaceId) async {
    try {
      await _workplaceService.deleteWorkplace(workplaceId);

      workplaces.removeWhere((w) => w.id == workplaceId);

      SnackbarHelper.showSuccess('사업장이 삭제되었습니다.');
    } catch (e) {
      print('사업장 삭제 오류: $e');
      SnackbarHelper.showError(e.toString());
    }
  }

  /// 사업장 이름 수정
  Future<void> updateWorkplaceName(String workplaceId, String newName) async {
    try {
      await _workplaceService.updateWorkplace(workplaceId, newName);

      final index = workplaces.indexWhere((w) => w.id == workplaceId);
      if (index != -1) {
        workplaces[index] = workplaces[index].copyWith(
          name: newName,
          updatedAt: DateTime.now(),
        );
      }

      SnackbarHelper.showSuccess('사업장 정보가 수정되었습니다.');
    } catch (e) {
      print('사업장 수정 오류: $e');
      SnackbarHelper.showError(e.toString());
    }
  }

  // 사업장별 직원 수 저장
  RxMap<String, int> employeeCountMap = <String, int>{}.obs;

// ✅ 사업장별 월별 급여 합계 저장
  RxMap<String, double> monthlySalaryMap = <String, double>{}.obs;

  /// 모든 사업장의 직원 수 조회
  Future<void> loadAllEmployeeCounts() async {
    try {
      for (var workplace in workplaces) {
        final count = await _employeeService.getEmployeeCount(workplace.id);
        employeeCountMap[workplace.id] = count;
      }

      // ✅ 월별 급여도 함께 조회
      await loadAllMonthlySalaries();
    } catch (e) {
      print('직원 수 조회 오류: $e');
    }
  }

  /// 특정 사업장의 직원 수 반환
  int getEmployeeCount(String workplaceId) {
    return employeeCountMap[workplaceId] ?? 0;
  }

  /// ✅ 모든 사업장의 이번 달 급여 합계 조회 (수정)
  Future<void> loadAllMonthlySalaries() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day); // ✅ 오늘 날짜

      for (var workplace in workplaces) {
        // ✅ 수정: 재직중 + 퇴사 직원 모두 조회
        final activeEmployees = await _employeeService.getEmployees(workplace.id);
        final resignedEmployees = await _employeeService.getResignedEmployees(workplace.id);
        final employees = [...activeEmployees, ...resignedEmployees];

        if (employees.isEmpty) {
          monthlySalaryMap[workplace.id] = 0;
          continue;
        }

        // 해당 사업장의 이번 달 스케줄 조회
        final schedules = await ScheduleService().getMonthlySchedules(
          workplaceId: workplace.id,
          year: now.year,
          month: now.month,
        );

        // ✅ 추가: 오늘까지의 스케줄만 필터링
        final schedulesUntilToday = schedules.where((schedule) {
          final scheduleDate = DateTime(
            schedule.date.year,
            schedule.date.month,
            schedule.date.day,
          );
          return scheduleDate.isBefore(today) || scheduleDate.isAtSameMomentAs(today);
        }).toList();

        // 전달 스케줄 조회 (주휴수당 계산용)
        List<Schedule> previousMonthSchedules = [];
        if (now.month == 1) {
          previousMonthSchedules = await ScheduleService().getMonthlySchedules(
            workplaceId: workplace.id,
            year: now.year - 1,
            month: 12,
          );
        } else {
          previousMonthSchedules = await ScheduleService().getMonthlySchedules(
            workplaceId: workplace.id,
            year: now.year,
            month: now.month - 1,
          );
        }

        // 직원별로 급여 계산
        double totalNetPay = 0;

        for (var employee in employees) {
          // ✅ 수정: 오늘까지의 스케줄만 사용
          final employeeSchedules = schedulesUntilToday
              .where((schedule) => schedule.employeeId == employee.id)
              .toList();

          if (employeeSchedules.isEmpty) continue;

          // 해당 직원의 전달 스케줄
          final employeePreviousSchedules = previousMonthSchedules
              .where((schedule) => schedule.employeeId == employee.id)
              .toList();

          // 급여 계산 (SalaryCalculator 사용)
          final salaryData = SalaryCalculator.calculateMonthlySalary(
            schedules: employeeSchedules,
            hourlyWage: employee.hourlyWage.toDouble(),
            previousMonthSchedules: employeePreviousSchedules, // ✅ 추가
          );

          totalNetPay += salaryData['netPay'];
        }

        monthlySalaryMap[workplace.id] = totalNetPay;

        print('${workplace.name} 이번달 급여 (오늘까지): ${totalNetPay.toStringAsFixed(0)}원');
      }
    } catch (e) {
      print('월별 급여 조회 오류: $e');
    }
  }

  /// ✅ 특정 사업장의 이번 달 급여 합계 반환
  double getMonthlySalary(String workplaceId) {
    return monthlySalaryMap[workplaceId] ?? 0;
  }
}