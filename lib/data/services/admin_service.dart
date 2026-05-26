import '../api/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';

/// Service quản lý người dùng dành cho Admin/Organizer
class AdminService {
  static const String _baseUrl = AppConstants.adminUsersEndpoint;

  /// Lấy danh sách tất cả users, tuỳ chọn lọc theo role (client-side)
  static Future<List<UserModel>> getUsers({String? roleFilter}) async {
    final data = await ApiClient.get(_baseUrl);

    // Hỗ trợ cả plain array lẫn response có phân trang (wrapped object)
    final List<dynamic> jsonList;
    if (data is List) {
      jsonList = data;
    } else if (data is Map<String, dynamic>) {
      // Thử các field phổ biến của paginated response
      final wrapped =
          data['items'] ??
          data['data'] ??
          data['users'] ??
          data['result'] ??
          data['content'] ??
          [];
      jsonList = wrapped is List ? wrapped : [];
    } else {
      jsonList = [];
    }

    final filtered = roleFilter != null
        ? jsonList.where(
            (item) =>
                (item['role'] as String?)?.toLowerCase() ==
                roleFilter.toLowerCase(),
          )
        : jsonList;

    return filtered.map((item) => UserModel.fromJson(item)).toList();
  }

  /// Lấy chi tiết user kèm lịch sử đăng ký sự kiện — GET /{id}
  static Future<Map<String, dynamic>> getUserDetail(int userId) async {
    final data = await ApiClient.get('$_baseUrl/$userId');
    return data is Map<String, dynamic> ? data : {};
  }

  /// Lấy danh sách sự kiện user đã tham gia
  static Future<List<dynamic>> getUserAttendedEvents(int userId) async {
    final data = await ApiClient.get('$_baseUrl/$userId/attended-events');
    return data is List ? data : [];
  }

  /// Tạo tài khoản người dùng mới — throws ApiException nếu thất bại
  static Future<UserModel> createUser({
    required String userName,
    required String email,
    required String password,
    required String role,
  }) async {
    final data = await ApiClient.post(
      _baseUrl,
      body: {
        'userName': userName,
        'email': email,
        'password': password,
        'role': role,
      },
    );
    return UserModel.fromJson(data as Map<String, dynamic>);
  }

  /// Khóa tài khoản user — throws ApiException nếu thất bại
  static Future<void> lockUser(int userId) async {
    await ApiClient.put('$_baseUrl/$userId/lock');
  }

  /// Mở khóa tài khoản user — throws ApiException nếu thất bại
  static Future<void> unlockUser(int userId) async {
    await ApiClient.put('$_baseUrl/$userId/unlock');
  }

  /// Cập nhật thông tin user (userName, email, role) qua PUT/PATCH /{id}
  /// — throws ApiException nếu thất bại
  static Future<void> updateUserInfo(
    int userId, {
    String? userName,
    String? email,
    String? role,
  }) async {
    final body = <String, dynamic>{};
    if (userName != null) body['userName'] = userName;
    if (email != null) body['email'] = email;
    if (role != null) body['role'] = role;
    await ApiClient.put('$_baseUrl/$userId', body: body);
  }

  /// Xóa tài khoản user — throws ApiException nếu thất bại
  static Future<void> deleteUser(int userId) async {
    await ApiClient.delete('$_baseUrl/$userId');
  }
}
