import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/date_utils.dart' as date_utils;
import '../../../core/utils/snackbar_helper.dart';
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
                color: date_utils.DateUtils.getWeekdayColorForLightBg(weekday),
              ),
            ),
          ],
        ),
        actions: [
          // 총 근무시간
          Obx(() => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '총 ${controller.getTotalWorkTime()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          )),
        ],
      ),
      body: Column(
        children: [
          // 액션 탭 바 (추가)
          _buildActionTabBar(),

          // 스케줄 리스트
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.schedules.isEmpty) {
                return _buildEmptyState();
              }

              return _buildScheduleList();
            }),
          ),
        ],
      ),
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

  /// 액션 탭 바 (추가)
  Widget _buildActionTabBar() {
    return Obx(() {
      if (controller.schedules.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
        ),
        child: Row(
          children: [
            // 다른 날 적용
            Expanded(
              child: _buildActionButton(
                icon: Icons.event_available_outlined,
                label: '다른 날 적용',
                color: Theme.of(Get.context!).primaryColor,
                onTap: controller.showApplyToOtherDatesDialog,
              ),
            ),
            const SizedBox(width: 8),

            // 다른 날 복사
            Expanded(
              child: _buildActionButton(
                icon: Icons.content_copy_outlined,
                label: '다른 날 복사',
                color: Colors.green,
                onTap: controller.showCopyScheduleDialog,
              ),
            ),
            const SizedBox(width: 8),

            // 전체 삭제
            Expanded(
              child: _buildActionButton(
                icon: Icons.delete_sweep_outlined,
                label: '전체 삭제',
                color: Colors.red,
                onTap: _showDeleteAllDialog,
              ),
            ),
          ],
        ),
      );
    });
  }

  /// 액션 버튼 (추가)
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),  // 상단 패딩 16 -> 8로 조정
      itemCount: controller.schedules.length,
      itemBuilder: (context, index) {
        final schedule = controller.schedules[index];
        return _buildScheduleCard(schedule);
      },
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

                // 다른 날 복사 버튼
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
    // 전체 스케줄의 최소/최대 시간 계산
    double minHour = 24.0;
    double maxHour = 0.0;

    for (var s in controller.schedules) {
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
    final startRatio = (startHour - minHour) / totalRange;
    final duration = (endHour - startHour) / totalRange;

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
                        : Theme.of(Get.context!).primaryColor,
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
      SnackbarHelper.showWarning('이번 달에 등록된 스케줄이 없습니다.');
      return;
    }

    // 현재 날짜 제외
    final currentDate = DateTime(controller.selectedDate.year, controller.selectedDate.month, controller.selectedDate.day);
    scheduleDates.removeWhere((date) => date.isAtSameMomentAs(currentDate));

    if (scheduleDates.isEmpty) {
      SnackbarHelper.showWarning('복사할 수 있는 다른 날짜의 스케줄이 없습니다.');
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

  /// 전체 스케줄 삭제 확인 다이얼로그
  void _showDeleteAllDialog() {
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('전체 스케줄 삭제'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${controller.selectedDate.month}/${controller.selectedDate.day}일의',
              ),
              const Text('모든 스케줄을 삭제하시겠습니까?'),
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
                        '총 ${controller.schedules.length}개의 스케줄이 영구적으로 삭제됩니다.',
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
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // dialogContext 사용
                await Future.delayed(const Duration(milliseconds: 200));
                await controller.deleteAllSchedules();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('전체 삭제'),
            ),
          ],
        );
      },
    );
  }
}
/// 다른 날 적용 다이얼로그
class ApplyToOtherDatesDialog extends StatefulWidget {
  final ScheduleSettingController controller;

  const ApplyToOtherDatesDialog({super.key, required this.controller});

  @override
  State<ApplyToOtherDatesDialog> createState() => _ApplyToOtherDatesDialogState();
}

class _ApplyToOtherDatesDialogState extends State<ApplyToOtherDatesDialog> {
  final Set<DateTime> _selectedDates = {};
  DateTime _displayMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _displayMonth = DateTime(
      widget.controller.selectedDate.year,
      widget.controller.selectedDate.month,
      1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('다른 날 적용'),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 안내 메시지
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.controller.selectedDate.month}/${widget.controller.selectedDate.day}일의 스케줄을\n적용할 날짜를 선택하세요',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 월 선택
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1, 1);
                    });
                  },
                ),
                Text(
                  '${_displayMonth.year}년 ${_displayMonth.month}월',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1, 1);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 요일 헤더
            _buildWeekHeader(),
            const SizedBox(height: 8),

            // 달력
            Expanded(
              child: _buildCalendar(),
            ),

            const SizedBox(height: 12),

            // 선택된 날짜 표시
            if (_selectedDates.isNotEmpty)
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
                      '선택된 날짜: ${_selectedDates.length}개',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _selectedDates.map((date) {
                        return Chip(
                          label: Text(
                            '${date.month}/${date.day}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          onDeleted: () {
                            setState(() {
                              _selectedDates.remove(date);
                            });
                          },
                          deleteIconColor: Colors.grey[600],
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
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
        ElevatedButton(
          onPressed: _selectedDates.isEmpty
              ? null
              : () async {
            Navigator.of(context).pop();
            await Future.delayed(const Duration(milliseconds: 200));
            await widget.controller.copySchedulesToMultipleDates(
              _selectedDates.toList(),
            );
          },
          child: const Text('적용'),
        ),
      ],
    );
  }

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
              day == '토' ? Colors.blue : Colors.grey[700],
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildCalendar() {
    final daysInMonth = DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;
    final firstDayOfWeek = DateTime(_displayMonth.year, _displayMonth.month, 1).weekday % 7;

    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: 42,
      itemBuilder: (context, index) {
        final day = index - firstDayOfWeek + 1;

        if (day <= 0 || day > daysInMonth) {
          return Container();
        }

        final date = DateTime(_displayMonth.year, _displayMonth.month, day);
        final isSelected = _selectedDates.contains(date);
        final isCurrentDate = date.year == widget.controller.selectedDate.year &&
            date.month == widget.controller.selectedDate.month &&
            date.day == widget.controller.selectedDate.day;

        return GestureDetector(
          onTap: isCurrentDate
              ? null
              : () {
            setState(() {
              if (isSelected) {
                _selectedDates.remove(date);
              } else {
                _selectedDates.add(date);
              }
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isCurrentDate
                  ? Colors.grey[300]
                  : isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCurrentDate
                    ? Colors.grey[500]!
                    : isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isCurrentDate
                      ? Colors.grey[700]
                      : isSelected
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}