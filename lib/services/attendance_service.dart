// lib/services/attendance_service.dart

import 'dart:io';

import 'api_exception.dart';
import 'base_api_service.dart';

class AttendanceService extends BaseApiService {
  /// Mengambil konteks presensi pengguna.
  ///
  /// Response dapat berupa:
  /// - attendance_mode = regular
  /// - attendance_mode = outside_duty
  ///
  /// Untuk outside_duty, backend juga mengirim data Surat Tugas aktif.
  Future<Map<String, dynamic>> getUserAttendanceContext(String token) async {
    final data = await getJson('/attendance/user-zone', token: token);

    final responseData = _asMap(data);

    if (responseData['success'] != true) {
      throw ApiException(
        responseData['message']?.toString() ??
            'Konfigurasi presensi tidak dapat dimuat.',
      );
    }

    return responseData;
  }

  /// Mengambil seluruh zona presensi polygon pengguna.
  ///
  /// Method ini dipertahankan untuk kompatibilitas dengan kode lama.
  /// Untuk mengetahui mode presensi, gunakan getUserAttendanceContext().
  Future<List<Map<String, dynamic>>> getUserAttendanceZones(
    String token,
  ) async {
    final responseData = await getUserAttendanceContext(token);

    final dynamic rawZones = responseData['zones'];

    if (rawZones is List) {
      return rawZones.map<Map<String, dynamic>>((dynamic zone) {
        return _asMap(zone);
      }).toList();
    }

    // Kompatibilitas sementara jika backend lama
    // masih mengirim satu zona.
    if (responseData['area'] != null) {
      return <Map<String, dynamic>>[
        <String, dynamic>{
          'id': responseData['id'],
          'name': responseData['name'],
          'area': responseData['area'],
        },
      ];
    }

    return <Map<String, dynamic>>[];
  }

  /// Memvalidasi posisi terkini terhadap polygon dan zona toleransi.
  Future<Map<String, dynamic>> validateAttendanceLocation({
    required String token,
    required double latitude,
    required double longitude,
  }) async {
    final data = await postJson(
      '/attendance/validate-location',
      token: token,
      body: {'latitude': latitude, 'longitude': longitude},
    );

    return _asMap(data);
  }

  /// Mengirim presensi masuk atau keluar dengan foto dan koordinat GPS.
  Future<Map<String, dynamic>> submitAttendance({
    required String token,
    required File photo,
    required double latitude,
    required double longitude,
    required bool isCheckIn,
  }) async {
    final endpoint = isCheckIn
        ? '/attendance/check-in'
        : '/attendance/check-out';

    final data = await postMultipart(
      endpoint,
      token: token,
      fields: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      },
      files: {'photo': photo},
    );

    final responseData = _asMap(data);

    return {
      'success': true,
      'message': responseData['message']?.toString() ?? 'Presensi berhasil.',
      'data': responseData,
    };
  }

  /// Endpoint sementara untuk mengambil data pengujian geofencing.
  Future<Map<String, dynamic>> getGeofenceTestData({
    required String token,
    required double latitude,
    required double longitude,
  }) async {
    final data = await postJson(
      '/attendance/geofence-test',
      token: token,
      body: {'latitude': latitude, 'longitude': longitude},
    );

    return _asMap(data);
  }

  /// Mengambil status presensi user pada hari berjalan.
  Future<Map<String, dynamic>?> getTodayAttendanceStatus(String token) async {
    final data = await getJson('/attendance/today', token: token);

    return _asMap(data);
  }

  /// Mengambil statistik presensi bulanan user.
  Future<Map<String, dynamic>?> getMonthlyStats(String token) async {
    final data = await getJson('/attendance/monthly-stats', token: token);

    return _asMap(data);
  }

  /// Mengambil riwayat presensi terbaru user.
  Future<List<dynamic>?> getAttendanceHistory(String token) async {
    final data = await getJson('/attendance/history', token: token);

    final responseData = _asMap(data);

    if (responseData['success'] == true) {
      return _asList(responseData['data']);
    }

    return null;
  }

  /// Mengambil laporan presensi bulanan berdasarkan filter bulan dan tahun.
  Future<Map<String, dynamic>?> getMonthlyReport(
    String token,
    int month,
    int year,
  ) async {
    final data = await getJson(
      '/attendance/report',
      token: token,
      queryParameters: {'month': month, 'year': year},
    );

    final responseData = _asMap(data);

    if (responseData['success'] == true) {
      return responseData;
    }

    return null;
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    throw ApiException('Format response server tidak valid.');
  }

  List<dynamic> _asList(dynamic data) {
    if (data is List<dynamic>) {
      return data;
    }

    throw ApiException('Format data riwayat presensi tidak valid.');
  }
}
