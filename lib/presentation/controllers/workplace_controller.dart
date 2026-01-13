import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/workplace_service.dart';
import '../../core/services/employee_service.dart';
import '../../core/services/subscription_limit_service.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/workplace_model.dart';

class WorkplaceController extends GetxController {
  final WorkplaceService _workplaceService = WorkplaceService();
  final EmployeeService _employeeService = EmployeeService();
  final SubscriptionLimitService _limitService = SubscriptionLimitService();

  RxList<Workplace> workplaces = <Workplace>[].obs;
  RxBool isLoading = false.obs;
  RxBool isAdding = false.obs;

  @override
  void onReady() {
    super.onReady();
    loadWorkplaces();
  }

  Future<void> loadWorkplaces() async {
    isLoading.value = true;

    try {
      workplaces.value = await _workplaceService.getWorkplaces();
      print('사업장 로드 완료: ${workplaces.length}개');

      await loadAllEmployeeCounts();
    } catch (e) {
      print('사업장 로드 오류: $e');
      SnackbarHelper.showError('사업장 목록을 불러오는데 실패했습니다.');
    } finally {
      isLoading.value = false;
    }
  }

  /// 사업장 추가 (한도 체크 포함)
  Future<void> addWorkplace(String name) async {
    if (isAdding.value) return;

    try {
      isAdding.value = true;

      // 1. 사업장 추가 가능 여부 확인
      final canAdd = await _limitService.canAddWorkplace();

      if (!canAdd) {
        // 한도 초과 시 구독 안내 다이얼로그 표시
        _showSubscriptionLimitDialog();
        return;
      }

      // 2. 사업장 추가
      final newWorkplace = await _workplaceService.addWorkplace(name);
      workplaces.insert(0, newWorkplace);

      await loadAllEmployeeCounts();

      SnackbarHelper.showSuccess('사업장이 추가되었습니다.');
    } catch (e) {
      print('사업장 추가 오류: $e');
      SnackbarHelper.showError(e.toString());
    } finally {
      isAdding.value = false;
    }
  }

  /// 구독 한도 초과 다이얼로그
  void _showSubscriptionLimitDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber[700]),
            const SizedBox(width: 8),
            const Text('사업장 추가 제한'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '무료 회원은 최대 1개의 사업장만 등록할 수 있습니다.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.amber[700], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        '프리미엄 혜택',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildBenefitItem('사업장 최대 10개 등록'),
                  _buildBenefitItem('사업장당 직원 20명까지'),
                  _buildBenefitItem('무제한 근무 스케줄 관리'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '💰 월 5,900원',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.toNamed('/account-settings');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('프리미엄 구독하기'),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check, color: Colors.amber[700], size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// 사업장 삭제
  Future<void> deleteWorkplace(String workplaceId) async {
    try {
      await _workplaceService.deleteWorkplace(workplaceId);

      workplaces.removeWhere((w) => w.id == workplaceId);

      SnackbarHelper.showSuccess('사업장이 삭제되었습니다.');
    } catch (e) {
      print('사업장 삭제 오류: $e');
      SnackbarHelper.showError(e.toString());
    }
  }

  /// 사업장 이름 수정
  Future<void> updateWorkplaceName(String workplaceId, String newName) async {
    try {
      await _workplaceService.updateWorkplace(workplaceId, newName);

      final index = workplaces.indexWhere((w) => w.id == workplaceId);
      if (index != -1) {
        workplaces[index] = workplaces[index].copyWith(
          name: newName,
          updatedAt: DateTime.now(),
        );
      }

      SnackbarHelper.showSuccess('사업장 정보가 수정되었습니다.');
    } catch (e) {
      print('사업장 수정 오류: $e');
      SnackbarHelper.showError(e.toString());
    }
  }

  // 사업장별 직원 수 저장
  RxMap<String, int> employeeCountMap = <String, int>{}.obs;

  /// 모든 사업장의 직원 수 조회
  Future<void> loadAllEmployeeCounts() async {
    try {
      for (var workplace in workplaces) {
        final count = await _employeeService.getEmployeeCount(workplace.id);
        employeeCountMap[workplace.id] = count;
      }
    } catch (e) {
      print('직원 수 조회 오류: $e');
    }
  }

  /// 특정 사업장의 직원 수 반환
  int getEmployeeCount(String workplaceId) {
    return employeeCountMap[workplaceId] ?? 0;
  }
}