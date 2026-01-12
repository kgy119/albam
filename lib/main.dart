import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/config/supabase_config.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'core/services/auth_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/workplace_service.dart';
import 'core/services/minimum_wage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Supabase 초기화 (딥링크 자동 처리 포함)
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce, // ✅ PKCE 플로우 사용
    ),
    debug: true, // ✅ 디버그 로그 활성화
  );

  print('✅ Supabase 초기화 완료 (딥링크 처리 포함)');

  // 로케일 초기화
  await initializeDateFormatting('ko_KR', null);

  // 서비스 등록
  print('서비스 등록 시작...');

  await Get.putAsync(() => AuthService().init());
  print('✅ AuthService 등록 완료');

  Get.put(ConnectivityService());
  Get.put(WorkplaceService());
  print('✅ WorkplaceService 등록 완료');

  await Get.putAsync(() => MinimumWageService().init());
  print('✅ MinimumWageService 등록 완료');

  print('🚀 앱 시작');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '알밤',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.login,
      getPages: AppPages.routes,
      locale: const Locale('ko', 'KR'),
      fallbackLocale: const Locale('en', 'US'),
    );
  }
}