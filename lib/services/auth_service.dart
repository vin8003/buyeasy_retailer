import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse(ApiConstants.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to login');
    }
  }

  Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await http.get(
      Uri.parse(ApiConstants.profile),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get profile');
    }
  }

  Future<void> registerDevice(String token, String fcmToken) async {
    final response = await http.post(
      Uri.parse(ApiConstants.registerDevice),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'registration_id': fcmToken,
        'type': 'android', // Or detect platform
        'name': 'retailer_app',
      }),
    );

    if (response.statusCode != 200) {
      print('Failed to register device: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> verifyOtp(
    String phone, {
    String? otp,
    String? firebaseToken,
  }) async {
    final body = <String, String>{'phone_number': phone};
    if (otp != null) body['otp_code'] = otp;
    if (firebaseToken != null) body['firebase_token'] = firebaseToken;

    final response = await http.post(
      Uri.parse(ApiConstants.verifyOtp),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to verify OTP');
    }
  }
}
