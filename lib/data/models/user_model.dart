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
      userId: json['id'] ?? json['userId'] ?? 0,
      userName: json['userName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      isLocked: json['isLocked'] ?? false,
      createdDate: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['createdDate'] != null
                ? DateTime.parse(json['createdDate'])
                : DateTime.now()),
      lastLoginDate: json['lastLoginDate'] != null
          ? DateTime.parse(json['lastLoginDate'])
          : null,
    );
  }

  UserModel copyWith({
    int? userId,
    String? userName,
    String? email,
    String? role,
    bool? isLocked,
    DateTime? createdDate,
    DateTime? lastLoginDate,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      role: role ?? this.role,
      isLocked: isLocked ?? this.isLocked,
      createdDate: createdDate ?? this.createdDate,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
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
