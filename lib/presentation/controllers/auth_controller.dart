import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/auth_service.dart';
import '../../app/routes/app_routes.dart';
import '../../core/services/connectivity_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  // 로딩 상태
  RxBool isGoogleLoading = false.obs;
  RxBool isEmailLoading = false.obs;
  RxBool isAppleLoading = false.obs;

  // 이메일 폼 컨트롤러
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordConfirmController = TextEditingController();

  // 유효성 검사
  RxBool isEmailValid = false.obs;
  RxBool isPasswordValid = false.obs;
  RxBool isPasswordConfirmValid = false.obs;

  // 회원가입 모드
  RxBool isSignUpMode = false.obs;

  // 비밀번호 찾기 상태
  RxBool isResetMode = false.obs;

  // 에러 메시지
  RxString errorMessage = ''.obs;
  RxString successMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();

    // 이메일 유효성 검사
    emailController.addListener(() {
      isEmailValid.value = _validateEmail(emailController.text);
      if (errorMessage.value.isNotEmpty) {
        errorMessage.value = '';
      }
    });

    // 비밀번호 유효성 검사
    passwordController.addListener(() {
      isPasswordValid.value = _validatePassword(passwordController.text);
      if (isSignUpMode.value) {
        isPasswordConfirmValid.value =
            passwordController.text == passwordConfirmController.text &&
                passwordConfirmController.text.isNotEmpty;
      }
      if (errorMessage.value.isNotEmpty) {
        errorMessage.value = '';
      }
    });

    // 비밀번호 확인 유효성 검사
    passwordConfirmController.addListener(() {
      if (isSignUpMode.value) {
        isPasswordConfirmValid.value =
            passwordController.text == passwordConfirmController.text &&
                passwordConfirmController.text.isNotEmpty;
      }
      if (errorMessage.value.isNotEmpty) {
        errorMessage.value = '';
      }
    });
  }

  @override
  void onReady() {
    super.onReady();
    _setupAuthStateListener();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    passwordConfirmController.dispose();
    super.onClose();
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

  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email.trim());
  }

  bool _validatePassword(String password) {
    return password.length >= 6;
  }

  bool get canSubmit {
    if (isSignUpMode.value) {
      return isEmailValid.value &&
          isPasswordValid.value &&
          isPasswordConfirmValid.value;
    } else {
      return isEmailValid.value && isPasswordValid.value;
    }
  }

  void toggleSignUpMode() {
    isSignUpMode.value = !isSignUpMode.value;
    if (isSignUpMode.value) {
      isResetMode.value = false;
    }
    passwordConfirmController.clear();
    isPasswordConfirmValid.value = false;
    errorMessage.value = '';
    successMessage.value = '';
  }

  void toggleResetMode() {
    isResetMode.value = !isResetMode.value;
    if (isResetMode.value) {
      isSignUpMode.value = false;
    }
    passwordController.clear();
    passwordConfirmController.clear();
    isPasswordValid.value = false;
    isPasswordConfirmValid.value = false;
    errorMessage.value = '';
    successMessage.value = '';
  }

  /// 이메일 로그인
  Future<void> signInWithEmail() async {
    if (isEmailLoading.value || !canSubmit) return;

    // ✅ 인터넷 연결 확인
    final connectivityService = Get.find<ConnectivityService>();
    if (!connectivityService.isConnected.value) {
      errorMessage.value = '인터넷 연결이 필요합니다.';
      return;
    }

    try {
      isEmailLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      final result = await _authService.signInWithEmail(
        emailController.text.trim(),
        passwordController.text,
      );

      if (result['success'] == true) {
        successMessage.value = '로그인이 완료되었습니다.';
      } else if (result['error'] != null) {
        errorMessage.value = result['error'];
      }
    } finally {
      isEmailLoading.value = false;
    }
  }

  /// 이메일/비밀번호 회원가입
  Future<void> signUpWithEmail() async {
    if (isEmailLoading.value || !canSubmit) return;

    // ✅ 인터넷 연결 확인
    final connectivityService = Get.find<ConnectivityService>();
    if (!connectivityService.isConnected.value) {
      errorMessage.value = '인터넷 연결이 필요합니다.';
      return;
    }

    try {
      isEmailLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      final result = await _authService.signUpWithEmail(
        emailController.text.trim(),
        passwordController.text,
      );

      if (result['success'] == true) {
        // ✅ 이메일 인증 안내 메시지로 변경
        successMessage.value =
        '회원가입 신청이 완료되었습니다!\n\n'
            '${emailController.text.trim()} 으로 전송된\n'
            '인증 이메일을 확인하고 링크를 클릭하여\n'
            '이메일 인증을 완료해주세요.\n\n'
            '인증 후 로그인할 수 있습니다.';

        // 이메일 입력란 비우기
        emailController.clear();
        passwordController.clear();
        passwordConfirmController.clear();

        // 3초 후 로그인 모드로 전환
        Future.delayed(const Duration(seconds: 5), () {
          if (isSignUpMode.value) {
            toggleSignUpMode();
            successMessage.value = '';
          }
        });
      } else if (result['error'] != null) {
        errorMessage.value = result['error'];
      }
    } finally {
      isEmailLoading.value = false;
    }
  }

  /// 비밀번호 재설정 이메일 전송
  Future<void> sendPasswordResetEmail() async {
    if (!isEmailValid.value) {
      errorMessage.value = '올바른 이메일을 입력해주세요.';
      return;
    }

    try {
      isEmailLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      final result = await _authService.sendPasswordResetEmail(
        emailController.text.trim(),
      );

      if (result['success'] == true) {
        successMessage.value = '비밀번호 재설정 이메일이 전송되었습니다.\n이메일을 확인해주세요.';

        // 3초 후 로그인 화면으로 전환
        Future.delayed(const Duration(seconds: 3), () {
          isResetMode.value = false;
          successMessage.value = '';
        });
      } else if (result['error'] != null) {
        errorMessage.value = result['error'];
      }
    } finally {
      isEmailLoading.value = false;
    }
  }

  /// Google 로그인
  Future<void> signInWithGoogle() async {
    if (isGoogleLoading.value) return;

    // ✅ 인터넷 연결 확인
    final connectivityService = Get.find<ConnectivityService>();
    if (!connectivityService.isConnected.value) {
      errorMessage.value = '인터넷 연결이 필요합니다.';
      return;
    }

    try {
      isGoogleLoading.value = true;
      errorMessage.value = '';
      successMessage.value = ''; // ✅ 메시지 제거

      final result = await _authService.signInWithGoogle();

      if (result['success'] == true) {
        // ✅ 성공 메시지 제거 (자동으로 홈 화면으로 이동)
        // successMessage.value = 'Google 로그인이 완료되었습니다.';
      } else if (result['error'] != null) {
        errorMessage.value = result['error'];
      }
    } catch (e) {
      errorMessage.value = 'Google 로그인 중 오류가 발생했습니다.';
      print('Google 로그인 오류: $e');
    } finally {
      isGoogleLoading.value = false;
    }
  }

  /// Apple 로그인 추가
  Future<void> signInWithApple() async {
    if (isAppleLoading.value) return;

    final connectivityService = Get.find<ConnectivityService>();
    if (!connectivityService.isConnected.value) {
      errorMessage.value = '인터넷 연결이 필요합니다.';
      return;
    }

    try {
      isAppleLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      final result = await _authService.signInWithApple();

      if (result['success'] == true) {
        // 성공 시 자동으로 홈으로 이동
      } else if (result['error'] != null) {
        errorMessage.value = result['error'];
      }
    } catch (e) {
      errorMessage.value = 'Apple 로그인 중 오류가 발생했습니다.';
      print('Apple 로그인 오류: $e');
    } finally {
      isAppleLoading.value = false;
    }
  }
}