import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/workplace_controller.dart';
import '../../widgets/add_workplace_dialog.dart';
import '../../../core/services/auth_service.dart';
import '../../../app/routes/app_routes.dart';

class HomeView extends GetView<WorkplaceController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 사업장'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(authService),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.loadWorkplaces,
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.workplaces.isEmpty) {
              return _buildEmptyState(context);
            }

            return _buildWorkplaceList(context);
          }),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWorkplaceDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showLogoutDialog(AuthService authService) {
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('로그아웃 하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // 다이얼로그 먼저 닫기

                await Future.delayed(const Duration(milliseconds: 200));

                await authService.signOut();

                // 로그인 화면으로 이동
                Get.offAllNamed(AppRoutes.login);
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
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
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '새로운 사업장을 추가해보세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkplaceList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.workplaces.length,
      itemBuilder: (context, index) {
        final workplace = controller.workplaces[index];
        return _buildWorkplaceCard(workplace, context);
      },
    );
  }

  Widget _buildWorkplaceCard(workplace, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // 사업장 세부페이지로 이동
          Get.toNamed(AppRoutes.workplaceDetail, arguments: workplace);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.business,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workplace.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '생성일: ${DateFormat('yyyy.MM.dd').format(workplace.createdAt)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    onSelected: (value) => _handleMenuSelection(value, workplace.id),
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

              const SizedBox(height: 12),

              // 사업장 정보 요약
              Obx(() => Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.people,
                    label: '직원 ${controller.getEmployeeCount(workplace.id)}명',
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.schedule,
                    label: '이번 달',
                    color: Colors.green,
                  ),
                ],
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddWorkplaceDialog() {
    Get.dialog(AddWorkplaceDialog());
  }

  void _handleMenuSelection(String value, String workplaceId) {
    switch (value) {
      case 'edit':
        _showEditWorkplaceDialog(workplaceId);
        break;
      case 'delete':
        _showDeleteConfirmDialog(workplaceId);
        break;
    }
  }

  void _showEditWorkplaceDialog(String workplaceId) {
    final workplace = controller.workplaces.firstWhere((w) => w.id == workplaceId);
    final TextEditingController nameController = TextEditingController(text: workplace.name);

    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('사업장 이름 수정'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: '사업장 이름',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  Navigator.of(context).pop(); // Get.back() 대신 사용
                  await Future.delayed(const Duration(milliseconds: 200));
                  await controller.updateWorkplaceName(workplaceId, newName);
                }
              },
              child: const Text('수정'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmDialog(String workplaceId) {
    final workplace = controller.workplaces.firstWhere((w) => w.id == workplaceId);

    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('사업장 삭제'),
          content: Text('\'${workplace.name}\' 사업장을 삭제하시겠습니까?\n삭제된 데이터는 복구할 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Get.back() 대신 사용
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
        );
      },
    );
  }
}