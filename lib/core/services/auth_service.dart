import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Rxn<User> currentUser = Rxn<User>();
  RxBool get isLoggedIn => (currentUser.value != null).obs;
  RxBool isInitialized = false.obs;

  Future<AuthService> init() async {
    try {
      print('AuthService 초기화 시작');

      _auth.authStateChanges().listen((User? user) {
        print('Auth state changed: ${user?.uid}');
        Future.delayed(const Duration(milliseconds: 50), () {
          currentUser.value = user;
        });
      });

      currentUser.value = _auth.currentUser;
      isInitialized.value = true;
      print('AuthService 초기화 완료');
      return this;
    } catch (e) {
      print('AuthService 초기화 오류: $e');
      isInitialized.value = true;
      return this;
    }
  }

  /// Google 로그인
  Future<UserCredential?> signInWithGoogle() async {
    try {
      print('Google 로그인 시작');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('사용자가 Google 로그인을 취소함');
        return null;
      }

      print('Google 사용자 정보 획득: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('Firebase 로그인 시도');

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      print('Firebase 로그인 완료: ${userCredential.user?.uid}');

      await _saveOrUpdateUser(
        userCredential.user!,
        'google',
        name: userCredential.user!.displayName,
        email: userCredential.user!.email,
        profileImage: userCredential.user!.photoURL,
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Google 로그인 오류: ${e.code} / ${e.message}');
      _handleAuthError(e);
      return null;
    } catch (e) {
      print('Google 로그인 일반 오류: $e');
      Get.snackbar('오류', 'Google 로그인 중 오류가 발생했습니다.');
      return null;
    }
  }

  /// Firestore에 사용자 정보 저장/업데이트
  Future<void> _saveOrUpdateUser(
      User user,
      String provider, {
        String? email,
        String? name,
        String? profileImage,
      }) async {
    final userDoc = _firestore.collection('users').doc(user.uid);

    Map<String, dynamic> data = {
      'loginProvider': provider,
      'lastLoginAt': FieldValue.serverTimestamp(),
    };

    if (email != null && email.isNotEmpty) data['email'] = email;
    if (name != null && name.isNotEmpty) data['name'] = name;
    if (profileImage != null && profileImage.isNotEmpty) data['profileImage'] = profileImage;

    await userDoc.set({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 로그아웃
  Future<void> signOut() async {
    try {
      print('로그아웃 시작');

      await Future.wait([
        _googleSignIn.signOut().catchError((e) {
          print('Google 로그아웃 오류 (무시): $e');
          return null;
        }),
        _auth.signOut().catchError((e) {
          print('Firebase 로그아웃 오류 (무시): $e');
          return null;
        }),
      ]);

      currentUser.value = null;
      print('로그아웃 완료');
    } catch (e) {
      print('로그아웃 오류: $e');
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