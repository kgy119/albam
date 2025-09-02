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
      print('사업장 목록 로드 시작'); // 디버깅용
      isLoading.value = true;

      final List<Workplace> loadedWorkplaces = await _workplaceService.getWorkplaces();
      workplaces.value = loadedWorkplaces;

      print('사업장 목록 로드 완료: ${workplaces.length}개'); // 디버깅용

      if (workplaces.isEmpty) {
        print('등록된 사업장이 없습니다.'); // 디버깅용
      }

    } catch (e) {
      print('사업장 목록 로드 실패: $e'); // 디버깅용
      Get.snackbar(
        '오류',
        e.toString(),
        duration: const Duration(seconds: 5), // 길게 표시하여 오류 내용 확인
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
}