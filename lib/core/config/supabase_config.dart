class SupabaseConfig {
  static const String supabaseUrl = 'https://iuzusurmnktpfqunfjsh.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_x1jx7atThjG3joiLRrv3ZA_MBBT38bu';

  // Storage bucket
  static const String contractsBucket = 'contracts';

  // 테이블 이름
  static const String usersTable = 'users';
  static const String workplacesTable = 'workplaces';
  static const String employeesTable = 'employees';
  static const String schedulesTable = 'schedules';
  static const String minimumWagesTable = 'minimum_wages';

  // Storage 상수
  static const int maxImageSizeMB = 5;
  static const int maxImageSizeBytes = maxImageSizeMB * 1024 * 1024;

  static const List<String> allowedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
  ];

  static const List<String> allowedMimeTypes = [
    'image/jpeg',
    'image/png',
  ];
}