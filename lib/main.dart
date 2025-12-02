import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

import 'firebase_options.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'core/services/auth_service.dart';
import 'core/services/workplace_service.dart';
import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Kakao SDK 초기화 (가장 먼저!)
  KakaoSdk.init(
    nativeAppKey: AppConstants.kakaoNativeAppKey,
  );
  print('Kakao SDK 초기화 완료: ${AppConstants.kakaoNativeAppKey}');

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
      initialRoute: AppRoutes.login,
      getPages: AppPages.routes,
      locale: const Locale('ko', 'KR'),
      fallbackLocale: const Locale('en', 'US'),
    );
  }
}