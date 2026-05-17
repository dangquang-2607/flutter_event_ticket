import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '../../../core/constants.dart';
import '../model/event.dart';

class EventService {
  static const String baseUrl = AppConstants.eventsEndpoint;

  /// Lấy accessToken đã lưu khi login
  static String? _getToken() {
    final box = GetStorage();
    return box.read("accessToken");
  }

  /// Lấy danh sách sự kiện
  static Future<List<Event>> getEvents() async {
    final token = _getToken();
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Event.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load events: ${response.body}");
    }
  }

  /// Lấy chi tiết 1 sự kiện
  static Future<Event?> getEventById(int id) async {
    final token = _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/$id"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Event.fromJson(data);
    } else {
      return null;
    }
  }

  /// Tạo sự kiện mới
  static Future<Event?> createEvent(Event event) async {
    final token = _getToken();
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode(event.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Event.fromJson(data);
    } else {
      return null;
    }
  }

  /// Cập nhật sự kiện
  static Future<bool> updateEvent(Event event) async {
    if (event.id == null) {
      debugPrint('updateEvent error: event.id is null');
      return false;
    }

    final token = _getToken();
    try {
      final body = event.toJson();
      debugPrint('Updating event ${event.id}');
      debugPrint('Request body: $body');

      final response = await http.put(
        Uri.parse("$baseUrl/${event.id}"),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      final success = response.statusCode == 200 || response.statusCode == 204;
      if (success) {
        debugPrint('Update succeeded with status ${response.statusCode}');
      } else {
        debugPrint('Update failed with status ${response.statusCode}');
      }
      return success;
    } catch (e, st) {
      debugPrint('updateEvent exception: $e\n$st');
      return false;
    }
  }

  /// Xóa sự kiện
  static Future<bool> deleteEvent(int id) async {
    final token = _getToken();
    final response = await http.delete(
      Uri.parse("$baseUrl/$id"),
      headers: {if (token != null) "Authorization": "Bearer $token"},
    );

    return response.statusCode == 200 || response.statusCode == 204;
  }
}
