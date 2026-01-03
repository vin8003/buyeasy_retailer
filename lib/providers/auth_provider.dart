import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  UserModel? _user;
  String? _token;
  bool _isLoading = false;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  AuthProvider() {
    _loadToken();
    // Set up forced logout callback so when ApiService detects token expiration,
    // it notifies us and we can update our state
    _apiService.setForcedLogoutCallback(_handleForcedLogout);
  }

  void _handleForcedLogout() {
    _token = null;
    _user = null;
    notifyListeners();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');

    // Also load refresh token into ApiService
    await _apiService.checkAuthToken();

    if (_token != null) {
      try {
        await fetchProfile();
      } catch (e) {
        // If profile fetch fails (likely expired token),
        // ApiService will handle the logout automatically
        debugPrint('Profile fetch failed during init: $e');
      }
    }
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.login(username, password);
      final data = response.data;

      _token = data['tokens']['access'];
      final refresh = data['tokens']['refresh'];

      await _apiService.setAuthToken(_token, refresh);

      // Register Device
      try {
        final fcmToken = await NotificationService().getToken();
        if (fcmToken != null) {
          await _apiService.registerDeviceToken(fcmToken);
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
      final response = await _apiService.signup(signupData);
      final data = response.data;

      _token = data['tokens']['access'];
      final refresh = data['tokens']['refresh'];

      await _apiService.setAuthToken(_token, refresh);

      // Register Device
      try {
        final fcmToken = await NotificationService().getToken();
        if (fcmToken != null) {
          await _apiService.registerDeviceToken(fcmToken);
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

  Future<void> requestPhoneVerification() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.requestPhoneVerification();
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
      final response = await _apiService.verifyOtp(
        phone,
        otp: otp,
        firebaseToken: firebaseToken,
      );
      final data = response.data;

      if (data['tokens'] != null) {
        _token = data['tokens']['access'];
        final refresh = data['tokens']['refresh'];
        await _apiService.setAuthToken(_token, refresh);
        await fetchProfile();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProfile() async {
    if (_token == null) return;
    final response = await _apiService.fetchProfile();
    _user = UserModel.fromJson(response.data);
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_token == null) return;
    final response = await _apiService.updateProfile(data);
    _user = UserModel.fromJson(response.data);
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await _apiService.setAuthToken(null, null);
    notifyListeners();
  }

  Future<void> forgotPassword(String phone) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.forgotPassword(phone);
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
      await _apiService.resetPassword(
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
