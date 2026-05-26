import '../api/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/event_model.dart';

class EventService {
  static const String _baseUrl = AppConstants.eventsEndpoint;

  /// Lấy danh sách sự kiện
  static Future<List<Event>> getEvents() async {
    final data = await ApiClient.get(_baseUrl);
    final List<dynamic> jsonList = data is List ? data : [];
    return jsonList.map((e) => Event.fromJson(e)).toList();
  }

  /// Lấy chi tiết 1 sự kiện (trả về raw Map để EventDetailScreen dùng)
  static Future<Map<String, dynamic>?> getEventDetail(int id) async {
    try {
      final data = await ApiClient.get("$_baseUrl/$id");
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return null;
    } on ApiException {
      return null;
    }
  }

  /// Lấy chi tiết 1 sự kiện dưới dạng Event model
  static Future<Event?> getEventById(int id) async {
    try {
      final data = await ApiClient.get("$_baseUrl/$id");
      if (data != null) return Event.fromJson(data);
      return null;
    } on ApiException {
      return null;
    }
  }

  /// Tạo sự kiện mới
  static Future<Event?> createEvent(Event event) async {
    try {
      final data = await ApiClient.post(
        _baseUrl,
        body: event.toJson(),
      );
      if (data != null) return Event.fromJson(data);
      return null;
    } on ApiException {
      return null;
    }
  }

  /// Cập nhật sự kiện
  static Future<bool> updateEvent(Event event) async {
    if (event.id == null) return false;

    try {
      await ApiClient.put(
        "$_baseUrl/${event.id}",
        body: event.toJson(),
      );
      return true;
    } on ApiException {
      return false;
    }
  }

  /// Xóa sự kiện
  static Future<bool> deleteEvent(int id) async {
    try {
      await ApiClient.delete("$_baseUrl/$id");
      return true;
    } on ApiException {
      return false;
    }
  }
}
