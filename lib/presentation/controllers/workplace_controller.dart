import 'package:get/get.dart';

class WorkplaceController extends GetxController {
  // 사업장 목록
  RxList workplaces = [].obs;

  // 로딩 상태
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadWorkplaces();
  }

  /// 사업장 목록 로드
  Future<void> loadWorkplaces() async {
    isLoading.value = true;

    try {
      // TODO: Firebase에서 사업장 목록 가져오기
      await Future.delayed(const Duration(seconds: 1)); // 임시 딜레이

      // 임시 데이터 (다음 단계에서 실제 데이터로 교체)
      workplaces.clear();

    } catch (e) {
      Get.snackbar('오류', '사업장 목록을 불러오는데 실패했습니다.');
    } finally {
      isLoading.value = false;
    }
  }

  /// 사업장 추가
  Future<void> addWorkplace(String name) async {
    // TODO: 다음 단계에서 구현
    Get.snackbar('알림', '사업장 추가 기능은 다음 단계에서 구현됩니다.');
  }
}