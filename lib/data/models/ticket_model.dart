class TicketModel {
  final int id;
  final int eventId;
  final String ticketName;
  final double price;
  final int quantity;
  final int sold;
  final String description;
  final DateTime startSaleDate;
  final DateTime endSaleDate;
  final bool isActive;

  TicketModel({
    required this.id,
    required this.eventId,
    required this.ticketName,
    required this.price,
    required this.quantity,
    required this.sold,
    required this.description,
    required this.startSaleDate,
    required this.endSaleDate,
    required this.isActive,
  });

  int get remaining => quantity - sold;

  bool get isSaleOngoing {
    final now = DateTime.now();
    return isActive && now.isAfter(startSaleDate) && now.isBefore(endSaleDate);
  }

  bool get canSell => isSaleOngoing && remaining > 0;

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] ?? 0,
      eventId: json['eventId'] ?? 0,
      ticketName: json['ticketName'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      sold: json['sold'] ?? 0,
      description: json['description'] ?? '',
      startSaleDate: json['startSaleDate'] != null
          ? DateTime.parse(json['startSaleDate'])
          : DateTime.now(),
      endSaleDate: json['endSaleDate'] != null
          ? DateTime.parse(json['endSaleDate'])
          : DateTime.now().add(const Duration(days: 30)),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'ticketName': ticketName,
    'price': price,
    'quantity': quantity,
    'sold': sold,
    'description': description,
    'startSaleDate': startSaleDate.toIso8601String(),
    'endSaleDate': endSaleDate.toIso8601String(),
    'isActive': isActive,
  };

  TicketModel copyWith({
    int? id,
    int? eventId,
    String? ticketName,
    double? price,
    int? quantity,
    int? sold,
    String? description,
    DateTime? startSaleDate,
    DateTime? endSaleDate,
    bool? isActive,
  }) {
    return TicketModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      ticketName: ticketName ?? this.ticketName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      sold: sold ?? this.sold,
      description: description ?? this.description,
      startSaleDate: startSaleDate ?? this.startSaleDate,
      endSaleDate: endSaleDate ?? this.endSaleDate,
      isActive: isActive ?? this.isActive,
    );
  }
}
