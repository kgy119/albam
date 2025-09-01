import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../data/models/workplace.dart';
import '../constants/app_constants.dart';
import 'auth_service.dart';

class WorkplaceService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 현재 사용자의 사업장 목록 가져오기
  Future<List<Workplace>> getWorkplaces() async {
    try {
      // AuthService가 초기화될 때까지 기다림
      final AuthService authService = Get.find<AuthService>();
      final userId = authService.currentUser.value?.uid;

      if (userId == null) {
        print('사용자가 로그인되지 않음'); // 디버깅용
        return [];
      }

      print('사용자 ID: $userId'); // 디버깅용
      print('사업장 조회 시작'); // 디버깅용
      print('컬렉션명: ${AppConstants.workplacesCollection}'); // 디버깅용

      // 먼저 전체 컬렉션이 존재하는지 확인
      final CollectionReference collection = _firestore.collection(AppConstants.workplacesCollection);
      print('컬렉션 참조 생성 완료'); // 디버깅용

      // orderBy 없이 먼저 시도해보기 (인덱스 문제 가능성)
      Query query = collection.where('ownerId', isEqualTo: userId);
      print('쿼리 생성 완료'); // 디버깅용

      final QuerySnapshot snapshot = await query.get();
      print('쿼리 실행 완료'); // 디버깅용
      print('조회된 문서 개수: ${snapshot.docs.length}'); // 디버깅용

      // 각 문서의 데이터 출력
      for (var doc in snapshot.docs) {
        print('문서 ID: ${doc.id}');
        print('문서 데이터: ${doc.data()}');
      }

      // 시간순 정렬은 클라이언트에서 수행
      List<Workplace> workplaces = snapshot.docs
          .map((doc) => Workplace.fromFirestore(doc))
          .toList();

      // 생성일 기준 내림차순 정렬
      workplaces.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('최종 변환된 사업장 개수: ${workplaces.length}'); // 디버깅용

      return workplaces;
    } catch (e, stackTrace) {
      print('사업장 조회 오류: $e'); // 디버깅용
      print('스택 트레이스: $stackTrace'); // 디버깅용

      // Firebase 권한 오류인 경우 특별 처리
      if (e.toString().contains('permission-denied')) {
        throw Exception('Firebase 권한이 없습니다. Firestore 보안 규칙을 확인해주세요.');
      }

      // 인덱스 오류인 경우
      if (e.toString().contains('index')) {
        throw Exception('Firestore 인덱스가 필요합니다. Firebase Console에서 인덱스를 생성해주세요.');
      }

      throw Exception('사업장 목록 조회 실패: $e');
    }
  }

  /// 새로운 사업장 추가
  Future<Workplace> addWorkplace(String name) async {
    try {
      final AuthService authService = Get.find<AuthService>();
      final userId = authService.currentUser.value?.uid;

      if (userId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      if (name.trim().isEmpty) {
        throw Exception('사업장 이름을 입력해주세요.');
      }

      final now = DateTime.now();
      final workplaceData = {
        'name': name.trim(),
        'ownerId': userId,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      print('사업장 추가 데이터: $workplaceData'); // 디버깅용

      final DocumentReference docRef = await _firestore
          .collection(AppConstants.workplacesCollection)
          .add(workplaceData);

      print('사업장 추가 완료, ID: ${docRef.id}'); // 디버깅용

      // 추가된 사업장 정보 반환
      return Workplace(
        id: docRef.id,
        name: name.trim(),
        ownerId: userId,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e, stackTrace) {
      print('사업장 추가 오류: $e'); // 디버깅용
      print('스택 트레이스: $stackTrace'); // 디버깅용
      throw Exception('사업장 추가 실패: $e');
    }
  }

  /// 사업장 정보 수정
  Future<void> updateWorkplace(String workplaceId, String newName) async {
    try {
      final AuthService authService = Get.find<AuthService>();
      final userId = authService.currentUser.value?.uid;

      if (userId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      if (newName.trim().isEmpty) {
        throw Exception('사업장 이름을 입력해주세요.');
      }

      await _firestore
          .collection(AppConstants.workplacesCollection)
          .doc(workplaceId)
          .update({
        'name': newName.trim(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('사업장 정보 수정 실패: $e');
    }
  }

  /// 사업장 삭제
  Future<void> deleteWorkplace(String workplaceId) async {
    try {
      final AuthService authService = Get.find<AuthService>();
      final userId = authService.currentUser.value?.uid;

      if (userId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // TODO: 향후 관련 직원, 스케줄 데이터도 함께 삭제하는 로직 추가
      await _firestore
          .collection(AppConstants.workplacesCollection)
          .doc(workplaceId)
          .delete();
    } catch (e) {
      throw Exception('사업장 삭제 실패: $e');
    }
  }
}