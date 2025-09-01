import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/auth_service.dart';
import '../../app/routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  // 로딩 상태
  RxBool isGoogleLoading = false.obs;
  RxBool isKakaoLoading = false.obs;

  @override
  void onReady() {
    super.onReady();
    // onReady에서 안전하게 초기 상태 확인
    _setupAuthStateListener();
  }

  /// 인증 상태 리스너 설정
  void _setupAuthStateListener() {
    // 빌드가 완료된 후 실행되도록 약간의 딜레이
    Future.delayed(const Duration(milliseconds: 100), () {
      _checkInitialAuthState();
    });

    // AuthService의 상태 변화를 감시
    ever(_authService.currentUser, (user) {
      if (user != null) {
        // 로그인된 경우, 약간의 딜레이 후 네비게이션 실행
        Future.delayed(const Duration(milliseconds: 100), () {
          _navigateToHome();
        });
      }
    });
  }

  /// 초기 인증 상태 확인
  void _checkInitialAuthState() {
    if (_authService.currentUser.value != null) {
      _navigateToHome();
    }
  }

  /// 홈 화면으로 안전하게 이동
  void _navigateToHome() {
    // 현재 라우트가 로그인 화면인 경우에만 이동
    if (Get.currentRoute == AppRoutes.login) {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  /// Google 로그인
  Future<void> signInWithGoogle() async {
    if (isGoogleLoading.value || isKakaoLoading.value) return;

    try {
      isGoogleLoading.value = true;

      final result = await _authService.signInWithGoogle();

      if (result != null) {
        Get.snackbar('성공', 'Google 로그인이 완료되었습니다.');
        // AuthService의 상태 변화를 통해 자동으로 홈으로 이동됨
      }
    } catch (e) {
      Get.snackbar('오류', 'Google 로그인 중 오류가 발생했습니다.');
      print('Google 로그인 오류: $e');
    } finally {
      isGoogleLoading.value = false;
    }
  }

  /// 카카오 로그인
  Future<void> signInWithKakao() async {
    if (isKakaoLoading.value || isGoogleLoading.value) return;

    try {
      isKakaoLoading.value = true;

      final result = await _authService.signInWithKakao();

      if (result != null) {
        Get.snackbar('성공', '카카오 로그인이 완료되었습니다.');
        // AuthService의 상태 변화를 통해 자동으로 홈으로 이동됨
      }
    } catch (e) {
      Get.snackbar('오류', '카카오 로그인 중 오류가 발생했습니다.');
      print('카카오 로그인 오류: $e');
    } finally {
      isKakaoLoading.value = false;
    }
  }
}