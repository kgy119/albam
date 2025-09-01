import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 현재 사용자 정보
  Rxn<User> currentUser = Rxn<User>();

  // 로그인 상태
  RxBool get isLoggedIn => (currentUser.value != null).obs;

  // 초기화 완료 여부
  RxBool isInitialized = false.obs;

  Future<AuthService> init() async {
    try {
      print('AuthService 초기화 시작'); // 디버깅용

      // 현재 사용자 설정
      currentUser.value = _auth.currentUser;

      // Firebase Auth 상태 변화 리스너 (빌드 안전하게)
      _auth.authStateChanges().listen((User? user) {
        print('Auth state changed: ${user?.uid}'); // 디버깅용

        // 상태 변경을 약간의 딜레이로 실행하여 빌드 중 setState 방지
        Future.delayed(const Duration(milliseconds: 50), () {
          currentUser.value = user;
        });
      });

      isInitialized.value = true;
      print('AuthService 초기화 완료'); // 디버깅용

      return this;
    } catch (e) {
      print('AuthService 초기화 오류: $e');
      isInitialized.value = true; // 오류가 발생해도 초기화 완료로 설정
      return this;
    }
  }

  /// Google 로그인
  Future<UserCredential?> signInWithGoogle() async {
    try {
      print('Google 로그인 시작'); // 디버깅용

      // Google 로그인 프로세스
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('사용자가 Google 로그인을 취소함'); // 디버깅용
        return null;
      }

      print('Google 사용자 정보 획득: ${googleUser.email}'); // 디버깅용

      // Google 인증 정보 획득
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase 인증 자격 증명 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('Firebase 로그인 시도'); // 디버깅용

      // Firebase에 로그인
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      print('Firebase 로그인 완료: ${userCredential.user?.uid}'); // 디버깅용

      return userCredential;
    } catch (e) {
      print('Google 로그인 오류: $e'); // 디버깅용

      if (e is FirebaseAuthException) {
        _handleAuthError(e);
      } else {
        Get.snackbar('오류', 'Google 로그인 중 오류가 발생했습니다: $e');
      }
      return null;
    }
  }

  /// 카카오 로그인 (향후 구현)
  Future<UserCredential?> signInWithKakao() async {
    // TODO: 카카오 로그인 구현 (다음에 추가)
    Get.snackbar('알림', '카카오 로그인은 곧 지원될 예정입니다.');
    return null;
  }

  /// 로그아웃
  Future<void> signOut() async {
    try {
      print('로그아웃 시작'); // 디버깅용

      await Future.wait([
        _googleSignIn.signOut(),
        _auth.signOut(),
      ]);

      currentUser.value = null;
      print('로그아웃 완료'); // 디버깅용

    } catch (e) {
      print('로그아웃 오류: $e'); // 디버깅용
      Get.snackbar('오류', '로그아웃 중 오류가 발생했습니다.');
    }
  }

  /// Firebase Auth 오류 처리
  void _handleAuthError(FirebaseAuthException e) {
    String message = '';

    switch (e.code) {
      case 'account-exists-with-different-credential':
        message = '다른 로그인 방법으로 이미 등록된 계정입니다.';
        break;
      case 'invalid-credential':
        message = '유효하지 않은 인증 정보입니다.';
        break;
      case 'operation-not-allowed':
        message = '해당 로그인 방법이 비활성화되어 있습니다.';
        break;
      case 'user-disabled':
        message = '비활성화된 계정입니다.';
        break;
      case 'user-not-found':
        message = '등록되지 않은 이메일입니다.';
        break;
      case 'wrong-password':
        message = '잘못된 비밀번호입니다.';
        break;
      case 'invalid-email':
        message = '유효하지 않은 이메일 형식입니다.';
        break;
      case 'email-already-in-use':
        message = '이미 사용 중인 이메일입니다.';
        break;
      case 'weak-password':
        message = '비밀번호가 너무 약합니다.';
        break;
      case 'too-many-requests':
        message = '너무 많은 시도가 있었습니다. 잠시 후 다시 시도해주세요.';
        break;
      default:
        message = '인증 오류: ${e.message}';
    }

    Get.snackbar('오류', message);
  }
}