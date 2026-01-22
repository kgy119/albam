import 'dart:io';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthService extends GetxService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 현재 사용자
  Rxn<User> currentUser = Rxn<User>();

  /// 초기화 여부
  RxBool isInitialized = false.obs;

  /// OAuth 처리 플래그
  bool _isProcessingOAuth = false;

  /* -------------------------------------------------------------------------- */
  /*                                   INIT                                     */
  /* -------------------------------------------------------------------------- */

  Future<AuthService> init() async {
    try {
      print('AuthService 초기화 시작');

      // 딥링크 / 인증 상태 리스너
      _setupAuthListener();

      // 앱 시작 시 세션 복구 (이메일 인증 / OAuth 콜백 대응)
      await _supabase.auth.getSessionFromUrl(Uri.base);

      final session = _supabase.auth.currentSession;
      currentUser.value = session?.user;

      // 로그인 상태라면 last_login_at 업데이트
      if (currentUser.value != null) {
        await _updateLastLogin(currentUser.value!.id);
      }

      isInitialized.value = true;
      print('AuthService 초기화 완료');
      return this;
    } catch (e) {
      print('AuthService 초기화 오류: $e');
      isInitialized.value = true;
      return this;
    }
  }

  void _setupAuthListener() {
    _supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      print('Auth event: $event');

      currentUser.value = session?.user;

      // 이메일 인증 완료 / OAuth 로그인 완료
      if (event == AuthChangeEvent.signedIn && session?.user != null) {
        print('로그인 완료: ${session!.user.email}');
        await _updateLastLogin(session.user.id);
        _isProcessingOAuth = false;
      }

      // 비밀번호 재설정
      if (event == AuthChangeEvent.passwordRecovery) {
        print('비밀번호 재설정 이벤트');
        Get.offAllNamed('/reset-password');
      }
    });
  }

  /* -------------------------------------------------------------------------- */
  /*                                AUTH ACTIONS                                */
  /* -------------------------------------------------------------------------- */

  /// 이메일 회원가입 (❗ users 테이블 건드리지 않음)
  Future<Map<String, dynamic>> signUpWithEmail(
      String email,
      String password,
      ) async {
    try {
      print('이메일 회원가입 시작: $email');

      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: 'com.albamanage.albam://login-callback',
      );


      if (response.user == null) {
        return {'success': false, 'error': '회원가입에 실패했습니다.'};
      }

      print('회원가입 성공 (이메일 인증 대기)');
      return {'success': true};
    } catch (e) {
      print('회원가입 오류: $e');
      return {'success': false, 'error': _getErrorMessage(e)};
    }
  }

  /// 이메일 로그인
  Future<Map<String, dynamic>> signInWithEmail(
      String email,
      String password,
      ) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        return {'success': false, 'error': '로그인 실패'};
      }

      await _saveOrUpdateUser(
        user: response.user!,
        provider: 'email',
      );

      return {'success': true};
    } on AuthException catch (e) {
      print('이메일 로그인 AuthException: ${e.message}');

      // ✅ 이메일 미인증 에러 감지
      if (e.message.contains('Email not confirmed')) {
        return {
          'success': false,
          'error': '이메일 인증이 필요합니다.',
          'isEmailNotConfirmed': true,
        };
      }

      return {
        'success': false,
        'error': _getErrorMessage(e.message),
      };
    } catch (e) {
      print('이메일 로그인 오류: $e');
      return {
        'success': false,
        'error': _getErrorMessage(e),
      };
    }
  }

  /// Google 로그인
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      _isProcessingOAuth = true;

      final redirectUrl = 'com.albamanage.albam://login-callback';

      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        authScreenLaunchMode: LaunchMode.platformDefault,
        queryParams: {
          'prompt': 'select_account',  // ✅ 추가: 항상 계정 선택 화면 표시
        },
      );

      return {'success': true};
    } catch (e) {
      _isProcessingOAuth = false;
      return {'success': false, 'error': _getErrorMessage(e)};
    }
  }

  /// Apple 로그인 추가
  Future<Map<String, dynamic>> signInWithApple() async {
    try {
      _isProcessingOAuth = true;

      final redirectUrl = 'com.albamanage.albam://login-callback';

      await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: redirectUrl,
        authScreenLaunchMode: LaunchMode.platformDefault,
      );

      return {'success': true};
    } catch (e) {
      _isProcessingOAuth = false;
      return {'success': false, 'error': _getErrorMessage(e)};
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    currentUser.value = null;
  }

  /* -------------------------------------------------------------------------- */
  /*                             USER TABLE (UPDATE)                             */
  /* -------------------------------------------------------------------------- */

  /// ✅ UPDATE ONLY (INSERT ❌)
  Future<void> _saveOrUpdateUser({
    required User user,
    required String provider,
  }) async {
    try {
      final data = {
        'email': user.email,
        'name': user.userMetadata?['name'] ??
            user.userMetadata?['full_name'] ??
            user.email?.split('@')[0],
        'profile_image': user.userMetadata?['avatar_url'] ??
            user.userMetadata?['picture'],
        'login_provider': provider,
        'last_login_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from(SupabaseConfig.usersTable)
          .update(data)
          .eq('id', user.id);

      print('users 테이블 업데이트 완료');
    } catch (e) {
      print('users UPDATE 오류: $e');
    }
  }

  Future<void> _updateLastLogin(String userId) async {
    try {
      await _supabase
          .from(SupabaseConfig.usersTable)
          .update({'last_login_at': DateTime.now().toIso8601String()})
          .eq('id', userId);
    } catch (_) {}
  }

  /* -------------------------------------------------------------------------- */
  /*                               PASSWORD RESET                                */
  /* -------------------------------------------------------------------------- */

  /// 비밀번호 재설정 이메일 전송
  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'com.albamanage.albam://reset-password',
      );

      return {'success': true};
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }


  Future<Map<String, dynamic>> updatePassword(String newPassword) async {
    try {
      final res = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (res.user == null) {
        return {'success': false};
      }

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': _getErrorMessage(e)};
    }
  }


/* -------------------------------------------------------------------------- */
/*                          EMAIL VERIFICATION                                */
/* -------------------------------------------------------------------------- */

  /// 이메일 인증 메일 재전송
  Future<Map<String, dynamic>> resendVerificationEmail(String email) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email.trim(),
      );

      print('인증 메일 재전송 완료: $email');
      return {'success': true};
    } catch (e) {
      print('이메일 재전송 오류: $e');
      return {
        'success': false,
        'error': '메일 재전송에 실패했습니다.',
      };
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                   UTILS                                    */
  /* -------------------------------------------------------------------------- */

  String _getErrorMessage(dynamic error) {
    final msg = error.toString().toLowerCase();

    if (msg.contains('email not confirmed')) {
      return '이메일 인증이 필요합니다.';
    }
    if (msg.contains('invalid login credentials')) {
      return '이메일 또는 비밀번호가 올바르지 않습니다.';
    }
    if (msg.contains('user already registered')) {
      return '이미 가입된 이메일입니다.';
    }
    return '인증 중 오류가 발생했습니다.';
  }

  String? get userId => currentUser.value?.id;
  String? get userEmail => currentUser.value?.email;
}


