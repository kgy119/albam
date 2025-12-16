import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_theme.dart';
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
      body: SafeArea(
        child: Column(
          children: [
            // 월/년 선택 헤더 (고정)
            _buildMonthHeader(),

            // 달력 + 월별 통계 (스크롤 가능)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 달력
                    _buildCalendarSection(),

                    // 월별 통계 카드
                    _buildMonthlyStatsCard(),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            ),
          ),

          Obx(() {
            final date = controller.selectedDate.value;
            return GestureDetector(
              onTap: _showMonthYearPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${date.year}년 ${date.month}월',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.calendar_month,
                      size: 20,
                      color: AppTheme.primaryColor,
                    ),
                  ],
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
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  /// 요일 헤더
  Widget _buildWeekHeader() {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];

    return Row(
      children: weekdays.map((day) => Expanded(
        child: Center(
          child: Text(
            day,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: day == '일' ? Colors.red :
              day == '토' ? Colors.blue : Colors.grey[700],
            ),
          ),
        ),
      )).toList(),
    );
  }

  /// 달력 섹션
  Widget _buildCalendarSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 요일 헤더
          _buildWeekHeader(),
          const SizedBox(height: 8),

          // 달력 그리드
          Obx(() {
            final daysInMonth = controller.getDaysInMonth();
            final firstDayOfWeek = controller.getFirstDayOfWeek();

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: 42, // 6주 * 7일
              itemBuilder: (context, index) {
                // 일요일 시작 (0: 일요일, 1: 월요일, ..., 6: 토요일)
                final day = index - firstDayOfWeek + 1;

                if (day <= 0 || day > daysInMonth) {
                  return Container();
                }

                return _buildCalendarDay(day);
              },
            );
          }),
        ],
      ),
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
          controller.loadMonthlySchedules();
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor
                : isToday
                ? AppTheme.primaryColor.withOpacity(0.15)
                : hasSchedule
                ? AppTheme.successColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasSchedule
                  ? AppTheme.successColor
                  : isToday
                  ? AppTheme.primaryColor
                  : Colors.grey[300]!,
              width: hasSchedule || isToday ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isSelected
                      ? Colors.white
                      : isToday
                      ? AppTheme.primaryColor
                      : hasSchedule
                      ? AppTheme.successColor
                      : Colors.black87,
                ),
              ),

              const SizedBox(height: 2),
              if (hasSchedule)
                Text(
                  '${dayTotalHours.toStringAsFixed(1)}h',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white.withOpacity(0.9)
                        : AppTheme.successColor,
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildMonthlyStatsCard() {
    return Obx(() {
      if (controller.isLoadingStats.value) {
        return Container(
          padding: const EdgeInsets.all(40),
          child: const Center(child: CircularProgressIndicator()),
        );
      }

      final stats = controller.monthlyStats.value;
      if (stats.isEmpty) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Icon(
                Icons.bar_chart_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                '이번 달 근무 기록이 없습니다',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }

      final currencyFormat = NumberFormat.currency(locale: 'ko_KR', symbol: '');

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 년월 표시 (폰트 색상 다르게)
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${controller.selectedDate.value.year}년 ',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text: '${controller.selectedDate.value.month}월 ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text: '요약',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '${stats['employeeCount']}명',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 총 실수령액
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '총 실수령액',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${currencyFormat.format(stats['totalNetPay'])}원',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2x2 그리드 통계
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    '총 근무시간',
                    '${stats['totalHours'].toStringAsFixed(1)}h',
                    Icons.access_time,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniStat(
                    '근무일수',
                    '${stats['totalWorkDays']}일',
                    Icons.calendar_today,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    '기본급',
                    '${currencyFormat.format(stats['totalBasicPay'])}원',
                    Icons.monetization_on,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniStat(
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

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
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
                    itemCount: 10,
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