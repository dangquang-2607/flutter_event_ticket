import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/login_response.dart';

class AuthService {
  static const String loginUrl = "http://10.0.2.2:5054/api/auth/login";

  static Future<LoginResponse?> login(String username, String password) async {
    final url = Uri.parse(loginUrl);

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"UserName": username, "Password": password}),
    );

    print("🔍 Login Response - Status: ${response.statusCode}");
    print("🔍 Login Response - Body: ${response.body}");

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        print("✅ Login Success - Data: $data");
        return LoginResponse.fromJson(data);
      } catch (e) {
        print("❌ JSON Parse Error: $e");
        return null;
      }
    } else {
      print("❌ Login failed: ${response.statusCode} - ${response.body}");
      return null;
    }
  }
}
