import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';
import '../model/login_response.dart';

class AuthService {
  static const String loginUrl = AppConstants.loginEndpoint;

  static Future<LoginResponse?> login(String username, String password) async {
    final url = Uri.parse(loginUrl);

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"UserName": username, "Password": password}),
    );

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        return LoginResponse.fromJson(data);
      } catch (e) {
        return null;
      }
    } else {
      return null;
    }
  }
}
