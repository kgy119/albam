import '../../data/models/schedule_model.dart';
import '../constants/app_constants.dart';

import '../../data/models/schedule_model.dart';
import '../constants/app_constants.dart';

class SalaryCalculator {
  /// 월 급여 계산 (일용직: 기본급 + 주휴수당 - 세금)
  static Map<String, dynamic> calculateMonthlySalary({
    required List<Schedule> schedules,
    required double hourlyWage,
    List<Schedule>? previousMonthSchedules,
  }) {
    double totalHours = 0;
    double regularHours = 0;
    double substituteHours = 0;
    double weeklyHolidayHours = 0;

    int regularDays = 0;
    int substituteDays = 0;

    Map<int, Map<DateTime, double>> weeklySchedules = {};
    Map<int, Map<DateTime, double>> weeklySubstituteSchedules = {};
    Map<DateTime, double> dailyHours = {};

    for (var schedule in schedules) {
      final date = DateTime(schedule.date.year, schedule.date.month, schedule.date.day);
      final hours = schedule.totalMinutes / 60.0;

      dailyHours[date] = (dailyHours[date] ?? 0) + hours;
      totalHours += hours;

      int weekNumber = _getWeekOfMonth(date);

      if (schedule.isSubstitute) {
        substituteHours += hours;
        if (!dailyHours.containsKey(date) || dailyHours[date] == hours) {
          substituteDays++;
        }

        weeklySubstituteSchedules[weekNumber] ??= {};
        weeklySubstituteSchedules[weekNumber]![date] =
            (weeklySubstituteSchedules[weekNumber]![date] ?? 0) + hours;
      } else {
        regularHours += hours;
        if (!dailyHours.containsKey(date) || dailyHours[date] == hours) {
          regularDays++;
        }

        weeklySchedules[weekNumber] ??= {};
        weeklySchedules[weekNumber]![date] =
            (weeklySchedules[weekNumber]![date] ?? 0) + hours;
      }
    }

    weeklyHolidayHours = _calculateWeeklyHolidayHoursWithPreviousMonth(
      weeklySchedules,
      previousMonthSchedules,
      schedules.isNotEmpty ? schedules.first.date : DateTime.now(),
    );

    double basicPay = totalHours * hourlyWage;
    double weeklyHolidayPay = weeklyHolidayHours * hourlyWage;
    double totalPay = basicPay + weeklyHolidayPay;

    double tax = totalPay * 0.033;
    double netPay = totalPay - tax;

    return {
      'totalHours': totalHours,
      'regularHours': regularHours,
      'substituteHours': substituteHours,
      'regularDays': regularDays,
      'substituteDays': substituteDays,
      'weeklyHolidayHours': weeklyHolidayHours,
      'basicPay': basicPay,
      'weeklyHolidayPay': weeklyHolidayPay,
      'totalPay': totalPay,
      'tax': tax,
      'netPay': netPay,
      'weeklyBreakdown': _getWeeklyBreakdown(
        weeklySchedules,
        weeklySubstituteSchedules,
        previousMonthSchedules,
        schedules.isNotEmpty ? schedules.first.date : DateTime.now(),
      ),
    };
  }

  /// 월의 주차 계산 (일요일 시작, 1일이 속한 주를 1주차로)
  static int _getWeekOfMonth(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);

    // 1일이 속한 주의 일요일 찾기
    int daysFromSunday = firstDayOfMonth.weekday % 7; // 일요일=0
    final firstWeekSunday = firstDayOfMonth.subtract(Duration(days: daysFromSunday));

    // 현재 날짜가 속한 주의 일요일 찾기
    int currentDaysFromSunday = date.weekday % 7;
    final currentWeekSunday = date.subtract(Duration(days: currentDaysFromSunday));

    // 주차 계산 (1주차부터 시작)
    int weekNumber = ((currentWeekSunday.difference(firstWeekSunday).inDays) / 7).floor() + 1;

    return weekNumber;
  }

  /// 주휴수당 시간 계산 (전달 마지막 주 고려, 일요일~토요일 기준)
  static double _calculateWeeklyHolidayHoursWithPreviousMonth(
      Map<int, Map<DateTime, double>> weeklySchedules,
      List<Schedule>? previousMonthSchedules,
      DateTime currentMonthDate,
      ) {
    double totalWeeklyHolidayHours = 0;

    weeklySchedules.forEach((week, dailySchedules) {
      double weekTotalHours = 0;
      int workDays = 0;

      // 1주차인 경우 전달 마지막 주와 연결 확인
      if (week == 1 && previousMonthSchedules != null && previousMonthSchedules.isNotEmpty) {
        final firstDateOfWeek1 = dailySchedules.keys.reduce((a, b) => a.isBefore(b) ? a : b);

        // 1일이 일요일이 아닌 경우에만 전월과 연결됨
        final firstDayOfMonth = DateTime(firstDateOfWeek1.year, firstDateOfWeek1.month, 1);
        if (firstDayOfMonth.weekday != DateTime.sunday) {
          // 1주차의 일요일 찾기
          int daysFromSunday = firstDateOfWeek1.weekday % 7;
          final week1Sunday = firstDateOfWeek1.subtract(Duration(days: daysFromSunday));

          // 전달 마지막 주에 해당하는 정규근무 찾기
          final previousMonthLastWeekSchedules = previousMonthSchedules.where((schedule) {
            if (schedule.isSubstitute) return false;

            final scheduleDate = DateTime(
              schedule.date.year,
              schedule.date.month,
              schedule.date.day,
            );

            // week1Sunday와 같은 주에 속하는지 확인 (일요일 기준)
            int scheduleDaysFromSunday = scheduleDate.weekday % 7;
            final scheduleSunday = scheduleDate.subtract(Duration(days: scheduleDaysFromSunday));

            return scheduleSunday.isAtSameMomentAs(week1Sunday);
          }).toList();

          // 전달 근무시간 합산
          for (var schedule in previousMonthLastWeekSchedules) {
            weekTotalHours += schedule.totalMinutes / 60.0;
            workDays++;
          }
        }
      }

      // 현재 월 근무시간 합산
      dailySchedules.forEach((date, hours) {
        weekTotalHours += hours;
        if (hours > 0) workDays++;
      });

      // 주 15시간 이상 근무 시 주휴수당 지급
      if (weekTotalHours >= AppConstants.weeklyHolidayMinHours && workDays > 0) {
        double dailyAverage = weekTotalHours / workDays;
        double holidayHours = dailyAverage > 8 ? 8 : dailyAverage;
        totalWeeklyHolidayHours += holidayHours;
      }
    });

    // 2주차 이상은 기존 로직
    weeklySchedules.forEach((week, dailySchedules) {
      if (week == 1) return; // 1주차는 이미 처리함

      double weekTotalHours = 0;
      int workDays = 0;

      dailySchedules.forEach((date, hours) {
        weekTotalHours += hours;
        if (hours > 0) workDays++;
      });

      if (weekTotalHours >= AppConstants.weeklyHolidayMinHours && workDays > 0) {
        double dailyAverage = weekTotalHours / workDays;
        double holidayHours = dailyAverage > 8 ? 8 : dailyAverage;
        totalWeeklyHolidayHours += holidayHours;
      }
    });

    return totalWeeklyHolidayHours;
  }

  /// 주별 근무시간 요약 (정규 + 대체 + 전달 연결 정보 + 각 주 주휴수당)
  static Map<int, Map<String, dynamic>> _getWeeklyBreakdown(
      Map<int, Map<DateTime, double>> weeklySchedules,
      Map<int, Map<DateTime, double>> weeklySubstituteSchedules,
      List<Schedule>? previousMonthSchedules,
      DateTime currentMonthDate) {
    Map<int, Map<String, dynamic>> weeklyHours = {};

    // 정규근무 집계
    weeklySchedules.forEach((week, dailySchedules) {
      double total = 0;
      dailySchedules.forEach((date, hours) {
        total += hours;
      });
      weeklyHours[week] = {
        'regular': total,
        'substitute': 0.0,
        'total': total,
        'previousMonthRegular': 0.0,
        'weeklyHolidayFromPrevious': 0.0,
        'weeklyHolidayHours': 0.0, // 이번 주 주휴수당 시간
      };
    });

    // 대체근무 집계
    weeklySubstituteSchedules.forEach((week, dailySchedules) {
      double total = 0;
      dailySchedules.forEach((date, hours) {
        total += hours;
      });

      if (weeklyHours.containsKey(week)) {
        weeklyHours[week]!['substitute'] = total;
        weeklyHours[week]!['total'] = (weeklyHours[week]!['total'] as double) + total;
      } else {
        weeklyHours[week] = {
          'regular': 0.0,
          'substitute': total,
          'total': total,
          'previousMonthRegular': 0.0,
          'weeklyHolidayFromPrevious': 0.0,
          'weeklyHolidayHours': 0.0,
        };
      }
    });

    // 1주차 전월 연결 확인
    if (weeklyHours.containsKey(1) && previousMonthSchedules != null && previousMonthSchedules.isNotEmpty) {
      final week1Data = weeklySchedules[1];
      if (week1Data != null && week1Data.isNotEmpty) {
        final firstDateOfWeek1 = week1Data.keys.reduce((a, b) => a.isBefore(b) ? a : b);

        // 1일이 일요일이 아닌 경우에만 전월과 연결됨
        final firstDayOfMonth = DateTime(firstDateOfWeek1.year, firstDateOfWeek1.month, 1);
        if (firstDayOfMonth.weekday != DateTime.sunday) {
          // 1주차의 일요일 찾기
          int daysFromSunday = firstDateOfWeek1.weekday % 7;
          final week1Sunday = firstDateOfWeek1.subtract(Duration(days: daysFromSunday));

          // 전달 마지막 주에 해당하는 정규근무 찾기
          double previousMonthRegular = 0;
          int previousWorkDays = 0;

          final previousMonthLastWeekSchedules = previousMonthSchedules.where((schedule) {
            if (schedule.isSubstitute) return false;

            final scheduleDate = DateTime(
              schedule.date.year,
              schedule.date.month,
              schedule.date.day,
            );

            int scheduleDaysFromSunday = scheduleDate.weekday % 7;
            final scheduleSunday = scheduleDate.subtract(Duration(days: scheduleDaysFromSunday));

            return scheduleSunday.isAtSameMomentAs(week1Sunday);
          }).toList();

          // 전달 정규근무시간 합산
          for (var schedule in previousMonthLastWeekSchedules) {
            previousMonthRegular += schedule.totalMinutes / 60.0;
            previousWorkDays++;
          }

          if (previousMonthRegular > 0) {
            weeklyHours[1]!['previousMonthRegular'] = previousMonthRegular;

            // 주휴수당 계산
            final currentMonthRegular = weeklyHours[1]!['regular'] as double;
            final currentWorkDays = week1Data.length;
            final totalRegular = previousMonthRegular + currentMonthRegular;
            final totalWorkDays = previousWorkDays + currentWorkDays;

            if (totalRegular >= AppConstants.weeklyHolidayMinHours && totalWorkDays > 0) {
              double dailyAverage = totalRegular / totalWorkDays;
              double holidayHours = dailyAverage > 8 ? 8 : dailyAverage;
              weeklyHours[1]!['weeklyHolidayFromPrevious'] = holidayHours;
              weeklyHours[1]!['weeklyHolidayHours'] = holidayHours;
            }
          }
        }
      }
    }

    // 각 주차별 주휴수당 계산
    weeklyHours.forEach((week, data) {
      // 1주차는 이미 계산됨
      if (week == 1 && (data['weeklyHolidayFromPrevious'] as double) > 0) {
        return;
      }

      final regularHours = data['regular'] as double;

      // 정규근무 15시간 이상이면 주휴수당 계산
      if (regularHours >= AppConstants.weeklyHolidayMinHours) {
        // 해당 주의 근무일수 계산
        int workDays = 0;
        weeklySchedules[week]?.forEach((date, hours) {
          if (hours > 0) workDays++;
        });

        if (workDays > 0) {
          double dailyAverage = regularHours / workDays;
          double holidayHours = dailyAverage > 8 ? 8 : dailyAverage;
          weeklyHours[week]!['weeklyHolidayHours'] = holidayHours;
        }
      }
    });

    return weeklyHours;
  }
}