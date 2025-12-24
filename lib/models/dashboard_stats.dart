class DashboardStats {
  final int totalOrders;
  final int pendingOrders;
  final int confirmedOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final double totalRevenue;
  final int todayOrders;
  final double todayRevenue;
  final double averageOrderValue;
  final List<dynamic> topCustomers;
  final List<dynamic> recentOrders;

  DashboardStats({
    required this.totalOrders,
    required this.pendingOrders,
    required this.confirmedOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.totalRevenue,
    required this.todayOrders,
    required this.todayRevenue,
    required this.averageOrderValue,
    required this.topCustomers,
    required this.recentOrders,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalOrders: json['total_orders'] ?? 0,
      pendingOrders: json['pending_orders'] ?? 0,
      confirmedOrders: json['confirmed_orders'] ?? 0,
      deliveredOrders: json['delivered_orders'] ?? 0,
      cancelledOrders: json['cancelled_orders'] ?? 0,
      totalRevenue: double.parse(json['total_revenue']?.toString() ?? '0'),
      todayOrders: json['today_orders'] ?? 0,
      todayRevenue: double.parse(json['today_revenue']?.toString() ?? '0'),
      averageOrderValue: double.parse(
        json['average_order_value']?.toString() ?? '0',
      ),
      topCustomers: json['top_customers'] ?? [],
      recentOrders: json['recent_orders'] ?? [],
    );
  }
}
