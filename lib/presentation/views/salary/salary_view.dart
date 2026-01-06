import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../controllers/salary_controller.dart';
import '../../../data/models/employee_model.dart';

class SalaryView extends GetView<SalaryController> {
  const SalaryView({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = Get.arguments as Map<String, dynamic>;
    final employee = arguments['employee'] as Employee;
    final year = arguments['year'] as int;
    final month = arguments['month'] as int;

    final currencyFormat = NumberFormat.currency(locale: 'ko_KR', symbol: '');

    return Scaffold(
      appBar: AppBar(
        title: Text('${employee.name} - $year년 $month월 급여'),
        actions: [
          // 직원 정보 수정 버튼 추가
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Get.toNamed(
                AppRoutes.editEmployee,
                arguments: employee,
              );

              // 수정 완료 후 돌아왔을 때 급여 재계산
              if (result == true) {
                // 직원 정보가 변경되었으므로 급여 다시 계산
                controller.calculateEmployeeSalary(
                  employee: employee,
                  year: year,
                  month: month,
                );
              }
            },
            tooltip: '직원 정보 수정',
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
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
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 직원 정보 카드
                _buildEmployeeInfoCard(employee, currencyFormat),
                const SizedBox(height: 16),

                // 달력 카드
                _buildCalendarCard(year, month, context),
                const SizedBox(height: 16),

                // 근무 시간 카드
                _buildWorkHoursCard(salaryData, context),
                const SizedBox(height: 16),

                // 급여 내역 카드
                _buildSalaryCard(salaryData, currencyFormat, context),
                const SizedBox(height: 16),

                // 주별 근무 내역
                if (salaryData['weeklyBreakdown'] != null)
                  _buildWeeklyBreakdownCard(salaryData),
                const SizedBox(height: 16),

                // 안내 문구
                _buildInfoBox(),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmployeeInfoCard(Employee employee, NumberFormat currencyFormat) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '직원 정보',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // 수정 버튼 추가
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Get.toNamed(
                      AppRoutes.editEmployee,
                      arguments: employee,
                    );

                    if (result == true) {
                      // 페이지 새로고침을 위해 Get.back 후 다시 진입
                      Get.snackbar(
                        '알림',
                        '직원 정보가 수정되었습니다. 변경된 시급으로 다시 계산하려면 해당 월을 다시 조회해주세요.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.orange,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 3),
                      );
                    }
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('수정'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
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
    );
  }


  Widget _buildCalendarCard(int year, int month, BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '근무 일정',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 요일 헤더
            _buildWeekHeader(),
            const SizedBox(height: 8),

            // 달력 그리드 - 높이 제한 추가
            SizedBox(
              height: 240, // 고정 높이 설정 (6주 * 40픽셀)
              child: _buildCalendarGrid(year, month),
            ),

            const SizedBox(height: 8),

            // 선택된 날짜의 상세 스케줄
            Obx(() {
              if (controller.selectedDay.value > 0) {
                return _buildSelectedDaySchedules(year, month);
              }
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.grey),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '날짜를 선택하면 상세 근무시간을 확인할 수 있습니다',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 요일 헤더 (일요일 시작)
  Widget _buildWeekHeader() {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];

    return Row(
      children: weekdays.map((day) => Expanded(
        child: Center(
          child: Text(
            day,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: day == '일' ? Colors.red :
              day == '토' ? Colors.blue : Colors.grey[600],
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildCalendarGrid(int year, int month) {
    final daysInMonth = controller.getDaysInMonth(year, month);
    final firstDayOfWeek = controller.getFirstDayOfWeek(year, month);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: 42, // 6주
      itemBuilder: (context, index) {
        // 일요일 시작 (0: 일요일, 1: 월요일, ..., 6: 토요일)
        final day = index - firstDayOfWeek + 1;

        if (day <= 0 || day > daysInMonth) {
          return Container();
        }

        return _buildCalendarDay(day, year, month);
      },
    );
  }

  Widget _buildInfoBox() {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMinWage = AppConstants.getCurrentMinimumWage();

    return Container(
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
              '일용직 급여 계산 ($currentYear년 최저시급: ${NumberFormat.currency(locale: 'ko_KR', symbol: '').format(currentMinWage)}원)\n• 기본급: 시급 × 근무시간\n• 주휴수당: 일~토 기준 주 15시간 이상 근무 시 지급 (일평균 근무시간, 최대 8시간)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDay(int day, int year, int month) {
    return Obx(() {
      final isSelected = controller.selectedDay.value == day;
      final dayTotalHours = controller.getDayTotalHours(day, year, month);
      final hasSchedule = dayTotalHours > 0;

      return GestureDetector(
        onTap: () {
          controller.selectDay(day);
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(Get.context!).primaryColor
                : hasSchedule
                ? Colors.blue[50]
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasSchedule
                  ? Theme.of(Get.context!).primaryColor
                  : Colors.grey[300]!,
              width: hasSchedule ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              // 날짜 (중앙)
              Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : hasSchedule
                        ? Theme.of(Get.context!).primaryColor
                        : Colors.black87,
                  ),
                ),
              ),
              // 근무시간 (하단)
              if (hasSchedule)
                Positioned(
                  bottom: 2,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      '${dayTotalHours.toStringAsFixed(1)}h',
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white.withOpacity(0.9)
                            : Theme.of(Get.context!).primaryColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSelectedDaySchedules(int year, int month) {
    final selectedDay = controller.selectedDay.value;
    final schedules = controller.getDaySchedules(selectedDay, year, month);

    if (schedules.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$month월 $selectedDay일: 근무 일정 없음',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    final totalHours = schedules.fold<double>(
      0,
          (sum, schedule) => sum + (schedule.totalMinutes / 60.0),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$month월 $selectedDay일 근무 상세',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(Get.context!).primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '총 ${totalHours.toStringAsFixed(1)}시간',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 시간순으로 정렬된 스케줄 표시
          ...schedules.asMap().entries.map((entry) {
            final index = entry.key;
            final schedule = entry.value;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  // 순번 표시
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.access_time, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    schedule.timeRangeString,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${schedule.workTimeString})',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue[700],
                    ),
                  ),

                  // 대체근무 표시
                  if (schedule.isSubstitute) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '대체',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWorkHoursCard(Map<String, dynamic> salaryData, BuildContext context) {
    return Card(
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
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                children: [
                  _buildInfoRow(
                    '∙ 정규근무',
                    '${salaryData['regularHours'].toStringAsFixed(1)}h (${salaryData['regularDays']}일)',
                    fontSize: 12,
                  ),
                  const SizedBox(height: 4),
                  _buildInfoRow(
                    '∙ 대체근무',
                    '${salaryData['substituteHours'].toStringAsFixed(1)}h (${salaryData['substituteDays']}일)',
                    fontSize: 12,
                    valueColor: Colors.orange,
                  ),
                ],
              ),
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
    );
  }

  Widget _buildSalaryCard(
      Map<String, dynamic> salaryData,
      NumberFormat currencyFormat,
      BuildContext context,
      ) {
    return Card(
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
    );
  }

  Widget _buildWeeklyBreakdownCard(Map<String, dynamic> salaryData) {
    final weeklyBreakdown = salaryData['weeklyBreakdown'] as Map<int, Map<String, dynamic>>;

    // 주차별로 정렬
    final sortedEntries = weeklyBreakdown.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Card(
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
            const SizedBox(height: 8),
            Text(
              '※ 일요일~토요일 기준',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedEntries.map((entry) {
              final weekNumber = entry.key;
              final hours = entry.value;
              final regularHours = (hours['regular'] as double?) ?? 0;
              final substituteHours = (hours['substitute'] as double?) ?? 0;
              final weeklyHolidayFromPrevious = (hours['weeklyHolidayFromPrevious'] as double?) ?? 0;
              final weeklyHolidayHours = (hours['weeklyHolidayHours'] as double?) ?? 0;
              final totalHours = (hours['total'] as double?) ?? 0;

              // 주휴수당 발생 여부
              final hasWeeklyHoliday = weeklyHolidayHours > 0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${weekNumber}주차',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '${totalHours.toStringAsFixed(1)} 시간',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            if (hasWeeklyHoliday) ...[
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
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 주휴수당 시간 표시
                          if (weeklyHolidayHours > 0) ...[
                            Row(
                              children: [
                                Icon(Icons.add_circle_outline, size: 14, color: Colors.green[700]),
                                const SizedBox(width: 4),
                                Text(
                                  weeklyHolidayFromPrevious > 0
                                      ? '전월 연결 주휴수당 ${weeklyHolidayHours.toStringAsFixed(1)}h'
                                      : '주휴수당 ${weeklyHolidayHours.toStringAsFixed(1)}h',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                          ],
                          // 현재 달 근무시간
                          Row(
                            children: [
                              if (regularHours > 0) ...[
                                Icon(Icons.work_outline, size: 14, color: Colors.blue[700]),
                                const SizedBox(width: 4),
                                Text(
                                  '정규 ${regularHours.toStringAsFixed(1)}h',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                              if (regularHours > 0 && substituteHours > 0)
                                const SizedBox(width: 12),
                              if (substituteHours > 0) ...[
                                Icon(Icons.swap_horiz, size: 14, color: Colors.orange[700]),
                                const SizedBox(width: 4),
                                Text(
                                  '대체 ${substituteHours.toStringAsFixed(1)}h',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
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