class ApiConstants {
  static const String serverUrl = 'http://localhost:8000';
  static const String baseUrl = '$serverUrl/api';

  // Auth endpoints
  static const String login = '$baseUrl/auth/retailer/login/';
  static const String signup = '$baseUrl/auth/retailer/signup/';
  static const String profile = '$baseUrl/auth/profile/';
  static const String registerDevice = '$baseUrl/auth/device/register/';

  // Product endpoints
  static const String products = '$baseUrl/products/';
  static const String createProduct = '$baseUrl/products/create/';
  static const String categories = '$baseUrl/products/categories/';
  static const String brands = '$baseUrl/products/brands/';
  static const String uploadProducts = '$baseUrl/products/upload/';
  static String productDetail(int id) => '$baseUrl/products/$id/';
  static String updateProduct(int id) => '$baseUrl/products/$id/update/';
  static String deleteProduct(int id) => '$baseUrl/products/$id/delete/';

  // Order endpoints
  static const String orders = '$baseUrl/orders/';
  static const String currentOrders = '$baseUrl/orders/current/';
  static const String orderHistory = '$baseUrl/orders/history/';
  static const String orderStats = '$baseUrl/orders/stats/';
}
