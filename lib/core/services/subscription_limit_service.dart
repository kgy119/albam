import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/subscription_limits_model.dart';

class SubscriptionLimitService extends GetxService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ✅ 구독 정보를 Rx로 저장
  Rxn<SubscriptionLimits> currentLimits = Rxn<SubscriptionLimits>();
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // ✅ 서비스 시작 시 자동 로드
    getUserSubscriptionLimits();
  }

  /// 사용자의 구독 한도 조회
  Future<SubscriptionLimits?> getUserSubscriptionLimits() async {
    try {
      isLoading.value = true;

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('❌ 사용자 ID 없음');
        currentLimits.value = null;
        return null;
      }

      final response = await _supabase.rpc(
        'get_user_subscription_limits',
        params: {'p_user_id': userId},
      );

      if (response == null) {
        print('❌ 구독 한도 정보 없음');
        currentLimits.value = null;
        return null;
      }

      final limits = SubscriptionLimits.fromJson(response as Map<String, dynamic>);
      currentLimits.value = limits;
      return limits;
    } catch (e) {
      print('❌ 구독 한도 조회 오류: $e');
      currentLimits.value = null;
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// 사업장 추가 가능 여부 확인
  Future<bool> canAddWorkplace() async {
    try {
      final limits = await getUserSubscriptionLimits();
      if (limits == null) return false;

      return limits.canAddWorkplace;
    } catch (e) {
      print('❌ 사업장 추가 가능 여부 확인 오류: $e');
      return false;
    }
  }

  /// 직원 추가 가능 여부 확인
  Future<Map<String, dynamic>> canAddEmployee(String workplaceId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {
          'can_add': false,
          'error': '사용자 ID 없음',
        };
      }

      final response = await _supabase.rpc(
        'can_add_employee',
        params: {
          'p_user_id': userId,
          'p_workplace_id': workplaceId,
        },
      );

      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      print('❌ 직원 추가 가능 여부 확인 오류: $e');
      return {
        'can_add': false,
        'error': e.toString(),
      };
    }
  }
}