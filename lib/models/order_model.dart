class OrderItem {
  final int id;
  final int productId;
  final String productName;
  final String? productImage;
  final double productPrice;
  final String productUnit;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.productPrice,
    required this.productUnit,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? 0,
      productId: json['product'] ?? 0,
      productName: json['product_name'] ?? '',
      productImage: json['product_image'],
      productPrice: double.parse(json['product_price']?.toString() ?? '0'),
      productUnit: json['product_unit'] ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: double.parse(json['unit_price']?.toString() ?? '0'),
      totalPrice: double.parse(json['total_price']?.toString() ?? '0'),
    );
  }
}

class OrderModel {
  final int id;
  final String orderNumber;
  final String status;
  final double totalAmount;
  final String customerName;
  final int customer;
  final String createdAt;
  final String deliveryMode;
  final String retailerName;

  // Detailed fields
  final String? retailerPhone;
  final String? retailerAddress;
  final String? paymentMode;
  final double? subtotal;
  final double? deliveryFee;
  final double? discountAmount;
  final String? specialInstructions;
  final String? cancellationReason;
  final String? deliveryAddressText;
  final String? customerPhone;
  final String? customerEmail;
  final List<OrderItem>? items;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String? updatedAt;
  final String? confirmedAt;
  final String? deliveredAt;
  final String? cancelledAt;
  // Loyalty fields
  final double? pointsRedeemed;
  final double? discountFromPoints;
  final int unreadChatCount;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    required this.customer,
    required this.customerName,
    required this.createdAt,
    required this.deliveryMode,
    required this.retailerName,
    this.retailerPhone,
    this.retailerAddress,
    this.paymentMode,
    this.subtotal,
    this.deliveryFee,
    this.discountAmount,
    this.specialInstructions,
    this.cancellationReason,
    this.deliveryAddressText,
    this.customerPhone,
    this.customerEmail,
    this.items,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.updatedAt,
    this.confirmedAt,
    this.deliveredAt,
    this.cancelledAt,
    this.pointsRedeemed,
    this.discountFromPoints,
    this.unreadChatCount = 0,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? 0,
      orderNumber: json['order_number'] ?? '',
      status: json['status'] ?? 'pending',
      totalAmount: double.parse(json['total_amount']?.toString() ?? '0'),
      customer: json['customer'] ?? 0,
      customerName: json['customer_name'] ?? 'Guest',
      createdAt: json['created_at'] ?? '',
      deliveryMode: json['delivery_mode'] ?? 'delivery',
      retailerName: json['retailer_name'] ?? '',
      retailerPhone: json['retailer_phone'],
      retailerAddress: json['retailer_address'],
      paymentMode: json['payment_mode'],
      subtotal: json['subtotal'] != null
          ? double.parse(json['subtotal'].toString())
          : null,
      deliveryFee: json['delivery_fee'] != null
          ? double.parse(json['delivery_fee'].toString())
          : null,
      discountAmount: json['discount_amount'] != null
          ? double.parse(json['discount_amount'].toString())
          : null,
      specialInstructions: json['special_instructions'],
      cancellationReason: json['cancellation_reason'],
      deliveryAddressText: json['delivery_address_text'],
      customerPhone: json['customer_phone'],
      customerEmail: json['customer_email'],
      items: json['items'] != null
          ? (json['items'] as List).map((i) => OrderItem.fromJson(i)).toList()
          : null,
      deliveryLatitude: json['delivery_latitude'] != null
          ? double.parse(json['delivery_latitude'].toString())
          : null,
      deliveryLongitude: json['delivery_longitude'] != null
          ? double.parse(json['delivery_longitude'].toString())
          : null,
      updatedAt: json['updated_at'],
      confirmedAt: json['confirmed_at'],
      deliveredAt: json['delivered_at'],
      cancelledAt: json['cancelled_at'],
      pointsRedeemed: json['points_redeemed'] != null
          ? double.tryParse(json['points_redeemed'].toString())
          : null,
      discountFromPoints: json['discount_from_points'] != null
          ? double.tryParse(json['discount_from_points'].toString())
          : null,
      unreadChatCount: json['unread_chat_count'] ?? 0,
    );
  }
}
