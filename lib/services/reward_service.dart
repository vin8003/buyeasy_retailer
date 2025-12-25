import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/reward_configuration.dart';

class RewardService {
  Future<RewardConfiguration> getRewardConfiguration(String token) async {
    final response = await http.get(
      Uri.parse(ApiConstants.rewardConfig),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return RewardConfiguration.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load reward configuration');
    }
  }

  Future<RewardConfiguration> updateRewardConfiguration(
    String token,
    RewardConfiguration config,
  ) async {
    final response = await http.put(
      Uri.parse(ApiConstants.rewardConfig),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(config.toJson()),
    );

    if (response.statusCode == 200) {
      return RewardConfiguration.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update reward configuration');
    }
  }

  Future<List<dynamic>> getRetailerCustomersLoyalty(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/customer/loyalty/retailer-customers/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load customer loyalty data');
    }
  }
}
