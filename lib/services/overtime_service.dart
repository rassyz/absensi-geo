import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:absensi_geo/services/base_api_service.dart';
import '../models/overtime_model.dart'; // Sesuaikan path model Anda

class OvertimeService extends BaseApiService {
  // --- Mengambil Data Daftar Lembur ---
  Future<List<OvertimeModel>?> fetchOvertimes(String token) async {
    try {
      final url = Uri.parse('${BaseApiService.baseUrl}/overtimes');
      final headers = await getHeaders(token);

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          List<dynamic> data = responseData['data'];
          return data.map((item) => OvertimeModel.fromJson(item)).toList();
        }
        return []; // Return list kosong jika sukses tapi data kosong
      } else {
        debugPrint(
          'Gagal mengambil data lembur: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint("Error API Lembur: $e");
      return null;
    }
  }

  // --- Merekam Absen Masuk Lembur (Clock In) ---
  Future<bool> clockInOvertime({
    required String token,
    required int overtimeId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse('${BaseApiService.baseUrl}/overtimes/clock-in');
      final headers = await getHeaders(token);
      headers['Content-Type'] = 'application/json';

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'overtime_id': overtimeId,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final errorMessage = responseData['message'] ?? 'Gagal Clock In.';

        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // --- Merekam Absen Keluar Lembur (Clock Out) ---
  Future<bool> clockOutOvertime({
    required String token,
    required int overtimeId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse('${BaseApiService.baseUrl}/overtimes/clock-out');
      final headers = await getHeaders(token);
      headers['Content-Type'] = 'application/json';

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'overtime_id': overtimeId,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final errorMessage = responseData['message'] ?? 'Gagal Clock Out.';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
