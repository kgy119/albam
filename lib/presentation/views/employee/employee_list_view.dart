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

    return DefaultTabController( // ✅ 추가
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${controller.workplace.name} 직원 관리'),
          bottom: TabBar(
            tabs: [
              Tab(
                child: Obx(() => Text('재직중 (${controller.employees.length})')),
              ),
              Tab(
                child: Obx(() => Text('퇴사자 (${controller.resignedEmployees.length})')),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView( // ✅ 기존 body를 TabBarView로 변경
            children: [
              _buildActiveEmployeeList(limitService), // 재직중
              _buildResignedEmployeeList(), // 퇴사자
            ],
          ),
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

            print('🔄 직원 추가 화면에서 복귀 - 구독 정보 새로고침');
            final limitService = Get.find<SubscriptionLimitService>();
            await limitService.getUserSubscriptionLimits();

            if (result != null && result['success'] == true) {
              await controller.loadEmployees();
              SnackbarHelper.showSuccess(
                '${result['employeeName']} 직원이 성공적으로 등록되었습니다.',
              );
            }
          },
          child: const Icon(Icons.person_add),
        ),
      ),
    );
  }

// ✅ 재직중 직원 목록
  Widget _buildActiveEmployeeList(SubscriptionLimitService limitService) {
    return Obx(() {
      if (limitService.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final isPremium = limitService.currentLimits.value?.isPremium ?? false;

      if (controller.isLoadingEmployees.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.employees.isEmpty) {
        return _buildEmptyState('재직중인 직원이 없습니다');
      }

      return ListView.builder(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(Get.context!).padding.bottom + 80,
        ),
        itemCount: controller.employees.length,
        itemBuilder: (context, index) {
          final employee = controller.employees[index];
          final isLocked = !isPremium && index >= 3;
          return _buildEmployeeCard(employee, isLocked, isActive: true);
        },
      );
    });
  }

// ✅ 퇴사 직원 목록
  Widget _buildResignedEmployeeList() {
    return Obx(() {
      if (controller.isLoadingResignedEmployees.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.resignedEmployees.isEmpty) {
        return _buildEmptyState('퇴사한 직원이 없습니다');
      }

      return ListView.builder(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(Get.context!).padding.bottom + 80,
        ),
        itemCount: controller.resignedEmployees.length,
        itemBuilder: (context, index) {
          final employee = controller.resignedEmployees[index];
          return _buildEmployeeCard(employee, false, isActive: false);
        },
      );
    });
  }

  Widget _buildEmptyState(String message) {
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
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEmployeeCard(employee, bool isLocked, {required bool isActive}) {
    final currencyFormatter = NumberFormat.currency(locale: 'ko_KR', symbol: '');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          InkWell(
            onTap: isLocked
                ? () => _showUpgradeDialog(employee: employee)
                : isActive
                ? () {
              Get.toNamed(
                AppRoutes.editEmployee,
                arguments: {
                  'employee': employee,
                  'workplace': controller.workplace,
                },
              );
            }
                : null, // 퇴사자는 수정 불가
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
                        colors: isActive
                            ? [AppTheme.primaryColor, AppTheme.primaryLightColor]
                            : [Colors.grey.shade400, Colors.grey.shade300],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        employee.name.isNotEmpty ? employee.name[0] : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 직원 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              employee.name,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isActive ? Colors.black : Colors.grey,
                              ),
                            ),
                            if (!isActive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '퇴사',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              employee.phoneNumber,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.payment, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '시급 ${currencyFormatter.format(employee.hourlyWage)}원',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        if (!isActive && employee.resignedAt != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.event, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                '퇴사일: ${DateFormat('yyyy-MM-dd').format(employee.resignedAt!)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 팝업 메뉴
                  if (!isLocked)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'call') {
                          _makePhoneCall(employee.phoneNumber);
                        } else if (value == 'edit') {
                          _showEditDialog(employee);
                        } else if (value == 'resign') {
                          _showResignDialog(employee);
                        } else if (value == 'rehire') {
                          _showRehireDialog(employee);
                        } else if (value == 'delete') {
                          _showDeleteDialog(employee, isActive: isActive);
                        } else if (value == 'salary') {
                          _showSalaryDialog(employee);
                        }
                      },
                      itemBuilder: (context) => isActive
                          ? [
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
                          value: 'call',
                          child: Row(
                            children: [
                              Icon(Icons.phone, size: 18),
                              SizedBox(width: 10),
                              Text('전화 걸기'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'resign',
                          child: Row(
                            children: [
                              Icon(Icons.exit_to_app, size: 18, color: Colors.orange),
                              SizedBox(width: 10),
                              Text('퇴사 처리', style: TextStyle(color: Colors.orange)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_forever, size: 18, color: Colors.red),
                              SizedBox(width: 10),
                              Text('완전 삭제', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ]
                          : [
                        const PopupMenuItem(
                          value: 'rehire',
                          child: Row(
                            children: [
                              Icon(Icons.restart_alt, size: 18, color: Colors.green),
                              SizedBox(width: 10),
                              Text('복직', style: TextStyle(color: Colors.green)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_forever, size: 18, color: Colors.red),
                              SizedBox(width: 10),
                              Text('완전 삭제', style: TextStyle(color: Colors.red)),
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
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, color: Colors.white, size: 36),
                          SizedBox(height: 8),
                          Text(
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

  // ✅ 퇴사 다이얼로그
  void _showResignDialog(employee) {
    Get.dialog(
      AlertDialog(
        title: const Text('퇴사 처리'),
        content: Text(
          '${employee.name} 직원을 퇴사 처리하시겠습니까?\n\n'
              '퇴사 처리 시:\n'
              '• 직원 정보와 근무 기록은 보존됩니다\n'
              '• 스케줄 등록 목록에서 제외됩니다\n'
              '• 나중에 복직 처리가 가능합니다',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.resignEmployee(employee.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('퇴사 처리'),
          ),
        ],
      ),
    );
  }

// ✅ 복직 다이얼로그
  void _showRehireDialog(employee) {
    Get.dialog(
      AlertDialog(
        title: const Text('복직 처리'),
        content: Text('${employee.name} 직원을 복직 처리하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.rehireEmployee(employee.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('복직'),
          ),
        ],
      ),
    );
  }

// ✅ 완전 삭제 다이얼로그 (기존 수정)
  void _showDeleteDialog(employee, {required bool isActive}) {
    Get.dialog(
      AlertDialog(
        title: const Text('완전 삭제'),
        content: Text(
          '${employee.name} 직원을 완전히 삭제하시겠습니까?\n\n'
              '⚠️ 주의:\n'
              '• 직원의 모든 정보가 삭제됩니다\n'
              '• 근무 기록도 모두 삭제됩니다\n'
              '• 이 작업은 되돌릴 수 없습니다',
        ),
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
            child: const Text('완전 삭제'),
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

  void _showEditDialog(employee) async {
    final latestEmployee = await controller.getLatestEmployeeInfo(employee.id);
    if (latestEmployee == null) {
      SnackbarHelper.showError('직원 정보를 불러올 수 없습니다.');
      return;
    }

    final result = await Get.toNamed(
      AppRoutes.editEmployee,
      arguments: {
        'employee': latestEmployee,
      },
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

        actions: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              // ✅ 퇴사 처리 버튼
              if (employee != null)
                OutlinedButton(
                  onPressed: () {
                    Get.back();
                    _showResignDialog(employee);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    minimumSize: const Size(72, 44),
                  ),
                  child: const Text('퇴사'),
                ),

              // ✅ 완전 삭제 버튼
              if (employee != null)
                OutlinedButton(
                  onPressed: () {
                    Get.back();
                    _showDeleteDialog(employee, isActive: true);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    minimumSize: const Size(72, 44),
                  ),
                  child: const Text('삭제'),
                ),

              // 취소 버튼
              OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(72, 44),
                ),
                child: const Text('취소'),
              ),

              // 구독하기 버튼
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  Get.toNamed(AppRoutes.premiumDetail);
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