import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import 'package:intl/intl.dart';
import 'order_edit_screen.dart';
import '../utils/constants.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final TextEditingController _cancelReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDetails();
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
                    _buildStatusSection(order, provider),
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
                            child: Image.network(
                              item.productImage!.startsWith('http')
                                  ? item.productImage!
                                  : '${ApiConstants.serverUrl}${item.productImage!}',
                              fit: BoxFit.cover,
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
    if (order.status == 'pending')
      nextStatuses = ['confirmed'];
    else if (order.status == 'confirmed')
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

    if (nextStatuses.isEmpty)
      return const Text('No status transitions available.');

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
}
