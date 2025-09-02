import 'package:cloud_firestore/cloud_firestore.dart';

class Schedule {
  final String id;
  final String workplaceId;
  final String employeeId;
  final String employeeName; // 조회 편의를 위해 이름도 저장
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final int totalMinutes; // 총 근무 시간 (분 단위)
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
    required this.createdAt,
    required this.updatedAt,
  });

  factory Schedule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Schedule(
      id: doc.id,
      workplaceId: data['workplaceId'] ?? '',
      employeeId: data['employeeId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      totalMinutes: data['totalMinutes'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'workplaceId': workplaceId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'date': Timestamp.fromDate(date),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'totalMinutes': totalMinutes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
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

  /// 시간 계산 유틸리티
  static int calculateTotalMinutes(DateTime startTime, DateTime endTime) {
    return endTime.difference(startTime).inMinutes;
  }
}