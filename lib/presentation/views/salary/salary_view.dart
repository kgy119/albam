import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../controllers/salary_controller.dart';
import '../../../data/models/employee_model.dart';

class SalaryView extends GetView<SalaryController> {
  const SalaryView({super.key});

  @override
  Widget build(BuildContext context) {
    // Get.arguments로 전달받은 데이터
    final arguments = Get.arguments as Map<String, dynamic>;
    final employee = arguments['employee'] as Employee;
    final year = arguments['year'] as int;
    final month = arguments['month'] as int;

    final currencyFormat = NumberFormat.currency(locale: 'ko_KR', symbol: '');

    return Scaffold(
      appBar: AppBar(
        title: Text('${employee.name} - $year년 $month월 급여'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final salaryData = controller.salaryData.value;
        if (salaryData == null) {
          return const Center(
            child: Text('급여 정보가 없습니다.'),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 직원 정보 카드
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '직원 정보',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('이름', employee.name),
                      const SizedBox(height: 8),
                      _buildInfoRow('전화번호', employee.phoneNumber),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        '시급',
                        '${currencyFormat.format(employee.hourlyWage)}원',
                      ),
                      const SizedBox(height: 8),

                      // 계좌정보 추가
                      if (employee.bankName != null && employee.accountNumber != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('계좌번호'),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: employee.accountNumber!));
                                Get.snackbar(
                                  '복사완료',
                                  '계좌번호가 클립보드에 복사되었습니다.',
                                  snackPosition: SnackPosition.BOTTOM,
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: Colors.green,
                                  colorText: Colors.white,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${employee.bankName} ${employee.accountNumber}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.copy,
                                      size: 16,
                                      color: Colors.blue[700],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 근무 시간 카드
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '근무 시간',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        '총 근무시간',
                        '${salaryData['totalHours'].toStringAsFixed(1)} 시간',
                        valueColor: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        '정규근무',
                        '${salaryData['regularHours'].toStringAsFixed(1)} 시간',
                        valueColor: Colors.blue,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        '대체근무',
                        '${salaryData['substituteHours'].toStringAsFixed(1)} 시간',
                        valueColor: Colors.orange,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        '주휴 적용시간',
                        '${salaryData['weeklyHolidayHours'].toStringAsFixed(1)} 시간',
                        valueColor: Colors.green,
                      ),
                      const SizedBox(height: 12),

                      // 대체근무 안내
                      if (salaryData['substituteHours'] > 0) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.orange[700], size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '대체근무 시간은 주휴수당 계산에서 제외됩니다.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 급여 내역 카드
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '급여 내역',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        '기본급',
                        '${currencyFormat.format(salaryData['basicPay'])}원',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        '주휴수당',
                        '${currencyFormat.format(salaryData['weeklyHolidayPay'])}원',
                        valueColor: Colors.green,
                      ),
                      const Divider(height: 24, thickness: 1),
                      _buildInfoRow(
                        '총 급여',
                        '${currencyFormat.format(salaryData['totalPay'])}원',
                        valueColor: Theme.of(context).primaryColor,
                        isBold: true,
                        fontSize: 16,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        '세금 (3.3%)',
                        '-${currencyFormat.format(salaryData['tax'])}원',
                        valueColor: Colors.red,
                      ),
                      const Divider(height: 24, thickness: 2),
                      _buildInfoRow(
                        '실수령액',
                        '${currencyFormat.format(salaryData['netPay'])}원',
                        valueColor: Theme.of(context).primaryColor,
                        isBold: true,
                        fontSize: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 주별 근무 내역
              if (salaryData['weeklyBreakdown'] != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '주별 근무 내역 (정규근무)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '※ 대체근무는 주휴수당 계산에서 제외',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...(salaryData['weeklyBreakdown'] as Map<int, double>)
                            .entries
                            .map((entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${entry.key + 1}주차'),
                              Row(
                                children: [
                                  Text(
                                    '${entry.value.toStringAsFixed(1)} 시간',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (entry.value >= AppConstants.weeklyHolidayMinHours) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        '주휴',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ))
                            .toList(),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // 안내 문구
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '일용직 급여 계산\n• 기본급: 시급 × 전체근무시간(정규+대체)\n• 주휴수당: 정규근무만 계산, 주 15시간 이상 시 지급\n• 대체근무: 기본급에는 포함, 주휴수당에는 제외',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 추가 하단 여백 (네비게이션 바를 위한 여유 공간)
              const SizedBox(height: 30),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInfoRow(
      String label,
      String value, {
        Color? valueColor,
        bool isBold = false,
        double? fontSize,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize ?? 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize ?? 14,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}