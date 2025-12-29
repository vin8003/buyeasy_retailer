import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  String? _token;
  bool _isLoading = false;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    if (_token != null) {
      try {
        await fetchProfile();
      } catch (e) {
        logout();
      }
    }
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _authService.login(username, password);
      _token = data['tokens']['access']; // JWT access token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', _token!);

      // Register Device
      try {
        final fcmToken = await NotificationService().getToken();
        if (fcmToken != null) {
          await _authService.registerDevice(_token!, fcmToken);
        }
      } catch (e) {
        debugPrint('Device registration error: $e');
      }

      await fetchProfile();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signup(Map<String, dynamic> signupData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _authService.signup(signupData);
      _token = data['tokens']['access']; // JWT access token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', _token!);

      // Register Device
      try {
        final fcmToken = await NotificationService().getToken();
        if (fcmToken != null) {
          await _authService.registerDevice(_token!, fcmToken);
        }
      } catch (e) {
        debugPrint('Device registration error: $e');
      }

      await fetchProfile();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyOtp(
    String phone, {
    String? otp,
    String? firebaseToken,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _authService.verifyOtp(
        phone,
        otp: otp,
        firebaseToken: firebaseToken,
      );
      if (data['tokens'] != null) {
        _token = data['tokens']['access'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', _token!);
        await fetchProfile();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProfile() async {
    if (_token == null) return;
    final data = await _authService.getProfile(_token!);
    _user = UserModel.fromJson(data);
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_token == null) return;
    final updatedData = await _authService.updateProfile(_token!, data);
    _user = UserModel.fromJson(updatedData);
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    notifyListeners();
  }

  Future<void> forgotPassword(String phone) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.forgotPassword(phone);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword({
    required String phone,
    required String newPassword,
    String? otp,
    String? firebaseToken,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.resetPassword(
        phone: phone,
        otp: otp,
        firebaseToken: firebaseToken,
        newPassword: newPassword,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
