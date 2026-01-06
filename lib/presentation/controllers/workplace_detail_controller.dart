import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/salary_calculator.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/employee_service.dart';
import '../../core/services/schedule_service.dart';
import '../../data/models/workplace_model.dart';
import '../../data/models/employee_model.dart';
import '../../data/models/schedule_model.dart';

class WorkplaceDetailController extends GetxController {
  final StorageService _storageService = StorageService();
  final EmployeeService _employeeService = EmployeeService();
  final ScheduleService _scheduleService = ScheduleService();

  // 현재 사업장 정보
  late Workplace workplace;

  // 직원 목록
  RxList<Employee> employees = <Employee>[].obs;

  // 선택된 월/년
  Rx<DateTime> selectedDate = DateTime.now().obs;

  // 로딩 상태
  RxBool isLoadingEmployees = false.obs;

  // 달력 관련
  RxInt selectedDay = 0.obs;

  // 월별 스케줄 데이터
  RxList<Schedule> monthlySchedules = <Schedule>[].obs;

  // 월별 통계 데이터
  Rx<Map<String, dynamic>> monthlyStats = Rx<Map<String, dynamic>>({});
  RxBool isLoadingStats = false.obs;

  @override
  void onInit() {
    super.onInit();
    workplace = Get.arguments as Workplace;

    // 초기 데이터 로드
    loadEmployees();
    loadMonthlySchedules();

    // 월 변경시 스케줄 다시 로드
    ever(selectedDate, (date) {
      loadMonthlySchedules();
      calculateMonthlyStats();
    });
  }

  /// 직원 목록 로드
  Future<void> loadEmployees() async {
    isLoadingEmployees.value = true;

    try {
      print('사업장 ID로 직원 조회 시작: ${workplace.id}');

      employees.value = await _employeeService.getEmployees(workplace.id);

      print('직원 목록 로드 완료: ${employees.length}명');
    } catch (e) {
      print('직원 목록 로드 오류: $e');
      employees.value = [];
      SnackbarHelper.showError('직원 목록을 불러오는데 실패했습니다.');
    } finally {
      isLoadingEmployees.value = false;
    }
  }

  /// 직원 추가
  Future<bool> addEmployee({
    required String name,
    required String phoneNumber,
    required int hourlyWage,
    String? contractImageUrl,
    String? bankName,
    String? accountNumber,
  }) async {
    try {
      print('직원 추가 시작: $name');

      final newEmployee = await _employeeService.addEmployee(
        workplaceId: workplace.id,
        name: name,
        phoneNumber: phoneNumber,
        hourlyWage: hourlyWage,
        contractImageUrl: contractImageUrl,
        bankName: bankName,
        accountNumber: accountNumber,
      );

      print('직원 추가 완료');

      // 리스트 맨 앞에 추가
      employees.insert(0, newEmployee);

      return true;
    } catch (e) {
      print('직원 추가 오류: $e');
      SnackbarHelper.showError('직원 등록에 실패했습니다. 다시 시도해주세요.');
      return false;
    }
  }

  /// 직원 정보 수정
  Future<bool> updateEmployee({
    required String employeeId,
    required String name,
    required String phoneNumber,
    required int hourlyWage,
    String? contractImageUrl,
    String? bankName,
    String? accountNumber,
  }) async {
    try {
      print('직원 수정 시작: $name');

      await _employeeService.updateEmployee(
        employeeId: employeeId,
        name: name,
        phoneNumber: phoneNumber,
        hourlyWage: hourlyWage,
        contractImageUrl: contractImageUrl,
        bankName: bankName,
        accountNumber: accountNumber,
      );

      print('직원 정보 수정 완료');

      // 리스트 새로고침
      await loadEmployees();

      return true;
    } catch (e) {
      print('직원 수정 오류: $e');
      SnackbarHelper.showError('직원 정보 수정에 실패했습니다: ${e.toString()}');
      return false;
    }
  }

  /// 전화번호 포맷팅
  String formatPhoneNumber(String phone) {
    String numbers = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (numbers.length == 11) {
      return '${numbers.substring(0, 3)}-${numbers.substring(3, 7)}-${numbers.substring(7)}';
    }

    return phone;
  }

  /// 전화번호 유효성 검사
  bool validatePhoneNumber(String phone) {
    String numbers = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return numbers.length == 11 && numbers.startsWith('010');
  }

  /// 직원 삭제
  Future<bool> deleteEmployee(String employeeId) async {
    try {
      // 1. 직원 정보 가져오기
      final employee = employees.firstWhere((e) => e.id == employeeId);

      // 2. 근로계약서 이미지 삭제
      if (employee.contractImageUrl != null &&
          employee.contractImageUrl!.isNotEmpty) {
        try {
          await _storageService.deleteContractImage(employee.contractImageUrl!);
          print('근로계약서 이미지 삭제 완료');
        } catch (e) {
          print('이미지 삭제 오류 (무시): $e');
        }
      }

      // 3. 직원 삭제 (CASCADE로 스케줄도 자동 삭제됨)
      await _employeeService.deleteEmployee(employeeId);

      // 4. 리스트에서 제거
      employees.removeWhere((e) => e.id == employeeId);

      SnackbarHelper.showSuccess('직원이 삭제되었습니다.');
      return true;
    } catch (e) {
      print('직원 삭제 오류: $e');
      SnackbarHelper.showError('직원 삭제에 실패했습니다.');
      return false;
    }
  }

  /// 월별 스케줄 로드
  Future<void> loadMonthlySchedules() async {
    try {
      final year = selectedDate.value.year;
      final month = selectedDate.value.month;

      monthlySchedules.value = await _scheduleService.getMonthlySchedules(
        workplaceId: workplace.id,
        year: year,
        month: month,
      );

      print('월별 스케줄 로드 완료: ${monthlySchedules.length}개');

      // 스케줄 로드 후 통계 계산
      await calculateMonthlyStats();
    } catch (e) {
      print('월별 스케줄 로드 오류: $e');
      monthlySchedules.value = [];
    }
  }

  /// 월별 통계 계산
  Future<void> calculateMonthlyStats() async {
    if (employees.isEmpty) {
      monthlyStats.value = {};
      return;
    }

    isLoadingStats.value = true;
    try {
      // 전달 스케줄 조회
      List<Schedule> previousMonthSchedules = [];
      final currentYear = selectedDate.value.year;
      final currentMonth = selectedDate.value.month;

      if (currentMonth == 1) {
        previousMonthSchedules = await _scheduleService.getMonthlySchedules(
          workplaceId: workplace.id,
          year: currentYear - 1,
          month: 12,
        );
      } else {
        previousMonthSchedules = await _scheduleService.getMonthlySchedules(
          workplaceId: workplace.id,
          year: currentYear,
          month: currentMonth - 1,
        );
      }

      double totalHours = 0;
      double totalRegularHours = 0;
      double totalSubstituteHours = 0;
      double totalWeeklyHolidayHours = 0;
      double totalBasicPay = 0;
      double totalWeeklyHolidayPay = 0;
      double totalSalary = 0;
      double totalTax = 0;
      double totalNetPay = 0;
      int totalWorkDays = 0;

      List<Map<String, dynamic>> employeeSalaries = [];

      for (var employee in employees) {
        // 해당 직원의 이번 달 스케줄 필터링
        final employeeSchedules = monthlySchedules
            .where((schedule) => schedule.employeeId == employee.id)
            .toList();

        if (employeeSchedules.isEmpty) continue;

        // 해당 직원의 전달 스케줄 필터링
        final employeePreviousSchedules = previousMonthSchedules
            .where((schedule) => schedule.employeeId == employee.id)
            .toList();

        // 급여 계산 (전달 스케줄 포함)
        final salaryData = SalaryCalculator.calculateMonthlySalary(
          schedules: employeeSchedules,
          hourlyWage: employee.hourlyWage.toDouble(),
          previousMonthSchedules: employeePreviousSchedules,
        );

        // 근무일수 계산
        final workDays = employeeSchedules
            .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
            .toSet()
            .length;

        employeeSalaries.add({
          'employee': employee,
          'salaryData': salaryData,
          'workDays': workDays,
        });

        // 전체 합계 계산
        totalHours += salaryData['totalHours'];
        totalRegularHours += salaryData['regularHours'];
        totalSubstituteHours += salaryData['substituteHours'];
        totalWeeklyHolidayHours += salaryData['weeklyHolidayHours'];
        totalBasicPay += salaryData['basicPay'];
        totalWeeklyHolidayPay += salaryData['weeklyHolidayPay'];
        totalSalary += salaryData['totalPay'];
        totalTax += salaryData['tax'];
        totalNetPay += salaryData['netPay'];
        totalWorkDays += workDays;
      }

      // 통계 데이터 저장
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
        'totalWorkDays': totalWorkDays,
        'employeeCount': employeeSalaries.length,
        'employeeSalaries': employeeSalaries,
      };

      print('월별 통계 계산 완료');
    } catch (e) {
      print('월별 통계 계산 오류: $e');
      monthlyStats.value = {};
    } finally {
      isLoadingStats.value = false;
    }
  }

  /// 특정 날짜의 총 근무시간 계산
  double getDayTotalHours(int day) {
    final targetDate = DateTime(selectedDate.value.year, selectedDate.value.month, day);

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

  /// 특정 날짜의 스케줄 목록 반환
  List<Schedule> getDaySchedules(int day) {
    final targetDate = DateTime(selectedDate.value.year, selectedDate.value.month, day);

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

  /// 월 변경
  void changeMonth(int year, int month) {
    selectedDate.value = DateTime(year, month, 1);
    selectedDay.value = 0;
    loadMonthlySchedules();
  }

  /// 일자 선택
  void selectDay(int day) {
    selectedDay.value = day;
  }

  /// 현재 월의 일수 계산
  int getDaysInMonth() {
    final year = selectedDate.value.year;
    final month = selectedDate.value.month;
    return DateTime(year, month + 1, 0).day;
  }

  /// 해당 월의 첫째 날이 무슨 요일인지 계산
  int getFirstDayOfWeek() {
    final firstDay = DateTime(selectedDate.value.year, selectedDate.value.month, 1);
    return firstDay.weekday % 7;
  }

  /// 최신 직원 정보 가져오기
  Future<Employee?> getLatestEmployeeInfo(String employeeId) async {
    try {
      return await _employeeService.getEmployee(employeeId);
    } catch (e) {
      print('최신 직원 정보 조회 오류: $e');
      return null;
    }
  }
}