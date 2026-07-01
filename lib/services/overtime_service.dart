// lib/services/overtime_service.dart

import '../models/overtime_model.dart';
import 'api_exception.dart';
import 'base_api_service.dart';

class OvertimeService extends BaseApiService {
  // Mengambil daftar lembur milik user login.
  Future<List<OvertimeModel>?> fetchOvertimes(String token) async {
    final data = await getJson('/overtimes', token: token);

    final responseData = _asMap(data);

    if (responseData['success'] == true) {
      final overtimeList = _asList(responseData['data']);

      return overtimeList
          .map((item) => OvertimeModel.fromJson(_asMap(item)))
          .toList();
    }

    return [];
  }

  // Merekam presensi masuk lembur.
  Future<bool> clockInOvertime({
    required String token,
    required int overtimeId,
    required double latitude,
    required double longitude,
  }) async {
    await postJson(
      '/overtimes/clock-in',
      token: token,
      body: {
        'overtime_id': overtimeId,
        'latitude': latitude,
        'longitude': longitude,
      },
    );

    return true;
  }

  // Merekam presensi keluar lembur.
  Future<bool> clockOutOvertime({
    required String token,
    required int overtimeId,
    required double latitude,
    required double longitude,
  }) async {
    await postJson(
      '/overtimes/clock-out',
      token: token,
      body: {
        'overtime_id': overtimeId,
        'latitude': latitude,
        'longitude': longitude,
      },
    );

    return true;
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

  List<dynamic> _asList(dynamic data) {
    if (data is List<dynamic>) {
      return data;
    }

    if (data is List) {
      return List<dynamic>.from(data);
    }

    throw ApiException('Format data lembur dari server tidak valid.');
  }
}
