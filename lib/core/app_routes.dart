import 'package:get/get.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/events/screens/event_list_screen.dart';
import '../features/home/screen/home_screen.dart';
import '../features/profile/screen/profile_screen.dart';
import '../features/auth/screens/registerscreen/register_screen.dart';
import '../features/profile/screen/change_email_screen.dart';
import '../features/profile/screen/change_password_screen.dart';


class AppRoutes {
  static const login = '/login';
  static const home = '/home';
  static const events = '/events';
  static const profile = '/profile';
  static const register = '/register';
  static const changeEmail = '/change-email';
  static const changePassword = '/change-password';
}

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterScreen(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
    ),
    GetPage(
      name: AppRoutes.events,
      page: () => const EventListScreen(),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
    ),
    GetPage(
      name: AppRoutes.changeEmail,
      page: () => const ChangeEmailScreen(),
    ),
    GetPage(
      name: AppRoutes.changePassword,
      page: () => const ChangePasswordScreen(),
    ),
  ];
}
