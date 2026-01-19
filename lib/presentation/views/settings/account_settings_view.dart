import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/account_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/services/subscription_limit_service.dart';
import '../../../app/routes/app_routes.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/utils/snackbar_helper.dart';

class AccountSettingsView extends StatefulWidget {
  const AccountSettingsView({super.key});

  @override
  State<AccountSettingsView> createState() => _AccountSettingsViewState();
}

class _AccountSettingsViewState extends State<AccountSettingsView> with WidgetsBindingObserver {
  String appVersion = '로딩 중...';

  late SubscriptionService subscriptionService;
  late SubscriptionLimitService limitService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initServices();
    _loadAppVersion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      print('📱 앱이 포어그라운드로 돌아옴 - 구독 정보 새로고침');
      _refreshSubscriptionInfo();
    }
  }

  void _initServices() {
    subscriptionService = Get.find<SubscriptionService>();
    limitService = Get.find<SubscriptionLimitService>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ 화면이 다시 보일 때마다 구독 정보 새로고침
    _refreshSubscriptionInfo();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          appVersion = '1.0.0';
        });
      }
    }
  }

  Future<void> _refreshSubscriptionInfo() async {
    await subscriptionService.loadCurrentSubscription();
    await limitService.getUserSubscriptionLimits();
  }

  @override
  Widget build(BuildContext context) {
    final accountService = AccountService();
    final authService = Get.find<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSubscriptionInfo,
        child: ListView(
          children: [
            // 📱 계정 정보 섹션
            _buildSectionHeader('계정 정보'),

            // ✅ Obx로 실시간 구독 상태 관찰
            Obx(() => _buildAccountCard(authService)),

            const SizedBox(height: 16),

            // 📋 앱 정보 섹션
            _buildSectionHeader('앱 정보'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('이용약관'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => _openWebPage('https://albamanager.kr/terms.html'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('개인정보처리방침'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => _openWebPage('https://albamanager.kr/privacy.html'),
                  ),
                  const Divider(height: 1),
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
      ),
    );
  }

  Future<void> _openWebPage(String url) async {
    try {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print('URL 열기 오류: $e');
      SnackbarHelper.showError('페이지를 열 수 없습니다.');
    }
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

  Widget _buildAccountCard(AuthService authService) {
    final user = authService.currentUser.value;
    final email = user?.email ?? '이메일 없음';

    // ✅ SubscriptionService의 Rx 변수에서 직접 가져오기
    final subscription = subscriptionService.currentSubscription.value;
    final isPremium = subscription?.tier == 'premium' && (subscription?.isActive ?? false);
    final isCancelled = subscription != null &&
        subscription.tier == 'premium' &&
        subscription.autoRenew == false;
    final expiryDate = subscription?.subscriptionEndDate;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이메일
            Row(
              children: [
                Icon(Icons.email_outlined, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    email,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 회원 등급 & 혜택 버튼
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isPremium ? Colors.amber[50] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isPremium ? Colors.amber[300]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isPremium ? Icons.workspace_premium : Icons.person_outline,
                              color: isPremium ? Colors.amber[700] : Colors.grey[600],
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isPremium ? '프리미엄 회원' : '무료 회원',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isPremium ? Colors.amber[900] : Colors.grey[800],
                              ),
                            ),
                          ],
                        ),

                        // 만료일 또는 다음 결제일 표시
                        if (isPremium && expiryDate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            isCancelled
                                ? '${DateFormat('yyyy년 M월 d일').format(expiryDate)}까지'
                                : '다음 결제: ${DateFormat('yyyy년 M월 d일').format(expiryDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isCancelled ? Colors.orange[700] : Colors.grey[600],
                              fontWeight: isCancelled ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                OutlinedButton(
                  onPressed: _showBenefitsDialog,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    side: BorderSide(color: Colors.amber[700]!),
                  ),
                  child: Text(
                    '프리미엄\n구독혜택',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber[900],
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),

            // 구독 취소 경고 메시지
            if (isCancelled && expiryDate != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '구독이 취소되었습니다.\n'
                            '${DateFormat('yyyy년 M월 d일').format(expiryDate)} 이후 무료 회원으로 전환됩니다.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[900],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 프리미엄 구독하기 / 재구독하기 버튼
            if (!isPremium || isCancelled) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSubscribe,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.amber[600],
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    isCancelled ? '재구독하기' : '프리미엄 구독하기',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],

            // 구독 관리 버튼 (활성 구독자만)
            if (isPremium && !isCancelled) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _handleManageSubscription,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('구독 관리 (취소/변경)'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey[400]!),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 💎 프리미엄 구독 혜택 다이얼로그
  void _showBenefitsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더
                Row(
                  children: [
                    Icon(Icons.workspace_premium, color: Colors.amber[700], size: 32),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '프리미엄 구독 혜택',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 비교 테이블
                _buildComparisonTable(),

                const SizedBox(height: 24),

                // 가격 정보
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.credit_card, color: Colors.amber[700]),
                          const SizedBox(width: 8),
                          const Text(
                            '월 결제',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '5,900원/월',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 📊 비교 테이블
  Widget _buildComparisonTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: SizedBox(),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '무료',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '구독',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[900],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 항목들
          _buildComparisonRow('모든 알바관리 기능', true, true),
          _buildComparisonRow('사업장 개설수', '1개', '무제한', isNumber: true),
          _buildComparisonRow('직원 등록수', '3명', '무제한', isNumber: true),
          _buildComparisonRow('광고 제거', false, true),
          _buildComparisonRow('가격', '무료', '월 결제', isPrice: true, isLast: true),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
      String title,
      dynamic freeValue,
      dynamic premiumValue, {
        bool isNumber = false,
        bool isPrice = false,
        bool isLast = false,
      }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: Colors.grey[300]!),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          // 제목
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // 무료
          Expanded(
            child: Center(
              child: _buildValueWidget(freeValue, isPrice: isPrice),
            ),
          ),

          // 프리미엄
          Expanded(
            child: Center(
              child: _buildValueWidget(premiumValue, isPremium: true, isPrice: isPrice),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueWidget(dynamic value, {bool isPremium = false, bool isPrice = false}) {
    if (value is bool) {
      return Icon(
        value ? Icons.check_circle : Icons.lock,
        color: value
            ? (isPremium ? Colors.amber[700] : Colors.green)
            : Colors.grey[400],
        size: 20,
      );
    }

    return Text(
      value.toString(),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: isPrice ? 11 : 12,
        fontWeight: FontWeight.w600,
        color: isPremium ? Colors.amber[900] : Colors.grey[700],
      ),
    );
  }

  // 구독하기 처리
  Future<void> _handleSubscribe() async {
    try {
      print('💳 구독 시작');

      final success = await subscriptionService.purchaseSubscription();

      print('✅ 구독 처리 완료 - 결과: $success');

      // ✅ 1초 대기 후 상태 확인 (Obx가 자동으로 UI 업데이트)
      await Future.delayed(const Duration(seconds: 1));

      print('🔄 구독 상태 확인 중...');
      await _refreshSubscriptionInfo();

      // ✅ 프리미엄 확인 후 메시지 표시
      final isPremium = subscriptionService.currentSubscription.value?.tier == 'premium' &&
          (subscriptionService.currentSubscription.value?.isActive ?? false);

      if (isPremium) {
        SnackbarHelper.showSuccess(
          '🎉 프리미엄 구독이 완료되었습니다!\n모든 기능을 이용할 수 있습니다.',
        );
      }
    } catch (e) {
      print('❌ 오류: $e');
      SnackbarHelper.showError('오류가 발생했습니다.');
    }
  }

  // 구독 관리 처리
  Future<void> _handleManageSubscription() async {
    _showManageSubscriptionDialog();
  }

  // 구독 관리 안내 다이얼로그
  void _showManageSubscriptionDialog() {
    final subscriptionPlatform = subscriptionService.currentSubscription.value?.platform;
    final currentPlatform = Theme.of(context).platform;

    print('📱 구독 플랫폼: $subscriptionPlatform');

    final isIOS = subscriptionPlatform == 'ios' ||
        (subscriptionPlatform == null && currentPlatform == TargetPlatform.iOS);

    final storeName = isIOS ? 'App Store' : 'Google Play';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '구독 관리 안내',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 구독 해지 시 유의사항
                const Text(
                  '구독 해지 시 유의사항',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),

                // 데이터 보존 안내
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              '데이터는 안전하게 보관됩니다',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• 모든 사업장 및 직원 데이터 보존\n'
                            '• 근무 기록 및 급여 데이터 보존\n'
                            '• 구독 기간 만료 시까지 프리미엄 유지',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 무료 전환 안내
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              '구독 만료 후 무료 회원 제한',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• 사업장 1개만 사용 가능 (나머지 잠김)\n'
                            '• 직원 3명까지만 활성화 (나머지 잠김)',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 재구독 안내
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.replay, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '재구독 시 모든 데이터 즉시 복원',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[900],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

                // 스토어 안내
                Text(
                  '$storeName에서 구독 관리',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),

                // 플랫폼별 안내
                if (!isIOS) ...[
                  _buildManualStep('1', 'Play 스토어 앱 열기'),
                  _buildManualStep('2', '프로필 아이콘 탭 (우측 상단)'),
                  _buildManualStep('3', '"결제 및 정기결제" 선택'),
                  _buildManualStep('4', '"정기결제" 탭에서 "알바관리" 찾기'),
                  _buildManualStep('5', '구독 취소 또는 변경'),
                ] else ...[
                  _buildManualStep('1', '설정 앱 열기'),
                  _buildManualStep('2', '[사용자 이름] 탭'),
                  _buildManualStep('3', '"구독" 선택'),
                  _buildManualStep('4', '"알바관리" 앱 찾기'),
                  _buildManualStep('5', '구독 취소 또는 변경'),
                ],

                const SizedBox(height: 20),

                // 버튼
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('닫기'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _openStore();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('$storeName'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 스토어 열기
  Future<void> _openStore() async {
    try {
      final subscriptionPlatform = subscriptionService.currentSubscription.value?.platform;

      print('📱 스토어 열기');
      print('   구독 플랫폼: $subscriptionPlatform');
      print('   현재 기기: ${Theme.of(context).platform}');

      if (subscriptionPlatform == 'ios') {
        print('🍎 iOS 구독 → App Store로 이동');
        await _openIOSSubscription();
      } else if (subscriptionPlatform == 'android') {
        print('🤖 Android 구독 → Google Play로 이동');
        await _openAndroidSubscription();
      } else {
        print('⚠️ 구독 플랫폼 정보 없음, 현재 기기 플랫폼 사용');
        final currentPlatform = Theme.of(context).platform;
        if (currentPlatform == TargetPlatform.android) {
          await _openAndroidSubscription();
        } else if (currentPlatform == TargetPlatform.iOS) {
          await _openIOSSubscription();
        }
      }
    } catch (e) {
      print('❌ 스토어 열기 오류: $e');
      SnackbarHelper.showError('스토어를 열 수 없습니다.');
    }
  }
// Android 구독 관리
  Future<void> _openAndroidSubscription() async {
    if (Platform.isIOS) {
      _showAndroidSubscriptionGuide();
      return;
    }
    try {
      final specificUrl = Uri.parse(
          'https://play.google.com/store/account/subscriptions?'
              'package=com.albamanage.albam&'
              'sku=premium_monthly_subscription'
      );

      final generalUrl = Uri.parse(
          'https://play.google.com/store/account/subscriptions'
      );

      bool success = false;

      if (await canLaunchUrl(specificUrl)) {
        success = await launchUrl(
          specificUrl,
          mode: LaunchMode.externalApplication,
        );
        print(success ? '✅ Google Play 구독 페이지 열기 성공' : '❌ 실패');
      }

      if (!success && await canLaunchUrl(generalUrl)) {
        success = await launchUrl(
          generalUrl,
          mode: LaunchMode.externalApplication,
        );
        print(success ? '✅ Google Play 구독 목록 열기 성공' : '❌ 실패');
      }

      if (!success) {
        _showAndroidSubscriptionGuide();
      }
    } catch (e) {
      print('❌ Android 구독 관리 오류: $e');
      _showAndroidSubscriptionGuide();
    }
  }
// iOS 구독 관리
  Future<void> _openIOSSubscription() async {
    if (Platform.isAndroid) {
      _showIOSSubscriptionGuide();
      return;
    }
    try {
      final settingsUrl = Uri.parse('https://apps.apple.com/account/subscriptions');

      if (await canLaunchUrl(settingsUrl)) {
        final success = await launchUrl(
          settingsUrl,
          mode: LaunchMode.externalApplication,
        );

        if (!success) {
          _showIOSSubscriptionGuide();
        }
      } else {
        _showIOSSubscriptionGuide();
      }
    } catch (e) {
      print('❌ iOS 구독 관리 오류: $e');
      _showIOSSubscriptionGuide();
    }
  }
// iOS 구독 안내 다이얼로그
  void _showIOSSubscriptionGuide() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.apple, color: Colors.black),
              const SizedBox(width: 8),
              const Text('Apple 구독 관리'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'iOS 기기에서 구독을 관리할 수 있습니다.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[900],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
                  const Text(
                    'iOS 기기에서 구독 관리 방법:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildManualStep('1', '설정 앱 열기'),
                  _buildManualStep('2', '[사용자 이름] 탭'),
                  _buildManualStep('3', '"구독" 선택'),
                  _buildManualStep('4', '"알바관리" 앱 찾기'),
                  _buildManualStep('5', '구독 취소 또는 변경'),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '구독을 취소해도 현재 결제 기간이\n끝날 때까지 프리미엄 혜택이 유지됩니다.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              height: 1.4,
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
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
    );
  }
// Android 구독 안내 다이얼로그
  void _showAndroidSubscriptionGuide() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.android, color: Colors.green[700]),
              const SizedBox(width: 8),
              const Text('Google Play 구독 관리'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Android 기기에서 구독을 관리할 수 있습니다.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[900],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
                  const Text(
                    'Android 기기에서 구독 관리 방법:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildManualStep('1', 'Play 스토어 앱 열기'),
                  _buildManualStep('2', '프로필 아이콘 탭 (우측 상단)'),
                  _buildManualStep('3', '"결제 및 정기결제" 선택'),
                  _buildManualStep('4', '"정기결제" 탭에서 "알바관리" 찾기'),
                  _buildManualStep('5', '구독 취소 또는 변경'),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '구독을 취소해도 현재 결제 기간이\n끝날 때까지 프리미엄 혜택이 유지됩니다.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              height: 1.4,
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
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
    );
  }
// 수동 단계 아이템
  Widget _buildManualStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue[700],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
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
          Get.dialog(
            const Center(child: CircularProgressIndicator()),
            barrierDismissible: false,
          );

          await Future.delayed(const Duration(milliseconds: 200));
          await authService.signOut();

          Get.back();
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
// 회원탈퇴 다이얼로그
class _DeleteAccountDialog extends StatefulWidget {
  final AccountService accountService;
  const _DeleteAccountDialog({required this.accountService});
  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}
class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {

  @override
  void initState() {
    super.initState();
  }
  @override
  void dispose() {
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
    Navigator.of(context).pop();

    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    await Future.delayed(const Duration(milliseconds: 300));

    final result = await widget.accountService.requestAccountDeletion();

    Get.back();

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