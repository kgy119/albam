import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/date_utils.dart' as date_utils;
import '../../core/services/employee_service.dart';
import '../../core/services/schedule_service.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/workplace_model.dart';
import '../../data/models/employee_model.dart';
import '../../data/models/schedule_model.dart';
import '../views/schedule/schedule_setting_view.dart';

class ScheduleSettingController extends GetxController {
  final EmployeeService _employeeService = EmployeeService();
  final ScheduleService _scheduleService = ScheduleService();
  final RxBool _isDialogShowing = false.obs; // 다이얼로그 표시 상태 추가

  // 전달받은 데이터
  late Workplace workplace;
  late DateTime selectedDate;

  // 직원 목록
  RxList<Employee> employees = <Employee>[].obs;
  RxList<Employee> resignedEmployees = <Employee>[].obs; // ✅ 추가

  // 해당 날짜의 스케줄 목록
  RxList<Schedule> schedules = <Schedule>[].obs;

  // 로딩 상태
  RxBool isLoading = false.obs;
  RxBool isSaving = false.obs;

  List<Employee> get allEmployees => [...employees, ...resignedEmployees];


  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments as Map<String, dynamic>;
    workplace = arguments['workplace'];
    selectedDate = arguments['date'];

    loadEmployees();
    loadSchedules();
  }

  /// 직원 목록 로드
  Future<void> loadEmployees() async {
    try {
      // ✅ 수정: 재직중 + 퇴사 직원 모두 조회
      employees.value = await _employeeService.getEmployees(workplace.id);
      resignedEmployees.value = await _employeeService.getResignedEmployees(workplace.id);

      print('재직중 직원: ${employees.length}명, 퇴사 직원: ${resignedEmployees.length}명');
    } catch (e) {
      print('직원 목록 로드 오류: $e');
      SnackbarHelper.showError('직원 목록을 불러오는데 실패했습니다.');
    }
  }


  /// 해당 날짜의 스케줄 로드
  Future<void> loadSchedules() async {
    isLoading.value = true;

    try {
      schedules.value = await _scheduleService.getDaySchedules(
        workplaceId: workplace.id,
        date: selectedDate,
      );

      print('스케줄 로드 완료: ${schedules.length}개');
    } catch (e) {
      print('스케줄 로드 오류: $e');
      SnackbarHelper.showError('스케줄을 불러오는데 실패했습니다.'); // 수정
    } finally {
      isLoading.value = false;
    }
  }

  /// 스케줄 추가
  Future<void> addSchedule({
    required String employeeId,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    bool isSubstitute = false,
    String? memo,
  }) async {
    try {
      final employee = employees.firstWhere((e) => e.id == employeeId);

      final startDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        startTime.hour,
        startTime.minute,
      );

      final endDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        endTime.hour,
        endTime.minute,
      );

      final actualEndDateTime = endDateTime.isBefore(startDateTime)
          ? endDateTime.add(const Duration(days: 1))
          : endDateTime;

      final totalMinutes = Schedule.calculateTotalMinutes(startDateTime, actualEndDateTime);

      if (totalMinutes <= 0) {
        SnackbarHelper.showWarning('종료시간이 시작시간보다 늦어야 합니다.'); // 수정
        return;
      }

      await _scheduleService.addSchedule(
        workplaceId: workplace.id,
        employeeId: employeeId,
        employeeName: employee.name,
        date: selectedDate,
        startTime: startDateTime,
        endTime: actualEndDateTime,
        totalMinutes: totalMinutes,
        isSubstitute: isSubstitute,
        memo: memo,
      );

      await loadSchedules();
      SnackbarHelper.showSuccess('스케줄이 추가되었습니다.'); // 수정
    } catch (e) {
      print('스케줄 추가 오류: $e');
      SnackbarHelper.showError('스케줄 추가에 실패했습니다.'); // 수정
    }
  }

  /// 스케줄 삭제
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _scheduleService.deleteSchedule(scheduleId);
      await loadSchedules();
      SnackbarHelper.showSuccess('스케줄이 삭제되었습니다.'); // 수정
    } catch (e) {
      print('스케줄 삭제 오류: $e');
      SnackbarHelper.showError('스케줄 삭제에 실패했습니다.'); // 수정
    }
  }

  /// 스케줄 수정
  Future<void> updateSchedule({
    required String scheduleId,
    required String employeeId,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    bool isSubstitute = false,
    String? memo,
  }) async {
    try {
      final employee = employees.firstWhere((e) => e.id == employeeId);

      final startDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        startTime.hour,
        startTime.minute,
      );

      final endDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        endTime.hour,
        endTime.minute,
      );

      final actualEndDateTime = endDateTime.isBefore(startDateTime)
          ? endDateTime.add(const Duration(days: 1))
          : endDateTime;

      final totalMinutes = Schedule.calculateTotalMinutes(startDateTime, actualEndDateTime);

      if (totalMinutes <= 0) {
        SnackbarHelper.showWarning('종료시간이 시작시간보다 늦어야 합니다.'); // 수정
        return;
      }

      await _scheduleService.updateSchedule(
        scheduleId: scheduleId,
        employeeId: employeeId,
        employeeName: employee.name,
        startTime: startDateTime,
        endTime: actualEndDateTime,
        totalMinutes: totalMinutes,
        isSubstitute: isSubstitute,
        memo: memo,
      );

      await loadSchedules();
      SnackbarHelper.showSuccess('스케줄이 수정되었습니다.'); // 수정
    } catch (e) {
      print('스케줄 수정 오류: $e');
      SnackbarHelper.showError('스케줄 수정에 실패했습니다.'); // 수정
    }
  }


  /// 해당 날짜의 총 근무시간 계산
  String getTotalWorkTime() {
    if (schedules.isEmpty) return '0시간 0분';

    final totalMinutes = schedules.fold<int>(0, (sum, schedule) => sum + schedule.totalMinutes);
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    return '${hours}시간 ${minutes}분';
  }

  /// 시간 선택 다이얼로그 표시
  Future<TimeOfDay?> selectTime(BuildContext context, {TimeOfDay? initialTime}) async {
    return await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
  }


  /// 스케줄이 있는 날짜들 조회
  Future<List<DateTime>> getScheduleDates() async {
    try {
      final startDate = DateTime(selectedDate.year, selectedDate.month - 1, 1);

      // 2개월치 스케줄 조회
      final allSchedules = <Schedule>[];

      // 이전 달
      final prevSchedules = await _scheduleService.getMonthlySchedules(
        workplaceId: workplace.id,
        year: startDate.year,
        month: startDate.month,
      );
      allSchedules.addAll(prevSchedules);

      // 현재 달
      final currentSchedules = await _scheduleService.getMonthlySchedules(
        workplaceId: workplace.id,
        year: selectedDate.year,
        month: selectedDate.month,
      );
      allSchedules.addAll(currentSchedules);

      Set<DateTime> uniqueDates = {};

      for (var schedule in allSchedules) {
        final dateOnly = DateTime(
          schedule.date.year,
          schedule.date.month,
          schedule.date.day,
        );
        uniqueDates.add(dateOnly);
      }

      // 현재 날짜 제외
      final currentDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
      uniqueDates.removeWhere((date) => date.isAtSameMomentAs(currentDate));

      List<DateTime> sortedDates = uniqueDates.toList();

      // 같은 요일 우선 정렬
      final currentWeekday = selectedDate.weekday;
      final sameWeekdayDates = sortedDates
          .where((date) => date.weekday == currentWeekday)
          .toList()
        ..sort((a, b) => b.compareTo(a));

      final otherWeekdayDates = sortedDates
          .where((date) => date.weekday != currentWeekday)
          .toList()
        ..sort((a, b) => b.compareTo(a));

      return [...sameWeekdayDates, ...otherWeekdayDates];
    } catch (e) {
      print('스케줄 날짜 조회 오류: $e');
      return [];
    }
  }

  /// 특정 날짜의 스케줄 조회
  Future<List<Schedule>> getSchedulesByDate(DateTime targetDate) async {
    try {
      return await _scheduleService.getDaySchedules(
        workplaceId: workplace.id,
        date: targetDate,
      );
    } catch (e) {
      print('특정 날짜 스케줄 조회 오류: $e');
      return [];
    }
  }

  /// 다른 날짜에서 스케줄 복사
  Future<void> copySchedulesFromDate(DateTime sourceDate) async {
    try {
      isSaving.value = true;

      // 복사할 스케줄 조회
      final sourceSchedules = await getSchedulesByDate(sourceDate);

      if (sourceSchedules.isEmpty) {
        SnackbarHelper.showWarning('선택한 날짜에 복사할 스케줄이 없습니다.');
        return;
      }

      // 현재 날짜의 기존 스케줄 조회
      final existingSchedules = await getSchedulesByDate(selectedDate);

      // 1. 기존 스케줄 삭제
      if (existingSchedules.isNotEmpty) {
        final scheduleIds = existingSchedules.map((s) => s.id).toList();
        await _scheduleService.deleteSchedules(scheduleIds);
      }

      // 2. 새로운 스케줄 추가
      for (var sourceSchedule in sourceSchedules) {
        final newStartTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          sourceSchedule.startTime.hour,
          sourceSchedule.startTime.minute,
        );

        final newEndTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          sourceSchedule.endTime.hour,
          sourceSchedule.endTime.minute,
        );

        final actualEndTime = newEndTime.isBefore(newStartTime)
            ? newEndTime.add(const Duration(days: 1))
            : newEndTime;

        await _scheduleService.addSchedule(
          workplaceId: workplace.id,
          employeeId: sourceSchedule.employeeId,
          employeeName: sourceSchedule.employeeName,
          date: selectedDate,
          startTime: newStartTime,
          endTime: actualEndTime,
          totalMinutes: sourceSchedule.totalMinutes,
          isSubstitute: sourceSchedule.isSubstitute,
        );
      }

      await loadSchedules();

      final deletedCount = existingSchedules.length;
      final addedCount = sourceSchedules.length;

      SnackbarHelper.showSuccess(
        '기존 스케줄 $deletedCount개 삭제 후\n${sourceDate.month}/${sourceDate.day}일 스케줄 $addedCount개가 복사되었습니다.',
      );
    } catch (e) {
      print('스케줄 복사 오류: $e');
      SnackbarHelper.showError('스케줄 복사에 실패했습니다.');
    } finally {
      isSaving.value = false;
    }
  }

  /// 스케줄 추가 다이얼로그 표시
  void showAddScheduleDialog() {
    if (employees.isEmpty) {
      SnackbarHelper.showWarning('등록된 직원이 없습니다.');
      return;
    }

    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _AddScheduleDialog(
          employees: employees,
          selectedDate: selectedDate,
          onAdd: addSchedule,
          onSelectTime: selectTime,
        );
      },
    );
  }

  /// 스케줄 수정 다이얼로그 표시
  void showEditScheduleDialog(Schedule schedule) {
    if (employees.isEmpty) {
      SnackbarHelper.showWarning('등록된 직원이 없습니다.');
      return;
    }

    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _EditScheduleDialog(
          employees: employees,
          selectedDate: selectedDate,
          schedule: schedule,
          onUpdate: updateSchedule,
          onSelectTime: selectTime,
        );
      },
    );
  }

  /// 스케줄 복사 다이얼로그 표시
  void showCopyScheduleDialog() async {
    // 🔒 async 시작 즉시 잠금
    if (_isDialogShowing.value) {
      debugPrint('다이얼로그가 이미 표시 중입니다');
      return;
    }
    _isDialogShowing.value = true;

    try {
      final scheduleDates = await getScheduleDates();

      if (scheduleDates.isEmpty) {
        SnackbarHelper.showWarning('복사할 수 있는 스케줄이 없습니다.');
        return;
      }

      final currentWeekday = selectedDate.weekday;
      final currentWeekdayText =
      date_utils.DateUtils.getWeekdayText(currentWeekday);

      await showDialog(
        context: Get.context!,
        barrierDismissible: false,
        builder: (BuildContext context) {
          final allSameWeekdayDates = scheduleDates
              .where((date) => date.weekday == currentWeekday)
              .toList();

          final topSameWeekdayDates = allSameWeekdayDates.take(3).toList();

          final otherDates = scheduleDates
              .where((date) => date.weekday != currentWeekday)
              .toList();

          // 확장 상태
          Map<String, bool> expandedStates = {};

          return WillPopScope(
            onWillPop: () async => true,
            child: StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Text('스케줄 복사 ($currentWeekdayText)'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('복사할 날짜를 선택하세요:'),
                        const SizedBox(height: 8),
                        Text(
                          '최근 2개월 이내의 스케줄',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 400,
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              // ⭐ 같은 요일
                              if (topSameWeekdayDates.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 16,
                                        color: Colors.orange[700],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '같은 요일 ($currentWeekdayText)',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ...topSameWeekdayDates.map((date) {
                                  final key =
                                      '${date.year}-${date.month}-${date.day}';
                                  return _buildExpandableDateCard(
                                    date: date,
                                    isSameWeekday: true,
                                    isExpanded:
                                    expandedStates[key] ?? false,
                                    onTap: () {
                                      setState(() {
                                        expandedStates[key] =
                                        !(expandedStates[key] ?? false);
                                      });
                                    },
                                    onCopy: () {
                                      Navigator.of(context).pop();
                                      _showCopyConfirmDialog(date);
                                    },
                                  );
                                }),
                                const SizedBox(height: 16),
                              ],

                              // 📅 다른 날짜
                              if (otherDates.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 8),
                                  child: Text(
                                    '다른 날짜',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                                ...otherDates.map((date) {
                                  final key =
                                      '${date.year}-${date.month}-${date.day}';
                                  return _buildExpandableDateCard(
                                    date: date,
                                    isSameWeekday: false,
                                    isExpanded:
                                    expandedStates[key] ?? false,
                                    onTap: () {
                                      setState(() {
                                        expandedStates[key] =
                                        !(expandedStates[key] ?? false);
                                      });
                                    },
                                    onCopy: () {
                                      Navigator.of(context).pop();
                                      _showCopyConfirmDialog(date);
                                    },
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('취소'),
                    ),
                  ],
                );
              },
            ),
          );
        },
      );
    } finally {
      // 🔓 어떤 경우든 반드시 해제
      _isDialogShowing.value = false;
    }
  }


  /// 확장 가능한 날짜 카드 빌더
  Widget _buildExpandableDateCard({
    required DateTime date,
    required bool isSameWeekday,
    required bool isExpanded,
    required VoidCallback onTap,
    required VoidCallback onCopy,
  }) {
    final weekday = date.weekday;
    final currentYear = DateTime.now().year;
    final currentMonth = DateTime.now().month;
    final isCurrentMonth = date.year == currentYear && date.month == currentMonth;

    return FutureBuilder<List<Schedule>>(
      future: getSchedulesByDate(date),
      builder: (context, snapshot) {
        final schedules = snapshot.data ?? [];
        final totalHours = schedules.fold<double>(
          0,
              (sum, schedule) => sum + (schedule.totalMinutes / 60.0),
        );

        return Column(
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isSameWeekday
                          ? Colors.orange[700]
                          : date_utils.DateUtils.getWeekdayColorForLightBg(
                        weekday,
                        dimmed: !isCurrentMonth,
                      ),
                      child: Text(
                        date_utils.DateUtils.getWeekdayText(weekday),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${date.month}/${date.day}일',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: date_utils.DateUtils.getWeekdayTextColor(weekday),
                                ),
                              ),
                              if (!isCurrentMonth) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '지난 달',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${schedules.length}개 스케줄 • ${totalHours.toStringAsFixed(1)}시간',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: isSameWeekday ? Colors.orange[700] : Colors.grey[600],
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.copy,
                            color: isSameWeekday ? Colors.orange[700] : Colors.grey[600],
                            size: 20,
                          ),
                          onPressed: onCopy,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // 확장된 스케줄 상세 내용
            if (isExpanded && schedules.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: schedules.map((schedule) {
                    // ✅ 추가: 직원 정보 조회
                    final employee = allEmployees.firstWhereOrNull(
                          (e) => e.id == schedule.employeeId,
                    );
                    final isResigned = employee?.employmentStatus == 'resigned';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            // ✅ 수정: 퇴사자는 회색
                            backgroundColor: isResigned
                                ? Colors.grey[400]
                                : schedule.isSubstitute
                                ? Colors.orange.withOpacity(0.2)
                                : Theme.of(Get.context!).primaryColor.withOpacity(0.2),
                            child: Text(
                              schedule.employeeName.isNotEmpty ? schedule.employeeName[0] : '?',
                              style: TextStyle(
                                // ✅ 수정: 퇴사자는 흰색 텍스트
                                color: isResigned
                                    ? Colors.white
                                    : schedule.isSubstitute
                                    ? Colors.orange[700]
                                    : Theme.of(Get.context!).primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      schedule.employeeName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        // ✅ 추가: 퇴사자는 회색 텍스트
                                        color: isResigned ? Colors.grey[600] : Colors.black,
                                      ),
                                    ),

                                    // ✅ 추가: 퇴사 배지
                                    if (isResigned) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '퇴사',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],

                                    if (schedule.isSubstitute) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
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
                                const SizedBox(height: 2),
                                Text(
                                  '${schedule.timeRangeString} (${schedule.workTimeString})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            if (isExpanded && schedules.isEmpty)
              Container(
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    '스케줄이 없습니다',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// 복사 확인 다이얼로그
  void _showCopyConfirmDialog(DateTime sourceDate) {
    showDialog(
        context: Get.context!,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
              title: const Text('스케줄 복사 확인'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${sourceDate.month}/${sourceDate.day}일의 스케줄을'),
                  Text('${selectedDate.month}/${selectedDate.day}일로 복사하시겠습니까?'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '현재 날짜의 기존 스케줄이 모두 삭제됩니다.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
              TextButton(
              onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await Future.delayed(const Duration(milliseconds: 200));
              await copySchedulesFromDate(sourceDate);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('복사'),
          ),
              ],
          );
        },
    );
  }

  /// 해당일 전체 스케줄 삭제
  Future<void> deleteAllSchedules() async {
    if (schedules.isEmpty) {
      SnackbarHelper.showWarning('삭제할 스케줄이 없습니다.');
      return;
    }

    try {
      isSaving.value = true;

      // 모든 스케줄 ID 수집
      final scheduleIds = schedules.map((s) => s.id).toList();
      final deleteCount = scheduleIds.length;

      // 일괄 삭제
      await _scheduleService.deleteSchedules(scheduleIds);

      // 로컬 리스트 초기화
      schedules.clear();

      // SnackbarHelper 사용
      SnackbarHelper.showSuccess(
        '${selectedDate.month}/${selectedDate.day}일의 스케줄 ${deleteCount}개가 삭제되었습니다.',
      );
    } catch (e) {
      print('스케줄 삭제 오류: $e');
      SnackbarHelper.showError('스케줄 삭제에 실패했습니다.');
    } finally {
      isSaving.value = false;
    }
  }

  /// 선택된 날짜들에 스케줄 복사
  Future<void> copySchedulesToMultipleDates(List<DateTime> targetDates) async {
    if (targetDates.isEmpty) {
      SnackbarHelper.showWarning('날짜를 선택해주세요.');
      return;
    }

    if (schedules.isEmpty) {
      SnackbarHelper.showWarning('복사할 스케줄이 없습니다.');
      return;
    }

    try {
      isSaving.value = true;

      int successCount = 0;
      int skipCount = 0;

      for (var targetDate in targetDates) {
        // 현재 날짜는 건너뛰기
        final currentDate = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
        );

        if (targetDate.isAtSameMomentAs(currentDate)) {
          skipCount++;
          continue;
        }

        // 대상 날짜의 기존 스케줄 삭제
        final existingSchedules = await _scheduleService.getDaySchedules(
          workplaceId: workplace.id,
          date: targetDate,
        );

        if (existingSchedules.isNotEmpty) {
          final scheduleIds = existingSchedules.map((s) => s.id).toList();
          await _scheduleService.deleteSchedules(scheduleIds);
        }

        // 새로운 스케줄 추가
        for (var sourceSchedule in schedules) {
          final newStartTime = DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
            sourceSchedule.startTime.hour,
            sourceSchedule.startTime.minute,
          );

          final newEndTime = DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
            sourceSchedule.endTime.hour,
            sourceSchedule.endTime.minute,
          );

          final actualEndTime = newEndTime.isBefore(newStartTime)
              ? newEndTime.add(const Duration(days: 1))
              : newEndTime;

          await _scheduleService.addSchedule(
            workplaceId: workplace.id,
            employeeId: sourceSchedule.employeeId,
            employeeName: sourceSchedule.employeeName,
            date: targetDate,
            startTime: newStartTime,
            endTime: actualEndTime,
            totalMinutes: sourceSchedule.totalMinutes,
            isSubstitute: sourceSchedule.isSubstitute,
          );
        }

        successCount++;
      }

      if (successCount > 0) {
        SnackbarHelper.showSuccess(
          '${successCount}개 날짜에 스케줄 ${schedules.length}개가 복사되었습니다.',
        );
      } else if (skipCount > 0) {
        SnackbarHelper.showInfo('현재 날짜는 복사에서 제외되었습니다.');
      }
    } catch (e) {
      print('스케줄 복사 오류: $e');
      SnackbarHelper.showError('스케줄 복사에 실패했습니다.');
    } finally {
      isSaving.value = false;
    }
  }

  /// 다른 날 적용 다이얼로그 표시
  void showApplyToOtherDatesDialog() {
    if (schedules.isEmpty) {
      SnackbarHelper.showWarning('복사할 스케줄이 없습니다.');
      return;
    }

    // Get.find로 view에서 직접 호출하도록 변경
    Get.dialog(
      _buildApplyDialog(),
      barrierDismissible: false,
    );
  }

  Widget _buildApplyDialog() {
    return ApplyToOtherDatesDialog(controller: this);
  }
}

// ============================================================================
// 스케줄 추가 다이얼로그 위젯
// ============================================================================
class _AddScheduleDialog extends StatefulWidget {
  final RxList<Employee> employees;
  final DateTime selectedDate;
  final Function({
  required String employeeId,
  required TimeOfDay startTime,
  required TimeOfDay endTime,
  bool isSubstitute,
  String? memo,
  }) onAdd;
  final Future<TimeOfDay?> Function(BuildContext, {TimeOfDay? initialTime}) onSelectTime;

  const _AddScheduleDialog({
    required this.employees,
    required this.selectedDate,
    required this.onAdd,
    required this.onSelectTime,
  });

  @override
  State<_AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends State<_AddScheduleDialog> {
  String? selectedEmployeeId;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  bool isSubstitute = false;
  late TextEditingController memoController;

  @override
  void initState() {
    super.initState();
    memoController = TextEditingController();
  }

  @override
  void dispose() {
    memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.selectedDate.month}/${widget.selectedDate.day} 스케줄 추가'),
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

            // 시작 시간 선택
            ListTile(
              title: const Text('시작 시간'),
              subtitle: Text(startTime?.format(context) ?? '선택해주세요'),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await widget.onSelectTime(context, initialTime: startTime);
                if (time != null) {
                  setState(() {
                    startTime = time;
                  });
                }
              },
            ),

            // 종료 시간 선택
            ListTile(
              title: const Text('종료 시간'),
              subtitle: Text(endTime?.format(context) ?? '선택해주세요'),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await widget.onSelectTime(context, initialTime: endTime);
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
            final memo = memoController.text.trim();
            Navigator.of(context).pop();
            await Future.delayed(const Duration(milliseconds: 200));
            await widget.onAdd(
              employeeId: selectedEmployeeId!,
              startTime: startTime!,
              endTime: endTime!,
              isSubstitute: isSubstitute,
              memo: memo.isEmpty ? null : memo,
            );
          }
              : null,
          child: const Text('추가'),
        ),
      ],
    );
  }
}

// ============================================================================
// 스케줄 수정 다이얼로그 위젯
// ============================================================================
class _EditScheduleDialog extends StatefulWidget {
  final RxList<Employee> employees;
  final DateTime selectedDate;
  final Schedule schedule;
  final Function({
  required String scheduleId,
  required String employeeId,
  required TimeOfDay startTime,
  required TimeOfDay endTime,
  bool isSubstitute,
  String? memo,
  }) onUpdate;
  final Future<TimeOfDay?> Function(BuildContext, {TimeOfDay? initialTime}) onSelectTime;

  const _EditScheduleDialog({
    required this.employees,
    required this.selectedDate,
    required this.schedule,
    required this.onUpdate,
    required this.onSelectTime,
  });

  @override
  State<_EditScheduleDialog> createState() => _EditScheduleDialogState();
}

class _EditScheduleDialogState extends State<_EditScheduleDialog> {
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
      title: Text('${widget.selectedDate.month}/${widget.selectedDate.day} 스케줄 수정'),
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

            // 시작 시간 선택
            ListTile(
              title: const Text('시작 시간'),
              subtitle: Text(startTime?.format(context) ?? '선택해주세요'),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await widget.onSelectTime(context, initialTime: startTime);
                if (time != null) {
                  setState(() {
                    startTime = time;
                  });
                }
              },
            ),

            // 종료 시간 선택
            ListTile(
              title: const Text('종료 시간'),
              subtitle: Text(endTime?.format(context) ?? '선택해주세요'),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await widget.onSelectTime(context, initialTime: endTime);
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
            final memo = memoController.text.trim();
            Navigator.of(context).pop();
            await Future.delayed(const Duration(milliseconds: 200));
            await widget.onUpdate(
              scheduleId: widget.schedule.id,
              employeeId: selectedEmployeeId!,
              startTime: startTime!,
              endTime: endTime!,
              isSubstitute: isSubstitute,
              memo: memo.isEmpty ? null : memo,
            );
          }
              : null,
          child: const Text('수정'),
        ),
      ],
    );
  }
}

