import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../controllers/salary_controller.dart';
import '../../../data/models/employee_model.dart';

class SalaryView extends GetView<SalaryController> {
  const SalaryView({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Controller에서 값 가져오기 (arguments 직접 읽지 않기)
    final employee = controller.currentEmployee.value;
    final year = controller.currentYear;
    final month = controller.currentMonth;

    if (employee == null || year == null || month == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('급여 정보')),
        body: const Center(child: Text('잘못된 접근입니다.')),
      );
    }

    final currencyFormat = NumberFormat.currency(locale: 'ko_KR', symbol: '');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // ✅ hasPaymentStatusChanged() 사용
          Get.back(result: controller.hasPaymentStatusChanged());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${employee.name} - $year년 $month월 급여'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // ✅ hasPaymentStatusChanged() 사용
              Get.back(result: controller.hasPaymentStatusChanged());
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Get.toNamed(
                  AppRoutes.editEmployee,
                  arguments: employee,
                );

                // ✅ result가 true일 때만 재계산 (Employee 객체가 아님)
                if (result == true) {
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
                  _buildEmployeeInfoCard(employee, currencyFormat),
                  const SizedBox(height: 16),
                  _buildCalendarCard(year, month, context),
                  const SizedBox(height: 16),
                  _buildWorkHoursCard(salaryData, context),
                  const SizedBox(height: 16),
                  _buildSalaryCard(salaryData, currencyFormat, context),
                  const SizedBox(height: 16),
                  if (salaryData['weeklyBreakdown'] != null)
                    _buildWeeklyBreakdownCard(salaryData),
                  const SizedBox(height: 16),
                  _buildInfoBox(),
                ],
              ),
            );
          }),
        ),
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
                      // ✅ controller에서 year, month 가져오기
                      await controller.calculateEmployeeSalary(
                        employee: employee,
                        year: controller.currentYear!,
                        month: controller.currentMonth!,
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
            InkWell(
              onTap: () => _makePhoneCall(employee.phoneNumber),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('전화번호'),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        employee.phoneNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.call,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            _buildInfoRow(
              '시급',
              '${currencyFormat.format(employee.hourlyWage)}원',
            ),
            const SizedBox(height: 8),
            if (employee.bankName != null && employee.accountNumber != null) ...[
              const SizedBox(height: 8),
              Column( // ✅ Row 대신 Column 사용
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '계좌번호',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: employee.accountNumber!));
                      SnackbarHelper.showCopied('계좌번호가 클립보드에 복사되었습니다.');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible( // ✅ Flexible로 감싸기
                            child: Text(
                              '${employee.bankName} ${employee.accountNumber}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                              overflow: TextOverflow.ellipsis, // ✅ 오버플로우 처리
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

            // 달력 그리드 - 화면 너비에 맞춰 자동 조정
            _buildCalendarGrid(year, month),

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
        childAspectRatio: 0.9, // 적절한 비율로 조정
        crossAxisSpacing: 2, // 간격 줄임
        mainAxisSpacing: 2, // 간격 줄임
      ),
      itemCount: 42,
      itemBuilder: (context, index) {
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

  Widget _buildSalaryCard(Map<String, dynamic> salaryData, NumberFormat currencyFormat, BuildContext context) {
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

            _buildSalaryRow('기본급', '${currencyFormat.format(salaryData['basicPay'])}원'),
            const Divider(height: 20),
            _buildSalaryRow('주휴수당', '${currencyFormat.format(salaryData['weeklyHolidayPay'])}원'),
            const Divider(height: 20),
            _buildSalaryRow(
              '총 급여',
              '${currencyFormat.format(salaryData['totalPay'])}원',
              isTotal: true,
            ),
            const Divider(height: 20),
            _buildSalaryRow(
              '세금 (3.3%)',
              '-${currencyFormat.format(salaryData['tax'])}원',
              isNegative: true,
            ),
            const Divider(height: 20),
            _buildSalaryRow(
              '실수령액',
              '${currencyFormat.format(salaryData['netPay'])}원',
              isFinal: true,
            ),

            // ✅ 급여 지급 버튼 추가
            const SizedBox(height: 24),
            Obx(() {
              final paymentRecord = controller.paymentRecord.value;

              if (paymentRecord != null) {
                // 지급 완료 상태
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700], size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '지급 완료',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '지급일시: ${DateFormat('yyyy-MM-dd HH:mm').format(paymentRecord.paidAt)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  '지급액: ${currencyFormat.format(paymentRecord.amount)}원',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('지급 취소'),
                                content: const Text('급여 지급을 취소하시겠습니까?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(),
                                    child: const Text('아니오'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop();
                                      controller.cancelPayment();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text('취소'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.cancel),
                          label: const Text('지급 취소'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.red[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                // 지급 전 상태
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: controller.isLoading.value
                        ? null
                        : () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('급여 지급'),
                          content: Text(
                            '${currencyFormat.format(salaryData['netPay'])}원을 지급 처리하시겠습니까?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: const Text('취소'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                controller.recordPayment();
                              },
                              child: const Text('지급'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.payment),
                    label: const Text('급여 지급'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                );
              }
            }),
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


  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll('-', '');
    final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        Clipboard.setData(ClipboardData(text: phoneNumber));
        SnackbarHelper.showCopied('전화번호가 복사되었습니다.');
      }
    } catch (e) {
      Clipboard.setData(ClipboardData(text: phoneNumber));
      SnackbarHelper.showCopied('전화번호가 복사되었습니다.');
    }
  }

  Widget _buildSalaryRow(String label, String value, {bool isTotal = false, bool isNegative = false, bool isFinal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isFinal ? 16 : 14,
            fontWeight: isFinal || isTotal ? FontWeight.bold : FontWeight.normal,
            color: isNegative ? Colors.red[700] : (isFinal ? Colors.black : Colors.grey[700]),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isFinal ? 18 : 14,
            fontWeight: isFinal || isTotal ? FontWeight.bold : FontWeight.w500,
            color: isNegative
                ? Colors.red[700]
                : (isFinal ? Theme.of(Get.context!).primaryColor : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
      String label,
      String value, {
        Color? valueColor,
        double? fontSize,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize ?? 14,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: fontSize ?? 14,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}