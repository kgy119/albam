import 'package:get/get.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/workplace_model.dart';
import '../../core/services/workplace_service.dart';
import '../../core/services/employee_service.dart';

class WorkplaceController extends GetxController {
  late final WorkplaceService _workplaceService;
  late final EmployeeService _employeeService;

  // 사업장 목록
  RxList<Workplace> workplaces = <Workplace>[].obs;

  // 로딩 상태
  RxBool isLoading = false.obs;
  RxBool isAdding = false.obs;

  @override
  void onInit() {
    super.onInit();

    // 서비스 의존성 확인
    try {
      _workplaceService = Get.find<WorkplaceService>();
      _employeeService = EmployeeService(); // 신규 생성
      print('WorkplaceService 찾음');
    } catch (e) {
      print('WorkplaceService를 찾을 수 없음: $e');
      return;
    }

    // 약간의 딜레이 후 사업장 목록 로드
    Future.delayed(const Duration(milliseconds: 500), () {
      loadWorkplaces();
    });
  }

  /// 사업장 목록 로드
  Future<void> loadWorkplaces() async {
    try {
      print('사업장 목록 로드 시작');
      isLoading.value = true;

      final List<Workplace> loadedWorkplaces = await _workplaceService.getWorkplaces();
      workplaces.value = loadedWorkplaces;

      print('사업장 목록 로드 완료: ${workplaces.length}개');

      await loadAllEmployeeCounts();

      if (workplaces.isEmpty) {
        print('등록된 사업장이 없습니다.');
      }
    } catch (e) {
      print('사업장 목록 로드 실패: $e');
      SnackbarHelper.showError(e.toString()); // 수정
    } finally {
      isLoading.value = false;
    }
  }


  Future<void> addWorkplace(String name) async {
    try {
      isAdding.value = true;

      final newWorkplace = await _workplaceService.addWorkplace(name);

      workplaces.insert(0, newWorkplace);

      SnackbarHelper.showSuccess('사업장이 추가되었습니다.'); // 수정
    } catch (e) {
      print('사업장 추가 오류: $e');
      SnackbarHelper.showError(e.toString()); // 수정
    } finally {
      isAdding.value = false;
    }
  }

  /// 사업장 삭제
  Future<void> deleteWorkplace(String workplaceId) async {
    try {
      await _workplaceService.deleteWorkplace(workplaceId);

      workplaces.removeWhere((w) => w.id == workplaceId);

      SnackbarHelper.showSuccess('사업장이 삭제되었습니다.'); // 수정
    } catch (e) {
      print('사업장 삭제 오류: $e');
      SnackbarHelper.showError(e.toString()); // 수정
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

      SnackbarHelper.showSuccess('사업장 정보가 수정되었습니다.'); // 수정
    } catch (e) {
      print('사업장 수정 오류: $e');
      SnackbarHelper.showError(e.toString()); // 수정
    }
  }

  // 사업장별 직원 수 저장
  RxMap<String, int> employeeCountMap = <String, int>{}.obs;

  /// 모든 사업장의 직원 수 조회
  Future<void> loadAllEmployeeCounts() async {
    try {
      for (var workplace in workplaces) {
        final count = await _employeeService.getEmployeeCount(workplace.id);
        employeeCountMap[workplace.id] = count;
      }
    } catch (e) {
      print('직원 수 조회 오류: $e');
    }
  }

  /// 특정 사업장의 직원 수 반환
  int getEmployeeCount(String workplaceId) {
    return employeeCountMap[workplaceId] ?? 0;
  }
}