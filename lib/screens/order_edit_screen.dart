import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../services/reward_service.dart';
import '../models/reward_configuration.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class OrderEditScreen extends StatefulWidget {
  final OrderModel order;

  const OrderEditScreen({super.key, required this.order});

  @override
  _OrderEditScreenState createState() => _OrderEditScreenState();
}

class _OrderEditScreenState extends State<OrderEditScreen> {
  late List<OrderItem> _items;
  late String _deliveryMode;
  late TextEditingController _discountController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  RewardConfiguration? _rewardConfig;

  // Track changes
  final Map<int, int> _quantityChanges = {};
  final Map<int, double> _priceChanges = {};

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.order.items ?? []);
    _deliveryMode = widget.order.deliveryMode;
    _discountController = TextEditingController(
      text: widget.order.discountAmount?.toString() ?? '0',
    );
    // Initialize trackers
    for (var item in _items) {
      _quantityChanges[item.id] = item.quantity;
      _priceChanges[item.id] = item.unitPrice;
    }
    _discountController.addListener(() {
      if (mounted) setState(() {});
    });
    _fetchRewardConfig();
  }

  Future<void> _fetchRewardConfig() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.token != null) {
        final config = await RewardService().getRewardConfiguration(
          authProvider.token!,
        );
        if (mounted) {
          setState(() {
            _rewardConfig = config;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching reward config: $e');
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _submitChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final orderService = OrderService();

      List<Map<String, dynamic>> itemsPayload = [];

      for (var item in _items) {
        int newQty = _quantityChanges[item.id]!;
        double newPrice = _priceChanges[item.id]!;

        // Sending all with current values
        itemsPayload.add({
          'id': item.id,
          'quantity': newQty,
          'unit_price': newPrice,
        });
      }

      await orderService.modifyOrder(
        authProvider.token!,
        widget.order.id,
        itemsPayload,
        _deliveryMode != widget.order.deliveryMode ? _deliveryMode : null,
        double.tryParse(_discountController.text),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order updated successfully')),
      );
      Navigator.pop(context, true); // Return true to refresh
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating order: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Order #${widget.order.orderNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _submitChanges,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDeliveryModeSection(),
                  const SizedBox(height: 16),
                  _buildDiscountSection(),
                  const Divider(height: 32),
                  const Text(
                    'Order Items',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ..._items.map((item) => _buildItemCard(item)),
                  const Divider(height: 32),
                  _buildSummarySection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSummarySection() {
    double subtotal = 0;
    for (var item in _items) {
      int qty = _quantityChanges[item.id] ?? 0;
      double price = _priceChanges[item.id] ?? 0;
      subtotal += qty * price;
    }

    double deliveryFee = _deliveryMode == 'delivery' ? 50 : 0;
    double discount = double.tryParse(_discountController.text) ?? 0;

    // Total before points is what we used for limits in backend
    double totalBeforePoints = subtotal + deliveryFee - discount;
    if (totalBeforePoints < 0) totalBeforePoints = 0;

    double pointsRefundValue = 0;
    double currentPointsValue = 0;

    // Calculate potential refund
    if (_rewardConfig != null &&
        widget.order.pointsRedeemed != null &&
        widget.order.pointsRedeemed! > 0) {
      currentPointsValue =
          widget.order.pointsRedeemed! * _rewardConfig!.conversionRate;

      double maxByPercent =
          (totalBeforePoints * _rewardConfig!.maxRewardUsagePercent) / 100;
      double maxByFlat = _rewardConfig!.maxRewardUsageFlat;

      double redeemableAmount = currentPointsValue;
      if (redeemableAmount > maxByPercent) redeemableAmount = maxByPercent;
      if (redeemableAmount > maxByFlat) redeemableAmount = maxByFlat;
      if (redeemableAmount > totalBeforePoints) {
        redeemableAmount = totalBeforePoints;
      }

      if (redeemableAmount < currentPointsValue) {
        pointsRefundValue = currentPointsValue - redeemableAmount;
      }
    }

    // Final total calculation:
    // Backend logic: order.total_amount = total_before_points - redeemable_amount
    // Here we can just subtract the adjusted points value
    double finalPointsDiscount = currentPointsValue - pointsRefundValue;
    double total = totalBeforePoints - finalPointsDiscount;
    if (total < 0) total = 0;

    return Card(
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary (Preview)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _summaryRow('Subtotal', subtotal),
            _summaryRow('Delivery Fee', deliveryFee),
            _summaryRow('Additional Discount', -discount, color: Colors.green),
            if (widget.order.pointsRedeemed != null &&
                widget.order.pointsRedeemed! > 0)
              _summaryRow(
                'Points Discount',
                -finalPointsDiscount,
                color: Colors.green,
              ),

            const Divider(),
            _summaryRow('Total Amount', total, isBold: true),

            if (pointsRefundValue > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Points worth ₹${pointsRefundValue.toStringAsFixed(2)} will be refunded to customer.',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    double amount, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₹${amount.abs().toStringAsFixed(2)}', // Use abs for display if desired, or let negative sign show
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryModeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Mode',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        DropdownButtonFormField<String>(
          initialValue: _deliveryMode,
          items: const [
            DropdownMenuItem(value: 'delivery', child: Text('Delivery')),
            DropdownMenuItem(value: 'pickup', child: Text('Pickup')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _deliveryMode = val);
          },
        ),
      ],
    );
  }

  Widget _buildDiscountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Discount',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        TextFormField(
          controller: _discountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            prefixText: '₹ ',
            helperText: 'Enter total discount amount for this order',
          ),
          validator: (val) {
            if (val == null || val.isEmpty) return 'Enter discount';
            if (double.tryParse(val) == null) return 'Invalid number';
            if (double.parse(val) < 0) return 'Cannot be negative';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildItemCard(OrderItem item) {
    int qty = _quantityChanges[item.id] ?? item.quantity;
    double price = _priceChanges[item.id] ?? item.unitPrice;

    // If quantity is 0, show differently?
    if (qty == 0) {
      return Card(
        color: Colors.red.shade50,
        child: ListTile(
          title: Text(
            item.productName,
            style: const TextStyle(decoration: TextDecoration.lineThrough),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () {
              setState(() {
                _quantityChanges[item.id] = 1; // Restore to 1 or original?
                // Better: Restore to original item quantity? Or just 1.
                _quantityChanges[item.id] = item.quantity > 0
                    ? item.quantity
                    : 1;
              });
            },
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.productImage != null)
                  Image.network(
                    item.productImage!.startsWith('http')
                        ? item.productImage!
                        : '${ApiConstants.serverUrl}${item.productImage!}',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image, size: 60),
                  )
                else
                  const Icon(Icons.image, size: 60),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(item.productUnit),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // Quantity Control
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        setState(() {
                          if (qty > 0) _quantityChanges[item.id] = qty - 1;
                        });
                      },
                    ),
                    Text('$qty', style: const TextStyle(fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        setState(() {
                          _quantityChanges[item.id] = qty + 1;
                        });
                      },
                    ),
                  ],
                ),
                const Spacer(),
                // Price Control
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    initialValue: price.toString(),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Unit Price',
                      prefixText: '₹',
                      isDense: true,
                      contentPadding: EdgeInsets.all(8),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      final p = double.tryParse(val);
                      if (p != null) {
                        setState(() {
                          _priceChanges[item.id] = p;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
