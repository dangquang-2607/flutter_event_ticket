import 'package:get/get.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/events/screens/event_list_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/profile/screens/change_email_screen.dart';
import '../../features/profile/screens/change_password_screen.dart';
import '../../features/admin/screens/user_management_screen.dart';
import '../../features/admin/screens/ticket_management_screen.dart';
import 'auth_middleware.dart';

class AppRoutes {
  static const login = '/login';
  static const home = '/home';
  static const events = '/events';
  static const profile = '/profile';
  static const register = '/register';
  static const changeEmail = '/change-email';
  static const changePassword = '/change-password';
  static const userManagement = '/user-management';
  static const ticketManagement = '/ticket-management';
}

class AppPages {
  static final pages = [
    // --- Public routes (không cần đăng nhập) ---
    GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
    GetPage(name: AppRoutes.register, page: () => const RegisterScreen()),

    // --- Protected routes (yêu cầu đăng nhập) ---
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.events,
      page: () => const EventListScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.changeEmail,
      page: () => const ChangeEmailScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.changePassword,
      page: () => const ChangePasswordScreen(),
      middlewares: [AuthMiddleware()],
    ),

    // --- Admin routes (yêu cầu đăng nhập + role Organizer) ---
    GetPage(
      name: AppRoutes.userManagement,
      page: () => const UserManagementScreen(),
      middlewares: [AuthMiddleware(), RoleMiddleware()],
    ),
    GetPage(
      name: AppRoutes.ticketManagement,
      page: () => const TicketManagementScreen(),
      middlewares: [AuthMiddleware(), RoleMiddleware()],
    ),
  ];
}
