import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/services/subscription_limit_service.dart';
import '../../../core/utils/snackbar_helper.dart';

class PremiumDetailView extends StatefulWidget {
  const PremiumDetailView({super.key});

  @override
  State<PremiumDetailView> createState() => _PremiumDetailViewState();
}

class _PremiumDetailViewState extends State<PremiumDetailView> {
  late SubscriptionService subscriptionService;
  late SubscriptionLimitService limitService;

  @override
  void initState() {
    super.initState();
    subscriptionService = Get.find<SubscriptionService>();
    limitService = Get.find<SubscriptionLimitService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('프리미엄 멤버십'),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // 혜택 비교
                    _buildBenefitsComparison(),

                    const SizedBox(height: 40),

                    // 가격 정보 (간단하게)
                    _buildPricing(),

                    const SizedBox(height: 32),

                    // 이용약관 & 개인정보처리방침
                    _buildTermsLinks(),

                    const SizedBox(height: 100), // 하단 버튼 공간
                  ],
                ),
              ),
            ),

            // 하단 구독 버튼 (고정)
            _buildSubscribeButton(),
          ],
        ),
      ),
    );
  }

  // 가격 정보 (간단하고 깔끔하게)
  Widget _buildPricing() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Text(
              '알바관리 프리미엄 월간 구독',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '5,900',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '원/월',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '1개월 자동 갱신',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 혜택 비교
  Widget _buildBenefitsComparison() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '프리미엄 혜택',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 20),

          _buildComparisonTable(),
        ],
      ),
    );
  }

  // 비교 테이블
  Widget _buildComparisonTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '프리미엄',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber[800],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 항목들
          _buildComparisonRow('기본 기능', true, true),
          _buildComparisonRow('사업장 개설', '1개', '무제한'),
          _buildComparisonRow('직원 등록', '3명', '무제한'),
          _buildComparisonRow('광고 제거', false, true, isLast: true),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
      String title,
      dynamic freeValue,
      dynamic premiumValue, {
        bool isLast = false,
      }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast ? BorderSide.none : BorderSide(color: Colors.grey[200]!),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: _buildValueWidget(freeValue),
            ),
          ),
          Expanded(
            child: Center(
              child: _buildValueWidget(premiumValue, isPremium: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueWidget(dynamic value, {bool isPremium = false}) {
    if (value is bool) {
      return Icon(
        value ? Icons.check_circle : Icons.cancel,
        color: value
            ? (isPremium ? Colors.amber[700] : Colors.green)
            : Colors.grey[400],
        size: 24,
      );
    }

    return Text(
      value.toString(),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isPremium ? Colors.amber[800] : Colors.grey[700],
      ),
    );
  }

  // 이용약관 링크 (정렬 맞추기)
  Widget _buildTermsLinks() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () => _openWebPage('https://albamanager.kr/terms.html'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              '이용약관',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 12,
            color: Colors.grey[400],
          ),
          TextButton(
            onPressed: () => _openWebPage('https://albamanager.kr/privacy.html'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              '개인정보처리방침',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 하단 구독 버튼
  Widget _buildSubscribeButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _handleSubscribe,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              '구독하기',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 웹페이지 열기
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

  // 구독하기 처리
  Future<void> _handleSubscribe() async {
    try {
      print('💳 구독 시작');

      final success = await subscriptionService.purchaseSubscription();
      print('✅ 구독 처리 완료 - 결과: $success');

      if (success) {
        await Future.delayed(const Duration(seconds: 1));
        await subscriptionService.loadCurrentSubscription();
        await limitService.getUserSubscriptionLimits();

        final isPremium = subscriptionService.currentSubscription.value?.tier == 'premium' &&
            (subscriptionService.currentSubscription.value?.isActive ?? false);

        if (isPremium) {
          SnackbarHelper.showSuccess(
            '🎉 프리미엄 구독이 완료되었습니다!\n모든 기능을 이용할 수 있습니다.',
          );

          // 설정 화면으로 돌아가기
          Get.back();
        }
      }
    } catch (e) {
      print('❌ 오류: $e');
      SnackbarHelper.showError('오류가 발생했습니다.');
    }
  }
}