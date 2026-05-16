class Event {
  final int? id;
  final String title;
  final String description;
  final String location;
  final DateTime startTime;
  final DateTime endTime;
  final int maxTickets;
  final double price;
  final bool isRegistrationOpen;
  final String status;
  final int registeredTickets;

  Event({
    this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.maxTickets,
    required this.price,
    this.isRegistrationOpen = false,
    this.status = "Sắp diễn ra",
    this.registeredTickets = 0,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      // Handle both field names from API: maxTickets or maxAttendees
      maxTickets: json['maxTickets'] ?? json['maxAttendees'] ?? 0,
      // Handle both field names from API: price or ticketPrice
      price: ((json['price'] ?? json['ticketPrice']) ?? 0.0).toDouble(),
      isRegistrationOpen: json['isRegistrationOpen'] ?? false,
      status: json['status'] ?? 'Sắp diễn ra',
      // Handle both field names from API: registeredTickets or registeredCount
      registeredTickets:
          json['registeredTickets'] ?? json['registeredCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) "id": id,
      "title": title,
      "description": description,
      "location": location,
      "startTime": startTime.toIso8601String(),
      "endTime": endTime.toIso8601String(),
      // Use API field names
      "maxAttendees": maxTickets,
      "ticketPrice": price,
      "isRegistrationOpen": isRegistrationOpen,
      "status": status,
      "registeredCount": registeredTickets,
    };
  }
}
