import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app_routes.dart';

/// Middleware bảo vệ các route yêu cầu đăng nhập
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final box = GetStorage();
    final token = box.read("accessToken");

    if (token == null || token.toString().isEmpty) {
      return const RouteSettings(name: AppRoutes.login);
    }

    // Kiểm tra token hết hạn
    final expiryStr = box.read("tokenExpiry") as String?;
    if (expiryStr != null) {
      try {
        final expiry = DateTime.parse(expiryStr);
        if (DateTime.now().isAfter(expiry)) {
          // Xóa session hết hạn
          box.remove("accessToken");
          box.remove("role");
          box.remove("userName");
          box.remove("tokenExpiry");
          return const RouteSettings(name: AppRoutes.login);
        }
      } catch (_) {
        // Parse lỗi → bỏ qua check expiry
      }
    }

    return null; // Cho phép truy cập
  }
}

/// Middleware bảo vệ các route chỉ dành cho Organizer/Admin
class RoleMiddleware extends GetMiddleware {
  @override
  int? get priority => 2;

  @override
  RouteSettings? redirect(String? route) {
    final box = GetStorage();
    final role = box.read("role") as String? ?? "";

    if (role.toLowerCase() != "organizer") {
      return const RouteSettings(name: AppRoutes.home);
    }

    return null; // Cho phép truy cập
  }
}
