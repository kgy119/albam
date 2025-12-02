import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/employee_model.dart';
import '../../data/models/schedule_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/salary_calculator.dart';

class SalaryController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RxBool isLoading = false.obs;
  Rxn<Map<String, dynamic>> salaryData = Rxn<Map<String, dynamic>>();
  Rxn<Employee> currentEmployee = Rxn<Employee>(); // 현재 직원 정보 저장

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
      final employeeDoc = await _firestore
          .collection(AppConstants.employeesCollection)
          .doc(employee.id)
          .get();

      if (!employeeDoc.exists) {
        Get.snackbar('오류', '직원 정보를 찾을 수 없습니다.');
        return;
      }

      final latestEmployee = Employee.fromFirestore(employeeDoc);
      currentEmployee.value = latestEmployee;

      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 1);

      final querySnapshot = await _firestore
          .collection(AppConstants.schedulesCollection)
          .where('employeeId', isEqualTo: latestEmployee.id)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
          .orderBy('date')
          .get();

      final schedules = querySnapshot.docs
          .map((doc) => Schedule.fromFirestore(doc))
          .toList();

      monthlySchedules.value = schedules;

      salaryData.value = SalaryCalculator.calculateMonthlySalary(
        schedules: schedules,
        hourlyWage: latestEmployee.hourlyWage.toDouble(),
      );

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

    return monthlySchedules.where((schedule) {
      final scheduleDate = DateTime(
        schedule.date.year,
        schedule.date.month,
        schedule.date.day,
      );
      return scheduleDate.isAtSameMomentAs(targetDate);
    }).toList();
  }

  int getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  int getFirstDayOfWeek(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    return firstDay.weekday;
  }

  void selectDay(int day) {
    selectedDay.value = day;
  }
}