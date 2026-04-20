class LoginResponse {
  final String accessToken;
  final String userName;
  final int expiresIn;
  final String role;
  final String email;

  LoginResponse({
    required this.accessToken,
    required this.userName,
    required this.expiresIn,
    required this.role,
    required this.email,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'],
      userName: json['userName'],
      expiresIn: json['expiresIn'],
      role: json['role'],
      email: json['email'],
    );
  }
}
