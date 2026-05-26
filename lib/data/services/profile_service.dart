import '../api/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';

class ProfileService {
  static const String _baseUrl = AppConstants.profileEndpoint;

  /// Lấy thông tin cá nhân dưới dạng UserModel
  static Future<UserModel> getProfile() async {
    final data = await ApiClient.get(_baseUrl);
    return UserModel.fromJson(data);
  }

  /// Lấy thông tin cá nhân dưới dạng Map (backward-compatible)
  static Future<Map<String, dynamic>> getProfileMap() async {
    final data = await ApiClient.get(_baseUrl);
    if (data is Map<String, dynamic>) return data;
    return Map<String, dynamic>.from(data);
  }

  /// Yêu cầu thay đổi email — gửi link xác nhận
  static Future<String> requestChangeEmail(String newEmail) async {
    final data = await ApiClient.post(
      "$_baseUrl/email/request-change",
      body: {"newEmail": newEmail},
    );

    if (data is Map<String, dynamic>) {
      return data["message"] ?? "Yêu cầu đã được gửi thành công.";
    }
    return "Yêu cầu đã được gửi thành công.";
  }

  /// Thay đổi mật khẩu
  static Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    final data = await ApiClient.put(
      "$_baseUrl/password",
      body: {
        "currentPassword": currentPassword,
        "newPassword": newPassword,
        "confirmNewPassword": confirmNewPassword,
      },
    );

    if (data is Map<String, dynamic>) {
      return data["message"] ?? "Đổi mật khẩu thành công.";
    }
    if (data is String) return data;
    return "Đổi mật khẩu thành công.";
  }
}
