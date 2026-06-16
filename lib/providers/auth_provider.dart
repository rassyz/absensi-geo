// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../models/user_model.dart';
// import '../services/api_service.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService authService;

  // --- API State ---
  UserModel? _user;
  bool _isLoading = false;
  String _errorMessage = '';

  // --- UI State (Restored) ---
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  AuthProvider(this.authService);

  // --- Getters ---
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;
  bool get agreeToTerms => _agreeToTerms;

  // --- UI Methods ---
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

  // --- API Methods ---
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      UserModel? result = await authService.login(email, password);
      if (result != null) {
        _user = result;
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(
    String name,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await authService.register(name, email, password, passwordConfirmation);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final token = await authService.getToken();

    if (token != null && token.isNotEmpty) {
      await authService.logout(token);
    } else {
      await authService.clearToken();
    }

    _user = null;
    notifyListeners();
  }

  Future<void> getUserProfile() async {
    try {
      UserModel? result = await authService.getUserProfile();
      if (result != null) {
        _user = result;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> restoreSession() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await authService.restoreSession();

      if (result != null) {
        _user = result;
        return true;
      }

      _user = null;
      return false;
    } catch (e) {
      _user = null;
      _errorMessage = e.toString();
      await authService.clearToken();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
