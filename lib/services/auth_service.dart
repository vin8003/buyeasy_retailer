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

  Future<Map<String, dynamic>> signup(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.serverUrl}/api/auth/retailer/signup/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['detail'] ??
            error['username']?[0] ??
            error['email']?[0] ??
            error['non_field_errors']?[0] ??
            'Failed to signup',
      );
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

  Future<Map<String, dynamic>> updateProfile(
    String token,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.serverUrl}/api/retailer/profile/update/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to update profile');
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

  Future<void> forgotPassword(String phone) async {
    final response = await http.post(
      Uri.parse(ApiConstants.forgotPassword),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone_number': phone}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(
        error['error'] ?? error['phone_number']?[0] ?? 'Failed to send OTP',
      );
    }
  }

  Future<void> resetPassword({
    required String phone,
    required String newPassword,
    String? otp,
    String? firebaseToken,
  }) async {
    final data = <String, dynamic>{
      'phone_number': phone,
      'new_password': newPassword,
      'confirm_password': newPassword,
    };
    if (otp != null) data['otp_code'] = otp;
    if (firebaseToken != null) data['firebase_token'] = firebaseToken;

    final response = await http.post(
      Uri.parse(ApiConstants.resetPassword),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(
        error['error'] ??
            error['new_password']?[0] ??
            'Failed to reset password',
      );
    }
  }
}
