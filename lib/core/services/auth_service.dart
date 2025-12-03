// lib/core/services/auth_service.dart

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
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      print('Google 로그인 시작');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('사용자가 Google 로그인을 취소함');
        return {'success': false};
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

      return {'success': true, 'user': userCredential};
    } on FirebaseAuthException catch (e) {
      print('Google 로그인 오류: ${e.code} / ${e.message}');
      return {'success': false, 'error': _getErrorMessage(e)};
    } catch (e) {
      print('Google 로그인 일반 오류: $e');
      return {'success': false, 'error': 'Google 로그인 중 오류가 발생했습니다.'};
    }
  }

  /// 이메일/비밀번호 로그인
  Future<Map<String, dynamic>> signInWithEmail(String email, String password) async {
    try {
      print('이메일 로그인 시작: $email');

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      print('이메일 로그인 완료: ${userCredential.user?.uid}');

      await _saveOrUpdateUser(
        userCredential.user!,
        'email',
        email: userCredential.user!.email,
      );

      return {'success': true, 'user': userCredential};
    } on FirebaseAuthException catch (e) {
      print('이메일 로그인 오류: ${e.code} / ${e.message}');
      return {'success': false, 'error': _getErrorMessage(e)};
    } catch (e) {
      print('이메일 로그인 일반 오류: $e');
      return {'success': false, 'error': '로그인 중 오류가 발생했습니다.'};
    }
  }

  /// 이메일/비밀번호 회원가입
  Future<Map<String, dynamic>> signUpWithEmail(String email, String password) async {
    try {
      print('이메일 회원가입 시작: $email');

      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      print('이메일 회원가입 완료: ${userCredential.user?.uid}');

      await _saveOrUpdateUser(
        userCredential.user!,
        'email',
        email: userCredential.user!.email,
      );

      return {'success': true, 'user': userCredential};
    } on FirebaseAuthException catch (e) {
      print('이메일 회원가입 오류: ${e.code} / ${e.message}');
      return {'success': false, 'error': _getErrorMessage(e)};
    } catch (e) {
      print('이메일 회원가입 일반 오류: $e');
      return {'success': false, 'error': '회원가입 중 오류가 발생했습니다.'};
    }
  }

  /// 비밀번호 재설정 이메일 전송
  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    try {
      print('비밀번호 재설정 이메일 전송: $email');

      await _auth.sendPasswordResetEmail(email: email.trim());

      print('비밀번호 재설정 이메일 전송 완료');
      return {'success': true};
    } on FirebaseAuthException catch (e) {
      print('비밀번호 재설정 오류: ${e.code} / ${e.message}');
      return {'success': false, 'error': _getErrorMessage(e)};
    } catch (e) {
      print('비밀번호 재설정 일반 오류: $e');
      return {'success': false, 'error': '비밀번호 재설정 중 오류가 발생했습니다.'};
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

  /// 에러 메시지 가져오기
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return '다른 로그인 방법으로 이미 등록된 계정입니다.';
      case 'invalid-credential':
        return '등록되지 않은 이메일이거나 비밀번호가 올바르지 않습니다.';
      case 'operation-not-allowed':
        return '해당 로그인 방법이 비활성화되어 있습니다.';
      case 'user-disabled':
        return '비활성화된 계정입니다.';
      case 'user-not-found':
        return '등록되지 않은 회원입니다. 회원가입을 먼저 진행해주세요.';
      case 'wrong-password':
        return '비밀번호가 올바르지 않습니다.';
      case 'invalid-email':
        return '유효하지 않은 이메일 형식입니다.';
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'weak-password':
        return '비밀번호가 너무 약합니다. 6자 이상 입력해주세요.';
      case 'too-many-requests':
        return '너무 많은 시도가 있었습니다. 잠시 후 다시 시도해주세요.';
      case 'network-request-failed':
        return '네트워크 연결을 확인해주세요.';
      default:
        return '로그인에 실패했습니다. 다시 시도해주세요.';
    }
  }

}