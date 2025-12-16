import 'package:get/get.dart';
import '../services/minimum_wage_service.dart';

class AppConstants {
  // 앱 정보
  static const String appName = 'Albam';
  static const String appVersion = '1.0.0';

  // Firebase 컬렉션명
  static const String usersCollection = 'users';
  static const String workplacesCollection = 'workplaces';
  static const String employeesCollection = 'employees';
  static const String schedulesCollection = 'schedules';
  static const String minimumWagesCollection = 'minimum_wages';

  // 근로기준법 관련 상수
  static const int weeklyHolidayMinHours = 15; // 주휴수당 지급 최소 근무시간
  static const int weeklyHolidayMaxHours = 8; // 주휴수당 최대 시간 (8시간)

  // MinimumWageService를 통한 최저시급 조회
  static int getCurrentMinimumWage() {
    try {
      final service = Get.find<MinimumWageService>();
      return service.getCurrentMinimumWage();
    } catch (e) {
      print('MinimumWageService를 찾을 수 없음: $e');
      return 10320; // 기본값
    }
  }

  static int getMinimumWageByYear(int year) {
    try {
      final service = Get.find<MinimumWageService>();
      return service.getMinimumWageByYear(year);
    } catch (e) {
      print('MinimumWageService를 찾을 수 없음: $e');
      return 10320; // 기본값
    }
  }

  static int getMinimumWageByDate(DateTime date) {
    try {
      final service = Get.find<MinimumWageService>();
      return service.getMinimumWageByDate(date);
    } catch (e) {
      print('MinimumWageService를 찾을 수 없음: $e');
      return 10320; // 기본값
    }
  }
}