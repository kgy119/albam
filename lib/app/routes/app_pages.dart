import 'package:get/get.dart';

import 'app_routes.dart';
import '../../presentation/views/auth/login_view.dart';
import '../../presentation/views/home/home_view.dart';
import '../../presentation/controllers/auth_controller.dart';
import '../../presentation/controllers/workplace_controller.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AuthController>(() => AuthController());
      }),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<WorkplaceController>(() => WorkplaceController());
      }),
    ),
    // 추후 추가될 페이지들은 각 단계에서 구현
  ];
}