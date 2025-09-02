import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
        ],
      ),
      body: Column(
        children: [
          // 월/년 선택 헤더
          _buildMonthHeader(),

          // 달력
          Expanded(
            child: _buildCalendar(),
          ),
        ],
      ),
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

      return GestureDetector(
        onTap: () {
          // TODO: 해당 날짜의 스케줄 설정 페이지로 이동
          Get.toNamed(
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
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(Get.context!).primaryColor
                : isToday
                ? Theme.of(Get.context!).primaryColor.withOpacity(0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
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
                      : Colors.black87,
                ),
              ),

              // TODO: 해당 날짜의 총 근무시간 표시
              const SizedBox(height: 2),
              Text(
                '8h', // 임시 데이터
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected || isToday
                      ? Colors.white70
                      : Colors.grey[600],
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