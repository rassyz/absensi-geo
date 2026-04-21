// lib/models/employee_model.dart

class EmployeeModel {
  final int? id;
  final int? userId;
  final int? departmentId;
  final String fullName;
  final String? employeeNumber;
  final String? position;
  final String? phone;
  final String? address;
  // --- Added this field ---
  final String? departmentName;

  EmployeeModel({
    this.id,
    this.userId,
    this.departmentId,
    required this.fullName,
    this.employeeNumber,
    this.position,
    this.phone,
    this.address,
    this.departmentName, // Added to constructor
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
      userId: json['user_id'] is String
          ? int.tryParse(json['user_id'])
          : json['user_id'],
      departmentId: json['department_id'] is String
          ? int.tryParse(json['department_id'])
          : json['department_id'],

      fullName: json['full_name'] ?? 'Unknown Name',
      employeeNumber: json['employee_number'],
      position: json['position'],
      phone: json['phone'],
      address: json['address'],

      // --- Logic to extract the Department Name ---
      // This works if your Laravel API returns: "department": {"name": "IT", ...}
      departmentName: json['department'] != null
          ? json['department']['name'] as String?
          : null,
    );
  }
}
