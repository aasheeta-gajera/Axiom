
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  AuthProvider(this._authService);

  // Form controllers
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  // State
  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  bool get isLogin => _isLogin;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Toggle between login and registration
  void toggleAuthMode() {
    _isLogin = !_isLogin;
    _errorMessage = null;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Handle form submission
  Future<bool> handleSubmit() async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    bool success;

    try {
      if (_isLogin) {
        success = await _authService.login(
          emailController.text.trim(),
          passwordController.text,
        );
      } else {
        success = await _authService.register(
          nameController.text.trim(),
          emailController.text.trim(),
          passwordController.text,
        );
      }

      if (!success) {
        _errorMessage = _isLogin
            ? 'Invalid email or password'
            : 'Registration failed. Email may already exist.';
      }
    } catch (e) {
      success = false;
      _errorMessage = 'An error occurred. Please try again.';
    }

    _isLoading = false;
    notifyListeners();

    return success;
  }

  // Clean up controllers
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }
}