import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AccountService extends GetxService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 회원탈퇴 (즉시 완전 삭제)
  Future<Map<String, dynamic>> requestAccountDeletion({
    String? reason,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        return {
          'success': false,
          'error': '로그인이 필요합니다.',
        };
      }

      print('회원탈퇴 시작: $userId');

      // 1. 사용자의 모든 사업장 조회
      final workplaces = await _supabase
          .from(SupabaseConfig.workplacesTable)
          .select('id')
          .eq('owner_id', userId);

      print('사업장 수: ${workplaces.length}');

      // 2. 각 사업장의 데이터 수동 삭제
      for (var workplace in workplaces) {
        final workplaceId = workplace['id'] as String;
        print('사업장 삭제 시작: $workplaceId');

        // 2-1. 스케줄 삭제
        await _supabase
            .from(SupabaseConfig.schedulesTable)
            .delete()
            .eq('workplace_id', workplaceId);
        print('스케줄 삭제 완료');

        // 2-2. 직원 삭제
        await _supabase
            .from(SupabaseConfig.employeesTable)
            .delete()
            .eq('workplace_id', workplaceId);
        print('직원 삭제 완료');

        // 2-3. Storage 파일 삭제
        try {
          final files = await _supabase.storage
              .from(SupabaseConfig.contractsBucket)
              .list(path: workplaceId);

          if (files.isNotEmpty) {
            final filePaths = files
                .map((file) => '$workplaceId/${file.name}')
                .toList();

            await _supabase.storage
                .from(SupabaseConfig.contractsBucket)
                .remove(filePaths);

            print('Storage 파일 삭제 완료: ${filePaths.length}개');
          }
        } catch (e) {
          print('Storage 삭제 오류 (무시): $e');
        }

        // 2-4. 사업장 삭제
        await _supabase
            .from(SupabaseConfig.workplacesTable)
            .delete()
            .eq('id', workplaceId);
        print('사업장 삭제 완료: $workplaceId');
      }

      // 4. users 테이블 삭제 (✅ RPC 함수 사용)
      await _supabase.rpc('delete_user_account', params: {
        'user_id': userId,
      });

      print('users 테이블 삭제 완료');

      // 5. 로그아웃
      await _supabase.auth.signOut();

      print('회원탈퇴 완료');

      return {'success': true};
    } catch (e) {
      print('회원탈퇴 오류: $e');
      print('오류 상세: ${e.toString()}');
      return {
        'success': false,
        'error': '탈퇴 처리 중 오류가 발생했습니다.\n${e.toString()}',
      };
    }
  }

  /// 탈퇴 취소 (30일 이내 복구)
  Future<Map<String, dynamic>> cancelAccountDeletion() async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        return {
          'success': false,
          'error': '로그인이 필요합니다.',
        };
      }

      print('탈퇴 취소 시작: $userId');

      // deleted_at, delete_scheduled_at 초기화
      await _supabase.from(SupabaseConfig.usersTable).update({
        'deleted_at': null,
        'delete_scheduled_at': null,
        'delete_reason': null,
      }).eq('id', userId);

      print('탈퇴 취소 완료');

      return {'success': true};
    } catch (e) {
      print('탈퇴 취소 오류: $e');
      return {
        'success': false,
        'error': '탈퇴 취소 중 오류가 발생했습니다.',
      };
    }
  }

  /// 탈퇴 신청 상태 확인
  Future<Map<String, dynamic>?> checkDeletionStatus(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.usersTable)
          .select('deleted_at, delete_scheduled_at, delete_reason')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;

      return {
        'deleted_at': response['deleted_at'],
        'delete_scheduled_at': response['delete_scheduled_at'],
        'delete_reason': response['delete_reason'],
      };
    } catch (e) {
      print('탈퇴 상태 확인 오류: $e');
      return null;
    }
  }

  /// 완전 삭제 (관리자용 - Edge Function에서 호출)
  Future<bool> permanentlyDeleteAccount(String userId) async {
    try {
      print('계정 완전 삭제 시작: $userId');

      // CASCADE로 자동 삭제: workplaces, employees, schedules
      await _supabase
          .from(SupabaseConfig.usersTable)
          .delete()
          .eq('id', userId);

      print('계정 완전 삭제 완료');
      return true;
    } catch (e) {
      print('계정 완전 삭제 오류: $e');
      return false;
    }
  }
}