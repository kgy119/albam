import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/workplace_model.dart';
import '../../data/models/employee_model.dart';
import '../../data/models/schedule_model.dart';
import '../../core/constants/app_constants.dart';

class ScheduleSettingController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      final querySnapshot = await _firestore
          .collection(AppConstants.employeesCollection)
          .where('workplaceId', isEqualTo: workplace.id)
          .get();

      employees.value = querySnapshot.docs
          .map((doc) => Employee.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('직원 목록 로드 오류: $e');
      Get.snackbar('오류', '직원 목록을 불러오는데 실패했습니다.');
    }
  }

  /// 해당 날짜의 스케줄 로드
  Future<void> loadSchedules() async {
    isLoading.value = true;

    try {
      // 해당 날짜의 시작과 끝 시간 계산
      final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection(AppConstants.schedulesCollection)
          .where('workplaceId', isEqualTo: workplace.id)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      schedules.value = querySnapshot.docs
          .map((doc) => Schedule.fromFirestore(doc))
          .toList();

      // 시작 시간으로 정렬
      schedules.sort((a, b) => a.startTime.compareTo(b.startTime));
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

      // 총 근무시간 계산 (분 단위)
      final totalMinutes = Schedule.calculateTotalMinutes(startDateTime, actualEndDateTime);

      if (totalMinutes <= 0) {
        Get.snackbar('오류', '종료시간이 시작시간보다 늦어야 합니다.');
        return;
      }

      final now = DateTime.now();
      final scheduleData = {
        'workplaceId': workplace.id,
        'employeeId': employeeId,
        'employeeName': employee.name,
        'date': Timestamp.fromDate(selectedDate),
        'startTime': Timestamp.fromDate(startDateTime),
        'endTime': Timestamp.fromDate(actualEndDateTime),
        'totalMinutes': totalMinutes,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      await _firestore
          .collection(AppConstants.schedulesCollection)
          .add(scheduleData);

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
      await _firestore
          .collection(AppConstants.schedulesCollection)
          .doc(scheduleId)
          .delete();

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

  /// 스케줄 추가 다이얼로그 표시
  void showAddScheduleDialog() {
    if (employees.isEmpty) {
      Get.snackbar('알림', '등록된 직원이 없습니다.');
      return;
    }

    String? selectedEmployeeId;
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    Get.dialog(
      StatefulBuilder(
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
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: selectedEmployeeId != null && startTime != null && endTime != null
                    ? () async {
                  Get.back();
                  await addSchedule(
                    employeeId: selectedEmployeeId!,
                    startTime: startTime!,
                    endTime: endTime!,
                  );
                }
                    : null,
                child: const Text('추가'),
              ),
            ],
          );
        },
      ),
    );
  }
}