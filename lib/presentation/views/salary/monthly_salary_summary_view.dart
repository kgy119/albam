import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/monthly_salary_summary_controller.dart';
import '../../../app/routes/app_routes.dart';

class MonthlySalarySummaryView extends GetView<MonthlySalarySummaryController> {
  const MonthlySalarySummaryView({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'ko_KR', symbol: '');

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
          '${controller.workplace.value?.name ?? ""} ${controller.year.value}년 ${controller.month.value}월 급여',
        )),
        actions: [
          // 월 선택 버튼
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => controller.showMonthPicker(),
            tooltip: '월 선택',
          ),
        ],
      ),
        body: SafeArea(  // SafeArea 추가
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            final stats = controller.monthlyStats.value;
            if (stats.isEmpty) {
              return const Center(
                child: Text('이번 달 급여 데이터가 없습니다.'),
              );
            }

            final employeeSalaries = stats['employeeSalaries'] as List<Map<String, dynamic>>;

            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16, // 하단 패딩 추가
              ),
              child: Column(
                children: [
                  // 전체 통계 요약
                  _buildTotalSummaryCard(stats, currencyFormat),

                  const SizedBox(height: 8),

                  // 직원별 급여 목록
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: employeeSalaries.length,
                    itemBuilder: (context, index) {
                      final item = employeeSalaries[index];
                      return _buildEmployeeSalaryCard(
                        item,
                        currencyFormat,
                        controller.year.value,
                        controller.month.value,
                      );
                    },
                  ),
                ],
              ),
            );
          }),
        ),
    );
  }

  Widget _buildTotalSummaryCard(Map<String, dynamic> stats, NumberFormat currencyFormat) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(Get.context!).primaryColor,
            Theme.of(Get.context!).primaryColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(Get.context!).primaryColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '전체 급여 요약',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          // 총 실수령액
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '총 실수령액',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${currencyFormat.format(stats['totalNetPay'])}원',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 상세 정보
          _buildSummaryRow('직원 수', '${stats['employeeCount']}명', currencyFormat),
          const Divider(color: Colors.white30, height: 20),
          _buildSummaryRow('총 근무시간', '${stats['totalHours'].toStringAsFixed(1)}시간', currencyFormat),
          _buildSummaryRow('  ∙ 정규근무', '${stats['totalRegularHours'].toStringAsFixed(1)}시간', currencyFormat, indent: true),
          _buildSummaryRow('  ∙ 대체근무', '${stats['totalSubstituteHours'].toStringAsFixed(1)}시간', currencyFormat, indent: true),
          const Divider(color: Colors.white30, height: 20),
          _buildSummaryRow('기본급', '${currencyFormat.format(stats['totalBasicPay'])}원', currencyFormat),
          _buildSummaryRow('주휴수당', '${currencyFormat.format(stats['totalWeeklyHolidayPay'])}원', currencyFormat),
          _buildSummaryRow('세금(3.3%)', '-${currencyFormat.format(stats['totalTax'])}원', currencyFormat),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, NumberFormat format, {bool indent = false}) {
    return Padding(
      padding: EdgeInsets.only(left: indent ? 16 : 0, top: 4, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: indent ? 13 : 14,
              color: indent ? Colors.white70 : Colors.white,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: indent ? 13 : 14,
              fontWeight: indent ? FontWeight.normal : FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeSalaryCard(
      Map<String, dynamic> item,
      NumberFormat currencyFormat,
      int year,
      int month,
      ) {
    final employee = item['employee'];
    final salaryData = item['salaryData'] as Map<String, dynamic>;
    final workDays = item['workDays'] as int;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // 상세 급여 페이지로 이동
          Get.toNamed(
            AppRoutes.salaryView,
            arguments: {
              'employee': employee,
              'year': year,
              'month': month,
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
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
                          '시급 ${currencyFormat.format(employee.hourlyWage)}원',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${currencyFormat.format(salaryData['netPay'])}원',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(Get.context!).primaryColor,
                        ),
                      ),
                      Text(
                        '실수령액',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),

              // 계좌번호 정보 추가
              if (employee.bankName != null && employee.accountNumber != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${employee.bankName} ${employee.accountNumber}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                      // 복사 버튼
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: employee.accountNumber!));
                          Get.snackbar(
                            '복사완료',
                            '${employee.name}님의 계좌번호가 복사되었습니다.',
                            snackPosition: SnackPosition.BOTTOM,
                            duration: const Duration(seconds: 2),
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                            margin: const EdgeInsets.all(10),
                          );
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.copy,
                            size: 16,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    '${salaryData['totalHours'].toStringAsFixed(1)}시간',
                    Icons.access_time,
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    '$workDays일',
                    Icons.calendar_today,
                    Colors.green,
                  ),
                  const SizedBox(width: 8),
                  if (salaryData['substituteHours'] > 0)
                    _buildInfoChip(
                      '대체 ${salaryData['substituteHours'].toStringAsFixed(1)}h',
                      Icons.swap_horiz,
                      Colors.orange,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}