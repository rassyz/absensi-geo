// lib/services/base_api_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_exception.dart';

class BaseApiService {
  static const String baseUrl = "https://gallery-wham-jaunt.ngrok-free.dev/api";

  static const Duration apiTimeout = Duration(seconds: 15);
  static const Duration multipartTimeout = Duration(seconds: 45);

  // Token Storage
  Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('loginToken');
  }

  Future<void> setToken(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('loginToken', token);
  }

  Future<void> clearToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('loginToken');
  }

  // Headers
  Future<Map<String, String>> getHeaders([String? providedToken]) async {
    final token = providedToken ?? await getToken();

    if (token == null || token.isEmpty) {
      throw UnauthorizedException('Token login tidak ditemukan.');
    }

    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',

      // Hapus header ini ketika sudah tidak memakai ngrok.
      'ngrok-skip-browser-warning': 'true',
    };
  }

  Future<Map<String, String>> getGuestHeaders() async {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',

      // Hapus header ini ketika sudah tidak memakai ngrok.
      'ngrok-skip-browser-warning': 'true',
    };
  }

  Future<Map<String, String>> getMultipartHeaders([
    String? providedToken,
  ]) async {
    final token = providedToken ?? await getToken();

    if (token == null || token.isEmpty) {
      throw UnauthorizedException('Token login tidak ditemukan.');
    }

    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',

      // Hapus header ini ketika sudah tidak memakai ngrok.
      'ngrok-skip-browser-warning': 'true',
    };
  }

  Uri buildUri(String endpoint, [Map<String, dynamic>? queryParameters]) {
    final uri = Uri.parse('$baseUrl$endpoint');

    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    final cleanQuery = <String, String>{};

    queryParameters.forEach((key, value) {
      if (value != null) {
        cleanQuery[key] = value.toString();
      }
    });

    return uri.replace(queryParameters: cleanQuery);
  }

  // JSON Request Helpers
  Future<dynamic> getJson(
    String endpoint, {
    String? token,
    Map<String, dynamic>? queryParameters,
    bool useAuth = true,
  }) async {
    return _guardRequest(() async {
      final response = await http
          .get(
            buildUri(endpoint, queryParameters),
            headers: useAuth
                ? await getHeaders(token)
                : await getGuestHeaders(),
          )
          .timeout(apiTimeout);

      return _handleResponse(response);
    });
  }

  Future<dynamic> postJson(
    String endpoint, {
    String? token,
    Map<String, dynamic>? body,
    bool useAuth = true,
  }) async {
    return _guardRequest(() async {
      final response = await http
          .post(
            buildUri(endpoint),
            headers: useAuth
                ? await getHeaders(token)
                : await getGuestHeaders(),
            body: jsonEncode(body ?? {}),
          )
          .timeout(apiTimeout);

      return _handleResponse(response);
    });
  }

  Future<dynamic> putJson(
    String endpoint, {
    String? token,
    Map<String, dynamic>? body,
    bool useAuth = true,
  }) async {
    return _guardRequest(() async {
      final response = await http
          .put(
            buildUri(endpoint),
            headers: useAuth
                ? await getHeaders(token)
                : await getGuestHeaders(),
            body: jsonEncode(body ?? {}),
          )
          .timeout(apiTimeout);

      return _handleResponse(response);
    });
  }

  Future<dynamic> deleteJson(
    String endpoint, {
    String? token,
    Map<String, dynamic>? body,
    bool useAuth = true,
  }) async {
    return _guardRequest(() async {
      final response = await http
          .delete(
            buildUri(endpoint),
            headers: useAuth
                ? await getHeaders(token)
                : await getGuestHeaders(),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(apiTimeout);

      return _handleResponse(response);
    });
  }

  // Multipart Request Helper
  Future<dynamic> postMultipart(
    String endpoint, {
    required String token,
    required Map<String, String> fields,
    Map<String, File>? files,
  }) async {
    return _guardRequest(() async {
      final request = http.MultipartRequest('POST', buildUri(endpoint));

      request.headers.addAll(await getMultipartHeaders(token));
      request.fields.addAll(fields);

      if (files != null && files.isNotEmpty) {
        for (final entry in files.entries) {
          request.files.add(
            await http.MultipartFile.fromPath(entry.key, entry.value.path),
          );
        }
      }

      final streamedResponse = await request.send().timeout(multipartTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    });
  }

  // Global Error Handling
  Future<dynamic> _guardRequest(Future<dynamic> Function() request) async {
    try {
      return await request();
    } on TimeoutException {
      throw RequestTimeoutException();
    } on SocketException {
      throw NetworkException();
    } on HttpException {
      throw NetworkException('Terjadi gangguan komunikasi dengan server.');
    } on FormatException {
      throw ApiException('Format response server tidak valid.');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Terjadi kesalahan. Silakan coba lagi.');
    }
  }

  dynamic _handleResponse(http.Response response) async {
    final int statusCode = response.statusCode;
    final dynamic decodedBody = _decodeBody(response.body);

    if (statusCode >= 200 && statusCode < 300) {
      return decodedBody;
    }

    final String message = _extractMessage(decodedBody, statusCode);
    final dynamic errors = _extractErrors(decodedBody);

    if (statusCode == 401) {
      await clearToken();
      throw UnauthorizedException(message);
    }

    if (statusCode == 403) {
      throw ForbiddenException(message);
    }

    if (statusCode == 422) {
      throw ApiException(message, statusCode: statusCode, errors: errors);
    }

    if (statusCode >= 500) {
      throw ApiException(
        'Server sedang mengalami gangguan. Silakan coba beberapa saat lagi.',
        statusCode: statusCode,
      );
    }

    throw ApiException(message, statusCode: statusCode, errors: errors);
  }

  dynamic _decodeBody(String body) {
    if (body.isEmpty) {
      return null;
    }

    return jsonDecode(body);
  }

  String _extractMessage(dynamic decodedBody, int statusCode) {
    if (decodedBody is Map<String, dynamic>) {
      final dynamic message = decodedBody['message'];

      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    switch (statusCode) {
      case 400:
        return 'Permintaan tidak valid.';
      case 401:
        return 'Sesi login telah berakhir. Silakan login kembali.';
      case 403:
        return 'Anda tidak memiliki izin untuk mengakses data ini.';
      case 404:
        return 'Data tidak ditemukan.';
      case 422:
        return 'Data yang dikirim belum valid.';
      default:
        return 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }

  dynamic _extractErrors(dynamic decodedBody) {
    if (decodedBody is Map<String, dynamic>) {
      return decodedBody['errors'];
    }

    return null;
  }
}
