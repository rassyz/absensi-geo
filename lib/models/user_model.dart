// lib/models/user_model.dart

import 'employee_model.dart'; // Make sure to import it!

class UserModel {
  final String token;
  final String name;
  final String email;
  final EmployeeModel? employee; // Nested object!

  final String? avatarUrl;

  UserModel({
    required this.token,
    required this.name,
    required this.email,
    this.employee,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Laravel sends { "token": "...", "user": { ..., "employee": { ... } } }
    final userObj = json['user'] ?? json;

    return UserModel(
      token: json['token'] ?? '',
      name: userObj['name'] ?? '',
      email: userObj['email'] ?? '',
      employee: userObj['employee'] != null
          ? EmployeeModel.fromJson(userObj['employee'])
          : null,
      avatarUrl: userObj['avatar_url'],
    );
  }
}
