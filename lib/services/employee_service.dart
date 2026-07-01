// lib/services/employee_service.dart

import 'api_exception.dart';
import 'base_api_service.dart';

class EmployeeService extends BaseApiService {
  // Mengambil daftar anggota tim sesuai departemen/user login.
  Future<List<Map<String, dynamic>>> fetchTeamMembers() async {
    final data = await getJson('/team-members');

    final responseData = _asMap(data);
    final teamMembers = _extractList(responseData, key: 'data');

    return teamMembers.map(_asMap).toList();
  }

  // Mengambil data presensi anggota tim berdasarkan employeeId.
  Future<List<Map<String, dynamic>>> fetchMemberAttendances({
    required int employeeId,
    int? month,
    int? year,
  }) async {
    final queryParameters = <String, dynamic>{};

    if (month != null && year != null) {
      queryParameters['month'] = month;
      queryParameters['year'] = year;
    }

    final data = await getJson(
      '/team-members/$employeeId/attendances',
      queryParameters: queryParameters,
    );

    final responseData = _asMap(data);
    final attendances = _extractList(responseData, key: 'data');

    return attendances.map(_asMap).toList();
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw ApiException('Format response server tidak valid.');
  }

  List<dynamic> _extractList(Map<String, dynamic> data, {required String key}) {
    final value = data[key];

    if (value is List<dynamic>) {
      return value;
    }

    if (data.values.length == 1 && data.values.first is List<dynamic>) {
      return data.values.first as List<dynamic>;
    }

    throw ApiException('Format data dari server tidak valid.');
  }
}
