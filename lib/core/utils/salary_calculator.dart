import '../../data/models/schedule_model.dart';
import '../constants/app_constants.dart';

class SalaryCalculator {
  /// 월 급여 계산 (일용직: 기본급 + 주휴수당)
  static Map<String, dynamic> calculateMonthlySalary({
    required List<Schedule> schedules,
    required double hourlyWage,
  }) {
    double totalHours = 0;
    double weeklyHolidayHours = 0;

    // 주별 근무 정리
    Map<int, Map<DateTime, double>> weeklySchedules = {};
    Map<DateTime, double> dailyHours = {};

    for (var schedule in schedules) {
      final date = DateTime(schedule.date.year, schedule.date.month, schedule.date.day);
      final hours = schedule.totalMinutes / 60.0;

      // 일별 근무시간 누적
      dailyHours[date] = (dailyHours[date] ?? 0) + hours;

      // 주별 스케줄 정리
      int weekNumber = _getWeekOfMonth(date);
      weeklySchedules[weekNumber] ??= {};
      weeklySchedules[weekNumber]![date] =
          (weeklySchedules[weekNumber]![date] ?? 0) + hours;

      totalHours += hours;
    }

    // 주휴수당 계산
    weeklyHolidayHours = _calculateWeeklyHolidayHours(weeklySchedules);

    // 급여 계산
    double basicPay = totalHours * hourlyWage;
    double weeklyHolidayPay = weeklyHolidayHours * hourlyWage;
    double totalPay = basicPay + weeklyHolidayPay;

    return {
      'totalHours': totalHours,
      'weeklyHolidayHours': weeklyHolidayHours,
      'basicPay': basicPay,
      'weeklyHolidayPay': weeklyHolidayPay,
      'totalPay': totalPay,
      'weeklyBreakdown': _getWeeklyBreakdown(weeklySchedules),
    };
  }

  /// 주휴수당 시간 계산
  static double _calculateWeeklyHolidayHours(
      Map<int, Map<DateTime, double>> weeklySchedules) {
    double totalWeeklyHolidayHours = 0;

    weeklySchedules.forEach((week, dailySchedules) {
      double weekTotalHours = 0;
      int workDays = 0;

      dailySchedules.forEach((date, hours) {
        weekTotalHours += hours;
        if (hours > 0) workDays++;
      });

      // 주 15시간 이상 근무 시 주휴수당 지급
      if (weekTotalHours >= AppConstants.weeklyHolidayMinHours && workDays > 0) {
        double holidayHours = weekTotalHours / workDays;
        // 최대 8시간 제한
        if (holidayHours > AppConstants.weeklyHolidayMaxHours) {
          holidayHours = AppConstants.weeklyHolidayMaxHours.toDouble();
        }
        totalWeeklyHolidayHours += holidayHours;
      }
    });

    return totalWeeklyHolidayHours;
  }

  /// 주별 근무시간 요약
  static Map<int, double> _getWeeklyBreakdown(
      Map<int, Map<DateTime, double>> weeklySchedules) {
    Map<int, double> weeklyHours = {};

    weeklySchedules.forEach((week, dailySchedules) {
      double total = 0;
      dailySchedules.forEach((date, hours) {
        total += hours;
      });
      weeklyHours[week] = total;
    });

    return weeklyHours;
  }

  /// 월의 주차 계산
  static int _getWeekOfMonth(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final firstMonday = firstDayOfMonth.weekday == DateTime.monday
        ? firstDayOfMonth
        : firstDayOfMonth.add(
      Duration(days: (8 - firstDayOfMonth.weekday) % 7),
    );

    if (date.isBefore(firstMonday)) {
      return 0; // 첫 주
    }

    return ((date.difference(firstMonday).inDays) / 7).floor() + 1;
  }
}