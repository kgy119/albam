class AppConstants {
  // 앱 정보
  static const String appName = 'Albam';
  static const String appVersion = '1.0.0';

  // Firebase 컬렉션명
  static const String usersCollection = 'users';
  static const String workplacesCollection = 'workplaces';
  static const String employeesCollection = 'employees';
  static const String schedulesCollection = 'schedules';

  // 근로기준법 관련 상수 (2025년 기준 - 일용직)
  static const int minimumWage = 10030; // 2025년 최저시급
  static const int weeklyHolidayMinHours = 15; // 주휴수당 지급 최소 근무시간
  static const int weeklyHolidayMaxHours = 8; // 주휴수당 최대 시간 (8시간)

  static const String kakaoNativeAppKey = '4f0023e9f5cc2bb0c464717c77418c1a';

}