// lib/services/leave_service.dart

import 'dart:io';

import 'api_exception.dart';
import 'base_api_service.dart';

class LeaveService extends BaseApiService {
  // Mengambil data master tipe cuti untuk dropdown form pengajuan cuti.
  Future<List<Map<String, dynamic>>?> getLeaveTypes(String token) async {
    final data = await getJson('/leave-types', token: token);

    final responseData = _asMap(data);

    if (responseData['success'] == true) {
      return _asList(responseData['data']).map(_asMap).toList();
    }

    return null;
  }

  // Mengambil data dashboard cuti, seperti daftar cuti user,
  Future<Map<String, dynamic>?> getLeaveDashboard(String token) async {
    final data = await getJson('/leaves/dashboard', token: token);

    return _asMap(data);
  }

  // Mengirim pengajuan cuti baru.
  Future<bool> submitLeaveRequest({
    required String token,
    required String leaveTypeId,
    required String startDate,
    required String endDate,
    required int applyDays,
    required String reason,
    File? attachment,
  }) async {
    await postMultipart(
      '/leaves/apply',
      token: token,
      fields: {
        'leave_type_id': leaveTypeId,
        'start_date': startDate,
        'end_date': endDate,
        'apply_days': applyDays.toString(),
        'reason': reason,
      },
      files: attachment == null ? null : {'attachment': attachment},
    );

    return true;
  }

  // Proses persetujuan atau penolakan cuti oleh Head/Manager.
  Future<bool> processTeamLeave({
    required String token,
    required int leaveId,
    required String status,
  }) async {
    await postJson(
      '/leaves/$leaveId/process',
      token: token,
      body: {'status': status},
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

    throw ApiException('Format data cuti dari server tidak valid.');
  }
}
