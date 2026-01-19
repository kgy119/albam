import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import '../../../core/services/auth_service.dart';
import '../../../app/routes/app_routes.dart'; // ✅ 추가

class EmailVerificationGuideScreen extends StatefulWidget {
  final String email;

  const EmailVerificationGuideScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  State<EmailVerificationGuideScreen> createState() =>
      _EmailVerificationGuideScreenState();
}

class _EmailVerificationGuideScreenState
    extends State<EmailVerificationGuideScreen> {
  final AuthService _authService = Get.find<AuthService>();
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    // 인증 상태 변화 감지
    _authSubscription = _authService.currentUser.listen((user) {
      if (user != null && mounted) {
        // 인증 완료되어 로그인되면 홈으로 이동
        Get.offAllNamed(AppRoutes.home); // ✅ 수정
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이메일 인증'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        // ✅ 추가: SingleChildScrollView로 감싸기
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            // ✅ 추가: ConstrainedBox로 최소 높이 설정
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    kToolbarHeight -
                    48, // padding
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mark_email_unread_outlined,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    '인증 메일을 발송했습니다',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.email,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '안내사항',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildGuideItem('메일이 도착하기까지 수 분이 소요될 수 있습니다.'),
                        const SizedBox(height: 8),
                        _buildGuideItem('메일이 오지 않는다면 스팸메일함을 확인해주세요.'),
                        const SizedBox(height: 8),
                        _buildGuideItem('메일의 인증 링크를 클릭하면 가입이 완료됩니다.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32), // ✅ 수정: Spacer 제거, 고정 간격
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      // ✅ 수정: Get.offAllNamed 사용
                      onPressed: () => Get.offAllNamed(AppRoutes.login),
                      child: const Text(
                        '로그인 화면으로',
                        style: TextStyle(fontSize: 16),
                      ),
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

  Widget _buildGuideItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(fontSize: 16)),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}