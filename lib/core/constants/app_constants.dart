class AppConstants {
  // 앱 정보
  static const String appName = 'Albam';
  static const String appVersion = '1.0.0';

  // Firebase 컬렉션명
  static const String usersCollection = 'users';
  static const String workplacesCollection = 'workplaces';
  static const String employeesCollection = 'employees';
  static const String schedulesCollection = 'schedules';

  // 근로기준법 관련 상수
  static const int standardWorkHours = 40; // 주 40시간
  static const int standardDailyWorkHours = 8; // 일 8시간
  static const double overtimeRate = 1.5; // 연장근무 50% 가산
  static const double nightWorkRate = 1.5; // 야간근무 50% 가산 (22시~6시)
  static const double holidayWorkRate = 1.5; // 휴일근무 50% 가산

  // 시간 관련 상수
  static const int nightWorkStartHour = 22; // 야간근무 시작시간
  static const int nightWorkEndHour = 6; // 야간근무 종료시간
}