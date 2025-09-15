// =====================================
// lib/data/models/user.dart
// =====================================

class User {
  final String id;
  final String username;
  final String? fullName;
  final String role;
  final String? accessToken;
  final String? refreshToken;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    this.fullName,
    required this.role,
    this.accessToken,
    this.refreshToken,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      fullName: json['full_name'],
      role: json['role'],
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'role': role,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
