import '../models/user_model.dart';
import 'api_exception.dart';
import 'base_api_service.dart';

class AuthService extends BaseApiService {
  Future<UserModel?> login(String email, String password) async {
    final data = await postJson(
      '/login',
      useAuth: false,
      body: {'email': email, 'password': password},
    );

    final responseData = _asMap(data);

    final token = responseData['token'];
    if (token == null || token.toString().isEmpty) {
      throw ApiException('Token tidak ditemukan dari server.');
    }

    await setToken(token.toString());

    return UserModel.fromJson(responseData);
  }

  Future<String> register(
    String name,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    final data = await postJson(
      '/register',
      useAuth: false,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    final responseData = _asMap(data);

    return responseData['message']?.toString() ?? 'Registrasi berhasil.';
  }

  Future<bool> logout([String? providedToken]) async {
    final token = providedToken ?? await getToken();

    try {
      if (token != null && token.isNotEmpty) {
        await postJson('/logout', token: token);
      }

      await clearToken();
      return true;
    } catch (_) {
      await clearToken();
      return false;
    }
  }

  Future<UserModel?> getUserProfile() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      return null;
    }

    final data = await getJson('/user', token: token);

    final responseData = _asMap(data);

    return UserModel.fromJson({
      'token': token,
      'user': responseData['user'] ?? responseData,
    });
  }

  Future<UserModel?> restoreSession() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      return null;
    }

    final data = await getJson('/user', token: token);

    final responseData = _asMap(data);

    return UserModel.fromJson({
      'token': token,
      'user': responseData['user'] ?? responseData,
    });
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    throw ApiException('Format response server tidak valid.');
  }
}
