import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/workplace_detail_controller.dart';
import '../../../app/routes/app_routes.dart';

class WorkplaceDetailView extends GetView<WorkplaceDetailController> {
  const WorkplaceDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.workplace.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              Get.toNamed(AppRoutes.employeeList, arguments: controller.workplace);
            },
            tooltip: '직원 관리',
          ),
          // 전체 급여 요약 버튼 추가
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              Get.toNamed(
                AppRoutes.monthlySalarySummary,
                arguments: {
                  'workplace': controller.workplace,
                  'year': controller.selectedDate.value.year,
                  'month': controller.selectedDate.value.month,
                },
              );
            },
            tooltip: '급여 요약',
          ),
        ],
      ),
      body: SafeArea(  // SafeArea 추가
        child: Column(
          children: [
            // 월/년 선택 헤더
            _buildMonthHeader(),

            // 월별 통계 카드
            _buildMonthlyStatsCard(),

            // 달력
            Expanded(
              child: _buildCalendar(),
            ),
          ],
        ),
      ),
    );
  }

  /// 월별 통계 카드
  Widget _buildMonthlyStatsCard() {
    return Obx(() {
      if (controller.isLoadingStats.value) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final stats = controller.monthlyStats.value;
      if (stats.isEmpty) {
        return const SizedBox.shrink();
      }

      final currencyFormat = NumberFormat.currency(locale: 'ko_KR', symbol: '');

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(Get.context!).primaryColor,
              Theme.of(Get.context!).primaryColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(Get.context!).primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '이번 달 통계',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '직원 ${stats['employeeCount']}명',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '총 근무시간',
                    '${stats['totalHours'].toStringAsFixed(1)}h',
                    Icons.access_time,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildStatItem(
                    '총 급여',
                    '${currencyFormat.format(stats['totalNetPay'])}원',
                    Icons.monetization_on,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '근무일수',
                    '${stats['totalWorkDays']}일',
                    Icons.calendar_today,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildStatItem(
                    '주휴수당',
                    '${currencyFormat.format(stats['totalWeeklyHolidayPay'])}원',
                    Icons.card_giftcard,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white70),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(Get.context!).primaryColor.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              final current = controller.selectedDate.value;
              final prevMonth = DateTime(current.year, current.month - 1, 1);
              controller.changeMonth(prevMonth.year, prevMonth.month);
            },
            icon: const Icon(Icons.chevron_left),
          ),

          Obx(() {
            final date = controller.selectedDate.value;
            return GestureDetector(
              onTap: _showMonthYearPicker,
              child: Text(
                '${date.year}년 ${date.month}월',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),

          IconButton(
            onPressed: () {
              final current = controller.selectedDate.value;
              final nextMonth = DateTime(current.year, current.month + 1, 1);
              controller.changeMonth(nextMonth.year, nextMonth.month);
            },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Obx(() {
      final daysInMonth = controller.getDaysInMonth();
      final firstDayOfWeek = controller.getFirstDayOfWeek();

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 요일 헤더
            _buildWeekHeader(),

            const SizedBox(height: 8),

            // 달력 그리드
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: 42, // 6주 * 7일
                itemBuilder: (context, index) {
                  final day = index - firstDayOfWeek + 2; // 월요일부터 시작하도록 조정

                  if (day <= 0 || day > daysInMonth) {
                    return Container(); // 빈 셀
                  }

                  return _buildCalendarDay(day);
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildWeekHeader() {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];

    return Row(
      children: weekdays.map((day) => Expanded(
        child: Center(
          child: Text(
            day,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: day == '일' ? Colors.red :
              day == '토' ? Colors.blue : Colors.grey[600],
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildCalendarDay(int day) {
    final isToday = DateTime.now().day == day &&
        DateTime.now().month == controller.selectedDate.value.month &&
        DateTime.now().year == controller.selectedDate.value.year;

    return Obx(() {
      final isSelected = controller.selectedDay.value == day;
      final dayTotalHours = controller.getDayTotalHours(day);
      final hasSchedule = dayTotalHours > 0;

      return GestureDetector(
        onTap: () async {
          // 스케줄 설정 화면으로 이동하고 결과를 기다림
          await Get.toNamed(
            AppRoutes.scheduleSetting,
            arguments: {
              'workplace': controller.workplace,
              'date': DateTime(
                controller.selectedDate.value.year,
                controller.selectedDate.value.month,
                day,
              ),
            },
          );

          // 돌아왔을 때 스케줄 데이터 새로고침
          controller.loadMonthlySchedules();
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(Get.context!).primaryColor
                : isToday
                ? Theme.of(Get.context!).primaryColor.withOpacity(0.3)
                : hasSchedule
                ? Colors.green.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasSchedule ? Colors.green : Colors.grey[300]!,
              width: hasSchedule ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected || isToday
                      ? Colors.white
                      : hasSchedule
                      ? Colors.green[700]
                      : Colors.black87,
                ),
              ),

              // 해당 날짜의 총 근무시간 표시
              const SizedBox(height: 2),
              if (hasSchedule)
                Text(
                  '${dayTotalHours.toStringAsFixed(1)}h',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: isSelected || isToday
                        ? Colors.white70
                        : Colors.green[600],
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  void _showMonthYearPicker() {
    showDialog(
      context: Get.context!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('월/년 선택'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: Column(
              children: [
                // 년도 선택
                Expanded(
                  child: ListView.builder(
                    itemCount: 10, // 현재 년도 기준 ±5년
                    itemBuilder: (context, index) {
                      final year = DateTime.now().year - 5 + index;
                      return ListTile(
                        title: Text('$year년'),
                        onTap: () {
                          final currentMonth = controller.selectedDate.value.month;
                          controller.changeMonth(year, currentMonth);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}