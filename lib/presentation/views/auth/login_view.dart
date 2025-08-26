import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 앱 로고/제목
                  const Icon(
                    Icons.work,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Albam',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '아르바이트 관리 서비스',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // 로그인/회원가입 폼
                  Form(
                    key: controller.formKey,
                    child: Column(
                      children: [
                        // 로그인/회원가입 토글
                        Obx(() => Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (!controller.isLoginMode.value) {
                                      controller.toggleMode();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: controller.isLoginMode.value
                                          ? Colors.blue
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Text(
                                      '로그인',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: controller.isLoginMode.value
                                            ? Colors.white
                                            : Colors.grey[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (controller.isLoginMode.value) {
                                      controller.toggleMode();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: !controller.isLoginMode.value
                                          ? Colors.blue
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Text(
                                      '회원가입',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: !controller.isLoginMode.value
                                            ? Colors.white
                                            : Colors.grey[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                        const SizedBox(height: 32),

                        // 이메일 입력
                        TextFormField(
                          controller: controller.emailController,
                          decoration: const InputDecoration(
                            labelText: '이메일',
                            hintText: 'example@email.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: controller.validateEmail,
                        ),
                        const SizedBox(height: 16),

                        // 비밀번호 입력
                        Obx(() => TextFormField(
                          controller: controller.passwordController,
                          decoration: InputDecoration(
                            labelText: '비밀번호',
                            hintText: '6자 이상 입력해주세요',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                controller.isPasswordVisible.value
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: controller.togglePasswordVisibility,
                            ),
                          ),
                          obscureText: !controller.isPasswordVisible.value,
                          validator: controller.validatePassword,
                        )),

                        // 비밀번호 확인 (회원가입 모드일 때만)
                        Obx(() => controller.isLoginMode.value
                            ? const SizedBox.shrink()
                            : Column(
                          children: [
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: controller.confirmPasswordController,
                              decoration: const InputDecoration(
                                labelText: '비밀번호 확인',
                                hintText: '비밀번호를 다시 입력해주세요',
                                prefixIcon: Icon(Icons.lock_outlined),
                              ),
                              obscureText: !controller.isPasswordVisible.value,
                              validator: controller.validateConfirmPassword,
                            ),
                          ],
                        )),
                        const SizedBox(height: 24),

                        // 로그인/회원가입 버튼
                        Obx(() => SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: controller.isLoading.value
                                ? null
                                : controller.submit,
                            child: controller.isLoading.value
                                ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                                : Text(
                              controller.isLoginMode.value ? '로그인' : '회원가입',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )),

                        // 비밀번호 찾기 (로그인 모드일 때만)
                        Obx(() => controller.isLoginMode.value
                            ? Column(
                          children: [
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: controller.resetPassword,
                              child: const Text('비밀번호를 잊으셨나요?'),
                            ),
                          ],
                        )
                            : const SizedBox.shrink()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}