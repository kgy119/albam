import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/account_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../app/routes/app_routes.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/utils/snackbar_helper.dart';

class AccountSettingsView extends StatefulWidget {
  const AccountSettingsView({super.key});

  @override
  State<AccountSettingsView> createState() => _AccountSettingsViewState();
}

class _AccountSettingsViewState extends State<AccountSettingsView> {
  String appVersion = '로딩 중...';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    } catch (e) {
      setState(() {
        appVersion = '1.0.0';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountService = AccountService();
    final authService = Get.find<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        children: [
          // 📱 계정 정보 섹션
          _buildSectionHeader('계정 정보'),
          _buildAccountInfoCard(authService),

          const SizedBox(height: 16),

          // 📋 앱 정보 섹션
          _buildSectionHeader('앱 정보'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('버전 정보'),
                  trailing: Text(
                    appVersion,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('이용약관'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    // TODO: 이용약관 페이지로 이동
                    SnackbarHelper.showInfo('이용약관 페이지를 준비중입니다.', title: '준비중');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('개인정보처리방침'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    // TODO: 개인정보처리방침 페이지로 이동
                    SnackbarHelper.showInfo('개인정보처리방침 페이지를 준비중입니다.', title: '준비중');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // 🚪 로그아웃
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutDialog(context, authService),
              icon: const Icon(Icons.logout),
              label: const Text('로그아웃'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey[400]!),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ⚠️ 회원탈퇴
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () => _showDeleteAccountDialog(context, accountService),
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text(
                '회원탈퇴',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildAccountInfoCard(AuthService authService) {
    final user = authService.currentUser.value;
    final email = user?.email ?? '이메일 없음';
    final userId = user?.id ?? 'ID 없음';

    // 로그인 방법 확인
    String loginMethod = '이메일';
    if (user?.appMetadata['provider'] == 'google') {
      loginMethod = 'Google';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow('이메일', email),
            const Divider(height: 24),
            _buildInfoRow('로그인 방법', loginMethod),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('로그아웃 하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                // 로딩 표시
                Get.dialog(
                  const Center(child: CircularProgressIndicator()),
                  barrierDismissible: false,
                );

                await Future.delayed(const Duration(milliseconds: 200));
                await authService.signOut();

                Get.back(); // 로딩 닫기
                Get.offAllNamed(AppRoutes.login);
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(
      BuildContext context,
      AccountService accountService,
      ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _DeleteAccountDialog(accountService: accountService);
      },
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  final AccountService accountService;

  const _DeleteAccountDialog({required this.accountService});

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  late TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('회원탈퇴'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '탈퇴 시 다음 데이터가 즉시 완전히 삭제됩니다:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWarningItem('모든 사업장 정보'),
                  _buildWarningItem('직원 정보 및 근로계약서'),
                  _buildWarningItem('근무 기록 및 급여 데이터'),
                  _buildWarningItem('계정 정보'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: '탈퇴 사유 (선택)',
                hintText: '예: 더 이상 서비스를 이용하지 않습니다',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, size: 20, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '삭제된 데이터는 복구할 수 없습니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () => _handleDeleteAccount(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('탈퇴'),
        ),
      ],
    );
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final reason = _reasonController.text.trim();

    Navigator.of(context).pop();

    // 로딩 표시
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    await Future.delayed(const Duration(milliseconds: 300));

    final result = await widget.accountService.requestAccountDeletion(
      reason: reason.isEmpty ? null : reason,
    );

    Get.back(); // 로딩 닫기

    if (result['success']) {
      Get.offAllNamed(AppRoutes.login);

      SnackbarHelper.showSuccess(
        '회원탈퇴가 완료되었습니다.\n그동안 이용해주셔서 감사합니다.',
        title: '탈퇴 완료',
      );
    } else {
      SnackbarHelper.showError(result['error']);
    }
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.circle, size: 6, color: Colors.red[700]),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }
}