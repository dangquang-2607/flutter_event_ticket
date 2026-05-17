class AppConstants {
  // API Base URL - Change localhost to 10.0.2.2 for Android Emulator
  static const String apiBaseUrl = "http://10.0.2.2:5054/api";
  
  // Auth endpoints
  static const String loginEndpoint = "$apiBaseUrl/auth/login";
  static const String registerEndpoint = "$apiBaseUrl/auth/register";
  
  // Admin endpoints
  static const String adminUsersEndpoint = "$apiBaseUrl/admin/users";
  
  // Events endpoints
  static const String eventsEndpoint = "$apiBaseUrl/events";
  
  // Profile endpoints
  static const String profileEndpoint = "$apiBaseUrl/profile";
  
  // Registrations endpoints
  static const String registrationsEndpoint = "$apiBaseUrl/registrations";
}
