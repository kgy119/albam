import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/workplace_model.dart';
import '../config/supabase_config.dart';
import 'auth_service.dart';

class WorkplaceService extends GetxService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 현재 사용자의 사업장 목록 가져오기
  Future<List<Workplace>> getWorkplaces() async {
    try {
      final AuthService authService = Get.find<AuthService>();
      final userId = authService.currentUser.value?.id;

      if (userId == null) {
        print('사용자가 로그인되지 않음');
        return [];
      }

      print('사용자 ID: $userId');
      print('사업장 조회 시작');

      // Supabase에서 데이터 조회
      final response = await _supabase
          .from(SupabaseConfig.workplacesTable)
          .select()
          .eq('owner_id', userId)
          .order('created_at', ascending: true);

      print('조회된 사업장 개수: ${response.length}');

      // JSON을 Workplace 객체로 변환
      final workplaces = (response as List)
          .map((json) => Workplace.fromJson(json as Map<String, dynamic>))
          .toList();

      print('최종 변환된 사업장 개수: ${workplaces.length}');

      return workplaces;
    } catch (e, stackTrace) {
      print('사업장 조회 오류: $e');
      print('스택 트레이스: $stackTrace');

      // Supabase 에러 메시지 파싱
      if (e.toString().contains('JWT')) {
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      }

      if (e.toString().contains('permission')) {
        throw Exception('사업장 조회 권한이 없습니다.');
      }

      throw Exception('사업장 목록 조회 실패: $e');
    }
  }

  /// 새로운 사업장 추가
  Future<Workplace> addWorkplace(String name) async {
    try {
      final AuthService authService = Get.find<AuthService>();
      final userId = authService.currentUser.value?.id;

      if (userId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      if (name.trim().isEmpty) {
        throw Exception('사업장 이름을 입력해주세요.');
      }

      print('사업장 추가 시작: $name');

      // Supabase에 데이터 삽입
      final response = await _supabase
          .from(SupabaseConfig.workplacesTable)
          .insert({
        'name': name.trim(),
        'owner_id': userId,
      })
          .select()
          .single();

      print('사업장 추가 완료');

      // 삽입된 데이터를 Workplace 객체로 변환
      final workplace = Workplace.fromJson(response as Map<String, dynamic>);

      return workplace;
    } catch (e, stackTrace) {
      print('사업장 추가 오류: $e');
      print('스택 트레이스: $stackTrace');
      throw Exception('사업장 추가 실패: $e');
    }
  }

  /// 사업장 정보 수정
  Future<void> updateWorkplace(String workplaceId, String newName) async {
    try {
      final AuthService authService = Get.find<AuthService>();
      final userId = authService.currentUser.value?.id;

      if (userId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      if (newName.trim().isEmpty) {
        throw Exception('사업장 이름을 입력해주세요.');
      }

      print('사업장 수정 시작: $workplaceId');

      // Supabase에서 데이터 업데이트
      await _supabase
          .from(SupabaseConfig.workplacesTable)
          .update({
        'name': newName.trim(),
      })
          .eq('id', workplaceId)
          .eq('owner_id', userId); // 소유자 확인

      print('사업장 수정 완료');
    } catch (e) {
      print('사업장 수정 오류: $e');
      throw Exception('사업장 정보 수정 실패: $e');
    }
  }

  /// 사업장 삭제
  Future<void> deleteWorkplace(String workplaceId) async {
    try {
      final AuthService authService = Get.find<AuthService>();
      final userId = authService.currentUser.value?.id;

      if (userId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      print('사업장 삭제 시작: $workplaceId');

      // Supabase에서 데이터 삭제
      // CASCADE 설정으로 관련 직원, 스케줄도 자동 삭제됨
      await _supabase
          .from(SupabaseConfig.workplacesTable)
          .delete()
          .eq('id', workplaceId)
          .eq('owner_id', userId); // 소유자 확인

      print('사업장 삭제 완료');
    } catch (e) {
      print('사업장 삭제 오류: $e');
      throw Exception('사업장 삭제 실패: $e');
    }
  }

  /// 특정 사업장 정보 조회
  Future<Workplace?> getWorkplace(String workplaceId) async {
    try {
      final AuthService authService = Get.find<AuthService>();
      final userId = authService.currentUser.value?.id;

      if (userId == null) {
        print('사용자가 로그인되지 않음');
        return null;
      }

      final response = await _supabase
          .from(SupabaseConfig.workplacesTable)
          .select()
          .eq('id', workplaceId)
          .eq('owner_id', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Workplace.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('사업장 조회 오류: $e');
      return null;
    }
  }
}