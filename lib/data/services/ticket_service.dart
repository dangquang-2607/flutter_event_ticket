import '../api/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/ticket_type_model.dart';
import '../models/ticket_model.dart';

class TicketService {
  // ─── TICKET TYPES ──────────────────────────────────────────────────────────

  /// GET /api/events/{eventId}/ticket-types
  static Future<List<TicketTypeModel>> getTicketTypesByEvent(
    int eventId,
  ) async {
    final data = await ApiClient.get(
      '${AppConstants.eventsEndpoint}/$eventId/ticket-types',
    );
    final list = _toList(data);
    return list.map((e) => TicketTypeModel.fromJson(e)).toList();
  }

  /// GET /api/ticket-types/{id}
  static Future<TicketTypeModel> getTicketTypeById(int id) async {
    final data = await ApiClient.get('${AppConstants.ticketTypesEndpoint}/$id');
    return TicketTypeModel.fromJson(data as Map<String, dynamic>);
  }

  /// POST /api/events/{eventId}/ticket-types
  static Future<TicketTypeModel> createTicketType(
    int eventId, {
    required String name,
    required double price,
    required int quantity,
    String description = '',
  }) async {
    final data = await ApiClient.post(
      '${AppConstants.eventsEndpoint}/$eventId/ticket-types',
      body: {
        'name': name,
        'description': description,
        'price': price,
        'quantity': quantity,
      },
    );
    return TicketTypeModel.fromJson(data as Map<String, dynamic>);
  }

  /// PUT /api/ticket-types/{id}
  static Future<TicketTypeModel> updateTicketType(
    int id, {
    String? name,
    double? price,
    int? quantity,
    String? description,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (price != null) body['price'] = price;
    if (quantity != null) body['quantity'] = quantity;
    if (description != null) body['description'] = description;

    final data = await ApiClient.put(
      '${AppConstants.ticketTypesEndpoint}/$id',
      body: body,
    );
    return TicketTypeModel.fromJson(data as Map<String, dynamic>);
  }

  /// DELETE /api/ticket-types/{id}
  static Future<void> deleteTicketType(int id) async {
    await ApiClient.delete('${AppConstants.ticketTypesEndpoint}/$id');
  }

  // ─── TICKETS ───────────────────────────────────────────────────────────────

  /// GET /api/tickets  (tuỳ chọn filter theo eventId)
  static Future<List<TicketModel>> getTickets({int? eventId}) async {
    final endpoint = eventId != null
        ? '${AppConstants.eventsEndpoint}/$eventId/tickets'
        : AppConstants.ticketsEndpoint;
    final data = await ApiClient.get(endpoint);
    final list = _toList(data);
    return list.map((e) => TicketModel.fromJson(e)).toList();
  }

  /// POST /api/events/{eventId}/tickets
  static Future<TicketModel> createTicket(
    int eventId, {
    required String ticketName,
    required double price,
    required int quantity,
    required DateTime startSaleDate,
    required DateTime endSaleDate,
    String description = '',
    bool isActive = true,
  }) async {
    final data = await ApiClient.post(
      '${AppConstants.eventsEndpoint}/$eventId/tickets',
      body: {
        'ticketName': ticketName,
        'price': price,
        'quantity': quantity,
        'description': description,
        'startSaleDate': startSaleDate.toIso8601String(),
        'endSaleDate': endSaleDate.toIso8601String(),
        'isActive': isActive,
      },
    );
    return TicketModel.fromJson(data as Map<String, dynamic>);
  }

  /// PUT /api/tickets/{id}
  static Future<TicketModel> updateTicket(
    int id, {
    String? ticketName,
    double? price,
    int? quantity,
    String? description,
    DateTime? startSaleDate,
    DateTime? endSaleDate,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (ticketName != null) body['ticketName'] = ticketName;
    if (price != null) body['price'] = price;
    if (quantity != null) body['quantity'] = quantity;
    if (description != null) body['description'] = description;
    if (startSaleDate != null) {
      body['startSaleDate'] = startSaleDate.toIso8601String();
    }
    if (endSaleDate != null) {
      body['endSaleDate'] = endSaleDate.toIso8601String();
    }
    if (isActive != null) body['isActive'] = isActive;

    final data = await ApiClient.put(
      '${AppConstants.ticketsEndpoint}/$id',
      body: body,
    );
    return TicketModel.fromJson(data as Map<String, dynamic>);
  }

  /// DELETE /api/tickets/{id}
  static Future<void> deleteTicket(int id) async {
    await ApiClient.delete('${AppConstants.ticketsEndpoint}/$id');
  }

  /// PUT /api/tickets/{id}/toggle-status — Bật/tắt trạng thái bán vé
  static Future<TicketModel> toggleTicketStatus(int id) async {
    final data = await ApiClient.put(
      '${AppConstants.ticketsEndpoint}/$id/toggle-status',
    );
    return TicketModel.fromJson(data as Map<String, dynamic>);
  }

  // ─── STATISTICS ────────────────────────────────────────────────────────────

  /// GET /api/admin/statistics/revenue — Thống kê tổng doanh thu
  static Future<Map<String, dynamic>> getRevenue() async {
    final data = await ApiClient.get(AppConstants.statisticsRevenueEndpoint);
    if (data is Map<String, dynamic>) return data;
    return {};
  }

  /// GET /api/admin/statistics/events/{id}/revenue — Doanh thu theo sự kiện
  static Future<Map<String, dynamic>> getEventRevenue(int eventId) async {
    final data = await ApiClient.get(
      '${AppConstants.statisticsEventsEndpoint}/$eventId/revenue',
    );
    if (data is Map<String, dynamic>) return data;
    return {};
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────

  static List<dynamic> _toList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in ['items', 'data', 'tickets', 'ticketTypes', 'result']) {
        if (data[key] is List) return data[key] as List;
      }
    }
    return [];
  }
}
