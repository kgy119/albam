import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/workplace_model.dart';
import '../../data/models/employee_model.dart';
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

  @override
  void onInit() {
    super.onInit();
    workplace = Get.arguments as Workplace;
    loadEmployees();
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
      // 오류가 발생해도 빈 배열로 초기화
      employees.value = [];
      // 오류 메시지는 표시하지 않음 (처음에는 직원이 없는 것이 정상)
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

      await loadEmployees();
      Get.snackbar('성공', '직원이 추가되었습니다.');
      return true;
    } catch (e) {
      print('직원 추가 오류: $e');
      Get.snackbar('오류', '직원 추가에 실패했습니다.');
      return false;
    }
  }

  /// 직원 삭제
  Future<bool> deleteEmployee(String employeeId) async {
    try {
      await _firestore
          .collection(AppConstants.employeesCollection)
          .doc(employeeId)
          .delete();

      await loadEmployees();
      Get.snackbar('성공', '직원이 삭제되었습니다.');
      return true;
    } catch (e) {
      print('직원 삭제 오류: $e');
      Get.snackbar('오류', '직원 삭제에 실패했습니다.');
      return false;
    }
  }

  /// 월 변경
  void changeMonth(int year, int month) {
    selectedDate.value = DateTime(year, month, 1);
    selectedDay.value = 0;
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
}