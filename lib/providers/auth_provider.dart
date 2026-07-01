// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService authService;

  // API State
  UserModel? _user;
  bool _isLoading = false;
  String _errorMessage = '';

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
      // ignore: unnecessary_nullable_for_final_variable_declarations
      final UserModel? result = await authService.login(email, password);

      if (result != null) {
        _user = result;
        _errorMessage = '';
        return true;
      }

      _user = null;
      _errorMessage = 'Login gagal. Silakan coba lagi.';
      return false;
    } catch (e) {
      _user = null;
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
        await authService.logout(token);
      } else {
        await authService.clearToken();
      }

      _user = null;
    } catch (e) {
      await authService.clearToken();
      _user = null;
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
        _errorMessage = '';
        return true;
      }

      _user = null;
      return false;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> restoreSession() async {
    _setLoading(true);
    _errorMessage = '';

    try {
      final UserModel? result = await authService.restoreSession();

      if (result != null && result.token.isNotEmpty) {
        _user = result;
        _errorMessage = '';
        return true;
      }

      _user = null;
      return false;
    } catch (e) {
      _user = null;
      _errorMessage = _cleanErrorMessage(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> checkLocalToken() async {
    final token = await authService.getToken();
    return token != null && token.isNotEmpty;
  }
}
