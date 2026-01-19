import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/snackbar_helper.dart';

class EmailVerificationPendingScreen extends StatefulWidget {
  final String email;

  const EmailVerificationPendingScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  State<EmailVerificationPendingScreen> createState() =>
      _EmailVerificationPendingScreenState();
}

class _EmailVerificationPendingScreenState
    extends State<EmailVerificationPendingScreen> {
  final AuthService _authService = Get.find<AuthService>();
  bool _isResending = false;
  bool _hasResent = false;
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


  Future<void> _resendVerificationEmail() async {
    if (_isResending || _hasResent) return;

    setState(() {
      _isResending = true;
    });

    try {
      final result = await _authService.resendVerificationEmail(widget.email);

      if (result['success'] == true) {
        setState(() {
          _hasResent = true;
        });
        SnackbarHelper.showSuccess('인증 메일이 재전송되었습니다.');
      } else {
        SnackbarHelper.showError(
            result['error'] ?? '메일 재전송에 실패했습니다.');
      }
    } catch (e) {
      SnackbarHelper.showError('오류가 발생했습니다: ${e.toString()}');
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이메일 인증 필요'),
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
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
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    '이메일 인증이 필요합니다',
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
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '인증 전입니다',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '로그인하려면 먼저 이메일 인증을 완료해주세요.',
                          style: TextStyle(fontSize: 14, height: 1.5),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• 메일함에서 인증 메일을 확인해주세요.\n'
                              '• 스팸메일함도 확인해보세요.\n'
                              '• 메일의 인증 링크를 클릭하세요.',
                          style: TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!_hasResent)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _isResending ? null : _resendVerificationEmail,
                        icon: _isResending
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Icon(Icons.refresh),
                        label: Text(
                          _isResending ? '전송 중...' : '인증 메일 재전송',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              '인증 메일이 재전송되었습니다.',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
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
}