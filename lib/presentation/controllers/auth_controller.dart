import 'package:get/get.dart';
import '../../core/services/auth_service.dart';
import '../../app/routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  // 로딩 상태
  RxBool isGoogleLoading = false.obs;
  RxBool isKakaoLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // 이미 로그인된 상태라면 홈으로 이동
    if (_authService.isLoggedIn.value) {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  /// Google 로그인
  Future<void> signInWithGoogle() async {
    isGoogleLoading.value = true;

    final result = await _authService.signInWithGoogle();

    if (result != null) {
      Get.snackbar('성공', 'Google 로그인이 완료되었습니다.');
      Get.offAllNamed(AppRoutes.home);
    }

    isGoogleLoading.value = false;
  }

  /// 카카오 로그인
  Future<void> signInWithKakao() async {
    isKakaoLoading.value = true;

    final result = await _authService.signInWithKakao();

    if (result != null) {
      Get.snackbar('성공', '카카오 로그인이 완료되었습니다.');
      Get.offAllNamed(AppRoutes.home);
    }

    isKakaoLoading.value = false;
  }
}