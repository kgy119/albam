import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/salary_calculator.dart';
import '../../data/models/workplace_model.dart';
import '../../data/models/employee_model.dart';
import '../../data/models/schedule_model.dart';
import '../../core/constants/app_constants.dart';

class WorkplaceDetailController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

    // 월 변경시 스케줄 다시 로드되도록 리스너 추가
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

      final querySnapshot = await _firestore
          .collection(AppConstants.employeesCollection)
          .where('workplaceId', isEqualTo: workplace.id)
          .get();

      print('조회된 직원 수: ${querySnapshot.docs.length}');

      employees.value = querySnapshot.docs
          .map((doc) => Employee.fromFirestore(doc))
          .toList();

      print('직원 목록 로드 완료');
    } catch (e) {
      print('직원 목록 로드 오류: $e');
      employees.value = [];
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

      final now = DateTime.now();
      final employeeData = {
        'workplaceId': workplace.id,
        'name': name,
        'phoneNumber': phoneNumber,
        'hourlyWage': hourlyWage,
        'contractImageUrl': contractImageUrl,
        'bankName': bankName,
        'accountNumber': accountNumber,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      await _firestore
          .collection(AppConstants.employeesCollection)
          .add(employeeData);

      print('Firestore 저장 완료');

      // 직원 목록 새로고침
      await loadEmployees();

      print('직원 목록 새로고침 완료');

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

      final updateData = <String, dynamic>{
        'name': name,
        'phoneNumber': phoneNumber,
        'hourlyWage': hourlyWage,
        'bankName': bankName,
        'accountNumber': accountNumber,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      // ⭐ contractImageUrl을 항상 업데이트 (null 포함)
      updateData['contractImageUrl'] = contractImageUrl;

      await _firestore
          .collection(AppConstants.employeesCollection)
          .doc(employeeId)
          .update(updateData);

      print('직원 정보 수정 완료');

      // 직원 목록 새로고침
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
    // 숫자만 추출
    String numbers = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (numbers.length == 11) {
      // 010-1234-5678 형태로 포맷팅
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
      final employeeDoc = await _firestore
          .collection(AppConstants.employeesCollection)
          .doc(employeeId)
          .get();

      if (employeeDoc.exists) {
        final employeeData = employeeDoc.data() as Map<String, dynamic>;
        final contractImageUrl = employeeData['contractImageUrl'] as String?;

        // 2. 근로계약서 이미지 삭제
        if (contractImageUrl != null && contractImageUrl.isNotEmpty) {
          try {
            final ref = FirebaseStorage.instance.refFromURL(contractImageUrl);
            await ref.delete();
            print('근로계약서 이미지 삭제 완료');
          } catch (e) {
            print('이미지 삭제 오류 (무시): $e');
          }
        }
      }

      // 3. 관련 스케줄 삭제
      final schedulesQuery = await _firestore
          .collection(AppConstants.schedulesCollection)
          .where('employeeId', isEqualTo: employeeId)
          .get();

      final batch = _firestore.batch();

      for (var doc in schedulesQuery.docs) {
        batch.delete(doc.reference);
      }

      // 4. 직원 정보 삭제
      batch.delete(
        _firestore.collection(AppConstants.employeesCollection).doc(employeeId),
      );

      await batch.commit();

      await loadEmployees();

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
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 1);

      final querySnapshot = await _firestore
          .collection(AppConstants.schedulesCollection)
          .where('workplaceId', isEqualTo: workplace.id)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
          .orderBy('date')
          .get();

      monthlySchedules.value = querySnapshot.docs
          .map((doc) => Schedule.fromFirestore(doc))
          .toList();

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

      // 직원별 급여 계산
      List<Map<String, dynamic>> employeeSalaries = [];

      for (var employee in employees) {
        // 해당 직원의 이번 달 스케줄 필터링
        final employeeSchedules = monthlySchedules
            .where((schedule) => schedule.employeeId == employee.id)
            .toList();

        if (employeeSchedules.isEmpty) continue;

        // 급여 계산
        final salaryData = SalaryCalculator.calculateMonthlySalary(
          schedules: employeeSchedules,
          hourlyWage: employee.hourlyWage.toDouble(),
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
          schedule.date.day
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
          schedule.date.day
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
      final doc = await _firestore
          .collection(AppConstants.employeesCollection)
          .doc(employeeId)
          .get();

      if (doc.exists) {
        return Employee.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('최신 직원 정보 조회 오류: $e');
      return null;
    }
  }
}