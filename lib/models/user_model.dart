// lib/models/user_model.dart

class UserModel {
  final String token;
  final String name;
  final String email;
  
  // Added to support your separate Employee biodata table
  final String? employeeId; 
  final String? position;

  UserModel({
    required this.token, 
    required this.name, 
    required this.email,
    this.employeeId,
    this.position,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Safely extract the nested 'user' object to prevent null errors 
    // if the API occasionally returns a flat response (like during getUserProfile)
    final userObj = json['user'] ?? json;

    return UserModel(
      token: json['token'] ?? '',
      name: userObj['name'] ?? '',
      email: userObj['email'] ?? '',
      
      // Safely extract data from the related Employee table if your Laravel API includes it
      // e.g., User::with('employee')->find($id);
      employeeId: userObj['employee'] != null ? userObj['employee']['employee_id'] : null,
      position: userObj['employee'] != null ? userObj['employee']['position'] : null,
    );
  }
}