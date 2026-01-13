import 'dart:async';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../../data/models/user_subscription_model.dart';

class SubscriptionService extends GetxService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  // 구독 상품 ID (Google Play Console에서 생성한 ID와 일치해야 함)
  static const String premiumMonthlyProductId = 'premium_monthly_subscription';

  // 구독 상태
  Rxn<UserSubscription> currentSubscription = Rxn<UserSubscription>();
  RxBool isSubscriptionAvailable = false.obs;
  RxBool isLoading = false.obs;

  late StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;

  @override
  Future<SubscriptionService> onInit() async {
    super.onInit();
    await _initializeInAppPurchase();
    return this;
  }

  @override
  void onClose() {
    _purchaseSubscription.cancel();
    super.onClose();
  }

  /// In-App Purchase 초기화
  Future<void> _initializeInAppPurchase() async {
    try {
      print('📱 In-App Purchase 초기화 시작');

      // 구독 사용 가능 여부 확인
      final available = await _inAppPurchase.isAvailable();
      isSubscriptionAvailable.value = available;

      if (!available) {
        print('❌ In-App Purchase를 사용할 수 없습니다');
        return;
      }

      print('✅ In-App Purchase 사용 가능');

      // 구매 업데이트 리스너 설정
      _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onError: (error) {
          print('❌ 구매 스트림 오류: $error');
        },
      );

      // 현재 구독 정보 로드
      await loadCurrentSubscription();
    } catch (e) {
      print('❌ In-App Purchase 초기화 오류: $e');
    }
  }

  /// 구매 업데이트 처리
  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      print('📦 구매 상태: ${purchase.status}');

      if (purchase.status == PurchaseStatus.pending) {
        print('⏳ 구매 대기 중...');
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        print('✅ 구매 완료!');

        // Supabase에 구매 정보 저장
        await _savePurchaseToSupabase(purchase);

        // 구독 정보 새로고침
        await loadCurrentSubscription();
      } else if (purchase.status == PurchaseStatus.error) {
        print('❌ 구매 오류: ${purchase.error}');
      }

      // 구매 완료 처리
      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  /// Supabase에 구매 정보 저장
  Future<void> _savePurchaseToSupabase(PurchaseDetails purchase) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('❌ 사용자 ID 없음');
        return;
      }

      String? purchaseToken;
      if (purchase is GooglePlayPurchaseDetails) {
        purchaseToken = purchase.billingClientPurchase.purchaseToken;
      }

      // 구독 시작일과 종료일 계산 (월 단위)
      final now = DateTime.now();
      final endDate = DateTime(now.year, now.month + 1, now.day);

      final data = {
        'user_id': userId,
        'tier': 'premium',
        'subscription_status': 'active',
        'purchase_token': purchaseToken,
        'product_id': purchase.productID,
        'subscription_start_date': now.toIso8601String(),
        'subscription_end_date': endDate.toIso8601String(),
        'auto_renew': true,
      };

      // UPSERT: 존재하면 업데이트, 없으면 삽입
      await _supabase
          .from(SupabaseConfig.userSubscriptionsTable)
          .upsert(data, onConflict: 'user_id');

      print('✅ 구독 정보 저장 완료');
    } catch (e) {
      print('❌ 구독 정보 저장 오류: $e');
    }
  }

  /// 현재 구독 정보 로드
  Future<void> loadCurrentSubscription() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('❌ 사용자 ID 없음');
        currentSubscription.value = null;
        return;
      }

      final response = await _supabase
          .from(SupabaseConfig.userSubscriptionsTable)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        print('📋 구독 정보 없음 (무료 사용자)');
        currentSubscription.value = null;
        return;
      }

      currentSubscription.value = UserSubscription.fromJson(response);
      print('✅ 구독 정보 로드 완료: ${currentSubscription.value?.tier}');
    } catch (e) {
      print('❌ 구독 정보 로드 오류: $e');
      currentSubscription.value = null;
    }
  }

  /// 구독 상품 정보 가져오기
  Future<ProductDetails?> getSubscriptionProduct() async {
    try {
      if (!isSubscriptionAvailable.value) {
        print('❌ In-App Purchase를 사용할 수 없습니다');
        return null;
      }

      final response = await _inAppPurchase.queryProductDetails(
        {premiumMonthlyProductId},
      );

      if (response.notFoundIDs.isNotEmpty) {
        print('❌ 상품을 찾을 수 없음: ${response.notFoundIDs}');
        return null;
      }

      if (response.productDetails.isEmpty) {
        print('❌ 상품 정보 없음');
        return null;
      }

      final product = response.productDetails.first;
      print('✅ 상품 정보: ${product.title} - ${product.price}');
      return product;
    } catch (e) {
      print('❌ 상품 조회 오류: $e');
      return null;
    }
  }

  /// 구독 구매 시작
  Future<bool> purchaseSubscription() async {
    try {
      isLoading.value = true;

      final product = await getSubscriptionProduct();
      if (product == null) {
        print('❌ 구독 상품을 찾을 수 없습니다');
        return false;
      }

      final purchaseParam = PurchaseParam(productDetails: product);
      final success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      print(success ? '✅ 구매 요청 성공' : '❌ 구매 요청 실패');
      return success;
    } catch (e) {
      print('❌ 구독 구매 오류: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 구독 복원
  Future<void> restorePurchases() async {
    try {
      isLoading.value = true;
      print('🔄 구독 복원 시작...');

      await _inAppPurchase.restorePurchases();
      await loadCurrentSubscription();

      print('✅ 구독 복원 완료');
    } catch (e) {
      print('❌ 구독 복원 오류: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 구독 취소 (Google Play Console로 리다이렉트)
  Future<void> manageSubscription() async {
    // Google Play 구독 관리 페이지로 이동
    // 실제 구현은 url_launcher를 사용하여 처리
    print('📱 Google Play 구독 관리 페이지로 이동');
  }

  /// 프리미엄 사용자 여부
  bool get isPremiumUser {
    if (currentSubscription.value == null) return false;
    return currentSubscription.value!.isPremium;
  }

  /// 구독 등급
  String get currentTier {
    return currentSubscription.value?.tier ?? 'free';
  }
}