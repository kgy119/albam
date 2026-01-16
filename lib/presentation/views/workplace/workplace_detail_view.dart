import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/services/schedule_service.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../data/models/employee_model.dart';
import '../../../data/models/schedule_model.dart';
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
          // 직원 관리 아이콘 변경
          IconButton(
            icon: const Icon(Icons.people_alt_outlined),  // 수정: people -> group_outlined
            onPressed: () {
              Get.toNamed(AppRoutes.employeeList, arguments: controller.workplace);
            },
            tooltip: '직원 관리',
          ),
          // 급여 요약 아이콘 변경
          IconButton(
            icon: const Icon(Icons.receipt_long),  // 수정: receipt_long -> account_balance_wallet_outlined
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

                  // 오늘 스케줄 섹션 (추가)
                  _buildTodayScheduleSection(),

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

  /// 오늘 스케줄 섹션
  Widget _buildTodayScheduleSection() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedMonth = DateTime(
      controller.selectedDate.value.year,
      controller.selectedDate.value.month,
      1,
    );

    // 선택된 월이 이번 달인지 확인
    if (selectedMonth.year != today.year || selectedMonth.month != today.month) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final todaySchedules = controller.getDaySchedules(now.day);

      // ✅ 스케줄이 없을 때 안내 메시지 표시
      if (todaySchedules.isEmpty) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_busy,
                  color: Colors.grey[400],
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '[오늘 ${now.day}일] 스케줄이 없습니다',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final currentTime = TimeOfDay.now();
      final currentMinutes = currentTime.hour * 60 + currentTime.minute;

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.today, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '오늘 ${now.day}일',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '스케줄 ${todaySchedules.length}개',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 스케줄 리스트
            ...todaySchedules.asMap().entries.map((entry) {
              final schedule = entry.value;

              // 현재 근무 중인지 확인
              final startMinutes = schedule.startTime.hour * 60 + schedule.startTime.minute;
              final endMinutes = schedule.endTime.hour * 60 + schedule.endTime.minute;
              final isWorkingNow = currentMinutes >= startMinutes && currentMinutes < endMinutes;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildTodayScheduleCard(schedule, isWorkingNow),
              );
            }),
          ],
        ),
      );
    });
  }

  /// 오늘 스케줄 카드
  Widget _buildTodayScheduleCard(schedule, bool isWorkingNow) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWorkingNow
              ? AppTheme.primaryColor
              : Colors.grey[300]!,
          width: isWorkingNow ? 2.5 : 1,
        ),
        boxShadow: isWorkingNow
            ? [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ]
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                // 직원 아바타
                CircleAvatar(
                  radius: 20,
                  backgroundColor: schedule.isSubstitute
                      ? Colors.orange.withOpacity(0.1)
                      : AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    schedule.employeeName.isNotEmpty ? schedule.employeeName[0] : '?',
                    style: TextStyle(
                      color: schedule.isSubstitute
                          ? Colors.orange[700]
                          : AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
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
                          Text(
                            schedule.employeeName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isWorkingNow ? AppTheme.primaryColor : Colors.grey[800],
                            ),
                          ),
                          if (schedule.isSubstitute) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '대체',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          // ✅ 메모 표시 수정
                          if (schedule.memo != null && schedule.memo!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              child: Tooltip(
                                triggerMode: TooltipTriggerMode.tap, // ⭐ 탭으로 표시
                                message: schedule.memo!,
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                textStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                preferBelow: false,
                                waitDuration: Duration.zero, // 탭이므로 대기시간 제거
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue[300]!),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.note,
                                        size: 12,
                                        color: Colors.blue[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '메모',
                                        style: TextStyle(
                                          color: Colors.blue[700],
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: isWorkingNow ? AppTheme.primaryColor : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            schedule.timeRangeString,
                            style: TextStyle(
                              fontSize: 13,
                              color: isWorkingNow ? AppTheme.primaryColor : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isWorkingNow
                                  ? AppTheme.primaryColor
                                  : Colors.grey[400],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              schedule.workTimeString,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 메뉴 버튼
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 20,
                    color: isWorkingNow ? AppTheme.primaryColor : Colors.grey[600],
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditScheduleDialog(schedule);
                    } else if (value == 'delete') {
                      _showDeleteScheduleDialog(schedule);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 10),
                          Text('수정'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 10),
                          Text('삭제', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // 시간 바 추가
            const SizedBox(height: 12),
            _buildTodayTimeBar(schedule),
          ],
        ),
      ),
    );
  }

  /// 오늘 스케줄 시간 바 (추가)
  Widget _buildTodayTimeBar(schedule) {
    final now = DateTime.now();
    final todaySchedules = controller.getDaySchedules(now.day);

    // 오늘의 모든 스케줄에서 최소/최대 시간 계산
    double minHour = 24.0;
    double maxHour = 0.0;

    for (var s in todaySchedules) {
      final startHour = s.startTime.hour + (s.startTime.minute / 60.0);
      final endHour = s.endTime.hour + (s.endTime.minute / 60.0);

      if (startHour < minHour) minHour = startHour;
      if (endHour > maxHour) maxHour = endHour;
    }

    // 현재 스케줄의 시간
    final startHour = schedule.startTime.hour + (schedule.startTime.minute / 60.0);
    final endHour = schedule.endTime.hour + (schedule.endTime.minute / 60.0);

    // 전체 범위 대비 비율 계산
    final totalRange = maxHour - minHour;
    final startRatio = totalRange > 0 ? (startHour - minHour) / totalRange : 0;
    final duration = totalRange > 0 ? (endHour - startHour) / totalRange : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        return Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              Positioned(
                left: maxWidth * startRatio,
                child: Container(
                  width: maxWidth * duration,
                  height: 8,
                  decoration: BoxDecoration(
                    color: schedule.isSubstitute
                        ? Colors.orange
                        : AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 스케줄 설정 화면으로 이동
  void _navigateToScheduleSetting(DateTime date) async {
    await Get.toNamed(
      AppRoutes.scheduleSetting,
      arguments: {
        'workplace': controller.workplace,
        'date': date,
      },
    );
    controller.loadMonthlySchedules();
  }

  /// 스케줄 삭제 다이얼로그
  void _showDeleteScheduleDialog(schedule) {
    Get.dialog(
      AlertDialog(
        title: const Text('스케줄 삭제'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('다음 스케줄을 삭제하시겠습니까?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '직원: ${schedule.employeeName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('시간: ${schedule.timeRangeString}'),
                  Text('근무: ${schedule.workTimeString}'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '이 작업은 되돌릴 수 없습니다.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _deleteSchedule(schedule.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  /// 스케줄 삭제 실행
  Future<void> _deleteSchedule(String scheduleId) async {
    try {
      // controller의 메서드 사용 (수정됨)
      await controller.deleteScheduleFromDetail(scheduleId);

      SnackbarHelper.showSuccess('스케줄이 삭제되었습니다.');
    } catch (e) {
      print('스케줄 삭제 오류: $e');
      SnackbarHelper.showError('스케줄 삭제에 실패했습니다.');
    }
  }

  /// 스케줄 수정 다이얼로그
  void _showEditScheduleDialog(schedule) {
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _WorkplaceEditScheduleDialog(
          schedule: schedule,
          employees: controller.employees,
          onUpdate: controller.updateScheduleFromDetail,
        );
      },
    );
  }

  /// 스케줄 수정 실행
  Future<void> _updateSchedule({
    required schedule,
    required String employeeId,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required bool isSubstitute,
  }) async {
    try {
      final employee = controller.employees.firstWhere((e) => e.id == employeeId);

      final startDateTime = DateTime(
        schedule.date.year,
        schedule.date.month,
        schedule.date.day,
        startTime.hour,
        startTime.minute,
      );

      final endDateTime = DateTime(
        schedule.date.year,
        schedule.date.month,
        schedule.date.day,
        endTime.hour,
        endTime.minute,
      );

      final actualEndDateTime = endDateTime.isBefore(startDateTime)
          ? endDateTime.add(const Duration(days: 1))
          : endDateTime;

      final totalMinutes = actualEndDateTime.difference(startDateTime).inMinutes;

      if (totalMinutes <= 0) {
        SnackbarHelper.showWarning('종료시간이 시작시간보다 늦어야 합니다.');
        return;
      }

      // controller의 _scheduleService 사용 (수정됨)
      await controller.updateScheduleFromDetail(
        scheduleId: schedule.id,
        employeeId: employeeId,
        employeeName: employee.name,
        startTime: startDateTime,
        endTime: actualEndDateTime,
        totalMinutes: totalMinutes,
        isSubstitute: isSubstitute,
      );

      SnackbarHelper.showSuccess('스케줄이 수정되었습니다.');
    } catch (e) {
      print('스케줄 수정 오류: $e');
      SnackbarHelper.showError('스케줄 수정에 실패했습니다.');
    }
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

// ============================================================================
// 스케줄 수정 다이얼로그 위젯 (WorkplaceDetailView용)
// ============================================================================
class _WorkplaceEditScheduleDialog extends StatefulWidget {
  final Schedule schedule;
  final RxList<Employee> employees;
  final Function({
  required String scheduleId,
  required String employeeId,
  required String employeeName,
  required DateTime startTime,
  required DateTime endTime,
  required int totalMinutes,
  required bool isSubstitute,
  String? memo,
  }) onUpdate;

  const _WorkplaceEditScheduleDialog({
    required this.schedule,
    required this.employees,
    required this.onUpdate,
  });

  @override
  State<_WorkplaceEditScheduleDialog> createState() => _WorkplaceEditScheduleDialogState();
}

class _WorkplaceEditScheduleDialogState extends State<_WorkplaceEditScheduleDialog> {
  late String? selectedEmployeeId;
  late TimeOfDay? startTime;
  late TimeOfDay? endTime;
  late bool isSubstitute;
  late TextEditingController memoController;

  @override
  void initState() {
    super.initState();
    selectedEmployeeId = widget.schedule.employeeId;
    startTime = TimeOfDay(
      hour: widget.schedule.startTime.hour,
      minute: widget.schedule.startTime.minute,
    );
    endTime = TimeOfDay(
      hour: widget.schedule.endTime.hour,
      minute: widget.schedule.endTime.minute,
    );
    isSubstitute = widget.schedule.isSubstitute;
    memoController = TextEditingController(text: widget.schedule.memo ?? '');
  }

  @override
  void dispose() {
    memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('스케줄 수정'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 직원 선택
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: '직원 선택',
                border: OutlineInputBorder(),
              ),
              value: selectedEmployeeId,
              items: widget.employees
                  .map((employee) => DropdownMenuItem(
                value: employee.id,
                child: Text(employee.name),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedEmployeeId = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // 시작 시간
            ListTile(
              title: const Text('시작 시간'),
              subtitle: Text(startTime?.format(context) ?? '선택해주세요'),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: startTime ?? TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() {
                    startTime = time;
                  });
                }
              },
            ),

            // 종료 시간
            ListTile(
              title: const Text('종료 시간'),
              subtitle: Text(endTime?.format(context) ?? '선택해주세요'),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: endTime ?? TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() {
                    endTime = time;
                  });
                }
              },
            ),

            // 대체근무 체크박스
            CheckboxListTile(
              title: const Text('대체근무'),
              subtitle: const Text('다른 직원 대신 근무하는 경우 체크'),
              value: isSubstitute,
              onChanged: (value) {
                setState(() {
                  isSubstitute = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),

            // 메모 입력
            const SizedBox(height: 8),
            TextField(
              controller: memoController,
              decoration: const InputDecoration(
                labelText: '메모 (선택)',
                hintText: '특이사항 입력',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 1,
              maxLength: 20,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: selectedEmployeeId != null && startTime != null && endTime != null
              ? () async {
            final employee = widget.employees.firstWhere((e) => e.id == selectedEmployeeId);

            final startDateTime = DateTime(
              widget.schedule.date.year,
              widget.schedule.date.month,
              widget.schedule.date.day,
              startTime!.hour,
              startTime!.minute,
            );

            final endDateTime = DateTime(
              widget.schedule.date.year,
              widget.schedule.date.month,
              widget.schedule.date.day,
              endTime!.hour,
              endTime!.minute,
            );

            final actualEndDateTime = endDateTime.isBefore(startDateTime)
                ? endDateTime.add(const Duration(days: 1))
                : endDateTime;

            final totalMinutes = actualEndDateTime.difference(startDateTime).inMinutes;

            if (totalMinutes <= 0) {
              SnackbarHelper.showWarning('종료시간이 시작시간보다 늦어야 합니다.');
              return;
            }

            final memo = memoController.text.trim();
            Navigator.of(context).pop();

            try {
              await widget.onUpdate(
                scheduleId: widget.schedule.id,
                employeeId: selectedEmployeeId!,
                employeeName: employee.name,
                startTime: startDateTime,
                endTime: actualEndDateTime,
                totalMinutes: totalMinutes,
                isSubstitute: isSubstitute,
                memo: memo.isEmpty ? null : memo,
              );

              SnackbarHelper.showSuccess('스케줄이 수정되었습니다.');
            } catch (e) {
              SnackbarHelper.showError('스케줄 수정에 실패했습니다.');
            }
          }
              : null,
          child: const Text('수정'),
        ),
      ],
    );
  }
}