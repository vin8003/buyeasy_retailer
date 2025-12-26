import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/dashboard_stats.dart';

class DashboardService {
  Future<DashboardStats> getStats(String token) async {
    final response = await http.get(
      Uri.parse(ApiConstants.orderStats),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return DashboardStats.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Failed to load dashboard statistics: ${response.statusCode} - ${response.body}',
      );
    }
  }
}
