import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../data/models/workplace_model.dart';
import '../../core/services/workplace_service.dart';

class WorkplaceController extends GetxController {
  late final WorkplaceService _workplaceService;

  // 사업장 목록
  RxList<Workplace> workplaces = <Workplace>[].obs;

  // 로딩 상태
  RxBool isLoading = false.obs;
  RxBool isAdding = false.obs;

  @override
  void onInit() {
    super.onInit();

    // WorkplaceService 의존성 확인
    try {
      _workplaceService = Get.find<WorkplaceService>();
      print('WorkplaceService 찾음'); // 디버깅용
    } catch (e) {
      print('WorkplaceService를 찾을 수 없음: $e'); // 디버깅용
      Get.snackbar('오류', 'WorkplaceService 초기화 실패');
      return;
    }

    // 약간의 딜레이 후 사업장 목록 로드 (AuthService 완전 초기화 대기)
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

      // 직원 수도 함께 로드
      await loadAllEmployeeCounts();

      if (workplaces.isEmpty) {
        print('등록된 사업장이 없습니다.');
      }

    } catch (e) {
      print('사업장 목록 로드 실패: $e');
      Get.snackbar(
        '오류',
        e.toString(),
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 사업장 추가
  Future<void> addWorkplace(String name) async {
    try {
      isAdding.value = true;
      await _workplaceService.addWorkplace(name);

      // 추가 후 약간의 딜레이를 두고 새로고침
      await Future.delayed(const Duration(milliseconds: 500));
      await loadWorkplaces(); // 목록 새로고침

      Get.snackbar('성공', '사업장이 추가되었습니다.');
    } catch (e) {
      Get.snackbar('오류', e.toString());
    } finally {
      isAdding.value = false;
    }
  }

  /// 사업장 삭제
  Future<void> deleteWorkplace(String workplaceId) async {
    try {
      await _workplaceService.deleteWorkplace(workplaceId);
      await loadWorkplaces(); // 목록 새로고침
      Get.snackbar('성공', '사업장이 삭제되었습니다.');
    } catch (e) {
      Get.snackbar('오류', e.toString());
    }
  }

  /// 사업장 이름 수정
  Future<void> updateWorkplaceName(String workplaceId, String newName) async {
    try {
      await _workplaceService.updateWorkplace(workplaceId, newName);
      await loadWorkplaces(); // 목록 새로고침
      Get.snackbar('성공', '사업장 정보가 수정되었습니다.');
    } catch (e) {
      Get.snackbar('오류', e.toString());
    }
  }

  // 사업장별 직원 수 저장
  RxMap<String, int> employeeCountMap = <String, int>{}.obs;

  /// 모든 사업장의 직원 수 조회
  Future<void> loadAllEmployeeCounts() async {
    try {
      for (var workplace in workplaces) {
        final count = await _getEmployeeCount(workplace.id);
        employeeCountMap[workplace.id] = count;
      }
    } catch (e) {
      print('직원 수 조회 오류: $e');
    }
  }

  /// 특정 사업장의 직원 수 조회
  Future<int> _getEmployeeCount(String workplaceId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('employees')
          .where('workplaceId', isEqualTo: workplaceId)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('사업장 $workplaceId 직원 수 조회 오류: $e');
      return 0;
    }
  }

  /// 특정 사업장의 직원 수 반환
  int getEmployeeCount(String workplaceId) {
    return employeeCountMap[workplaceId] ?? 0;
  }
}