import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart'; // FlutterFire CLI로 생성된 파일
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'core/services/auth_service.dart';
import 'core/services/workplace_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('ko_KR', null);

  // 서비스 등록 (순서 중요)
  await Get.putAsync(() => AuthService().init());

  // AuthService가 초기화된 후 WorkplaceService 등록
  Get.put(WorkplaceService());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Albam',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      // 항상 로그인 화면으로 시작 (AuthController에서 자동 리디렉션 처리)
      initialRoute: AppRoutes.login,
      getPages: AppPages.routes,
      // 한국어 로케일 설정
      locale: const Locale('ko', 'KR'),
      fallbackLocale: const Locale('en', 'US'),
    );
  }
}