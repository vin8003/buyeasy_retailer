import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../services/reward_service.dart';
import '../models/reward_configuration.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import 'product_selection_screen.dart';

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
    // Initialize trackers for existing items
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
        // Skip items that are marked for removal (quantity 0) IF they are new items.
        // For existing items (id > 0), simple quantity=0 update deletes them on backend.
        // For new items (id < 0), if quantity is 0, just don't send them.

        int qty = _quantityChanges[item.id] ?? item.quantity;
        double price = _priceChanges[item.id] ?? item.unitPrice;

        if (item.id < 0 && qty == 0) continue;

        if (item.id < 0) {
          // New item
          itemsPayload.add({
            'product_id': item.productId,
            'quantity': qty,
            // 'unit_price': price, // Price for new items usually taken from product, but if we want to support custom price for new items, backend needs update. For now serializer uses product.price but we can override if backend supports it. Checked serializer: it uses product.price. Adding unit_price support would be next step.
          });
        } else {
          // Existing item
          itemsPayload.add({
            'id': item.id,
            'quantity': qty,
            'unit_price': price,
          });
        }
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

  Future<void> _addProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProductSelectionScreen()),
    );

    if (result != null) {
      // Create a temporary OrderItem
      // Use negative ID to mark as new/local
      // Ensure unique negative ID
      int tempId = -1;
      while (_items.any((item) => item.id == tempId)) {
        tempId--;
      }

      final product = result; // Is Product object

      final newItem = OrderItem(
        id: tempId,
        productId: product.id,
        productName: product.name,
        productImage: product.image,
        productPrice: product.price,
        productUnit: product.unit,
        quantity: 1, // Default to 1
        unitPrice: product.price,
        totalPrice: product.price,
      );

      setState(() {
        _items.add(newItem);
        _quantityChanges[tempId] = 1;
        _priceChanges[tempId] = product.price;
      });
    }
  }

  void _removeItem(int itemId) {
    setState(() {
      // If it's a new item (id < 0), remove from list completely
      if (itemId < 0) {
        _items.removeWhere((item) => item.id == itemId);
        _quantityChanges.remove(itemId);
        _priceChanges.remove(itemId);
      } else {
        // Existing item: set quantity to 0 to mark for deletion
        _quantityChanges[itemId] = 0;
      }
    });
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Order Items',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addProduct,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Product'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._items.map((item) {
                    // Hide if marked for deletion (quantity 0)?
                    // Or show in red? Let's show in red or distinct style.
                    // Actually logic in _buildItemCard handles 0 quantity.
                    return _buildItemCard(item);
                  }).toList(), // .toList() needed if map returns Iterable
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
          value:
              _deliveryMode, // Fix: Use value instead of initialValue for dynamic updates if needed, though here state drives it.
          // initialValue: _deliveryMode,
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
    bool isNew = item.id < 0;

    // If quantity is 0, show differently
    if (qty == 0) {
      return Card(
        color: Colors.red.shade50,
        child: ListTile(
          title: Text(
            item.productName,
            style: const TextStyle(decoration: TextDecoration.lineThrough),
          ),
          subtitle: const Text('Marked for removal'),
          trailing: IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () {
              setState(() {
                // Restore to original quantity if existing, or 1 if new
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
      color: isNew ? Colors.green.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            if (isNew)
              Container(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.productImage != null)
                  CachedNetworkImage(
                    imageUrl: item.productImage!.startsWith('http')
                        ? item.productImage!
                        : '${ApiConstants.serverUrl}${item.productImage!}',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: Colors.grey[200]),
                    errorWidget: (context, url, error) =>
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
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeItem(item.id),
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
                          if (qty > 1) {
                            // Don't go to 0 here, use delete button
                            _quantityChanges[item.id] = qty - 1;
                          }
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
                // Disable price edit for new items if backend doesn't support it yet
                // Or allow it if we think we can send it (currently backend serializer ignores unit_price for new items)
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
                    enabled:
                        !isNew, // Disable for new items for now as per serializer analysis
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
