import 'package:get/get.dart';
import '../../core/services/employee_service.dart';
import '../../core/services/schedule_service.dart';
import '../../core/services/payment_service.dart'; // ✅ 추가
import '../../data/models/employee_model.dart';
import '../../data/models/schedule_model.dart';
import '../../data/models/payment_record_model.dart'; // ✅ 추가
import '../../core/utils/salary_calculator.dart';
import '../../core/utils/snackbar_helper.dart';

class SalaryController extends GetxController {
  final EmployeeService _employeeService = EmployeeService();
  final ScheduleService _scheduleService = ScheduleService();
  final PaymentService _paymentService = PaymentService();

  RxBool isLoading = false.obs;
  Rxn<Map<String, dynamic>> salaryData = Rxn<Map<String, dynamic>>();
  Rxn<Employee> currentEmployee = Rxn<Employee>();
  Rxn<PaymentRecord> paymentRecord = Rxn<PaymentRecord>();

  RxList<Schedule> monthlySchedules = <Schedule>[].obs;
  RxInt selectedDay = 0.obs;

  int? currentYear;
  int? currentMonth;

  bool _paymentStatusChanged = false; // ✅ 추가
  bool _initialPaymentStatus = false; // ✅ 추가

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
        currentYear = year;
        currentMonth = month;
        calculateEmployeeSalary(
          employee: employee,
          year: year,
          month: month,
        );
      }
    }
  }

  Future<void> calculateEmployeeSalary({
    required Employee employee,
    required int year,
    required int month,
  }) async {
    isLoading.value = true;
    try {
      final latestEmployee = await _employeeService.getEmployee(employee.id);

      if (latestEmployee == null) {
        SnackbarHelper.showError('직원 정보를 찾을 수 없습니다.');
        return;
      }

      currentEmployee.value = latestEmployee;
      currentYear = year;
      currentMonth = month;

      paymentRecord.value = await _paymentService.getPaymentRecord(
        employeeId: latestEmployee.id,
        year: year,
        month: month,
      );

      _initialPaymentStatus = paymentRecord.value != null; // ✅ 초기 상태 저장

      final schedules = await _scheduleService.getEmployeeMonthlySchedules(
        employeeId: latestEmployee.id,
        year: year,
        month: month,
      );

      List<Schedule> previousMonthSchedules = [];
      if (month == 1) {
        previousMonthSchedules = await _scheduleService.getEmployeeMonthlySchedules(
          employeeId: latestEmployee.id,
          year: year - 1,
          month: 12,
        );
      } else {
        previousMonthSchedules = await _scheduleService.getEmployeeMonthlySchedules(
          employeeId: latestEmployee.id,
          year: year,
          month: month - 1,
        );
      }

      monthlySchedules.value = schedules;

      salaryData.value = SalaryCalculator.calculateMonthlySalary(
        schedules: schedules,
        hourlyWage: latestEmployee.hourlyWage.toDouble(),
        previousMonthSchedules: previousMonthSchedules,
      );

      print('급여 계산 완료');
    } catch (e) {
      print('급여 계산 오류: $e');
      SnackbarHelper.showError('급여 계산 중 문제가 발생했습니다.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> recordPayment() async {
    if (currentEmployee.value == null || currentYear == null || currentMonth == null) {
      SnackbarHelper.showError('급여 정보가 없습니다.');
      return;
    }

    final salary = salaryData.value;
    if (salary == null) {
      SnackbarHelper.showError('급여 계산 정보가 없습니다.');
      return;
    }

    try {
      isLoading.value = true;

      final record = await _paymentService.recordPayment(
        employeeId: currentEmployee.value!.id,
        year: currentYear!,
        month: currentMonth!,
        amount: salary['netPay'],
      );

      paymentRecord.value = record;
      _paymentStatusChanged = true; // ✅ 상태 변경 표시
      SnackbarHelper.showSuccess('급여 지급이 완료되었습니다.');
    } catch (e) {
      print('급여 지급 오류: $e');
      SnackbarHelper.showError('급여 지급 처리 중 오류가 발생했습니다.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cancelPayment() async {
    if (currentEmployee.value == null || currentYear == null || currentMonth == null) {
      SnackbarHelper.showError('급여 정보가 없습니다.');
      return;
    }

    try {
      isLoading.value = true;

      await _paymentService.cancelPayment(
        employeeId: currentEmployee.value!.id,
        year: currentYear!,
        month: currentMonth!,
      );

      paymentRecord.value = null;
      _paymentStatusChanged = true; // ✅ 상태 변경 표시
      SnackbarHelper.showSuccess('급여 지급이 취소되었습니다.');
    } catch (e) {
      print('급여 지급 취소 오류: $e');
      SnackbarHelper.showError('급여 지급 취소 중 오류가 발생했습니다.');
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ 지급 상태가 변경되었는지 확인
  bool hasPaymentStatusChanged() {
    final currentStatus = paymentRecord.value != null;
    return _paymentStatusChanged || (_initialPaymentStatus != currentStatus);
  }

  // 기존 메서드들...
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