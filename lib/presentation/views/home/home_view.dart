import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_theme.dart';
import '../../controllers/workplace_controller.dart';
import '../../widgets/add_workplace_dialog.dart';
import '../../../core/services/subscription_limit_service.dart';
import '../../../app/routes/app_routes.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WorkplaceController>();
    final limitService = Get.find<SubscriptionLimitService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 사업장'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Get.toNamed(AppRoutes.accountSettings);
              // ✅ 설정 화면에서 돌아오면 구독 정보 새로고침
              print('🔄 설정 화면에서 복귀 - 구독 정보 새로고침');
              await limitService.getUserSubscriptionLimits();
            },
            tooltip: '설정',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            print('🔄 아래로 당겨서 새로고침');
            await controller.loadWorkplaces();
            await limitService.getUserSubscriptionLimits();
          },
          child: Obx(() {
            // ✅ Obx 내부에서 실시간으로 구독 상태 감지
            if (limitService.isLoading.value || controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.workplaces.isEmpty) {
              return _buildEmptyState(context);
            }

            return _buildWorkplaceList(context, controller, limitService);
          }),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWorkplaceDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business,
            size: 64,
            color: Theme.of(context).primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            '등록된 사업장이 없습니다',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            '새로운 사업장을 추가해보세요',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkplaceList(
      BuildContext context,
      WorkplaceController controller,
      SubscriptionLimitService limitService,
      ) {
    // ✅ 실시간으로 isPremium 값 가져오기
    final isPremium = limitService.currentLimits.value?.isPremium ?? false;

    print('📊 사업장 목록 렌더링 - 프리미엄: $isPremium, 사업장 수: ${controller.workplaces.length}');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.workplaces.length,
      itemBuilder: (context, index) {
        final workplace = controller.workplaces[index];
        final isLocked = !isPremium && index >= 1;

        return _buildWorkplaceCard(
          workplace,
          index,
          context,
          isLocked,
          controller,
        );
      },
    );
  }

  Widget _buildWorkplaceCard(
      dynamic workplace,
      int index,
      BuildContext context,
      bool isLocked,
      WorkplaceController controller,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          InkWell(
            onTap: isLocked
                ? () => _showUpgradeDialog(workplace: workplace)
                : () {
              Get.toNamed(
                AppRoutes.workplaceDetail,
                arguments: workplace,
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 헤더 (이름 + 메뉴)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workplace.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('yyyy.MM.dd 등록')
                                  .format(workplace.createdAt),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLocked)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (value) =>
                              _handleMenuSelection(value, workplace.id, controller),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 18),
                                  SizedBox(width: 8),
                                  Text('이름 수정'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('삭제', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 통계 정보
                  Obx(() {
                    final employeeCount = controller.employeeCountMap[workplace.id] ?? 0;
                    final monthlySalary = controller.monthlySalaryMap[workplace.id] ?? 0;

                    return Row(
                      children: [
                        Expanded(
                          child: _buildClickableStatChip(
                            icon: Icons.people,
                            label: '직원',
                            value: '${employeeCount}명',
                            color: AppTheme.primaryColor,
                            onTap: isLocked
                                ? null
                                : () {
                              Get.toNamed(
                                AppRoutes.employeeList,
                                arguments: workplace,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildClickableStatChip(
                            icon: Icons.attach_money,
                            label: '이번 달 급여',
                            value: monthlySalary > 0
                                ? '${NumberFormat('#,###').format(monthlySalary)}원'
                                : '-',
                            color: AppTheme.successColor,
                            onTap: isLocked
                                ? null
                                : () {
                              final now = DateTime.now();
                              Get.toNamed(
                                AppRoutes.monthlySalarySummary,
                                arguments: {
                                  'workplace': workplace,
                                  'year': now.year,
                                  'month': now.month,
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),

          // 잠금 오버레이
          if (isLocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showUpgradeDialog(workplace: workplace),
                    borderRadius: BorderRadius.circular(12),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '프리미엄 구독 필요',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '탭하여 구독하기',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClickableStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: color.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuSelection(
      String value,
      String workplaceId,
      WorkplaceController controller,
      ) {
    switch (value) {
      case 'edit':
        _showEditWorkplaceDialog(workplaceId, controller);
        break;
      case 'delete':
        _showDeleteConfirmDialog(workplaceId, controller);
        break;
    }
  }

  void _showEditWorkplaceDialog(
      String workplaceId,
      WorkplaceController controller,
      ) {
    final workplace =
    controller.workplaces.firstWhere((w) => w.id == workplaceId);
    final TextEditingController nameController =
    TextEditingController(text: workplace.name);

    Get.dialog(
      AlertDialog(
        title: const Text('사업장 이름 수정'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: '사업장 이름'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                Get.back();
                await Future.delayed(const Duration(milliseconds: 200));
                await controller.updateWorkplaceName(workplaceId, newName);
              }
            },
            child: const Text('수정'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(
      String workplaceId,
      WorkplaceController controller,
      ) {
    final workplace =
    controller.workplaces.firstWhere((w) => w.id == workplaceId);

    Get.dialog(
      AlertDialog(
        title: const Text('사업장 삭제'),
        content: Text(
            '\'${workplace.name}\' 사업장을 삭제하시겠습니까?\n삭제된 데이터는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await Future.delayed(const Duration(milliseconds: 200));
              await controller.deleteWorkplace(workplaceId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showAddWorkplaceDialog() {
    Get.dialog(AddWorkplaceDialog());
  }

  void _showUpgradeDialog({dynamic workplace}) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber[700]),
            const SizedBox(width: 8),
            const Text('프리미엄 구독 필요'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '이 사업장은 프리미엄 구독이 필요합니다.',
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
                  _buildBenefitItem('사업장 무제한 개설'),
                  _buildBenefitItem('직원 무제한 등록'),
                  _buildBenefitItem('광고 제거'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              if (workplace != null)
                OutlinedButton(
                  onPressed: () {
                    Get.back();
                    final controller = Get.find<WorkplaceController>();
                    _showDeleteConfirmDialog(workplace.id, controller);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    minimumSize: const Size(72, 44),
                  ),
                  child: const Text('삭제'),
                ),
              OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(72, 44),
                ),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  Get.toNamed(AppRoutes.accountSettings);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[600],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(96, 44),
                ),
                child: const Text(
                  '구독하기',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
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
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}