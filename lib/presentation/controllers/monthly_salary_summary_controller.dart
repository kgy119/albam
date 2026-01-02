import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/employee_service.dart';
import '../../core/services/schedule_service.dart';
import '../../data/models/workplace_model.dart';
import '../../data/models/employee_model.dart';
import '../../data/models/schedule_model.dart';
import '../../core/utils/salary_calculator.dart';

class MonthlySalarySummaryController extends GetxController {
  final EmployeeService _employeeService = EmployeeService();
  final ScheduleService _scheduleService = ScheduleService();

  Rxn<Workplace> workplace = Rxn<Workplace>();
  RxInt year = DateTime.now().year.obs;
  RxInt month = DateTime.now().month.obs;

  RxBool isLoading = false.obs;
  Rx<Map<String, dynamic>> monthlyStats = Rx<Map<String, dynamic>>({});

  @override
  void onInit() {
    super.onInit();

    final arguments = Get.arguments as Map<String, dynamic>;
    workplace.value = arguments['workplace'];
    year.value = arguments['year'];
    month.value = arguments['month'];

    loadMonthlySalaries();
  }

  /// 월별 급여 로드
  Future<void> loadMonthlySalaries() async {
    isLoading.value = true;
    try {
      print('월별 급여 로드 시작: ${year.value}년 ${month.value}월');

      // 직원 목록 조회
      final employees = await _employeeService.getEmployees(workplace.value!.id);

      if (employees.isEmpty) {
        monthlyStats.value = {};
        return;
      }

      print('직원 수: ${employees.length}명');

      // 해당 월의 스케줄 조회
      final schedules = await _scheduleService.getMonthlySchedules(
        workplaceId: workplace.value!.id,
        year: year.value,
        month: month.value,
      );

      print('스케줄 수: ${schedules.length}개');

      // 통계 계산
      await _calculateStats(employees, schedules);
    } catch (e) {
      print('급여 로드 오류: $e');
      Get.snackbar('오류', '급여 정보를 불러오는데 실패했습니다.');
    } finally {
      isLoading.value = false;
    }
  }

  /// 통계 계산
  Future<void> _calculateStats(List<Employee> employees, List<Schedule> schedules) async {
    double totalHours = 0;
    double totalRegularHours = 0;
    double totalSubstituteHours = 0;
    double totalWeeklyHolidayHours = 0;
    double totalBasicPay = 0;
    double totalWeeklyHolidayPay = 0;
    double totalSalary = 0;
    double totalTax = 0;
    double totalNetPay = 0;

    List<Map<String, dynamic>> employeeSalaries = [];

    for (var employee in employees) {
      final employeeSchedules = schedules
          .where((schedule) => schedule.employeeId == employee.id)
          .toList();

      if (employeeSchedules.isEmpty) continue;

      final salaryData = SalaryCalculator.calculateMonthlySalary(
        schedules: employeeSchedules,
        hourlyWage: employee.hourlyWage.toDouble(),
      );

      final workDays = employeeSchedules
          .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
          .toSet()
          .length;

      employeeSalaries.add({
        'employee': employee,
        'salaryData': salaryData,
        'workDays': workDays,
      });

      totalHours += salaryData['totalHours'];
      totalRegularHours += salaryData['regularHours'];
      totalSubstituteHours += salaryData['substituteHours'];
      totalWeeklyHolidayHours += salaryData['weeklyHolidayHours'];
      totalBasicPay += salaryData['basicPay'];
      totalWeeklyHolidayPay += salaryData['weeklyHolidayPay'];
      totalSalary += salaryData['totalPay'];
      totalTax += salaryData['tax'];
      totalNetPay += salaryData['netPay'];
    }

    // 실수령액 기준 내림차순 정렬
    employeeSalaries.sort((a, b) {
      final aNetPay = (a['salaryData'] as Map<String, dynamic>)['netPay'] as double;
      final bNetPay = (b['salaryData'] as Map<String, dynamic>)['netPay'] as double;
      return bNetPay.compareTo(aNetPay);
    });

    monthlyStats.value = {
      'totalHours': totalHours,
      'totalRegularHours': totalRegularHours,
      'totalSubstituteHours': totalSubstituteHours,
      'totalWeeklyHolidayHours': totalWeeklyHolidayHours,
      'totalBasicPay': totalBasicPay,
      'totalWeeklyHolidayPay': totalWeeklyHolidayPay,
      'totalSalary': totalSalary,
      'totalTax': totalTax,
      'totalNetPay': totalNetPay,
      'employeeCount': employeeSalaries.length,
      'employeeSalaries': employeeSalaries,
    };

    print('통계 계산 완료');
  }

  /// 월 선택 다이얼로그
  void showMonthPicker() {
    showDialog(
      context: Get.context!,
      builder: (BuildContext context) {
        int selectedYear = year.value;
        int selectedMonth = month.value;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('월 선택'),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 년도 선택
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: '년도',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedYear,
                      items: List.generate(5, (index) {
                        final year = DateTime.now().year - 2 + index;
                        return DropdownMenuItem(
                          value: year,
                          child: Text('$year년'),
                        );
                      }),
                      onChanged: (value) {
                        setState(() {
                          selectedYear = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // 월 선택
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: '월',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedMonth,
                      items: List.generate(12, (index) {
                        final month = index + 1;
                        return DropdownMenuItem(
                          value: month,
                          child: Text('$month월'),
                        );
                      }),
                      onChanged: (value) {
                        setState(() {
                          selectedMonth = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    year.value = selectedYear;
                    month.value = selectedMonth;
                    Navigator.of(context).pop();
                    loadMonthlySalaries();
                  },
                  child: const Text('확인'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}