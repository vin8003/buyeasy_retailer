class ApiConstants {
  static const String _serverUrl = 'https://api.ordereasy.win';
  // static const String _serverUrl = 'http://127.0.0.1:8000';

  static String get serverUrl => _serverUrl;
  static String get baseUrl => '$serverUrl/api';

  static Future<void> loadServerUrl() async {
    // No-op as URL is now hardcoded
  }

  static Future<void> setServerUrl(String url) async {
    // No-op as URL is now hardcoded
  }

  // Auth endpoints
  static String get login => '$baseUrl/auth/retailer/login/';
  static String get signup => '$baseUrl/auth/retailer/signup/';
  static String get profile => '$baseUrl/auth/profile/';
  static String get registerDevice => '$baseUrl/auth/device/register/';
  static String get verifyOtp => '$baseUrl/auth/customer/verify-otp/';
  static String get forgotPassword => '$baseUrl/auth/password/forgot/';
  static String get resetPassword => '$baseUrl/auth/password/reset/';

  // Product endpoints
  static String get products => '$baseUrl/products/';
  static String get createProduct => '$baseUrl/products/create/';
  static String get categories => '$baseUrl/products/categories/';
  static String get brands => '$baseUrl/products/brands/';
  static String get uploadProducts => '$baseUrl/products/upload/';
  static String productDetail(int id) => '$baseUrl/products/$id/';
  static String updateProduct(int id) => '$baseUrl/products/$id/update/';
  static String deleteProduct(int id) => '$baseUrl/products/$id/delete/';
  static String get masterProductSearch => '$baseUrl/products/master/search/';
  static String get downloadTemplate => '$baseUrl/products/bulk-template/';

  // Visual Bulk Upload
  static String get getActiveSessions =>
      '$baseUrl/products/upload/session/active/';
  static String getSessionDetails(int id) =>
      '$baseUrl/products/upload/session/$id/';
  static String get updateSessionItems =>
      '$baseUrl/products/upload/session/update-items/';
  static String get commitSession => '$baseUrl/products/upload/session/commit/';

  // Order endpoints
  static String get orders => '$baseUrl/orders/';
  static String get currentOrders => '$baseUrl/orders/current/';
  static String get orderHistory => '$baseUrl/orders/history/';
  static String get orderStats => '$baseUrl/orders/stats/';

  // Retailer endpoints
  static String get rewardConfig => '$baseUrl/retailers/reward-config/';
}
