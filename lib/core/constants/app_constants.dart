class AppConstants {
  // 앱 정보
  static const String appName = 'Albam';
  static const String appVersion = '1.0.0';

  // Firebase 컬렉션명
  static const String usersCollection = 'users';
  static const String workplacesCollection = 'workplaces';
  static const String employeesCollection = 'employees';
  static const String schedulesCollection = 'schedules';

  // 근로기준법 관련 상수 (2025년 기준)
  static const int standardWorkHours = 40; // 주 40시간 기준
  static const int standardDailyWorkHours = 8; // 일 8시간
  static const int minimumWage = 10030; // 2025년 최저시급

  // 주휴수당 관련
  static const int weeklyHolidayRequiredHours = 15; // 주 15시간 이상 근무시 주휴수당 지급 자격
  static const int weeklyHolidayMaxHours = 8; // 주휴수당 최대 시간 (8시간)
  static const int weeklyStandardHours = 40; // 주휴수당 계산 기준 시간 (40시간)
}