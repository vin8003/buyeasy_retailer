import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../services/notification_service.dart';
import 'order_edit_screen.dart';
import '../utils/constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'order_chat_screen.dart';
import '../services/api_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final TextEditingController _cancelReasonController = TextEditingController();
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDetails();
    });
    _listenForNotifications();
  }

  void _listenForNotifications() {
    _notificationSubscription = NotificationService().updateStream.listen((
      data,
    ) {
      bool shouldRefresh = false;
      if (data['event'] == 'order_refresh' &&
          data['order_id'] == widget.orderId.toString()) {
        shouldRefresh = true;
      }
      if (data['type'] == 'order_chat' &&
          data['order_id'] == widget.orderId.toString()) {
        shouldRefresh = true;
      }

      if (shouldRefresh) {
        _fetchDetails();
      }
    });
  }

  void _fetchDetails() {
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      context.read<OrderProvider>().fetchOrderDetails(token, widget.orderId);
    }
  }

  @override
  void dispose() {
    _cancelReasonController.dispose();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final order = orderProvider.selectedOrder;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          order != null ? 'Order #${order.orderNumber}' : 'Order Details',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            orderProvider.clearSelectedOrder();
            Navigator.pop(context);
          },
        ),
        actions: [],
      ),
      body: orderProvider.isLoading && order == null
          ? const Center(child: CircularProgressIndicator())
          : orderProvider.error != null && order == null
          ? Center(child: Text('Error: ${orderProvider.error}'))
          : order == null
          ? const Center(child: Text('Order not found'))
          : _buildContent(order, orderProvider),
    );
  }

  Widget _buildContent(OrderModel order, OrderProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(order),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildItemsList(order),
                    const SizedBox(height: 24),
                    _buildOrderSummary(order),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildChatCta(order),
                    const SizedBox(height: 24),
                    _buildStatusSection(order, provider),
                    const SizedBox(height: 24),
                    _buildRatingSection(order),
                    const SizedBox(height: 24),
                    _buildCustomerSection(order),
                    const SizedBox(height: 24),
                    _buildTimelineSection(order),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(OrderModel order) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order #${order.orderNumber}',
                style: Theme.of(context).textTheme.headlineMedium,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Placed on ${DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(order.createdAt))}',
                style: const TextStyle(color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _buildStatusBadge(order.status),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildItemsList(OrderModel order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items?.length ?? 0,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = order.items![index];
                return ListTile(
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: item.productImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: ApiService().formatImageUrl(
                                item.productImage,
                              ),
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  Container(color: Colors.grey[200]),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.broken_image),
                            ),
                          )
                        : const Icon(Icons.shopping_bag, color: Colors.grey),
                  ),
                  title: Text(item.productName),
                  subtitle: Text(
                    'Quantity: ${item.quantity} ${item.productUnit}',
                  ),
                  trailing: Text(
                    '₹${item.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(OrderModel order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildSummaryRow(
              'Subtotal',
              '₹${order.subtotal?.toStringAsFixed(2) ?? '0.00'}',
            ),
            _buildSummaryRow(
              'Delivery Fee',
              '₹${order.deliveryFee?.toStringAsFixed(2) ?? '0.00'}',
            ),
            if (order.discountAmount != null && order.discountAmount! > 0)
              _buildSummaryRow(
                'Discount',
                '-₹${order.discountAmount?.toStringAsFixed(2)}',
                color: Colors.green,
              ),
            if (order.discountFromPoints != null &&
                order.discountFromPoints! > 0)
              _buildSummaryRow(
                'Points Discount',
                '-₹${order.discountFromPoints?.toStringAsFixed(2)}',
                color: Colors.green,
              ),
            if (order.pointsRedeemed != null && order.pointsRedeemed! > 0)
              _buildSummaryRow(
                'Points Redeemed',
                '${order.pointsRedeemed!.toInt()} pts',
                fontSize: 12,
                color: Colors.orange,
              ),
            const Divider(),
            _buildSummaryRow(
              'Total Amount',
              '₹${order.totalAmount.toStringAsFixed(2)}',
              isBold: true,
              fontSize: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 14,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize)),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(OrderModel order, OrderProvider provider) {
    final token = context.read<AuthProvider>().token;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage Order',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const Text('Update Status:', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            _buildStatusButtons(order, provider, token),
            if (order.status != 'cancelled' && order.status != 'delivered') ...[
              const Divider(),
              const Divider(),
              if (order.status == 'pending') ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderEditScreen(order: order),
                        ),
                      );
                      if (result == true) {
                        provider.fetchOrderDetails(token!, order.id);
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Order Details'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _showCancelDialog(order, provider, token),
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text(
                    'Cancel Order',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButtons(
    OrderModel order,
    OrderProvider provider,
    String? token,
  ) {
    if (order.status == 'cancelled' || order.status == 'delivered') {
      return Text(
        'This order is ${order.status}. No further actions.',
        style: const TextStyle(fontStyle: FontStyle.italic),
      );
    }

    List<String> nextStatuses = [];
    if (order.status == 'pending') {
      nextStatuses = ['confirmed'];
    } else if (order.status == 'confirmed')
      nextStatuses = ['processing', 'packed'];
    else if (order.status == 'processing')
      nextStatuses = ['packed'];
    else if (order.status == 'packed') {
      if (order.deliveryMode == 'pickup') {
        nextStatuses = ['delivered'];
      } else {
        nextStatuses = ['out_for_delivery'];
      }
    } else if (order.status == 'out_for_delivery') {
      nextStatuses = ['delivered'];
    }

    if (nextStatuses.isEmpty) {
      return const Text('No status transitions available.');
    }

    return Wrap(
      spacing: 8,
      children: nextStatuses.map((status) {
        String label = status.toUpperCase();
        if (order.deliveryMode == 'pickup') {
          if (status == 'packed') label = 'READY FOR PICKUP';
          if (status == 'delivered') label = 'MARK AS PICKED UP';
        }

        return ElevatedButton(
          onPressed: token != null
              ? () => provider.updateStatus(token, order.id, status)
              : null,
          child: Text(label),
        );
      }).toList(),
    );
  }

  Widget _buildCustomerSection(OrderModel order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(order.customerName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Verified Customer'),
                  if (order.customerPhone != null)
                    Text('Phone: ${order.customerPhone}'),
                  if (order.customerEmail != null)
                    Text('Email: ${order.customerEmail}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Delivery Address:',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(order.deliveryAddressText ?? 'No address provided'),
            if (order.specialInstructions != null &&
                order.specialInstructions!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Special Instructions:',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(order.specialInstructions!),
            ],
            if (order.deliveryLatitude != null &&
                order.deliveryLongitude != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Delivery Location:',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        order.deliveryLatitude!,
                        order.deliveryLongitude!,
                      ),
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('delivery_loc'),
                        position: LatLng(
                          order.deliveryLatitude!,
                          order.deliveryLongitude!,
                        ),
                        infoWindow: InfoWindow(title: order.customerName),
                      ),
                    },
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    scrollGesturesEnabled: false,
                    zoomGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    rotateGesturesEnabled: false,
                    mapToolbarEnabled: true,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection(OrderModel order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Timeline',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildTimelineItem('Placed', order.createdAt, isFirst: true),
            if (order.confirmedAt != null)
              _buildTimelineItem('Confirmed', order.confirmedAt!),
            if (order.deliveredAt != null)
              _buildTimelineItem(
                order.deliveryMode == 'pickup' ? 'Picked Up' : 'Delivered',
                order.deliveredAt!,
              ),
            if (order.cancelledAt != null)
              _buildTimelineItem(
                'Cancelled',
                order.cancelledAt!,
                color: Colors.red,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    String label,
    String date, {
    bool isFirst = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: color ?? Colors.blue),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(
            DateFormat('MMM dd, hh:mm a').format(DateTime.parse(date)),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(
    OrderModel order,
    OrderProvider provider,
    String? token,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for cancellation:'),
            const SizedBox(height: 12),
            TextField(
              controller: _cancelReasonController,
              decoration: const InputDecoration(
                hintText: 'e.g., Row out of stock, shop closed',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (token != null && _cancelReasonController.text.isNotEmpty) {
                provider.cancelOrder(
                  token,
                  order.id,
                  _cancelReasonController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Cancel Order',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'waiting_for_customer_approval':
        return Colors.purple;
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.indigo;
      case 'packed':
        return Colors.teal;
      case 'out_for_delivery':
        return Colors.deepPurple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'returned':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRatingSection(OrderModel order) {
    if (order.status != 'delivered' && order.status != 'cancelled') {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Rating',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            if (order.hasRetailerRating)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You have rated this customer.',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showRatingDialog(order),
                  icon: const Icon(Icons.star),
                  label: const Text('Rate Customer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showRatingDialog(OrderModel order) {
    int rating = 0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Rate Customer'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Rate your experience with this customer.'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < rating
                                ? Icons.star_rate_rounded
                                : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 36,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              rating = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                    // Explicit option for 0 stars / Blacklist
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Mark as Bad/Blacklist (0 Stars)"),
                      leading: Radio<int>(
                        value: 0,
                        groupValue: rating,
                        onChanged: (val) => setDialogState(() => rating = 0),
                      ),
                      onTap: () => setDialogState(() => rating = 0),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Rate Stars (1-5)"),
                      leading: Radio<int>(
                        value: 1, // Represents "Using stars"
                        groupValue: rating > 0
                            ? 1
                            : 0, // if rating > 0, select this group.
                        onChanged: (val) => setDialogState(() => rating = 1),
                      ),
                      onTap: () => setDialogState(() => rating = 1),
                    ),

                    if (rating == 0)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Warning: A 0-star rating will automatically BLACKLIST this customer.',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: commentController,
                      decoration: const InputDecoration(
                        hintText: 'Add a comment (required for blacklist)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (rating == 0 && commentController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reason required for 0-star rating'),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    await _submitRating(
                      order.id,
                      rating,
                      commentController.text,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: rating == 0 ? Colors.red : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(rating == 0 ? 'Blacklist & Rate' : 'Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitRating(int orderId, int rating, String comment) async {
    try {
      final response = await ApiService().createRetailerRating(
        orderId,
        rating,
        comment,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rating submitted successfully')),
        );
        _fetchDetails();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to submit rating: $e')));
    }
  }

  Widget _buildChatCta(OrderModel order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderChatScreen(
                orderId: order.id,
                orderNumber: order.orderNumber,
              ),
            ),
          );
          _fetchDetails();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.support_agent, color: Colors.teal),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Support',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chat with Customer',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (order.unreadMessagesCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${order.unreadMessagesCount} new',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
