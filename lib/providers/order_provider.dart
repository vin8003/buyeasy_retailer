import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();
  List<OrderModel> _orders = [];
  OrderModel? _selectedOrder;
  bool _isLoading = false;
  String? _error;

  List<OrderModel> get orders => _orders;
  OrderModel? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchOrders(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await _orderService.getOrders(token);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOrderDetails(String token, int orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedOrder = await _orderService.getOrderDetails(token, orderId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching order details: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateStatus(String token, int orderId, String status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _orderService.updateOrderStatus(token, orderId, status);
      // Refresh list
      await fetchOrders(token);
      // If the selected order is the same, refresh it too
      if (_selectedOrder?.id == orderId) {
        await fetchOrderDetails(token, orderId);
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelOrder(String token, int orderId, String reason) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _orderService.cancelOrder(token, orderId, reason);
      // Refresh list
      await fetchOrders(token);
      // If the selected order is the same, refresh it too
      if (_selectedOrder?.id == orderId) {
        await fetchOrderDetails(token, orderId);
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSelectedOrder() {
    _selectedOrder = null;
    notifyListeners();
  }
}
