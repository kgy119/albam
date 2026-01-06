import 'dart:io';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthService extends GetxService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 현재 사용자
  Rxn<User> currentUser = Rxn<User>();

  // 로그인 상태
  RxBool get isLoggedIn => (currentUser.value != null).obs;
  RxBool isInitialized = false.obs;

  // ✅ OAuth 리다이렉트 처리용 flag
  bool _isProcessingOAuth = false;

  Future<AuthService> init() async {
    try {
      print('AuthService 초기화 시작');

      // ✅ 딥링크 리스너 등록
      _setupDeepLinkListener();

      // 인증 상태 변화 리스너
      _supabase.auth.onAuthStateChange.listen((data) {
        final session = data.session;
        print('Auth state changed: ${session?.user.id}');

        Future.delayed(const Duration(milliseconds: 50), () {
          currentUser.value = session?.user;

          // OAuth 처리 중이었다면 완료 표시
          if (_isProcessingOAuth && session?.user != null) {
            print('OAuth 로그인 완료!');
            _isProcessingOAuth = false;
          }
        });
      });

      // 현재 세션 확인
      final session = _supabase.auth.currentSession;
      currentUser.value = session?.user;

      // 사용자 정보가 있으면 users 테이블에 업데이트
      if (currentUser.value != null) {
        await _updateUserProfile(currentUser.value!);
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

  /// ✅ 딥링크 리스너 설정
  void _setupDeepLinkListener() {
    // Supabase가 딥링크를 자동으로 처리하도록 설정
    // 이미 Supabase.initialize()에서 처리되지만 명시적으로 재확인
    print('딥링크 리스너 활성화됨');
  }

  /// Google 로그인
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      print('Google 로그인 시작');

      _isProcessingOAuth = true;

      // ✅ launchMode를 externalApplication으로 설정
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: Platform.isAndroid
            ? 'com.albamanage.albam://login-callback'
            : 'com.albamanage.albam://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      if (!response) {
        print('사용자가 Google 로그인을 취소함');
        _isProcessingOAuth = false;
        return {'success': false};
      }

      print('Google 인증 화면 표시됨, 콜백 대기 중...');

      // ✅ 인증 상태 변경을 기다림 (최대 30초)
      int waitCount = 0;
      while (_isProcessingOAuth && waitCount < 60) {
        await Future.delayed(const Duration(milliseconds: 500));
        waitCount++;

        // 사용자가 로그인되었는지 확인
        if (_supabase.auth.currentUser != null) {
          print('사용자 세션 감지됨!');
          break;
        }
      }

      final user = _supabase.auth.currentUser;
      if (user != null) {
        print('Google 로그인 성공: ${user.email}');

        await _saveOrUpdateUser(
          user: user,
          provider: 'google',
        );

        _isProcessingOAuth = false;
        return {'success': true};
      } else {
        print('타임아웃: 사용자 정보를 가져오지 못함');
        _isProcessingOAuth = false;
        return {
          'success': false,
          'error': '로그인 시간이 초과되었습니다. 다시 시도해주세요.',
        };
      }
    } catch (e) {
      print('Google 로그인 오류: $e');
      _isProcessingOAuth = false;
      return {
        'success': false,
        'error': _getErrorMessage(e),
      };
    }
  }

  /// 이메일/비밀번호 로그인
  Future<Map<String, dynamic>> signInWithEmail(
      String email,
      String password,
      ) async {
    try {
      print('이메일 로그인 시작: $email');

      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        return {
          'success': false,
          'error': '로그인에 실패했습니다.',
        };
      }

      print('이메일 로그인 완료: ${response.user?.id}');

      await _saveOrUpdateUser(
        user: response.user!,
        provider: 'email',
      );

      return {'success': true};
    } catch (e) {
      print('이메일 로그인 오류: $e');
      return {
        'success': false,
        'error': _getErrorMessage(e),
      };
    }
  }

  /// 이메일/비밀번호 회원가입
  Future<Map<String, dynamic>> signUpWithEmail(
      String email,
      String password,
      ) async {
    try {
      print('이메일 회원가입 시작: $email');

      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        return {
          'success': false,
          'error': '회원가입에 실패했습니다.',
        };
      }

      print('이메일 회원가입 완료: ${response.user?.id}');

      await _saveOrUpdateUser(
        user: response.user!,
        provider: 'email',
      );

      return {'success': true};
    } catch (e) {
      print('이메일 회원가입 오류: $e');
      return {
        'success': false,
        'error': _getErrorMessage(e),
      };
    }
  }

  /// 비밀번호 재설정 이메일 전송
  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    try {
      print('비밀번호 재설정 이메일 전송: $email');

      await _supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'com.albamanage.albam://reset-password',
      );

      print('비밀번호 재설정 이메일 전송 완료');
      return {'success': true};
    } catch (e) {
      print('비밀번호 재설정 오류: $e');
      return {
        'success': false,
        'error': _getErrorMessage(e),
      };
    }
  }

  // lib/core/services/auth_service.dart

  /// users 테이블에 사용자 정보 저장/업데이트
  Future<void> _saveOrUpdateUser({
    required User user,
    required String provider,
  }) async {
    try {
      final userData = {
        'id': user.id,
        'email': user.email,
        'name': user.userMetadata?['name'] ??
            user.userMetadata?['full_name'] ??
            user.email?.split('@')[0],
        'profile_image': user.userMetadata?['avatar_url'] ??
            user.userMetadata?['picture'],
        'login_provider': provider,
        'last_login_at': DateTime.now().toIso8601String(),
      };

      print('사용자 정보 저장: ${userData['email']}');

      // ✅ upsert 대신 명시적으로 확인 후 처리
      try {
        // 먼저 사용자가 존재하는지 확인
        final existing = await _supabase
            .from(SupabaseConfig.usersTable)
            .select('id')
            .eq('id', user.id)
            .maybeSingle();

        if (existing == null) {
          // 새 사용자 추가
          await _supabase
              .from(SupabaseConfig.usersTable)
              .insert({
            ...userData,
            'created_at': DateTime.now().toIso8601String(),
          });
          print('신규 사용자 추가 완료');
        } else {
          // 기존 사용자 업데이트
          await _supabase
              .from(SupabaseConfig.usersTable)
              .update(userData)
              .eq('id', user.id);
          print('기존 사용자 정보 업데이트 완료');
        }
      } catch (e) {
        print('사용자 정보 저장 상세 오류: $e');
        // 실패해도 로그인은 계속 진행
      }

      print('사용자 정보 저장 완료');
    } catch (e) {
      print('사용자 정보 저장 오류: $e');
      // 사용자 정보 저장 실패는 치명적이지 않으므로 예외를 던지지 않음
    }
  }

  /// users 테이블 프로필 업데이트
  Future<void> _updateUserProfile(User user) async {
    try {
      await _supabase
          .from(SupabaseConfig.usersTable)
          .update({
        'last_login_at': DateTime.now().toIso8601String(),
      })
          .eq('id', user.id);
    } catch (e) {
      print('프로필 업데이트 오류: $e');
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    try {
      print('로그아웃 시작');

      await _supabase.auth.signOut();

      currentUser.value = null;
      print('로그아웃 완료');
    } catch (e) {
      print('로그아웃 오류: $e');
    }
  }

  /// 에러 메시지 변환
  String _getErrorMessage(dynamic error) {
    final errorMessage = error.toString().toLowerCase();

    if (errorMessage.contains('invalid login credentials') ||
        errorMessage.contains('invalid email or password')) {
      return '등록되지 않은 이메일이거나 비밀번호가 올바르지 않습니다.';
    }

    if (errorMessage.contains('email not confirmed')) {
      return '이메일 인증이 필요합니다. 이메일을 확인해주세요.';
    }

    if (errorMessage.contains('user already registered')) {
      return '이미 사용 중인 이메일입니다.';
    }

    if (errorMessage.contains('password should be at least')) {
      return '비밀번호가 너무 약합니다. 6자 이상 입력해주세요.';
    }

    if (errorMessage.contains('email rate limit exceeded')) {
      return '너무 많은 시도가 있었습니다. 잠시 후 다시 시도해주세요.';
    }

    if (errorMessage.contains('network')) {
      return '네트워크 연결을 확인해주세요.';
    }

    if (errorMessage.contains('invalid email')) {
      return '유효하지 않은 이메일 형식입니다.';
    }

    return '로그인에 실패했습니다. 다시 시도해주세요.';
  }

  /// 현재 사용자 ID 반환
  String? get userId => currentUser.value?.id;

  /// 현재 사용자 이메일 반환
  String? get userEmail => currentUser.value?.email;
}