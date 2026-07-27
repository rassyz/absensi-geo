// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService authService;

  static const String defaultSessionExpiredMessage =
      'Sesi login telah berakhir. Silakan login kembali.';

  // API State
  UserModel? _user;
  bool _isLoading = false;
  String _errorMessage = '';

  // Session State
  bool _isSessionExpired = false;
  String _sessionExpiredMessage = defaultSessionExpiredMessage;

  // UI State
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  AuthProvider(this.authService);

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  bool get isAuthenticated => _user != null && _user!.token.isNotEmpty;
  bool get isSessionExpired => _isSessionExpired;
  String get sessionExpiredMessage => _sessionExpiredMessage;

  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;
  bool get agreeToTerms => _agreeToTerms;

  // Private Helpers
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ignore: unused_element
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  String _cleanErrorMessage(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.replaceFirst('Exception: ', '');
    }

    return message;
  }

  void _resetExpiredSessionState() {
    _isSessionExpired = false;
    _sessionExpiredMessage = defaultSessionExpiredMessage;
  }

  // Session Methods
  void markSessionExpired([String? message]) {
    _user = null;
    _isSessionExpired = true;
    _sessionExpiredMessage = message?.trim().isNotEmpty == true
        ? message!.trim()
        : defaultSessionExpiredMessage;
    _errorMessage = _sessionExpiredMessage;
    notifyListeners();
  }

  void clearSessionExpiredNotice() {
    _resetExpiredSessionState();
    _errorMessage = '';
    notifyListeners();
  }

  // UI Methods
  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  void toggleTermsAgreement() {
    _agreeToTerms = !_agreeToTerms;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  // Auth Methods
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = '';

    try {
      final UserModel? result = await authService.login(email, password);

      if (result != null) {
        _user = result;
        _resetExpiredSessionState();
        _errorMessage = '';

        await NotificationService.instance.syncCurrentToken();

        return true;
      }

      _user = null;
      _resetExpiredSessionState();
      _errorMessage = 'Login gagal. Silakan coba lagi.';
      return false;
    } catch (e) {
      _user = null;
      _resetExpiredSessionState();
      _errorMessage = _cleanErrorMessage(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(
    String name,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    _setLoading(true);
    _errorMessage = '';

    try {
      await authService.register(name, email, password, passwordConfirmation);

      _errorMessage = '';
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    _errorMessage = '';

    try {
      final token = await authService.getToken();

      if (token != null && token.isNotEmpty) {
        // Hapus hubungan token FCM dengan pengguna sebelum
        // Bearer token Laravel dihapus.
        await NotificationService.instance.removeCurrentTokenFromBackend();

        await authService.logout(token);
      } else {
        await authService.clearToken();
      }

      _user = null;
      _resetExpiredSessionState();
    } catch (e) {
      await authService.clearToken();
      _user = null;
      _resetExpiredSessionState();
      _errorMessage = _cleanErrorMessage(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> getUserProfile() async {
    _setLoading(true);
    _errorMessage = '';

    try {
      final UserModel? result = await authService.getUserProfile();

      if (result != null) {
        _user = result;
        _resetExpiredSessionState();
        _errorMessage = '';
        return true;
      }

      _user = null;
      return false;
    } on UnauthorizedException catch (e) {
      markSessionExpired(e.message);
      return false;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Dipakai SplashScreen ketika aplikasi dimulai.
  ///
  /// Kondisi yang dibedakan:
  /// - Tidak ada token: pengguna memang belum login.
  /// - Token ditolak 401: sesi kedaluwarsa.
  /// - Token valid: sesi dipulihkan.
  Future<bool> restoreSession() async {
    _setLoading(true);
    _errorMessage = '';

    final bool previouslyAuthenticated = _user != null;

    try {
      final token = await authService.getToken();

      if (token == null || token.isEmpty) {
        _user = null;

        if (previouslyAuthenticated) {
          _isSessionExpired = true;
          _sessionExpiredMessage = defaultSessionExpiredMessage;
          _errorMessage = _sessionExpiredMessage;
        } else {
          _resetExpiredSessionState();
        }

        return false;
      }

      final UserModel? result = await authService.restoreSession();

      if (result != null && result.token.isNotEmpty) {
        _user = result;
        _resetExpiredSessionState();
        _errorMessage = '';

        await NotificationService.instance.syncCurrentToken();

        return true;
      }

      _user = null;
      _resetExpiredSessionState();
      return false;
    } on UnauthorizedException catch (e) {
      _user = null;
      _isSessionExpired = true;
      _sessionExpiredMessage = e.message;
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _user = null;
      _resetExpiredSessionState();
      _errorMessage = _cleanErrorMessage(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Dipakai ketika aplikasi kembali dari background.
  ///
  /// Gangguan jaringan tidak langsung mengeluarkan pengguna. Hanya respons
  /// Unauthorized/401 atau token lokal yang hilang yang dianggap sesi berakhir.
  Future<bool> validateCurrentSession() async {
    if (_isSessionExpired) {
      return false;
    }

    final bool previouslyAuthenticated = _user != null;

    try {
      final token = await authService.getToken();

      if (token == null || token.isEmpty) {
        if (previouslyAuthenticated) {
          markSessionExpired();
        }

        return false;
      }

      final UserModel? result = await authService.restoreSession();

      if (result != null && result.token.isNotEmpty) {
        _user = result;
        _resetExpiredSessionState();
        _errorMessage = '';
        notifyListeners();
        return true;
      }

      if (previouslyAuthenticated) {
        markSessionExpired();
      }

      return false;
    } on UnauthorizedException catch (e) {
      markSessionExpired(e.message);
      return false;
    } catch (e) {
      // Jangan keluarkan pengguna hanya karena internet sedang bermasalah.
      _errorMessage = _cleanErrorMessage(e);
      return isAuthenticated;
    }
  }

  Future<bool> checkLocalToken() async {
    final token = await authService.getToken();
    return token != null && token.isNotEmpty;
  }
}
