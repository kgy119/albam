import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_theme.dart';
import '../../controllers/workplace_detail_controller.dart';
import '../../../app/routes/app_routes.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/snackbar_helper.dart'; // ✅ 추가

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
                MediaQuery.of(context).padding.bottom
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

          if (result != null && result['success'] == true) {
            print('직원 추가 성공 - 목록 새로고침 및 스낵바 표시');

            await controller.loadEmployees();

            // ✅ Get.snackbar → SnackbarHelper로 변경
            SnackbarHelper.showSuccess(
              '${result['employeeName']} 직원이 성공적으로 등록되었습니다.',
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
      child: InkWell(
        onTap: () => _showSalaryDialog(employee),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryLightColor,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        employee.name.isNotEmpty ? employee.name[0] : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _makePhoneCall(employee.phoneNumber),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 14,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                employee.phoneNumber,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_horiz),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 10),
                            Text('정보 수정'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'salary',
                        child: Row(
                          children: [
                            Icon(Icons.account_balance_wallet_outlined, size: 18),
                            SizedBox(width: 10),
                            Text('급여 조회'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            SizedBox(width: 10),
                            Text('삭제', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.payments_outlined,
                            size: 18,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '시급 ',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${currencyFormatter.format(employee.hourlyWage)}원',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              if (employee.contractImageUrl != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 14,
                      color: AppTheme.successColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '근로계약서 첨부됨',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll('-', '');
    final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _copyPhoneNumber(phoneNumber);
      }
    } catch (e) {
      _copyPhoneNumber(phoneNumber);
    }
  }

  void _copyPhoneNumber(String phoneNumber) {
    Clipboard.setData(ClipboardData(text: phoneNumber));
    SnackbarHelper.showCopied('전화번호가 복사되었습니다.'); // ✅ 수정
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
    final latestEmployee = await controller.getLatestEmployeeInfo(employee.id);

    if (latestEmployee == null) {
      SnackbarHelper.showError('직원 정보를 불러올 수 없습니다.'); // ✅ 수정
      return;
    }

    final result = await Get.toNamed(
      '/edit-employee',
      arguments: latestEmployee,
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