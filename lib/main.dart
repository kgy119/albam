import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

import 'firebase_options.dart'; // FlutterFire CLI로 생성된 파일
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'core/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 서비스 등록
  await Get.putAsync(() => AuthService().init());

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
    );
  }
}