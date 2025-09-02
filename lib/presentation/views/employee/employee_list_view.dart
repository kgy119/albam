import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/workplace_detail_controller.dart';
import '../../../app/routes/app_routes.dart';
import 'package:intl/intl.dart';

class EmployeeListView extends GetView<WorkplaceDetailController> {
  const EmployeeListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${controller.workplace.name} 직원 관리'),
      ),
      body: Obx(() {
        if (controller.isLoadingEmployees.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (controller.employees.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.employees.length,
          itemBuilder: (context, index) {
            final employee = controller.employees[index];
            return _buildEmployeeCard(employee);
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.toNamed(AppRoutes.addEmployee, arguments: controller.workplace);
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Theme.of(Get.context!).primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            '등록된 직원이 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '새로운 직원을 추가해보세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(employee) {
    final currencyFormatter = NumberFormat.currency(locale: 'ko_KR', symbol: '');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(Get.context!).primaryColor.withOpacity(0.1),
                  child: Text(
                    employee.name.isNotEmpty ? employee.name[0] : '?',
                    style: TextStyle(
                      color: Theme.of(Get.context!).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        employee.phoneNumber,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteDialog(employee);
                    } else if (value == 'salary') {
                      // TODO: 급여 조회 페이지로 이동
                      Get.toNamed(
                        AppRoutes.salaryView,
                        arguments: {
                          'employee': employee,
                          'workplace': controller.workplace,
                        },
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'salary',
                      child: Row(
                        children: [
                          Icon(Icons.monetization_on),
                          SizedBox(width: 8),
                          Text('급여 조회'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
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

            // 시급 정보
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(Get.context!).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Theme.of(Get.context!).primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '시급 ${currencyFormatter.format(employee.hourlyWage)}원',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(Get.context!).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // 근로계약서 첨부 여부
            if (employee.contractImageUrl != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.attach_file,
                    size: 16,
                    color: Colors.green[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '근로계약서 첨부됨',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(employee) {
    Get.dialog(
      AlertDialog(
        title: const Text('직원 삭제'),
        content: Text('${employee.name} 직원을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await controller.deleteEmployee(employee.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}