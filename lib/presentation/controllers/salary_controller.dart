import 'package:get/get.dart';
import '../../core/services/employee_service.dart';
import '../../core/services/schedule_service.dart';
import '../../data/models/employee_model.dart';
import '../../data/models/schedule_model.dart';
import '../../core/utils/salary_calculator.dart';

class SalaryController extends GetxController {
  final EmployeeService _employeeService = EmployeeService();
  final ScheduleService _scheduleService = ScheduleService();

  RxBool isLoading = false.obs;
  Rxn<Map<String, dynamic>> salaryData = Rxn<Map<String, dynamic>>();
  Rxn<Employee> currentEmployee = Rxn<Employee>();

  RxList<Schedule> monthlySchedules = <Schedule>[].obs;
  RxInt selectedDay = 0.obs;

  @override
  void onInit() {
    super.onInit();

    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      final employee = arguments['employee'];
      final year = arguments['year'];
      final month = arguments['month'];

      if (employee != null && year != null && month != null) {
        currentEmployee.value = employee;
        calculateEmployeeSalary(
          employee: employee,
          year: year,
          month: month,
        );
      }
    }
  }

  /// 직원의 월별 급여 계산
  Future<void> calculateEmployeeSalary({
    required Employee employee,
    required int year,
    required int month,
  }) async {
    isLoading.value = true;
    try {
      // 최신 직원 정보 다시 가져오기 (시급 변경 등 반영)
      final latestEmployee = await _employeeService.getEmployee(employee.id);

      if (latestEmployee == null) {
        Get.snackbar('오류', '직원 정보를 찾을 수 없습니다.');
        return;
      }

      currentEmployee.value = latestEmployee;

      // 월별 스케줄 조회
      final schedules = await _scheduleService.getEmployeeMonthlySchedules(
        employeeId: latestEmployee.id,
        year: year,
        month: month,
      );

      monthlySchedules.value = schedules;

      // 급여 계산
      salaryData.value = SalaryCalculator.calculateMonthlySalary(
        schedules: schedules,
        hourlyWage: latestEmployee.hourlyWage.toDouble(),
      );

      print('급여 계산 완료');
    } catch (e) {
      print('급여 계산 오류: $e');
      Get.snackbar('오류', '급여 계산 중 문제가 발생했습니다.');
    } finally {
      isLoading.value = false;
    }
  }

  double getDayTotalHours(int day, int year, int month) {
    final targetDate = DateTime(year, month, day);

    double totalHours = 0;
    for (var schedule in monthlySchedules) {
      final scheduleDate = DateTime(
        schedule.date.year,
        schedule.date.month,
        schedule.date.day,
      );

      if (scheduleDate.isAtSameMomentAs(targetDate)) {
        totalHours += schedule.totalMinutes / 60.0;
      }
    }

    return totalHours;
  }

  List<Schedule> getDaySchedules(int day, int year, int month) {
    final targetDate = DateTime(year, month, day);

    final daySchedules = monthlySchedules.where((schedule) {
      final scheduleDate = DateTime(
        schedule.date.year,
        schedule.date.month,
        schedule.date.day,
      );
      return scheduleDate.isAtSameMomentAs(targetDate);
    }).toList();

    // 시작 시간 기준 오름차순 정렬
    daySchedules.sort((a, b) => a.startTime.compareTo(b.startTime));

    return daySchedules;
  }

  int getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  int getFirstDayOfWeek(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    return firstDay.weekday % 7;
  }

  void selectDay(int day) {
    selectedDay.value = day;
  }
}