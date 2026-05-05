// lib/services/employee_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:absensi_geo/services/base_api_service.dart';

class EmployeeService extends BaseApiService {
  // --- Mengambil Data Anggota Tim ---
  // 👇 Tidak perlu lagi parameter token!
  Future<List<Map<String, dynamic>>> fetchTeamMembers() async {
    try {
      final url = Uri.parse('${BaseApiService.baseUrl}/team-members');

      final headers = await getHeaders();

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body)['data'];
        return List<Map<String, dynamic>>.from(responseData);
      } else {
        debugPrint('Gagal mengambil data karyawan: ${response.body}');
        throw Exception('Gagal mengambil data karyawan.');
      }
    } catch (e) {
      debugPrint("Error API Karyawan: $e");
      rethrow;
    }
  }

  // --- Mengambil Data Presensi Spesifik Anggota ---
  Future<List<Map<String, dynamic>>> fetchMemberAttendances({
    required int employeeId,
    int? month,
    int? year,
  }) async {
    try {
      // Siapkan URL dengan query parameters
      String urlString =
          '${BaseApiService.baseUrl}/team-members/$employeeId/attendances';
      if (month != null && year != null) {
        urlString += '?month=$month&year=$year';
      }

      final url = Uri.parse(urlString);
      final headers = await getHeaders();

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body)['data'];
        return List<Map<String, dynamic>>.from(responseData);
      } else if (response.statusCode == 403) {
        // debugPrint('--- DEBUG 403 DARI LARAVEL: ${response.body} ---');
        throw Exception('Unauthorized');
      } else {
        // debugPrint('Gagal mengambil data presensi: ${response.body}');
        throw Exception('Gagal mengambil data presensi anggota.');
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized')) {
        rethrow;
      }
      debugPrint("Exception saat memproses presensi: $e");
      rethrow;
    }
  }
}
