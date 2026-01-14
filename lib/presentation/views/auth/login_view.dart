// lib/presentation/views/auth/login_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 앱 로고
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.work_rounded,
                          size: 60,
                          color: Theme.of(context).primaryColor,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 앱 이름
                Text(
                  '알바관리',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '아르바이트 관리 서비스',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),

                // 모드 안내 텍스트
                Obx(() {
                  final isReset = controller.isResetMode.value;

                  if (isReset) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        '비밀번호 재설정 링크를 받을\n이메일을 입력해주세요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),

                // 이메일 입력
                TextField(
                  controller: controller.emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: '이메일',
                    prefixIcon: const Icon(Icons.email),
                    border: const OutlineInputBorder(),
                    errorText: _getEmailError(),
                  ),
                ),
                const SizedBox(height: 16),

                // 비밀번호 입력 (비밀번호 찾기 모드가 아닐 때)
                Obx(() {
                  final isReset = controller.isResetMode.value;
                  if (isReset) return const SizedBox.shrink();

                  return TextField(
                    controller: controller.passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      errorText: _getPasswordError(),
                    ),
                  );
                }),

                // 비밀번호 확인 (회원가입 모드)
                Obx(() {
                  final isSignUp = controller.isSignUpMode.value;
                  final isReset = controller.isResetMode.value;

                  if (!isSignUp || isReset) return const SizedBox.shrink();

                  return Column(
                    children: [
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller.passwordConfirmController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: '비밀번호 확인',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          errorText: _getPasswordConfirmError(),
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 8),

                // 비밀번호 찾기 버튼 (로그인 모드일 때)
                Obx(() {
                  final isSignUp = controller.isSignUpMode.value;
                  final isReset = controller.isResetMode.value;

                  if (isSignUp || isReset) return const SizedBox.shrink();

                  return Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: controller.toggleResetMode,
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                      child: const Text(
                        '비밀번호를 잊으셨나요?',
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),

                // 에러/성공 메시지 표시
                // 에러/성공 메시지 표시
                Obx(() {
                  final error = controller.errorMessage.value;
                  final success = controller.successMessage.value;

                  if (error.isEmpty && success.isEmpty) {
                    return const SizedBox(height: 8);
                  }

                  return Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16), // ✅ 패딩 증가
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: error.isNotEmpty
                              ? Colors.red.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12), // ✅ 라운드 증가
                          border: Border.all(
                            color: error.isNotEmpty ? Colors.red : Colors.green,
                            width: 2, // ✅ 테두리 두께 증가
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start, // ✅ 변경
                          children: [
                            Icon(
                              error.isNotEmpty ? Icons.error_outline : Icons.mark_email_read, // ✅ 아이콘 변경
                              color: error.isNotEmpty ? Colors.red : Colors.green,
                              size: 24, // ✅ 아이콘 크기 증가
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                error.isNotEmpty ? error : success,
                                style: TextStyle(
                                  color: error.isNotEmpty ? Colors.red[700] : Colors.green[700],
                                  fontSize: 14, // ✅ 폰트 크기 증가
                                  height: 1.5, // ✅ 줄간격
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 회원가입 안내 (로그인 실패 시)
                      if (error.isNotEmpty && !controller.isSignUpMode.value && !controller.isResetMode.value)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue[700],
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '아직 회원이 아니신가요? 아래에서 회원가입을 진행해주세요.',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                }),


                // 로그인/회원가입/재설정 버튼
                Obx(() {
                  final isLoading = controller.isEmailLoading.value;
                  final canSubmit = controller.canSubmit;
                  final isSignUp = controller.isSignUpMode.value;
                  final isReset = controller.isResetMode.value;
                  final isEmailValid = controller.isEmailValid.value;

                  String buttonText;
                  VoidCallback? onPressed;

                  if (isReset) {
                    buttonText = '재설정 이메일 전송';
                    onPressed = isLoading || !isEmailValid
                        ? null
                        : controller.sendPasswordResetEmail;
                  } else if (isSignUp) {
                    buttonText = '회원가입';
                    onPressed = isLoading || !canSubmit
                        ? null
                        : controller.signUpWithEmail;
                  } else {
                    buttonText = '로그인';
                    onPressed = isLoading || !canSubmit
                        ? null
                        : controller.signInWithEmail;
                  }

                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: onPressed,
                      child: isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Text(
                        buttonText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // 회원가입/로그인 전환
                Obx(() {
                  final isSignUp = controller.isSignUpMode.value;
                  final isReset = controller.isResetMode.value;

                  if (isReset) {
                    return TextButton(
                      onPressed: controller.toggleResetMode,
                      child: Text(
                        '로그인으로 돌아가기',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    );
                  }

                  return TextButton(
                    onPressed: controller.toggleSignUpMode,
                    child: Text(
                      isSignUp
                          ? '이미 계정이 있으신가요? 로그인'
                          : '계정이 없으신가요? 회원가입',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 18),

                // 구분선 (비밀번호 찾기 모드가 아닐 때만)
                Obx(() {
                  final isReset = controller.isResetMode.value;
                  if (isReset) return const SizedBox.shrink();

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[300])),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '또는',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey[300])),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                }),

                // Google 로그인 버튼 (비밀번호 찾기 모드가 아닐 때만)
                Obx(() {
                  final isReset = controller.isResetMode.value;
                  if (isReset) return const SizedBox.shrink();

                  final isGoogleLoading = controller.isGoogleLoading.value;
                  final isAppleLoading = controller.isAppleLoading.value;

                  return Row(
                    children: [
                      // Google 로그인 버튼
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: isGoogleLoading || isAppleLoading
                                ? null
                                : controller.signInWithGoogle,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            child: isGoogleLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.grey,
                              ),
                            )
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/google_logo.png',
                                  height: 20,
                                  width: 20,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.g_mobiledata,
                                      size: 24,
                                      color: Colors.red,
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Google',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Apple 로그인 버튼
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: isGoogleLoading || isAppleLoading
                                ? null
                                : controller.signInWithApple,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey[300]!),
                              backgroundColor: Colors.white,
                            ),
                            child: isAppleLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                                : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.apple,
                                  color: Colors.black,
                                  size: 24,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Apple',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _getEmailError() {
    if (controller.emailController.text.isEmpty) return null;
    return controller.isEmailValid.value ? null : '올바른 이메일을 입력하세요';
  }

  String? _getPasswordError() {
    if (controller.passwordController.text.isEmpty) return null;
    return controller.isPasswordValid.value ? null : '비밀번호는 6자 이상이어야 합니다';
  }

  String? _getPasswordConfirmError() {
    if (controller.passwordConfirmController.text.isEmpty) return null;
    return controller.isPasswordConfirmValid.value ? null : '비밀번호가 일치하지 않습니다';
  }
}