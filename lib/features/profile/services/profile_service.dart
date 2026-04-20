import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class ProfileService {
  static const String _baseUrl = "http://10.0.2.2:5054/api";

  static Future<Map<String, dynamic>> getProfile() async {
    final box = GetStorage();
    final token = box.read("accessToken");

    // Bỏ kiểm tra token ở đây vì ProfileScreen đã xử lý việc chuyển hướng
    // khi không có token. Service giờ chỉ tập trung vào việc gọi API.

    final url = Uri.parse("$_baseUrl/profile");
    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Không thể tải thông tin cá nhân');
    }
  }
}
