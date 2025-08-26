import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/workplace_controller.dart';
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
            onPressed: () async {
              await authService.signOut();
              Get.offAllNamed(AppRoutes.login);
            },
          ),
        ],
      ),
      body: Center(
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 사업장 추가 페이지로 이동
          Get.snackbar('알림', '사업장 추가 기능은 다음 단계에서 구현됩니다.');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}