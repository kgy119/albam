import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
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
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoadingEmployees.value) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (controller.employees.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).padding.bottom // FloatingActionButton 공간 확보
            ),
            itemCount: controller.employees.length,
            itemBuilder: (context, index) {
              final employee = controller.employees[index];
              return _buildEmployeeCard(employee);
            },
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Get.toNamed(
            AppRoutes.addEmployee,
            arguments: {
              'workplace': controller.workplace,
              'existingEmployees': controller.employees.toList(),
            },
          );

          // 직원 추가 성공시 처리
          if (result != null && result['success'] == true) {
            print('직원 추가 성공 - 목록 새로고침 및 스낵바 표시');

            // 목록 새로고침
            await controller.loadEmployees();

            // 성공 스낵바 표시
            Get.snackbar(
              '완료',
              '${result['employeeName']} 직원이 성공적으로 등록되었습니다.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
              margin: const EdgeInsets.all(10),
            );
          }
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
                      InkWell(
                        onTap: () => _makePhoneCall(employee.phoneNumber),
                        onLongPress: () => _copyPhoneNumber(employee.phoneNumber),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.phone,
                              size: 14,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              employee.phoneNumber,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue[700],
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditDialog(employee);
                    } else if (value == 'delete') {
                      _showDeleteDialog(employee);
                    } else if (value == 'salary') {
                      _showSalaryDialog(employee);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('정보 수정'),
                        ],
                      ),
                    ),
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

  // 전화 걸기
  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll('-', '');
    final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        // 전화 걸기가 안 되면 자동으로 복사
        _copyPhoneNumber(phoneNumber);
      }
    } catch (e) {
      // 오류 발생시 복사로 대체
      _copyPhoneNumber(phoneNumber);
    }
  }

// 전화번호 복사
  void _copyPhoneNumber(String phoneNumber) {
    Clipboard.setData(ClipboardData(text: phoneNumber));
    Get.snackbar(
      '복사완료',
      '전화번호가 복사되었습니다.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.green,
      colorText: Colors.white,
      margin: const EdgeInsets.all(10),
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

  void _showEditDialog(employee) async {
    // ⭐ 최신 직원 정보 다시 가져오기
    final latestEmployee = await controller.getLatestEmployeeInfo(employee.id);

    if (latestEmployee == null) {
      Get.snackbar('오류', '직원 정보를 불러올 수 없습니다.');
      return;
    }

    final result = await Get.toNamed(
      '/edit-employee',
      arguments: latestEmployee, // ⭐ 최신 정보 전달
    );

    if (result == true) {
      await controller.loadEmployees();
    }
  }

  void _showSalaryDialog(employee) {
    final now = DateTime.now();
    int selectedYear = now.year;
    int selectedMonth = now.month;

    Get.dialog(
      AlertDialog(
        title: Text('${employee.name} 급여 조회'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 년도 선택
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: '년도',
                border: OutlineInputBorder(),
              ),
              value: selectedYear,
              items: List.generate(5, (index) {
                final year = now.year - 2 + index;
                return DropdownMenuItem(
                  value: year,
                  child: Text('$year년'),
                );
              }),
              onChanged: (value) {
                selectedYear = value!;
              },
            ),
            const SizedBox(height: 16),

            // 월 선택
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: '월',
                border: OutlineInputBorder(),
              ),
              value: selectedMonth,
              items: List.generate(12, (index) {
                final month = index + 1;
                return DropdownMenuItem(
                  value: month,
                  child: Text('$month월'),
                );
              }),
              onChanged: (value) {
                selectedMonth = value!;
              },
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
              Get.toNamed(
                AppRoutes.salaryView,
                arguments: {
                  'employee': employee,
                  'year': selectedYear,
                  'month': selectedMonth,
                },
              );
            },
            child: const Text('조회'),
          ),
        ],
      ),
    );
  }
}