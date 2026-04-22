// lib/services/auth_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'base_api_service.dart';

class AuthService extends BaseApiService {
  Future<UserModel?> login(String email, String password) async {
    final url = Uri.parse("${BaseApiService.baseUrl}/login");
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
        await setToken(data['token']); // Uses BaseApiService method
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
    final url = Uri.parse("${BaseApiService.baseUrl}/register");
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
        Uri.parse('${BaseApiService.baseUrl}/logout'),
        headers: await getHeaders(token),
      );

      await clearToken(); // Uses BaseApiService method
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Logout API Error: $e");
      return false;
    }
  }

  Future<UserModel?> getUserProfile() async {
    final url = Uri.parse("${BaseApiService.baseUrl}/user");
    final response = await http.get(url, headers: await getHeaders());

    if (response.statusCode == 200) {
      return UserModel.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to fetch user profile: ${response.body}");
    }
  }
}
