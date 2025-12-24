import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/order_model.dart';

class OrderService {
  Future<List<OrderModel>> getOrders(String token) async {
    final response = await http.get(
      Uri.parse(ApiConstants.orderHistory),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)['results'];
      return data.map((json) => OrderModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load orders');
    }
  }

  Future<OrderModel> getOrderDetails(String token, int orderId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.orders}$orderId/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return OrderModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load order details');
    }
  }

  Future<void> updateOrderStatus(
    String token,
    int orderId,
    String status,
  ) async {
    final response = await http.patch(
      Uri.parse('${ApiConstants.orders}$orderId/status/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update order status: ${response.body}');
    }
  }

  Future<void> cancelOrder(String token, int orderId, String reason) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.orders}$orderId/cancel/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'cancellation_reason': reason}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to cancel order');
    }
  }
}
