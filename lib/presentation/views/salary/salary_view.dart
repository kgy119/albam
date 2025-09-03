import 'package:flutter/material.dart';
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

    // 컨트롤러 초기화
    controller.calculateEmployeeSalary(
      employee: employee,
      year: year,
      month: month,
    );

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
                        '주휴 적용시간',
                        '${salaryData['weeklyHolidayHours'].toStringAsFixed(1)} 시간',
                        valueColor: Colors.green,
                      ),
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
                      const Divider(height: 24, thickness: 2),
                      _buildInfoRow(
                        '총 급여',
                        '${currencyFormat.format(salaryData['totalPay'])}원',
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
                          '주별 근무 내역',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
                        '일용직 급여 계산\n• 기본급: 시급 × 근무시간\n• 주휴수당: 주 15시간 이상 근무 시 지급',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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