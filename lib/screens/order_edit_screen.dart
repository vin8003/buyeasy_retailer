import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../services/reward_service.dart';
import '../models/reward_configuration.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../utils/constants.dart';
import 'product_selection_screen.dart';
import 'package:collection/collection.dart';

class OrderEditScreen extends StatefulWidget {
  final OrderModel order;

  const OrderEditScreen({super.key, required this.order});

  @override
  _OrderEditScreenState createState() => _OrderEditScreenState();
}

class EditableOrderItem {
  final int? id; // null for new items
  final int productId;
  final String productName;
  final String? productImage;
  final String productUnit;
  int quantity;
  double unitPrice;

  EditableOrderItem({
    this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.productUnit,
    required this.quantity,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'quantity': quantity,
      'unit_price': unitPrice,
    };
    if (id != null) {
      map['id'] = id;
    } else {
      map['product'] = productId;
    }
    return map;
  }
}

class _OrderEditScreenState extends State<OrderEditScreen> {
  late List<EditableOrderItem> _items;
  late String _deliveryMode;
  late TextEditingController _discountController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  RewardConfiguration? _rewardConfig;

  @override
  void initState() {
    super.initState();
    _items = (widget.order.items ?? [])
        .map(
          (item) => EditableOrderItem(
            id: item.id,
            productId: item.productId,
            productName: item.productName,
            productImage: item.productImage,
            productUnit: item.productUnit,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
          ),
        )
        .toList();

    _deliveryMode = widget.order.deliveryMode;
    _discountController = TextEditingController(
      text: widget.order.discountAmount?.toString() ?? '0',
    );
    _discountController.addListener(() {
      if (mounted) setState(() {});
    });
    _fetchRewardConfig();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      context.read<ProductProvider>().fetchProducts(token);
    }
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

      List<Map<String, dynamic>> itemsPayload = _items
          .map((e) => e.toJson())
          .toList();

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
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating order: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                        onPressed: _showProductPicker,
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

  void _showProductPicker() {
    final productProvider = context.read<ProductProvider>();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Product'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: productProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : productProvider.products.isEmpty
                ? const Center(child: Text('No products available'))
                : ListView.builder(
                    itemCount: productProvider.products.length,
                    itemBuilder: (context, index) {
                      final product = productProvider.products[index];
                      return ListTile(
                        leading: product.image != null
                            ? CachedNetworkImage(
                                imageUrl:
                                    '${ApiConstants.serverUrl}${product.image}',
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.image),
                        title: Text(product.name),
                        subtitle: Text('₹${product.price} / ${product.unit}'),
                        onTap: () {
                          setState(() {
                            // Check if already added
                            final existing = _items
                                .where((i) => i.productId == product.id)
                                .firstOrNull;
                            if (existing != null) {
                              existing.quantity += 1;
                            } else {
                              _items.add(
                                EditableOrderItem(
                                  productId: product.id,
                                  productName: product.name,
                                  productImage: product.image,
                                  productUnit: product.unit,
                                  quantity: 1,
                                  unitPrice: product.price,
                                ),
                              );
                            }
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummarySection() {
    double subtotal = 0;
    for (var item in _items) {
      subtotal += item.quantity * item.unitPrice;
    }

    double deliveryFee = _deliveryMode == 'delivery' ? 50 : 0;
    double discount = double.tryParse(_discountController.text) ?? 0;

    double totalBeforePoints = subtotal + deliveryFee - discount;
    if (totalBeforePoints < 0) totalBeforePoints = 0;

    double pointsRefundValue = 0;
    double currentPointsValue = 0;

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
            '₹${amount.abs().toStringAsFixed(2)}',
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
          value: _deliveryMode,
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

  Widget _buildItemCard(EditableOrderItem item) {
    if (item.quantity == 0) {
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
            onPressed: () => setState(() => item.quantity = 1),
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
              children: [
                if (item.productImage != null)
                  CachedNetworkImage(
                    imageUrl: item.productImage!.startsWith('http')
                        ? item.productImage!
                        : '${ApiConstants.serverUrl}${item.productImage!}',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
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
                  onPressed: () {
                    setState(() {
                      if (item.id == null) {
                        _items.remove(item);
                      } else {
                        item.quantity = 0;
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => setState(() {
                        if (item.quantity > 0) item.quantity--;
                      }),
                    ),
                    Text(
                      '${item.quantity}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => setState(() => item.quantity++),
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    initialValue: item.unitPrice.toString(),
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
                      if (p != null) setState(() => item.unitPrice = p);
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
