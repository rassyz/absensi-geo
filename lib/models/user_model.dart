// lib/models/user_model.dart
class UserModel {
  final String token;
  final String name;
  final String email;

  UserModel({required this.token, required this.name, required this.email});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      token: json['token'] ?? '',
      name: json['user']['name'] ?? '',
      email: json['user']['email'] ?? '',
    );
  }
}
