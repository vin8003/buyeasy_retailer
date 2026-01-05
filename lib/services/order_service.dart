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

  Future<void> modifyOrder(
    String token,
    int orderId,
    List<Map<String, dynamic>> items,
    String? deliveryMode,
    double? discountAmount,
  ) async {
    final Map<String, dynamic> body = {'items': items};

    if (deliveryMode != null) {
      body['delivery_mode'] = deliveryMode;
    }

    if (discountAmount != null) {
      body['discount_amount'] = discountAmount;
    }

    final response = await http.post(
      Uri.parse('${ApiConstants.orders}$orderId/modify/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to modify order: ${response.body}');
    }
  }

  Future<void> rateCustomer(
    String token,
    int customerId,
    int rating,
    String comment,
  ) async {
    final response = await http.post(
      Uri.parse(ApiConstants.rateCustomer),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'customer': customerId,
        'rating': rating,
        'comment': comment,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to rate customer: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getCustomerRating(
    String token,
    int customerId,
  ) async {
    final response = await http.get(
      Uri.parse(ApiConstants.getCustomerRating(customerId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch customer rating');
    }
  }

  Future<List<dynamic>> getOrderMessages(String token, int orderId) async {
    final response = await http.get(
      Uri.parse(ApiConstants.orderMessages(orderId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load chat messages');
    }
  }

  Future<Map<String, dynamic>> sendOrderMessage(
    String token,
    int orderId,
    String message,
  ) async {
    final response = await http.post(
      Uri.parse(ApiConstants.sendOrderMessage(orderId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'message': message}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send message');
    }
  }
}
