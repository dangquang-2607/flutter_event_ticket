class UserModel {
  final int userId;
  final String userName;
  final String email;
  final String role;
  final bool isLocked;
  final DateTime createdDate;
  final DateTime? lastLoginDate;

  UserModel({
    required this.userId,
    required this.userName,
    required this.email,
    required this.role,
    required this.isLocked,
    required this.createdDate,
    this.lastLoginDate,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'User',
      isLocked: json['isLocked'] ?? false,
      createdDate: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'])
          : DateTime.now(),
      lastLoginDate: json['lastLoginDate'] != null
          ? DateTime.parse(json['lastLoginDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'email': email,
      'role': role,
      'isLocked': isLocked,
      'createdDate': createdDate.toIso8601String(),
      'lastLoginDate': lastLoginDate?.toIso8601String(),
    };
  }
}
