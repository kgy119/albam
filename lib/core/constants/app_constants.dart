import 'package:get/get.dart';
import '../services/minimum_wage_service.dart';
import '../config/supabase_config.dart';

class AppConstants {
  // 앱 정보
  static const String appName = '알바관리';
  static const String appVersion = '1.0.0';

  // Supabase 테이블명 (Firestore 컬렉션명에서 변경)
  static const String usersTable = 'users';
  static const String workplacesTable = 'workplaces';
  static const String employeesTable = 'employees';
  static const String schedulesTable = 'schedules';
  static const String minimumWagesTable = 'minimum_wages';

  // 근로기준법 관련 상수
  static const int weeklyHolidayMinHours = 15;
  static const int weeklyHolidayMaxHours = 8;

  // 최저시급 조회 (기존과 동일)
  static int getCurrentMinimumWage() {
    try {
      final service = Get.find<MinimumWageService>();
      return service.getCurrentMinimumWage();
    } catch (e) {
      print('MinimumWageService를 찾을 수 없음: $e');
      return 10320;
    }
  }

  static int getMinimumWageByYear(int year) {
    try {
      final service = Get.find<MinimumWageService>();
      return service.getMinimumWageByYear(year);
    } catch (e) {
      print('MinimumWageService를 찾을 수 없음: $e');
      return 10320;
    }
  }

  static int getMinimumWageByDate(DateTime date) {
    try {
      final service = Get.find<MinimumWageService>();
      return service.getMinimumWageByDate(date);
    } catch (e) {
      print('MinimumWageService를 찾을 수 없음: $e');
      return 10320;
    }
  }
}