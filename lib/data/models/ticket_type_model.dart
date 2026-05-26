class TicketTypeModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final int quantity;
  final int quantitySold;
  final int eventId;
  final DateTime createdAt;
  final DateTime updatedAt;

  TicketTypeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.quantitySold,
    required this.eventId,
    required this.createdAt,
    required this.updatedAt,
  });

  int get remaining => quantity - quantitySold;

  factory TicketTypeModel.fromJson(Map<String, dynamic> json) {
    return TicketTypeModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      quantitySold: json['quantitySold'] ?? 0,
      eventId: json['eventId'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'quantity': quantity,
    'quantitySold': quantitySold,
    'eventId': eventId,
  };

  TicketTypeModel copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    int? quantity,
    int? quantitySold,
    int? eventId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TicketTypeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      quantitySold: quantitySold ?? this.quantitySold,
      eventId: eventId ?? this.eventId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
