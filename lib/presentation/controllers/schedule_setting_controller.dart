import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/date_utils.dart' as date_utils;
import '../../core/services/employee_service.dart';
import '../../core/services/schedule_service.dart';
import '../../data/models/workplace_model.dart';
import '../../data/models/employee_model.dart';
import '../../data/models/schedule_model.dart';

class ScheduleSettingController extends GetxController {
  final EmployeeService _employeeService = EmployeeService();
  final ScheduleService _scheduleService = ScheduleService();

  // 전달받은 데이터
  late Workplace workplace;
  late DateTime selectedDate;

  // 직원 목록
  RxList<Employee> employees = <Employee>[].obs;

  // 해당 날짜의 스케줄 목록
  RxList<Schedule> schedules = <Schedule>[].obs;

  // 로딩 상태
  RxBool isLoading = false.obs;
  RxBool isSaving = false.obs;

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
      employees.value = await _employeeService.getEmployees(workplace.id);
    } catch (e) {
      print('직원 목록 로드 오류: $e');
      Get.snackbar('오류', '직원 목록을 불러오는데 실패했습니다.');
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
      Get.snackbar('오류', '스케줄을 불러오는데 실패했습니다.');
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
  }) async {
    try {
      // 직원 정보 찾기
      final employee = employees.firstWhere((e) => e.id == employeeId);

      // DateTime 객체 생성
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

      // 종료시간이 시작시간보다 이른 경우 다음날로 설정
      final actualEndDateTime = endDateTime.isBefore(startDateTime)
          ? endDateTime.add(const Duration(days: 1))
          : endDateTime;

      // 총 근무시간 계산
      final totalMinutes = Schedule.calculateTotalMinutes(startDateTime, actualEndDateTime);

      if (totalMinutes <= 0) {
        Get.snackbar('오류', '종료시간이 시작시간보다 늦어야 합니다.');
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
      );

      await loadSchedules(); // 목록 새로고침
      Get.snackbar('성공', '스케줄이 추가되었습니다.');
    } catch (e) {
      print('스케줄 추가 오류: $e');
      Get.snackbar('오류', '스케줄 추가에 실패했습니다.');
    }
  }

  /// 스케줄 삭제
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _scheduleService.deleteSchedule(scheduleId);
      await loadSchedules(); // 목록 새로고침
      Get.snackbar('성공', '스케줄이 삭제되었습니다.');
    } catch (e) {
      print('스케줄 삭제 오류: $e');
      Get.snackbar('오류', '스케줄 삭제에 실패했습니다.');
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

  /// 스케줄 수정
  Future<void> updateSchedule({
    required String scheduleId,
    required String employeeId,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    bool isSubstitute = false,
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
        Get.snackbar('오류', '종료시간이 시작시간보다 늦어야 합니다.');
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
      );

      await loadSchedules();
      Get.snackbar('성공', '스케줄이 수정되었습니다.');
    } catch (e) {
      print('스케줄 수정 오류: $e');
      Get.snackbar('오류', '스케줄 수정에 실패했습니다.');
    }
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
        Get.snackbar('알림', '선택한 날짜에 복사할 스케줄이 없습니다.');
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

      Get.snackbar(
        '완료',
        '기존 스케줄 $deletedCount개 삭제 후\n${sourceDate.month}/${sourceDate.day}일 스케줄 $addedCount개가 복사되었습니다.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      print('스케줄 복사 오류: $e');
      Get.snackbar('오류', '스케줄 복사에 실패했습니다.');
    } finally {
      isSaving.value = false;
    }
  }

  /// 스케줄 추가 다이얼로그 표시
  void showAddScheduleDialog() {
    if (employees.isEmpty) {
      Get.snackbar('알림', '등록된 직원이 없습니다.');
      return;
    }

    String? selectedEmployeeId;
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    bool isSubstitute = false;

    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('${selectedDate.month}/${selectedDate.day} 스케줄 추가'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 직원 선택
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: '직원 선택',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedEmployeeId,
                    items: employees
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
                      final time = await selectTime(context, initialTime: startTime);
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
                      final time = await selectTime(context, initialTime: endTime);
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
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: selectedEmployeeId != null && startTime != null && endTime != null
                      ? () async {
                    Navigator.of(context).pop();
                    await Future.delayed(const Duration(milliseconds: 200));
                    await addSchedule(
                      employeeId: selectedEmployeeId!,
                      startTime: startTime!,
                      endTime: endTime!,
                      isSubstitute: isSubstitute,
                    );
                  }
                      : null,
                  child: const Text('추가'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 스케줄 수정 다이얼로그 표시
  void showEditScheduleDialog(Schedule schedule) {
    if (employees.isEmpty) {
      Get.snackbar('알림', '등록된 직원이 없습니다.');
      return;
    }

    String? selectedEmployeeId = schedule.employeeId;
    TimeOfDay? startTime = TimeOfDay(
      hour: schedule.startTime.hour,
      minute: schedule.startTime.minute,
    );
    TimeOfDay? endTime = TimeOfDay(
      hour: schedule.endTime.hour,
      minute: schedule.endTime.minute,
    );
    bool isSubstitute = schedule.isSubstitute;

    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('${selectedDate.month}/${selectedDate.day} 스케줄 수정'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 직원 선택
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: '직원 선택',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedEmployeeId,
                    items: employees
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
                      final time = await selectTime(context, initialTime: startTime);
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
                      final time = await selectTime(context, initialTime: endTime);
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
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: selectedEmployeeId != null && startTime != null && endTime != null
                      ? () async {
                    Navigator.of(context).pop();
                    await Future.delayed(const Duration(milliseconds: 200));
                    await updateSchedule(
                      scheduleId: schedule.id,
                      employeeId: selectedEmployeeId!,
                      startTime: startTime!,
                      endTime: endTime!,
                      isSubstitute: isSubstitute,
                    );
                  }
                      : null,
                  child: const Text('수정'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 스케줄 복사 다이얼로그 표시
  void showCopyScheduleDialog() async {
    final scheduleDates = await getScheduleDates();

    if (scheduleDates.isEmpty) {
      Get.snackbar('알림', '복사할 수 있는 스케줄이 없습니다.');
      return;
    }

    final currentWeekday = selectedDate.weekday;
    final currentWeekdayText = date_utils.DateUtils.getWeekdayText(currentWeekday);

    showDialog(
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
                      // 같은 요일 섹션
                      if (topSameWeekdayDates.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                        ...topSameWeekdayDates.map((date) => _buildDateCard(date, true)),
                        const SizedBox(height: 16),
                      ],

                      // 다른 날짜 섹션
                      if (otherDates.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Text(
                            '다른 날짜',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        ...otherDates.map((date) => _buildDateCard(date, false)),
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
    );
  }

  Widget _buildDateCard(DateTime date, bool isSameWeekday) {
    final isCurrentMonth = date.year == selectedDate.year &&
        date.month == selectedDate.month;
    final weekday = date.weekday;

    return FutureBuilder<List<Schedule>>(
      future: getSchedulesByDate(date),
      builder: (context, snapshot) {
        final schedules = snapshot.data ?? [];
        final totalHours = schedules.fold<double>(
          0,
              (sum, schedule) => sum + (schedule.totalMinutes / 60.0),
        );

        return Card(
          color: isSameWeekday
              ? Colors.orange[50]
              : (isCurrentMonth ? null : Colors.grey[50]),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: InkWell(
            onTap: () async {
              Navigator.of(Get.context!).pop();
              await Future.delayed(const Duration(milliseconds: 200));
              _showCopyConfirmDialog(date);
            },
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
                  Icon(
                    Icons.copy,
                    color: isSameWeekday ? Colors.orange[700] : Colors.grey[600],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
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
}