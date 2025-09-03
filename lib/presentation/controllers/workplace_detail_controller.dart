import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  void onInit() {
    super.onInit();
    workplace = Get.arguments as Workplace;
    loadEmployees();
    loadMonthlySchedules();
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
      Get.snackbar(
        '오류',
        '직원 등록에 실패했습니다. 다시 시도해주세요.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
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
  }) async {
    try {
      print('직원 수정 시작: $name');

      final updateData = {
        'name': name,
        'phoneNumber': phoneNumber,
        'hourlyWage': hourlyWage,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      // contractImageUrl이 변경된 경우만 업데이트
      if (contractImageUrl != null) {
        updateData['contractImageUrl'] = contractImageUrl;
      }

      await _firestore
          .collection(AppConstants.employeesCollection)
          .doc(employeeId)
          .update(updateData);

      print('직원 정보 수정 완료');

      // 직원 목록 새로고침
      await loadEmployees();

      Get.snackbar(
        '성공',
        '직원 정보가 수정되었습니다.',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      print('직원 수정 오류: $e');
      Get.snackbar(
        '오류',
        '직원 정보 수정에 실패했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    }
  }

  /// 직원 삭제
  Future<bool> deleteEmployee(String employeeId) async {
    try {
      // 관련 스케줄도 함께 삭제
      final schedulesQuery = await _firestore
          .collection(AppConstants.schedulesCollection)
          .where('employeeId', isEqualTo: employeeId)
          .get();

      final batch = _firestore.batch();

      // 스케줄 삭제
      for (var doc in schedulesQuery.docs) {
        batch.delete(doc.reference);
      }

      // 직원 삭제
      batch.delete(
        _firestore.collection(AppConstants.employeesCollection).doc(employeeId),
      );

      await batch.commit();

      await loadEmployees();
      Get.snackbar('성공', '직원이 삭제되었습니다.');
      return true;
    } catch (e) {
      print('직원 삭제 오류: $e');
      Get.snackbar('오류', '직원 삭제에 실패했습니다.');
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
    } catch (e) {
      print('월별 스케줄 로드 오류: $e');
      monthlySchedules.value = [];
    }
  }

  /// 특정 날짜의 총 근무시간 계산
  double getDayTotalHours(int day) {
    final targetDate = DateTime(selectedDate.value.year, selectedDate.value.month, day);

    double totalHours = 0;
    for (var schedule in monthlySchedules) {
      if (schedule.date.year == targetDate.year &&
          schedule.date.month == targetDate.month &&
          schedule.date.day == targetDate.day) {
        totalHours += schedule.totalMinutes / 60.0;
      }
    }

    return totalHours;
  }

  /// 월 변경
  void changeMonth(int year, int month) {
    selectedDate.value = DateTime(year, month, 1);
    selectedDay.value = 0;
    loadMonthlySchedules(); // 월 변경 시 스케줄 다시 로드
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
    return firstDay.weekday;
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
}