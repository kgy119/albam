import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/schedule_setting_controller.dart';

class ScheduleSettingView extends GetView<ScheduleSettingController> {
  const ScheduleSettingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${controller.selectedDate.month}월 ${controller.selectedDate.day}일 스케줄',
        ),
        actions: [
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
      floatingActionButton: FloatingActionButton(
        onPressed: controller.showAddScheduleDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
        ],
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
            padding: const EdgeInsets.all(16),
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
                  backgroundColor: Theme.of(Get.context!).primaryColor.withOpacity(0.1),
                  child: Text(
                    schedule.employeeName.isNotEmpty ? schedule.employeeName[0] : '?',
                    style: TextStyle(
                      color: Theme.of(Get.context!).primaryColor,
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
                      Text(
                        schedule.employeeName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
                    color: Theme.of(Get.context!).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    schedule.workTimeString,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(Get.context!).primaryColor,
                    ),
                  ),
                ),

                // 삭제 버튼
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _showDeleteDialog(schedule),
                  tooltip: '삭제',
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
                color: Theme.of(Get.context!).primaryColor,
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
        content: Text(
          '${schedule.employeeName}의 ${schedule.timeRangeString} 스케줄을 삭제하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteSchedule(schedule.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}