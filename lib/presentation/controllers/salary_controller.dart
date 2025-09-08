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

  @override
  void onInit() {
    super.onInit();

    // Get.arguments로 전달받은 데이터 자동 처리
    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      final employee = arguments['employee'];
      final year = arguments['year'];
      final month = arguments['month'];

      if (employee != null && year != null && month != null) {
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
      // 해당 월의 스케줄 조회
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 1);

      final querySnapshot = await _firestore
          .collection(AppConstants.schedulesCollection)
          .where('employeeId', isEqualTo: employee.id)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
          .orderBy('date')
          .get();

      final schedules = querySnapshot.docs
          .map((doc) => Schedule.fromFirestore(doc))
          .toList();

      // 급여 계산
      salaryData.value = SalaryCalculator.calculateMonthlySalary(
        schedules: schedules,
        hourlyWage: employee.hourlyWage.toDouble(),
      );

    } catch (e) {
      print('급여 계산 오류: $e');
      Get.snackbar('오류', '급여 계산 중 문제가 발생했습니다.');
    } finally {
      isLoading.value = false;
    }
  }
}