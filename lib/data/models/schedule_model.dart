class Schedule {
  final String id;
  final String workplaceId;
  final String employeeId;
  final String employeeName;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final int totalMinutes;
  final bool isSubstitute;
  final String? memo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Schedule({
    required this.id,
    required this.workplaceId,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.totalMinutes,
    this.isSubstitute = false,
    this.memo,
    required this.createdAt,
    required this.updatedAt,
  });

  // Supabase에서 데이터 가져올 때 사용
  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] as String,
      workplaceId: json['workplace_id'] as String? ?? '',
      employeeId: json['employee_id'] as String? ?? '',
      employeeName: json['employee_name'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String)
          : DateTime.now(),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : DateTime.now(),
      totalMinutes: json['total_minutes'] as int? ?? 0,
      isSubstitute: json['is_substitute'] as bool? ?? false,
      memo: json['memo'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  // Supabase에 저장할 때 사용
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workplace_id': workplaceId,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'date': date.toIso8601String(),
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'total_minutes': totalMinutes,
      'is_substitute': isSubstitute,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Insert용 (id 제외)
  Map<String, dynamic> toInsertJson() {
    return {
      'workplace_id': workplaceId,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'date': date.toIso8601String(),
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'total_minutes': totalMinutes,
      'is_substitute': isSubstitute,
      'memo': memo,
      // created_at, updated_at은 DB에서 자동 생성
    };
  }

  // Update용
  Map<String, dynamic> toUpdateJson() {
    return {
      'employee_id': employeeId,
      'employee_name': employeeName,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'total_minutes': totalMinutes,
      'is_substitute': isSubstitute,
      'memo': memo,
      // updated_at은 트리거에서 자동 업데이트
    };
  }

  /// 근무 시간 계산 (시간:분 형태로 반환)
  String get workTimeString {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours}시간 ${minutes}분';
  }

  /// 시작/종료 시간 문자열
  String get timeRangeString {
    final startHour = startTime.hour.toString().padLeft(2, '0');
    final startMinute = startTime.minute.toString().padLeft(2, '0');
    final endHour = endTime.hour.toString().padLeft(2, '0');
    final endMinute = endTime.minute.toString().padLeft(2, '0');
    return '$startHour:$startMinute ~ $endHour:$endMinute';
  }

  /// 대체근무 여부 표시 문자열
  String get workTypeDisplay {
    return isSubstitute ? '대체근무' : '정규근무';
  }

  /// 시간 계산 유틸리티
  static int calculateTotalMinutes(DateTime startTime, DateTime endTime) {
    return endTime.difference(startTime).inMinutes;
  }

  @override
  String toString() {
    return 'Schedule(id: $id, employeeName: $employeeName, date: $date, totalMinutes: $totalMinutes)';
  }
}