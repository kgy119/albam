import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/date_utils.dart' as date_utils;
import '../../../data/models/schedule_model.dart';
import '../../controllers/schedule_setting_controller.dart';

class ScheduleSettingView extends GetView<ScheduleSettingController> {
  const ScheduleSettingView({super.key});

  @override
  Widget build(BuildContext context) {
    final weekday = controller.selectedDate.weekday;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${controller.selectedDate.month}월 ${controller.selectedDate.day}일',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              date_utils.DateUtils.getWeekdayText(weekday),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: date_utils.DateUtils.getWeekdayColorForDarkBg(weekday),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () => controller.showCopyScheduleDialog(),
            tooltip: '다른 날 복사',
          ),
          Obx(() => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '총 ${controller.getTotalWorkTime()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          )),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.schedules.isEmpty) {
          return _buildEmptyState();
        }

        return _buildScheduleList();
      }),
      floatingActionButton: Obx(() => FloatingActionButton(
        onPressed: controller.isSaving.value
            ? null
            : controller.showAddScheduleDialog,
        child: controller.isSaving.value
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Icon(Icons.add),
      )),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80), // 플로팅버튼 여백
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              size: 64,
              color: Theme.of(Get.context!).primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              '등록된 스케줄이 없습니다',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '직원의 근무시간을 추가해보세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            // 버튼들
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 새로 추가 버튼
                ElevatedButton.icon(
                  onPressed: () => controller.showAddScheduleDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('새로 추가'),
                ),

                const SizedBox(width: 16),

                // 복사하기 버튼
                OutlinedButton.icon(
                  onPressed: () => controller.showCopyScheduleDialog(),
                  icon: const Icon(Icons.copy),
                  label: const Text('다른 날 복사'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(Get.context!).primaryColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 안내 텍스트
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline,
                      color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '팁: 비슷한 스케줄이 있는 날짜에서 복사하면 시간을 절약할 수 있어요!',
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
      ),
    );
  }

  Widget _buildScheduleList() {
    return Column(
      children: [
        // 24시간 타임라인 헤더
        _buildTimelineHeader(),

        // 스케줄 목록
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // 하단에 플로팅버튼 여백 추가
            itemCount: controller.schedules.length,
            itemBuilder: (context, index) {
              final schedule = controller.schedules[index];
              return _buildScheduleCard(schedule);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineHeader() {
    return Container(
      height: 60,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 0시부터 23시까지 시간 표시
          for (int hour = 0; hour < 24; hour += 6)
            Expanded(
              child: Center(
                child: Text(
                  '${hour.toString().padLeft(2, '0')}시',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(Get.context!).primaryColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(schedule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 직원 아바타
                CircleAvatar(
                  backgroundColor: schedule.isSubstitute
                      ? Colors.orange.withOpacity(0.1) // 대체근무시 다른 색상
                      : Theme.of(Get.context!).primaryColor.withOpacity(0.1),
                  child: Text(
                    schedule.employeeName.isNotEmpty ? schedule.employeeName[0] : '?',
                    style: TextStyle(
                      color: schedule.isSubstitute
                          ? Colors.orange[700] // 대체근무시 다른 색상
                          : Theme.of(Get.context!).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // 직원 이름 및 근무시간
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            schedule.employeeName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // 대체근무 표시 추가
                          if (schedule.isSubstitute) ...[
                            const SizedBox(width: 8),
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
                        ],
                      ),
                      Text(
                        schedule.timeRangeString,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // 근무시간 정보
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: schedule.isSubstitute
                        ? Colors.orange.withOpacity(0.1) // 대체근무시 다른 색상
                        : Theme.of(Get.context!).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    schedule.workTimeString,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: schedule.isSubstitute
                          ? Colors.orange[700] // 대체근무시 다른 색상
                          : Theme.of(Get.context!).primaryColor,
                    ),
                  ),
                ),

                // 수정/삭제 버튼
                const SizedBox(width: 8),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) {
                    if (value == 'edit') {
                      controller.showEditScheduleDialog(schedule);
                    } else if (value == 'delete') {
                      _showDeleteDialog(schedule);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('수정'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('삭제', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // 시간 바 시각화
            const SizedBox(height: 12),
            _buildTimeBar(schedule),
          ],
        ),
      ),
    );
  }


  Widget _buildTimeBar(schedule) {
    // 시작 시간을 0~24시간 범위로 정규화
    final startHour = schedule.startTime.hour + (schedule.startTime.minute / 60.0);
    final endHour = schedule.endTime.hour + (schedule.endTime.minute / 60.0);

    // 24시간 기준으로 비율 계산
    final startRatio = startHour / 24.0;
    final duration = (endHour > startHour ? endHour - startHour : (24 - startHour) + endHour) / 24.0;

    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          Positioned(
            left: MediaQuery.of(Get.context!).size.width * 0.8 * startRatio,
            child: Container(
              width: MediaQuery.of(Get.context!).size.width * 0.8 * duration,
              height: 8,
              decoration: BoxDecoration(
                color: schedule.isSubstitute
                    ? Colors.orange // 대체근무시 다른 색상
                    : Theme.of(Get.context!).primaryColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showDeleteDialog(schedule) {
    Get.dialog(
      AlertDialog(
        title: const Text('스케줄 삭제'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('다음 스케줄을 삭제하시겠습니까?'),
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
            onPressed: () {
              Get.back();
              controller.deleteSchedule(schedule.id);
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
  /// 스케줄 복사 다이얼로그 표시
  void showCopyScheduleDialog() async {
    final scheduleDates = await controller.getScheduleDates();

    if (scheduleDates.isEmpty) {
      Get.snackbar('알림', '이번 달에 등록된 스케줄이 없습니다.');
      return;
    }

    // 현재 날짜 제외
    final currentDate = DateTime(controller.selectedDate.year, controller.selectedDate.month, controller.selectedDate.day);
    scheduleDates.removeWhere((date) => date.isAtSameMomentAs(currentDate));

    if (scheduleDates.isEmpty) {
      Get.snackbar('알림', '복사할 수 있는 다른 날짜의 스케줄이 없습니다.');
      return;
    }

    Get.dialog(
      AlertDialog(
        title: const Text('스케줄 복사'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 경고 메시지 추가
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '기존 스케줄이 모두 삭제되고\n선택한 날짜의 스케줄로 교체됩니다.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('복사할 날짜를 선택하세요:'),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: scheduleDates.length,
                  itemBuilder: (context, index) {
                    final date = scheduleDates[index];
                    return FutureBuilder<List<Schedule>>(
                      future: controller.getSchedulesByDate(date),
                      builder: (context, snapshot) {
                        final schedules = snapshot.data ?? [];
                        final totalHours = schedules.fold<double>(
                            0, (sum, schedule) => sum + (schedule.totalMinutes / 60.0)
                        );

                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(Get.context!).primaryColor,
                              child: Text(
                                '${date.day}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text('${date.month}/${date.day}일'),
                            subtitle: Text(
                              '${schedules.length}개 스케줄 • ${totalHours.toStringAsFixed(1)}시간',
                            ),
                            trailing: const Icon(Icons.copy),
                            onTap: () async {
                              // 복사 확인 다이얼로그 표시
                              _showCopyConfirmDialog(date);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  /// 복사 확인 다이얼로그
  void _showCopyConfirmDialog(DateTime sourceDate) {
    Get.back(); // 이전 다이얼로그 닫기

    Get.dialog(
      AlertDialog(
        title: const Text('스케줄 복사 확인'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${sourceDate.month}/${sourceDate.day}일의 스케줄을'),
            Text('${controller.selectedDate.month}/${controller.selectedDate.day}일로 복사하시겠습니까?'),
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
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.copySchedulesFromDate(sourceDate);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('복사'),
          ),
        ],
      ),
    );
  }
}