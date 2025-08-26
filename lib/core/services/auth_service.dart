import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 현재 사용자 정보
  Rxn<User> currentUser = Rxn<User>();

  // 로그인 상태
  RxBool get isLoggedIn => (currentUser.value != null).obs;

  Future<AuthService> init() async {
    // Firebase Auth 상태 변화 리스너
    _auth.authStateChanges().listen((User? user) {
      currentUser.value = user;
    });

    // 현재 사용자 설정
    currentUser.value = _auth.currentUser;

    return this;
  }

  /// 이메일/비밀번호 회원가입
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return null;
    } catch (e) {
      Get.snackbar('오류', '회원가입 중 오류가 발생했습니다.');
      return null;
    }
  }

  /// 이메일/비밀번호 로그인
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return null;
    } catch (e) {
      Get.snackbar('오류', '로그인 중 오류가 발생했습니다.');
      return null;
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      currentUser.value = null;
    } catch (e) {
      Get.snackbar('오류', '로그아웃 중 오류가 발생했습니다.');
    }
  }

  /// 비밀번호 재설정
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar('알림', '비밀번호 재설정 이메일을 발송했습니다.');
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      Get.snackbar('오류', '이메일 발송 중 오류가 발생했습니다.');
    }
  }

  /// Firebase Auth 오류 처리
  void _handleAuthError(FirebaseAuthException e) {
    String message = '';

    switch (e.code) {
      case 'user-not-found':
        message = '등록되지 않은 이메일입니다.';
        break;
      case 'wrong-password':
        message = '잘못된 비밀번호입니다.';
        break;
      case 'invalid-email':
        message = '유효하지 않은 이메일 형식입니다.';
        break;
      case 'user-disabled':
        message = '비활성화된 계정입니다.';
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