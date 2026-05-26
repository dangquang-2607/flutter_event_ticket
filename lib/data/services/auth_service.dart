import '../api/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/login_response.dart';

class AuthService {
  /// Đăng nhập — trả về LoginResponse nếu thành công, null nếu thất bại
  /// Throws [ApiException] nếu đăng nhập thất bại (sai mật khẩu, bị khóa, v.v.)
  static Future<LoginResponse?> login(String username, String password) async {
    final data = await ApiClient.post(
      AppConstants.loginEndpoint,
      body: {"UserName": username, "Password": password},
      withAuth: false,
    );

    if (data != null && data is Map<String, dynamic>) {
      return LoginResponse.fromJson(data);
    }
    return null;
  }

  /// Đăng ký tài khoản mới — trả về message từ server
  /// Throws ApiException nếu lỗi (409 = trùng username, 4xx/5xx = lỗi khác)S
  static Future<String> register({
    required String username,
    required String password,
    required String email,
  }) async {
    final data = await ApiClient.post(
      AppConstants.registerEndpoint,
      body: {"userName": username, "password": password, "email": email},
      withAuth: false, // Chưa có token khi register
    );

    if (data is Map<String, dynamic>) {
      return data["message"] ?? "Đăng ký thành công!";
    }
    return "Đăng ký thành công!";
  }
}
