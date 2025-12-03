import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/auth_service.dart';
import '../../app/routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  RxBool isGoogleLoading = false.obs;

  @override
  void onReady() {
    super.onReady();
    _setupAuthStateListener();
  }

  void _setupAuthStateListener() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _checkInitialAuthState();
    });

    ever(_authService.currentUser, (user) {
      if (user != null) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _navigateToHome();
        });
      }
    });
  }

  void _checkInitialAuthState() {
    if (_authService.currentUser.value != null) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    if (Get.currentRoute == AppRoutes.login) {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  /// Google 로그인
  Future<void> signInWithGoogle() async {
    if (isGoogleLoading.value) return;

    try {
      isGoogleLoading.value = true;

      final result = await _authService.signInWithGoogle();

      if (result != null) {
        Get.snackbar('성공', 'Google 로그인이 완료되었습니다.');
      }
    } catch (e) {
      Get.snackbar('오류', 'Google 로그인 중 오류가 발생했습니다.');
      print('Google 로그인 오류: $e');
    } finally {
      isGoogleLoading.value = false;
    }
  }
}