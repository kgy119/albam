import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' hide User;

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore 인스턴스 추가

  // Rxn<User>는 User 타입이 nullable임을 나타냅니다.
  Rxn<User> currentUser = Rxn<User>();
  // .obs를 붙여야 GetX 반응형 변수가 됩니다.
  RxBool get isLoggedIn => (currentUser.value != null).obs;
  RxBool isInitialized = false.obs;

  Future<AuthService> init() async {
    try {
      print('AuthService 초기화 시작');

      // Firebase Auth 상태 변경 리스너 설정
      _auth.authStateChanges().listen((User? user) {
        print('Auth state changed: ${user?.uid}');
        // UI 깜박임 방지를 위해 아주 짧은 지연 후 상태 업데이트
        Future.delayed(const Duration(milliseconds: 50), () {
          currentUser.value = user;
        });
      });

      // 초기 사용자 상태를 한번 확인
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

      // Firestore에 사용자 정보 업데이트/저장 로직 추가
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
      _handleAuthError(e); // 오류 메시지는 여기서 처리
      return null;
    } catch (e) {
      print('Google 로그인 일반 오류: $e');
      // 서비스 계층에서는 UI 호출 대신 오류를 throw하거나 콘솔에 로깅하는 것이 원칙입니다.
      Get.snackbar('오류', 'Google 로그인 중 오류가 발생했습니다.');
      return null;
    }
  }

  /// 카카오 로그인 구현
  Future<UserCredential?> signInWithKakao() async {
    try {
      print('카카오 로그인 시작');

      OAuthToken token;

      // 카카오톡 설치 여부 확인 및 로그인
      if (await isKakaoTalkInstalled()) {
        try {
          token = await UserApi.instance.loginWithKakaoTalk();
          print('카카오톡으로 로그인 성공');
        } catch (e) {
          print('카카오톡 로그인 실패, 웹 로그인 시도: $e');

          if (e is PlatformException && e.code == 'CANCELED') {
            print('사용자가 카카오 로그인을 취소함');
            return null;
          }
          // 웹 로그인 시도 (GetX Overlay 에러를 발생시키는 Get.snackbar 대신 print)
          print('카카오 계정으로 웹 로그인 시도');
          token = await UserApi.instance.loginWithKakaoAccount();
          print('카카오 계정으로 로그인 성공');
        }
      } else {
        // 웹 로그인 시도
        print('카카오 계정으로 웹 로그인 시도 (카카오톡 미설치)');
        token = await UserApi.instance.loginWithKakaoAccount();
        print('카카오 계정으로 로그인 성공');
      }

      print('카카오 토큰 획득 완료');

      // 사용자 정보 가져오기
      final kakaoUser = await UserApi.instance.me();

      // NOTE: kakaoUser.kakaoAccount?.email 이 null 일 수 있습니다.
      // 카카오 개발자 콘솔에서 이메일 동의 항목을 필수 동의로 설정했는지 확인이 필요합니다.
      print('카카오 사용자 정보 (email): ${kakaoUser.kakaoAccount?.email}');


      // *************************************************************************
      // TODO: 중요! 카카오 로그인을 Firebase에 연동하는 표준 방법은 서버에서 Custom Token을 발급받는 것입니다.
      // 현재는 임시로 익명 로그인을 사용합니다.
      // 만약 'admin-restricted-operation' 오류가 지속된다면 Firebase Console에서
      // 'Auth Blocking' 기능이 비활성화되었는지, 'Anonymous' 로그인이 활성화되었는지 확인해야 합니다.
      // *************************************************************************

      final UserCredential credential = await _auth.signInAnonymously();

      print('Firebase 익명 로그인 완료: ${credential.user?.uid}');

      // Firestore에 카카오 사용자 정보 저장 및 업데이트
      await _saveOrUpdateUser(
        credential.user!,
        'kakao',
        kakaoId: kakaoUser.id.toString(),
        email: kakaoUser.kakaoAccount?.email,
        name: kakaoUser.kakaoAccount?.profile?.nickname,
        profileImage: kakaoUser.kakaoAccount?.profile?.profileImageUrl,
      );

      // UI 로직 (Snackbar) 제거: UI 관련 코드는 Controller에서 처리해야 'No Overlay' 오류를 방지할 수 있습니다.
      // Get.snackbar('성공', '${kakaoUser.kakaoAccount?.profile?.nickname ?? "사용자"}님, 환영합니다!', ...);

      return credential;
    } on PlatformException catch (e) {
      // 사용자가 로그인 취소 시, 예외를 던지지 않고 null 반환
      if (e.code == 'CANCELED') {
        print('사용자가 카카오 로그인을 취소함');
        return null;
      }
      // UI 로직 (Snackbar) 제거: 나머지 PlatformException은 호출자에게 전달
      print('카카오 PlatformException 오류: ${e.code} / ${e.message}');
      rethrow;
    } catch (e) {
      print('카카오 로그인 일반 오류: $e');
      // 카카오 로그인 설정 오류 다이얼로그는 서비스에서 예외적으로 유지
      if (e.toString().contains('KOE101')) {
        _showKakaoErrorDialog();
        return null;
      }
      // 다른 오류는 호출자에게 전달
      rethrow;
    }
  }

  /// Firestore에 사용자 정보를 저장하거나 업데이트하는 공통 함수
  Future<void> _saveOrUpdateUser(
      User user,
      String provider, {
        String? kakaoId,
        String? email,
        String? name,
        String? profileImage,
      }) async {
    final userDoc = _firestore.collection('users').doc(user.uid);

    // 데이터 맵 구성
    Map<String, dynamic> data = {
      'loginProvider': provider,
      'lastLoginAt': FieldValue.serverTimestamp(),
    };

    // 익명 로그인의 경우, 이메일/이름 등은 카카오에서 가져온 정보로 채웁니다.
    if (email != null && email.isNotEmpty) data['email'] = email;
    if (name != null && name.isNotEmpty) data['name'] = name;
    if (profileImage != null && profileImage.isNotEmpty) data['profileImage'] = profileImage;
    if (kakaoId != null) data['kakaoId'] = kakaoId;

    // 최초 생성 시에만 createdAt 필드를 설정
    await userDoc.set({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }


  /// 카카오 로그인 설정 오류 다이얼로그 (Get.dialog는 Overlay가 없어도 비교적 안전하나, Controller로 이동 권장)
  void _showKakaoErrorDialog() {
    // 이 코드는 현재는 서비스에 남겨두지만, 원칙적으로 Controller/View에서 실행되어야 합니다.
    Get.dialog(
      AlertDialog(
        title: const Text('카카오 로그인 설정 필요'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '카카오 개발자 콘솔에서 다음 설정을 확인해주세요:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('1. 앱 설정 > 플랫폼 > Android 추가'),
              Text('   • 패키지명: com.albamanage.albam'),
              Text('   • 키 해시 등록'),
              SizedBox(height: 8),
              Text('2. 카카오 로그인 > 활성화 설정 ON'),
              SizedBox(height: 8),
              Text('3. Redirect URI 등록'),
              Text('   • kakao{NATIVE_APP_KEY}://oauth'),
              SizedBox(height: 12),
              Text(
                '개발자 콘솔: developers.kakao.com',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 로그아웃
  Future<void> signOut() async {
    try {
      print('로그아웃 시작');

      // Google, Firebase, Kakao 로그아웃을 병렬로 처리
      await Future.wait([
        _googleSignIn.signOut().catchError((e) => print('Google 로그아웃 오류 (무시): $e')),
        _auth.signOut().catchError((e) => print('Firebase 로그아웃 오류 (무시): $e')),
        // Kakao 로그아웃은 오류 발생 시 무시
        UserApi.instance.logout().catchError((e) {
          print('카카오 로그아웃 오류 (무시): $e');
          return null;
        }),
      ]);

      currentUser.value = null;
      print('로그아웃 완료');

    } catch (e) {
      print('로그아웃 오류: $e');
      Get.snackbar('오류', '로그아웃 중 오류가 발생했습니다.');
    }
  }

  /// Firebase Auth 오류 처리 (UI 호출은 여기서만 이루어지도록 유지)
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
    // 카카오 로그인 시 발생한 오류 코드를 여기에 추가
      case 'admin-restricted-operation':
        message = 'Firebase 서버 설정 오류로 인해 로그인에 실패했습니다. Firebase Console에서 "Auth Blocking" 설정을 확인해주세요.';
        break;
      default:
        message = '인증 오류: ${e.message}';
    }

    Get.snackbar('오류', message);
  }
}