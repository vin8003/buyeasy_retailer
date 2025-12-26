import 'package:flutter/material.dart';
import '../models/dashboard_stats.dart';
import '../services/dashboard_service.dart';

class DashboardProvider with ChangeNotifier {
  final DashboardService _dashboardService = DashboardService();
  DashboardStats? _stats;
  bool _isLoading = false;
  String? _error;

  DashboardStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchStats(String token) async {
    debugPrint('DashboardProvider: fetchStats started');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stats = await _dashboardService.getStats(token);
      debugPrint(
        'DashboardProvider: fetchStats success. Orders: ${_stats?.totalOrders}',
      );
    } catch (e) {
      debugPrint('DashboardProvider: fetchStats error: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
