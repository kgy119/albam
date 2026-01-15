import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_theme.dart';
import '../../controllers/workplace_detail_controller.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/services/subscription_limit_service.dart';
import '../../../data/models/subscription_limits_model.dart';

class EmployeeListView extends GetView<WorkplaceDetailController> {
  const EmployeeListView({super.key});

  @override
  Widget build(BuildContext context) {
    final limitService = Get.find<SubscriptionLimitService>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${controller.workplace.name} 직원 관리'),
      ),
      body: SafeArea(
        child: Obx(() {
          // ✅ 구독 정보 로딩 중
          if (limitService.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final isPremium = limitService.currentLimits.value?.isPremium ?? false;

          // 직원 목록 로딩 중
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
              MediaQuery.of(context).padding.bottom + 80,
            ),
            itemCount: controller.employees.length,
            itemBuilder: (context, index) {
              final employee = controller.employees[index];
              final isLocked = !isPremium && index >= 3;
              return _buildEmployeeCard(employee, isLocked);
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
            await controller.loadEmployees();
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

  Widget _buildEmployeeCard(employee, bool isLocked) {
    final currencyFormatter = NumberFormat.currency(locale: 'ko_KR', symbol: '');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          InkWell(
            onTap: isLocked ? () => _showUpgradeDialog(employee: employee) : () {
              Get.toNamed(
                AppRoutes.editEmployee,
                arguments: {
                  'employee': employee,
                  'workplace': controller.workplace,
                },
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 아바타
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

                  // 정보 영역
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 이름
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                employee.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // 시급, 근로계약서
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '시급 ${currencyFormatter.format(employee.hourlyWage)}원',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (employee.contractImageUrl != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.successColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.description,
                                      size: 11,
                                      color: AppTheme.successColor,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '계약서',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.successColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),

                        // 전화번호
                        InkWell(
                          onTap: isLocked ? null : () => _makePhoneCall(employee.phoneNumber),
                          child: Row(
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 13,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  employee.phoneNumber,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.call,
                                size: 12,
                                color: AppTheme.primaryColor,
                              ),
                            ],
                          ),
                        ),

                        // 계좌번호
                        if (employee.bankName != null && employee.accountNumber != null) ...[
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: isLocked ? null : () {
                              Clipboard.setData(ClipboardData(text: employee.accountNumber!));
                              SnackbarHelper.showCopied('계좌번호가 복사되었습니다.');
                            },
                            child: Row(
                              children: [
                                Icon(
                                  Icons.account_balance,
                                  size: 13,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${employee.bankName} ${employee.accountNumber}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.copy,
                                  size: 12,
                                  color: AppTheme.primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 팝업 메뉴 (잠금 상태가 아닐 때만)
                  if (!isLocked)
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
                    onTap: () => _showUpgradeDialog(employee: employee),
                    borderRadius: BorderRadius.circular(12),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: 36,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '프리미엄 구독 필요',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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
    SnackbarHelper.showCopied('전화번호가 복사되었습니다.');
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
  }void _showEditDialog(employee) async {
    final latestEmployee = await controller.getLatestEmployeeInfo(employee.id);
    if (latestEmployee == null) {
      SnackbarHelper.showError('직원 정보를 불러올 수 없습니다.');
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
  void _showUpgradeDialog({dynamic employee}) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber[700]),
            const SizedBox(width: 8),
            const Text(
              '프리미엄 구독 필요',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('이 직원은 프리미엄 구독이 필요합니다.'),
            SizedBox(height: 12),
            Text(
              '무료 회원은 최대 3명의 직원만 활성화할 수 있습니다.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),

        /// 🔥 핵심: Row ❌ → Wrap ✅
        actions: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              if (employee != null)
                OutlinedButton(
                  onPressed: () {
                    Get.back();
                    _showDeleteDialog(employee);
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

}