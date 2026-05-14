class User {
  final int userId;
  final String fullName;
  final String email;
  final String role;
  final String? phoneNumber;
  final String? token;

  User({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    this.phoneNumber,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      phoneNumber: json['phone']?.toString(),
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'role': role,
      'phone': phoneNumber,
    };
  }
}