import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../../core/routes/app_routes.dart';

/// API Client trung tâm — xử lý:
/// - Tự động đính kèm Authorization header
/// - Timeout 30 giây cho mọi request
/// - Xử lý 401 (token hết hạn) → tự động redirect về Login
/// - Phân loại lỗi mạng rõ ràng cho user
class ApiClient {
  static const Duration _timeout = Duration(seconds: 30);
  static final GetStorage _box = GetStorage();

  /// Lấy access token từ bộ nhớ cục bộ
  static String? _getToken() => _box.read("accessToken");

  /// Kiểm tra token có hết hạn chưa
  static bool _isTokenExpired() {
    final expiryStr = _box.read("tokenExpiry") as String?;
    if (expiryStr == null) return false; // Không có thông tin → coi như còn hạn
    try {
      final expiry = DateTime.parse(expiryStr);
      return DateTime.now().isAfter(expiry);
    } catch (_) {
      return false;
    }
  }

  /// Xây dựng headers chung cho mọi request
  static Map<String, String> _buildHeaders({bool withAuth = true}) {
    final headers = <String, String>{
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
    if (withAuth) {
      final token = _getToken();
      if (token != null && token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }
    }
    return headers;
  }

  /// Xử lý response chung — check 401 và trả về parsed body
  /// [withAuth] = false khi gọi từ login/register → không redirect, parse message thực từ backend
  static dynamic _handleResponse(
    http.Response response, {
    bool withAuth = true,
  }) {
    if (response.statusCode == 401) {
      if (withAuth) {
        _handleUnauthorized();
        throw ApiException(
          "Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.",
          401,
        );
      }
      // withAuth = false (login/register) → parse message thực từ backend
    }

    if (response.statusCode == 403) {
      throw ApiException("Tài khoản của bạn đã bị khóa.", 403);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return response.body; // Trường hợp backend trả text thuần
      }
    }

    // Parse error message từ server
    String errorMessage = "Lỗi ${response.statusCode}";
    try {
      final errorData = jsonDecode(response.body);
      if (errorData is Map<String, dynamic>) {
        if (errorData.containsKey("message")) {
          // Phổ biến: {"message": "..."}
          errorMessage = errorData["message"].toString();
        } else if (errorData.containsKey("errors")) {
          // .NET validation errors: {"errors":{"Field":["msg"]}, "title":"..."}
          final errors = errorData["errors"];
          if (errors is Map) {
            final msgs = errors.values
                .expand(
                  (v) =>
                      v is List ? v.map((e) => e.toString()) : [v.toString()],
                )
                .join('; ');
            errorMessage = msgs.isNotEmpty
                ? msgs
                : (errorData["title"]?.toString() ?? errorMessage);
          } else {
            errorMessage = errorData["title"]?.toString() ?? errorMessage;
          }
        } else if (errorData.containsKey("title")) {
          errorMessage = errorData["title"].toString();
        }
      } else if (errorData is String) {
        errorMessage = errorData;
      }
    } catch (_) {
      if (response.body.isNotEmpty) {
        errorMessage = response.body;
      }
    }

    throw ApiException(errorMessage, response.statusCode);
  }

  /// Xử lý lỗi mạng/timeout
  static Never _handleError(Object error) {
    if (error is SocketException) {
      throw ApiException("Mất kết nối mạng. Vui lòng kiểm tra lại.", 0);
    }
    if (error is TimeoutException) {
      throw ApiException("Server không phản hồi. Vui lòng thử lại.", 0);
    }
    if (error is FormatException) {
      throw ApiException("Dữ liệu phản hồi không hợp lệ.", 0);
    }
    if (error is ApiException) {
      throw error;
    }
    throw ApiException("Có lỗi xảy ra: $error", 0);
  }

  /// Xử lý khi nhận 401 — xóa session và redirect về Login
  static void _handleUnauthorized() {
    _box.remove("accessToken");
    _box.remove("role");
    _box.remove("userName");
    _box.remove("tokenExpiry");

    // Chỉ redirect nếu đang không ở màn Login
    if (Get.currentRoute != AppRoutes.login) {
      Get.offAllNamed(AppRoutes.login);
      Get.snackbar(
        "Hết phiên đăng nhập",
        "Vui lòng đăng nhập lại để tiếp tục.",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ─── PUBLIC METHODS ────────────────────────────────────────────

  /// HTTP GET
  static Future<dynamic> get(String endpoint, {bool withAuth = true}) async {
    // Kiểm tra token trước khi gọi
    if (withAuth && _isTokenExpired()) {
      _handleUnauthorized();
      throw ApiException("Token hết hạn.", 401);
    }

    try {
      final url = Uri.parse(endpoint);
      final response = await http
          .get(url, headers: _buildHeaders(withAuth: withAuth))
          .timeout(_timeout);
      return _handleResponse(response, withAuth: withAuth);
    } catch (e) {
      _handleError(e);
    }
  }

  /// HTTP POST
  static Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    if (withAuth && _isTokenExpired()) {
      _handleUnauthorized();
      throw ApiException("Token hết hạn.", 401);
    }

    try {
      final url = Uri.parse(endpoint);
      final response = await http
          .post(
            url,
            headers: _buildHeaders(withAuth: withAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);
      return _handleResponse(response, withAuth: withAuth);
    } catch (e) {
      _handleError(e);
    }
  }

  /// HTTP PUT
  static Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    if (withAuth && _isTokenExpired()) {
      _handleUnauthorized();
      throw ApiException("Token hết hạn.", 401);
    }

    try {
      final url = Uri.parse(endpoint);
      final response = await http
          .put(
            url,
            headers: _buildHeaders(withAuth: withAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);
      return _handleResponse(response, withAuth: withAuth);
    } catch (e) {
      _handleError(e);
    }
  }

  /// HTTP PATCH
  static Future<dynamic> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    if (withAuth && _isTokenExpired()) {
      _handleUnauthorized();
      throw ApiException("Token hết hạn.", 401);
    }

    try {
      final url = Uri.parse(endpoint);
      final response = await http
          .patch(
            url,
            headers: _buildHeaders(withAuth: withAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);
      return _handleResponse(response, withAuth: withAuth);
    } catch (e) {
      _handleError(e);
    }
  }

  /// HTTP DELETE
  static Future<dynamic> delete(String endpoint, {bool withAuth = true}) async {
    if (withAuth && _isTokenExpired()) {
      _handleUnauthorized();
      throw ApiException("Token hết hạn.", 401);
    }

    try {
      final url = Uri.parse(endpoint);
      final response = await http
          .delete(url, headers: _buildHeaders(withAuth: withAuth))
          .timeout(_timeout);
      return _handleResponse(response, withAuth: withAuth);
    } catch (e) {
      _handleError(e);
    }
  }
}

/// Custom exception để phân biệt lỗi API với lỗi khác
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
