// lib/services/attendance_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'base_api_service.dart';

class AttendanceService extends BaseApiService {
  /// Fetches the attendance zone polygon for the logged-in user's department
  Future<Map<String, dynamic>?> getUserAttendanceZone(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${BaseApiService.baseUrl}/attendance/zone'),
        headers: await getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {'name': data['name'], 'area': data['area']};
        }
      } else {
        debugPrint("Failed to fetch zone. Status: ${response.statusCode}");
      }
      return null;
    } catch (e) {
      debugPrint("API Error fetching attendance zone: $e");
      return null;
    }
  }

  /// Submits the attendance (Check-In / Check-Out) with a photo and GPS coordinates
  Future<Map<String, dynamic>> submitAttendance({
    required String token,
    required File photo,
    required double latitude,
    required double longitude,
    required bool isCheckIn,
  }) async {
    try {
      final endpoint = isCheckIn
          ? '/attendance/check-in'
          : '/attendance/check-out';
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${BaseApiService.baseUrl}$endpoint'),
      );

      // We manually build headers here because MultipartRequest handles Content-Type differently
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();
      request.files.add(await http.MultipartFile.fromPath('photo', photo.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Success',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to submit attendance',
        };
      }
    } catch (e) {
      debugPrint("API Error submitting attendance: $e");
      return {'success': false, 'message': 'Network error: Please try again.'};
    }
  }

  /// Fetches the user's attendance status for the current day
  Future<Map<String, dynamic>?> getTodayAttendanceStatus(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${BaseApiService.baseUrl}/attendance/today'),
        headers: await getHeaders(token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("API Error fetching today's status: $e");
      return null;
    }
  }

  /// Fetches the user's monthly attendance statistics
  Future<Map<String, dynamic>?> getMonthlyStats(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${BaseApiService.baseUrl}/attendance/monthly-stats'),
        headers: await getHeaders(token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("API Error fetching monthly stats: $e");
      return null;
    }
  }

  /// Fetches the recent attendance history for the user
  Future<List<dynamic>?> getAttendanceHistory(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${BaseApiService.baseUrl}/attendance/history'),
        headers: await getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      debugPrint("API Error fetching history: $e");
      return null;
    }
  }

  /// Fetches the full monthly report based on selected dropdown filters
  Future<Map<String, dynamic>?> getMonthlyReport(
    String token,
    int month,
    int year,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${BaseApiService.baseUrl}/attendance/report?month=$month&year=$year',
        ),
        headers: await getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data;
        }
      }
      return null;
    } catch (e) {
      debugPrint("API Error fetching monthly report: $e");
      return null;
    }
  }

  // // Di dalam kelas ApiService atau LeaveService Anda:
  // Future<Map<String, dynamic>?> getLeaveDashboard(String token) async {
  //   try {
  //     final response = await http.get(
  //       Uri.parse('${BaseApiService.baseUrl}/leaves/dashboard'),
  //       headers: {
  //         'Authorization': 'Bearer $token',
  //         'Accept': 'application/json',
  //       },
  //     );

  //     if (response.statusCode == 200) {
  //       return jsonDecode(response.body);
  //     }
  //     return null;
  //   } catch (e) {
  //     debugPrint("API Error fetching leave dashboard: $e");
  //     return null;
  //   }
  // }
}
