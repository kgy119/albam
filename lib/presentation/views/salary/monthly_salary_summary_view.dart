import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/snackbar_helper.dart';
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
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            // 오른쪽으로 스와이프 (이전 달)
            if (details.primaryVelocity! > 0) {
              controller.goToPreviousMonth();
            }
            // 왼쪽으로 스와이프 (다음 달)
            else if (details.primaryVelocity! < 0) {
              controller.goToNextMonth();
            }
          },
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            final stats = controller.monthlyStats.value;
            if (stats.isEmpty) {
              return _buildEmptyState();
            }

            final employeeSalaries = stats['employeeSalaries'] as List<Map<String, dynamic>>;

            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Column(
                children: [
                  // 스와이프 안내
                  _buildSwipeHint(),

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
                      );
                    },
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSwipeHint() {
    return Obx(() => Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          // 이전 달 버튼
          InkWell(
            onTap: controller.goToPreviousMonth,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.chevron_left,
                color: Colors.blue[700],
                size: 28,
              ),
            ),
          ),

          // 년월 표시
          Expanded(
            child: Column(
              children: [
                Text(
                  '${controller.year.value}년 ${controller.month.value}월',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.swipe, size: 12, color: Colors.blue[600]),
                    const SizedBox(width: 4),
                    Text(
                      '좌우 스와이프',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 다음 달 버튼
          InkWell(
            onTap: controller.goToNextMonth,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.chevron_right,
                color: Colors.blue[700],
                size: 28,
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            '이번 달 급여 데이터가 없습니다.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '좌우로 스와이프하여 다른 달을 확인하세요',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
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

  Widget _buildEmployeeSalaryCard(Map<String, dynamic> employeeSalary, NumberFormat currencyFormat) {
    final employee = employeeSalary['employee'];
    final salaryData = employeeSalary['salaryData'];
    final workDays = employeeSalary['workDays'];
    final paymentRecord = employeeSalary['paymentRecord']; // ✅ 추가

    // ✅ 지급 완료 여부에 따른 스타일
    final isPaid = paymentRecord != null;
    final textColor = isPaid ? Colors.grey[600] : Colors.black;
    final amountColor = isPaid ? Colors.grey[600] : AppTheme.primaryColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async { // ✅ async 추가
          final result = await Get.toNamed( // ✅ await 추가
            AppRoutes.salaryView,
            arguments: {
              'employee': employee,
              'year': controller.year.value,
              'month': controller.month.value,
            },
          );

          // ✅ 지급 상태가 변경되었으면 새로고침
          if (result == true) {
            controller.loadMonthlySalaries();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
        padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 아바타
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isPaid // ✅ 지급 완료 시 회색
                            ? [Colors.grey[400]!, Colors.grey[300]!]
                            : [AppTheme.primaryColor, AppTheme.primaryLightColor],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        employee.name.isNotEmpty ? employee.name[0] : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 직원 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                employee.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor, // ✅ 지급 완료 시 회색
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // ✅ 지급 완료 표시
                            if (isPaid) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green[300]!),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 12,
                                      color: Colors.green[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '지급완료',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '근무 ${workDays}일 • ${salaryData['totalHours'].toStringAsFixed(1)}시간',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        // ✅ 지급일시 표시
                        if (isPaid) ...[
                          const SizedBox(height: 2),
                          Text(
                            '지급: ${DateFormat('MM/dd HH:mm').format(paymentRecord.paidAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // 급여 상세
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '기본급',
                    style: TextStyle(fontSize: 13, color: textColor), // ✅ 회색
                  ),
                  Text(
                    '${currencyFormat.format(salaryData['basicPay'])}원',
                    style: TextStyle(fontSize: 13, color: textColor), // ✅ 회색
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '주휴수당',
                    style: TextStyle(fontSize: 13, color: textColor), // ✅ 회색
                  ),
                  Text(
                    '${currencyFormat.format(salaryData['weeklyHolidayPay'])}원',
                    style: TextStyle(fontSize: 13, color: textColor), // ✅ 회색
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '세금 (3.3%)',
                    style: TextStyle(fontSize: 13, color: textColor), // ✅ 회색
                  ),
                  Text(
                    '-${currencyFormat.format(salaryData['tax'])}원',
                    style: TextStyle(fontSize: 13, color: textColor), // ✅ 회색
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // 실수령액
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '실수령액',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor, // ✅ 회색
                    ),
                  ),
                  Text(
                    '${currencyFormat.format(salaryData['netPay'])}원',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: amountColor, // ✅ 지급 완료 시 회색
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}