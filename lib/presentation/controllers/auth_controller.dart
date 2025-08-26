import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/auth_service.dart';
import '../../app/routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  // 로딩 상태
  RxBool isLoading = false.obs;

  // 로그인/회원가입 모드
  RxBool isLoginMode = true.obs;

  // 비밀번호 표시/숨김
  RxBool isPasswordVisible = false.obs;

  // 폼 컨트롤러들
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // 폼 키
  final formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    // 이미 로그인된 상태라면 홈으로 이동
    if (_authService.isLoggedIn.value) {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  /// 로그인/회원가입 모드 토글
  void toggleMode() {
    isLoginMode.value = !isLoginMode.value;
    confirmPasswordController.clear();
  }

  /// 비밀번호 표시/숨김 토글
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  /// 이메일 유효성 검사
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '이메일을 입력해주세요';
    }
    if (!GetUtils.isEmail(value)) {
      return '올바른 이메일 형식을 입력해주세요';
    }
    return null;
  }

  /// 비밀번호 유효성 검사
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요';
    }
    if (value.length < 6) {
      return '비밀번호는 6자 이상이어야 합니다';
    }
    return null;
  }

  /// 비밀번호 확인 유효성 검사
  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호 확인을 입력해주세요';
    }
    if (value != passwordController.text) {
      return '비밀번호가 일치하지 않습니다';
    }
    return null;
  }

  /// 로그인 처리
  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;

    final result = await _authService.signInWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text,
    );

    if (result != null) {
      Get.offAllNamed(AppRoutes.home);
    }

    isLoading.value = false;
  }

  /// 회원가입 처리
  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;

    final result = await _authService.registerWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text,
    );

    if (result != null) {
      Get.snackbar('성공', '회원가입이 완료되었습니다.');
      Get.offAllNamed(AppRoutes.home);
    }

    isLoading.value = false;
  }

  /// 비밀번호 재설정
  Future<void> resetPassword() async {
    if (emailController.text.trim().isEmpty) {
      Get.snackbar('알림', '이메일을 입력해주세요.');
      return;
    }

    await _authService.sendPasswordResetEmail(emailController.text.trim());
  }

  /// 로그인/회원가입 실행
  Future<void> submit() async {
    if (isLoginMode.value) {
      await login();
    } else {
      await register();
    }
  }
}