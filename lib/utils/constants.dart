import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String serverUrl =
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  static String baseUrl = '$serverUrl/api';

  // Auth endpoints
  static String login = '$baseUrl/auth/retailer/login/';
  static String signup = '$baseUrl/auth/retailer/signup/';
  static String profile = '$baseUrl/auth/profile/';
  static String registerDevice = '$baseUrl/auth/device/register/';
  static String verifyOtp = '$baseUrl/auth/customer/verify-otp/';

  // Product endpoints
  static String products = '$baseUrl/products/';
  static String createProduct = '$baseUrl/products/create/';
  static String categories = '$baseUrl/products/categories/';
  static String brands = '$baseUrl/products/brands/';
  static String uploadProducts = '$baseUrl/products/upload/';
  static String productDetail(int id) => '$baseUrl/products/$id/';
  static String updateProduct(int id) => '$baseUrl/products/$id/update/';
  static String deleteProduct(int id) => '$baseUrl/products/$id/delete/';

  // Order endpoints
  static String orders = '$baseUrl/orders/';
  static String currentOrders = '$baseUrl/orders/current/';
  static String orderHistory = '$baseUrl/orders/history/';
  static String orderStats = '$baseUrl/orders/stats/';
}
