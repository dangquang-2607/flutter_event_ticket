class AppConstants {
  // API Base URL
  static const String apiBaseUrl = "http://10.0.2.2:5054/api";

  // Auth endpoints
  static const String loginEndpoint = "$apiBaseUrl/auth/login";
  static const String registerEndpoint = "$apiBaseUrl/auth/register";

  // Admin endpoints
  static const String adminUsersEndpoint = "$apiBaseUrl/admin/users";

  // Events endpoints
  static const String eventsEndpoint = "$apiBaseUrl/events";

  // Ticket endpoints
  static const String ticketTypesEndpoint = "$apiBaseUrl/ticket-types";
  static const String ticketsEndpoint = "$apiBaseUrl/tickets";

  // Statistics endpoints
  static const String statisticsRevenueEndpoint =
      "$apiBaseUrl/admin/statistics/revenue";
  static const String statisticsEventsEndpoint =
      "$apiBaseUrl/admin/statistics/events";

  // Profile endpoints
  static const String profileEndpoint = "$apiBaseUrl/profile";

  // Registrations endpoints
  static const String registrationsEndpoint = "$apiBaseUrl/registrations";
}
