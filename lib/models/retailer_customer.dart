class RetailerCustomer {
  final int customerId;
  final String customerName;
  final String? phoneNumber;
  final String? profileImage;
  final double points;
  final double averageRating;
  final int totalOrders;
  final double totalSpent;
  final bool isBlacklisted;
  final DateTime? lastOrderDate;
  final DateTime? joinedDate;

  RetailerCustomer({
    required this.customerId,
    required this.customerName,
    this.phoneNumber,
    this.profileImage,
    required this.points,
    required this.averageRating,
    required this.totalOrders,
    required this.totalSpent,
    required this.isBlacklisted,
    this.lastOrderDate,
    this.joinedDate,
  });

  factory RetailerCustomer.fromJson(Map<String, dynamic> json) {
    return RetailerCustomer(
      customerId: json['customer_id'] ?? 0,
      customerName: json['customer_name'] ?? 'Unknown',
      phoneNumber: json['phone_number'],
      profileImage: json['profile_image'],
      points: double.tryParse(json['points'].toString()) ?? 0.0,
      averageRating: double.tryParse(json['average_rating'].toString()) ?? 0.0,
      totalOrders: json['total_orders'] ?? 0,
      totalSpent: double.tryParse(json['total_spent'].toString()) ?? 0.0,
      isBlacklisted: json['is_blacklisted'] ?? false,
      lastOrderDate: json['last_order_date'] != null
          ? DateTime.parse(json['last_order_date'])
          : null,
      joinedDate: json['joined_date'] != null
          ? DateTime.parse(json['joined_date'])
          : null,
    );
  }
}

class RetailerCustomerDetail extends RetailerCustomer {
  final String? email;
  final List<dynamic> recentOrders;
  final List<dynamic> rewardHistory;
  final List<dynamic> retailerRatings;

  RetailerCustomerDetail({
    required super.customerId,
    required super.customerName,
    super.phoneNumber,
    super.profileImage,
    required super.points,
    required super.averageRating,
    required super.totalOrders,
    required super.totalSpent,
    required super.isBlacklisted,
    super.lastOrderDate,
    super.joinedDate,
    this.email,
    required this.recentOrders,
    required this.rewardHistory,
    required this.retailerRatings,
  });

  factory RetailerCustomerDetail.fromJson(Map<String, dynamic> json) {
    return RetailerCustomerDetail(
      customerId: json['customer_id'] ?? 0,
      customerName: json['customer_name'] ?? 'Unknown',
      phoneNumber: json['phone_number'],
      profileImage: json['profile_image'],
      points: double.tryParse(json['points'].toString()) ?? 0.0,
      averageRating: double.tryParse(json['average_rating'].toString()) ?? 0.0,
      totalOrders: json['total_orders'] ?? 0,
      totalSpent: double.tryParse(json['total_spent'].toString()) ?? 0.0,
      isBlacklisted: json['is_blacklisted'] ?? false,
      lastOrderDate: json['last_order_date'] != null
          ? DateTime.parse(json['last_order_date'])
          : null,
      joinedDate: json['joined_date'] != null
          ? DateTime.parse(json['joined_date'])
          : null,
      email: json['email'],
      recentOrders: json['recent_orders'] ?? [],
      rewardHistory: json['reward_history'] ?? [],
      retailerRatings: json['retailer_ratings'] ?? [],
    );
  }
}
