import 'package:flutter/material.dart';

class DateUtils {
  /// 요일 텍스트 반환 (1:월 ~ 7:일)
  static String getWeekdayText(int weekday) {
    switch (weekday) {
      case 1:
        return '월';
      case 2:
        return '화';
      case 3:
        return '수';
      case 4:
        return '목';
      case 5:
        return '금';
      case 6:
        return '토';
      case 7:
        return '일';
      default:
        return '';
    }
  }

  /// 요일 색상 반환 (어두운 배경용)
  static Color getWeekdayColorForDarkBg(int weekday) {
    if (weekday == 7) {
      // 일요일
      return Colors.red[200]!;
    } else if (weekday == 6) {
      // 토요일
      return Colors.blue[200]!;
    } else {
      // 평일 (월~금)
      return Colors.grey[300]!;
    }
  }

  /// 요일 색상 반환 (밝은 배경용 - CircleAvatar 등)
  static Color getWeekdayColorForLightBg(int weekday, {bool dimmed = false}) {
    Color color;
    if (weekday == 7) {
      // 일요일
      color = Colors.red;
    } else if (weekday == 6) {
      // 토요일
      color = Colors.blue;
    } else {
      // 평일 (월~금)
      color = Colors.grey[600]!;
    }

    return dimmed ? color.withOpacity(0.6) : color;
  }

  /// 요일 텍스트 색상 반환 (일반 텍스트용)
  static Color? getWeekdayTextColor(int weekday) {
    if (weekday == 7) {
      // 일요일
      return Colors.red[700];
    } else if (weekday == 6) {
      // 토요일
      return Colors.blue[700];
    } else {
      // 평일
      return null; // 기본 색상 사용
    }
  }
}