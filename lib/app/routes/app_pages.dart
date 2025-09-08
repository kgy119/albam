import 'package:get/get.dart';

import '../../presentation/controllers/add_employee_controller.dart';
import '../../presentation/controllers/salary_controller.dart';
import '../../presentation/controllers/schedule_setting_controller.dart';
import '../../presentation/controllers/workplace_detail_controller.dart';
import '../../presentation/views/employee/add_employee_view.dart';
import '../../presentation/views/employee/employee_list_view.dart';
import '../../presentation/views/salary/salary_view.dart';
import '../../presentation/views/schedule/schedule_setting_view.dart';
import '../../presentation/views/workplace/workplace_detail_view.dart';
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
    GetPage(
      name: AppRoutes.workplaceDetail,
      page: () => const WorkplaceDetailView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<WorkplaceDetailController>(() => WorkplaceDetailController());
      }),
    ),
    GetPage(
      name: AppRoutes.employeeList,
      page: () => const EmployeeListView(),
    ),
    GetPage(
      name: AppRoutes.addEmployee,
      page: () => const AddEmployeeView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AddEmployeeController>(() => AddEmployeeController());
      }),
    ),
    GetPage(
      name: AppRoutes.scheduleSetting,
      page: () => const ScheduleSettingView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ScheduleSettingController>(() => ScheduleSettingController());
      }),
    ),
    GetPage(
      name: AppRoutes.salaryView,
      page: () => const SalaryView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SalaryController>(() => SalaryController());
      }),
    ),
  ];
}