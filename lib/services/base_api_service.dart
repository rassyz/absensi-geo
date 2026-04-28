// lib/services/base_api_service.dart

import 'package:shared_preferences/shared_preferences.dart';

class BaseApiService {
  // Use your local IP for physical device testing
  static const String baseUrl = "https://gallery-wham-jaunt.ngrok-free.dev/api";

  /// Retrieves the stored authentication token
  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('loginToken');
  }

  /// Saves the authentication token
  Future<void> setToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('loginToken', token);
  }

  /// Removes the authentication token upon logout
  Future<void> clearToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('loginToken');
  }

  /// Generates the standard headers required for authenticated requests
  Future<Map<String, String>> getHeaders([String? providedToken]) async {
    final token = providedToken ?? await getToken();

    if (token == null) {
      throw Exception("Authentication token is not set.");
    }

    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
  }
}
