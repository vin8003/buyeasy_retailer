import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Centralized API service for the retailer app with token refresh and
/// automatic logout on token expiration.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;
  String? _accessToken;
  String? _refreshToken;

  String _baseUrl = 'https://api.ordereasy.win/api/';

  // Navigation key to allow navigating from outside the widget tree
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Callback for when automatic logout happens due to token expiration
  VoidCallback? _onForcedLogout;

  /// Set a callback to be invoked when the API service forces a logout
  /// due to token expiration or invalid token.
  void setForcedLogoutCallback(VoidCallback? callback) {
    _onForcedLogout = callback;
  }

  String formatImageUrl(String? path) {
    if (path == null || path.isEmpty) return 'https://via.placeholder.com/150';
    if (path.startsWith('http')) return path;
    // Remove /api/ from base URL for media paths
    final serverUrl = _baseUrl.replaceAll('/api/', '/');
    return '$serverUrl${path.startsWith('/') ? path.substring(1) : path}';
  }

  // --- Concurrency / Refresh Locking ---
  bool _isRefreshing = false;
  late final _refreshCompleter = <Completer<String?>>[];

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(milliseconds: 30000),
        receiveTimeout: const Duration(milliseconds: 30000),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Do NOT attach token for refresh endpoint
          if (options.path.contains('/auth/token/refresh/')) {
            return handler.next(options);
          }

          if (_accessToken != null && _accessToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Handle 401 (Unauthorized) errors
          if (e.response?.statusCode == 401) {
            // Check if it's a refresh token failure or if we don't have a refresh token
            if (_refreshToken == null ||
                e.requestOptions.path.contains('/auth/token/refresh/')) {
              logout();
              return handler.next(e);
            }

            if (_isRefreshing) {
              // Wait for the current refresh to complete
              final completer = Completer<String?>();
              _refreshCompleter.add(completer);
              final newToken = await completer.future;

              if (newToken != null) {
                return _retry(e.requestOptions, newToken, handler);
              } else {
                return handler.next(e);
              }
            }

            _isRefreshing = true;

            try {
              // Attempt to refresh token
              final newAccessToken = await _refreshTokenAndGetNew();

              // Complete all waiting requests
              for (var completer in _refreshCompleter) {
                completer.complete(newAccessToken);
              }
              _refreshCompleter.clear();
              _isRefreshing = false;

              if (newAccessToken != null) {
                return _retry(e.requestOptions, newAccessToken, handler);
              } else {
                logout();
                return handler.next(e);
              }
            } catch (refreshError) {
              // Fail all waiting
              for (var completer in _refreshCompleter) {
                completer.complete(null);
              }
              _refreshCompleter.clear();
              _isRefreshing = false;

              logout();
              return handler.next(e);
            }
          }
          debugPrint('API Error: ${e.response?.data ?? e.message}');
          return handler.next(e);
        },
      ),
    );
    _initBaseUrl(); // Load saved URL on startup
  }

  Future<void> _initBaseUrl() async {
    _baseUrl = 'https://api.ordereasy.win/api/';
    _dio.options.baseUrl = _baseUrl;
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = '$url/api/';
    _dio.options.baseUrl = _baseUrl;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_server_url', url);
  }

  String get baseUrl => _baseUrl;

  Future<void> _retry(
    RequestOptions requestOptions,
    String newToken,
    ErrorInterceptorHandler handler,
  ) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    options.headers?['Authorization'] = 'Bearer $newToken';
    try {
      final response = await _dio.request(
        requestOptions.path,
        data: requestOptions.data,
        queryParameters: requestOptions.queryParameters,
        options: options,
      );
      handler.resolve(response);
    } catch (e) {
      if (e is DioException) {
        handler.next(e);
      }
    }
  }

  Future<void> logout() async {
    await setAuthToken(null, null);
    // Notify listeners (e.g., AuthProvider) about the forced logout
    _onForcedLogout?.call();
    // Use navigatorKey to navigate to login screen
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  Future<void> registerDeviceToken(String token) async {
    try {
      await _dio.post(
        'auth/device/register/',
        data: {
          'registration_id': token,
          'type': defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
          'name': 'retailer_app',
        },
      );
      if (kDebugMode) {
        debugPrint('FCM Token registered successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to register FCM token: $e');
      }
    }
  }

  Future<String?> _refreshTokenAndGetNew() async {
    try {
      final response = await _dio.post(
        'auth/token/refresh/',
        data: {'refresh': _refreshToken},
      );

      if (response.statusCode == 200) {
        final newAccess = response.data['access'];
        final newRefresh = response.data['refresh'] ?? _refreshToken;

        await setAuthToken(newAccess, newRefresh);
        return newAccess;
      }
    } catch (e) {
      debugPrint('Token Refresh Failed: $e');
    }
    return null;
  }

  Future<void> checkAuthToken() async {
    _baseUrl = 'https://api.ordereasy.win/api/';
    _dio.options.baseUrl = _baseUrl;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  Future<void> setAuthToken(String? access, String? refresh) async {
    _accessToken = access;
    _refreshToken = refresh;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (access == null) {
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
    } else {
      await prefs.setString('access_token', access);
      if (refresh != null) {
        await prefs.setString('refresh_token', refresh);
      }
    }
  }

  // --- Auth Methods ---
  Future<Response> login(String username, String password) async {
    await setAuthToken(null, null);
    return _dio.post(
      'auth/retailer/login/',
      data: {'username': username, 'password': password},
    );
  }

  Future<Response> signup(Map<String, dynamic> data) async {
    await setAuthToken(null, null);
    return _dio.post('auth/retailer/signup/', data: data);
  }

  // --- Profile Methods ---
  Future<Response> fetchProfile() {
    return _dio.get('retailer/profile/');
  }

  Future<Response> updateProfile(Map<String, dynamic> data) {
    return _dio.put('retailer/profile/update/', data: data);
  }

  // --- Product Methods ---
  Future<Response> getProducts() {
    return _dio.get('products/');
  }

  Future<Response> createProduct(Map<String, dynamic> data) {
    return _dio.post('products/create/', data: data);
  }

  Future<Response> updateProduct(int id, Map<String, dynamic> data) {
    return _dio.put('products/$id/update/', data: data);
  }

  Future<Response> deleteProduct(int id) {
    return _dio.delete('products/$id/delete/');
  }

  Future<Response> getCategories() {
    return _dio.get('products/categories/');
  }

  Future<Response> getBrands() {
    return _dio.get('products/brands/');
  }

  Future<Response> searchMasterProduct(String barcode) {
    return _dio.get(
      'products/master/search/',
      queryParameters: {'barcode': barcode},
    );
  }

  Future<Response> checkBulkUpload(FormData formData) {
    return _dio.post('products/upload/check/', data: formData);
  }

  Future<Response> completeBulkUpload(FormData formData) {
    return _dio.post('products/upload/complete/', data: formData);
  }

  // --- Order Methods ---
  Future<Response> getOrders() {
    return _dio.get('orders/');
  }

  Future<Response> getCurrentOrders() {
    return _dio.get('orders/current/');
  }

  Future<Response> getOrderHistory() {
    return _dio.get('orders/history/');
  }

  Future<Response> getOrderDetail(int orderId) {
    return _dio.get('orders/$orderId/');
  }

  Future<Response> updateOrderStatus(int orderId, String status) {
    return _dio.put('orders/$orderId/status/', data: {'status': status});
  }

  Future<Response> getOrderStats() {
    return _dio.get('orders/stats/');
  }

  // --- Retailer Config Methods ---
  Future<Response> getRewardConfig() {
    return _dio.get('retailers/reward-config/');
  }

  Future<Response> updateRewardConfig(Map<String, dynamic> data) {
    return _dio.put('retailers/reward-config/', data: data);
  }

  // --- OTP/Password Methods ---
  Future<Response> requestPhoneVerification() {
    return _dio.post('auth/customer/request-verification/');
  }

  Future<Response> verifyOtp(
    String phone, {
    String? otp,
    String? firebaseToken,
  }) {
    final data = {'phone_number': phone};
    if (otp != null) data['otp_code'] = otp;
    if (firebaseToken != null) data['firebase_token'] = firebaseToken;

    return _dio.post('auth/customer/verify-otp/', data: data);
  }

  Future<Response> forgotPassword(String phone) {
    return _dio.post('auth/password/forgot/', data: {'phone_number': phone});
  }

  Future<Response> resetPassword({
    required String phone,
    required String newPassword,
    String? otp,
    String? firebaseToken,
  }) {
    final data = <String, dynamic>{
      'phone_number': phone,
      'new_password': newPassword,
      'confirm_password': newPassword,
    };
    if (otp != null) data['otp_code'] = otp;
    if (firebaseToken != null) data['firebase_token'] = firebaseToken;

    return _dio.post('auth/password/reset/', data: data);
  }
}
