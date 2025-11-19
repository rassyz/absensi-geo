// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart'; // Path relatif untuk model

class ApiService {
  static const String baseUrl = "http://absensigeo.test/api";
  String? _authToken;

  // Constructor untuk memuat token saat pertama kali aplikasi dijalankan
  ApiService() {
    _loadAuthToken(); // Membaca token yang sudah disimpan saat aplikasi dijalankan
  }

  // Membaca token dari SharedPreferences
  Future<void> _loadAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(
      'loginToken',
    ); // Membaca token dari SharedPreferences
  }

  // Simpan token setelah auth
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'loginToken',
      token,
    ); // Menyimpan token ke SharedPreferences
  }

  // Hapus token saat logout
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('loginToken'); // Menghapus token dari SharedPreferences
    _authToken = null; // Reset token di memory
  }

  // Helper function to set headers with Authorization
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

  // Fungsi untuk login
  Future<UserModel?> login(String email, String password) async {
    final url = Uri.parse("$baseUrl/login");

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['token'] != null) {
        await setAuthToken(data['token']); // Simpan token setelah auth berhasil
        return UserModel.fromJson(data); // Kembalikan objek UserModel
      } else {
        throw Exception("Token not found in response.");
      }
    } else if (response.statusCode == 403) {
      throw Exception("You are not authorized to auth.");
    } else if (response.statusCode == 401) {
      throw Exception("Incorrect email or password.");
    } else {
      throw Exception("Auth failed: ${response.body}");
    }
  }

  // Fungsi untuk registrasi
  Future<String> register(
    String name,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    final url = Uri.parse("$baseUrl/register");

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      // Kembalikan pesan sukses
      return data['message'] ?? "Registration successful";
    } else {
      throw Exception("Registration failed: ${response.body}");
    }
  }

  // Fungsi untuk mendapatkan user profile
  Future<UserModel?> getUserProfile() async {
    final url = Uri.parse(
      "$baseUrl/user",
    ); // Endpoint untuk mendapatkan data user

    final response = await http.get(url, headers: _getHeaders());

    if (response.statusCode == 200) {
      return UserModel.fromJson(
        json.decode(response.body),
      ); // Kembalikan objek UserModel
    } else {
      throw Exception("Failed to fetch user profile: ${response.body}");
    }
  }
}
