import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();
  List<OrderModel> _orders = [];
  OrderModel? _selectedOrder;
  Map<String, dynamic>? _customerRating;
  List<dynamic> _chatMessages = [];
  bool _isLoading = false;
  String? _error;

  List<OrderModel> get orders => _orders;
  OrderModel? get selectedOrder => _selectedOrder;
  Map<String, dynamic>? get customerRating => _customerRating;
  List<dynamic> get chatMessages => _chatMessages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<int, int> _unreadCounts = {};
  Map<int, int> get unreadCounts => _unreadCounts;

  int? _currentChatOrderId;
  int? get currentChatOrderId => _currentChatOrderId;

  void updateUnreadCount(int orderId, int count) {
    _unreadCounts[orderId] = count;
    notifyListeners();
  }

  void incrementUnreadCount(int orderId) {
    _unreadCounts[orderId] = (_unreadCounts[orderId] ?? 0) + 1;
    notifyListeners();
  }

  void resetUnreadCount(int orderId) {
    _unreadCounts[orderId] = 0;
    notifyListeners();
  }

  void setCurrentChatOrderId(int? orderId) {
    _currentChatOrderId = orderId;
    if (orderId != null) {
      resetUnreadCount(orderId);
    }
    notifyListeners();
  }

  Future<void> fetchOrders(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await _orderService.getOrders(token);
      _unreadCounts.clear();
      for (var order in _orders) {
        _unreadCounts[order.id] = order.unreadChatCount;
      }
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
      if (_selectedOrder != null) {
        updateUnreadCount(orderId, _selectedOrder!.unreadChatCount);
      }
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

  Future<void> fetchCustomerRating(String token, int customerId) async {
    try {
      _customerRating = await _orderService.getCustomerRating(
        token,
        customerId,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching customer rating: $e');
    }
  }

  Future<void> rateCustomer(
    String token,
    int customerId,
    int rating,
    String comment,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _orderService.rateCustomer(token, customerId, rating, comment);
      // Refresh rating
      await fetchCustomerRating(token, customerId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchChatMessages(String token, int orderId) async {
    try {
      _chatMessages = await _orderService.getOrderMessages(token, orderId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching chat messages: $e');
    }
  }

  Future<void> sendChatMessage(
    String token,
    int orderId,
    String message,
  ) async {
    try {
      final newMessage = await _orderService.sendOrderMessage(
        token,
        orderId,
        message,
      );
      _chatMessages.add(newMessage);
      notifyListeners();
    } catch (e) {
      debugPrint('Error sending chat message: $e');
      rethrow;
    }
  }

  void clearSelectedOrder() {
    _selectedOrder = null;
    _customerRating = null;
    _chatMessages = [];
    notifyListeners();
  }
}
