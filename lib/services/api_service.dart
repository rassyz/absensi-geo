// lib/services/api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class ApiService {
  // static const String baseUrl = "http://absensigeo.test/api";
  static const String baseUrl = "https://gallery-wham-jaunt.ngrok-free.dev/api";

  String? _authToken;

  ApiService() {
    _loadAuthToken();
  }

  Future<void> _loadAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('loginToken');
  }

  Future<void> setAuthToken(String token) async {
    _authToken = token;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('loginToken', token);
  }

  Map<String, String> _getHeaders() {
    if (_authToken == null) {
      throw Exception("Authentication token is not set.");
    }
    return {
      'Authorization': 'Bearer $_authToken',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  // --- 1. Authentication Methods ---

  Future<UserModel?> login(String email, String password) async {
    final url = Uri.parse("$baseUrl/login");
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['token'] != null) {
        await setAuthToken(data['token']);
        return UserModel.fromJson(data);
      } else {
        throw Exception("Token not found in response.");
      }
    } else {
      throw Exception("Auth failed: ${response.body}");
    }
  }

  Future<String> register(
    String name,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    final url = Uri.parse("$baseUrl/register");

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['message'] ?? "Registration successful";
    } else {
      throw Exception("Registration failed: ${response.body}");
    }
  }

  Future<bool> logout(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('loginToken');
      _authToken = null;

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Logout API Error: $e");
      return false;
    }
  }

  Future<UserModel?> getUserProfile() async {
    final url = Uri.parse("$baseUrl/user");
    final response = await http.get(url, headers: _getHeaders());

    if (response.statusCode == 200) {
      return UserModel.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to fetch user profile: ${response.body}");
    }
  }

  // --- 2. Attendance & Geofencing Methods ---

  /// Fetches the attendance zone polygon for the logged-in user's department
  Future<Map<String, dynamic>?> getUserAttendanceZone(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/zone'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'name': data['name'], // e.g., "HR"
            'area': data['area'], // e.g., "POLYGON((...))"
          };
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
        Uri.parse('$baseUrl$endpoint'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Attach GPS Data
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();

      // Attach Image File
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
        Uri.parse('$baseUrl/attendance/today'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint("Failed to fetch today's status: ${response.statusCode}");
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
        Uri.parse('$baseUrl/attendance/monthly-stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint("Failed to fetch monthly stats: ${response.statusCode}");
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
        Uri.parse('$baseUrl/attendance/history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data']; // Returns the list of records
        }
      } else {
        debugPrint("Failed to fetch history: ${response.statusCode}");
      }
      return null;
    } catch (e) {
      debugPrint("API Error fetching history: $e");
      return null;
    }
  }
}
