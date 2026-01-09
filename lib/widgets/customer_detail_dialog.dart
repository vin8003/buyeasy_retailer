import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/retailer_customer.dart';

class CustomerDetailDialog extends StatefulWidget {
  final int customerId;
  final VoidCallback onUpdate;

  const CustomerDetailDialog({
    super.key,
    required this.customerId,
    required this.onUpdate,
  });

  @override
  State<CustomerDetailDialog> createState() => _CustomerDetailDialogState();
}

class _CustomerDetailDialogState extends State<CustomerDetailDialog> {
  final ApiService _apiService = ApiService();
  RetailerCustomerDetail? _customer;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await _apiService.getRetailerCustomerDetail(
        widget.customerId,
      );
      if (response.statusCode == 200) {
        setState(() {
          _customer = RetailerCustomerDetail.fromJson(response.data);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load details');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBlacklist() async {
    if (_customer == null) return;
    final isBlacklisted = _customer!.isBlacklisted;
    final action = isBlacklisted ? 'unblacklist' : 'blacklist';

    // Show confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isBlacklisted ? 'Remove from Blacklist?' : 'Blacklist Customer?',
        ),
        content: Text(
          isBlacklisted
              ? 'This customer will be able to place orders again.'
              : 'This customer will be blocked from placing orders at your shop.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              isBlacklisted ? 'Unblacklist' : 'Blacklist',
              style: TextStyle(
                color: isBlacklisted ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await _apiService.toggleRetailerBlacklist(
        widget.customerId,
        action,
        reason: isBlacklisted
            ? 'Manual removal'
            : 'Manual blacklist by retailer',
      );

      if (response.statusCode == 200) {
        _fetchDetails(); // Refresh local view
        widget.onUpdate(); // Refresh parent list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['message'] ?? 'Success')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 800),
        child: _isLoading
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            : _error != null
            ? SizedBox(
                height: 200,
                child: Center(child: Text('Error: $_error')),
              )
            : Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: _customer!.profileImage != null
                              ? NetworkImage(
                                  _apiService.formatImageUrl(
                                    _customer!.profileImage,
                                  ),
                                )
                              : null,
                          child: _customer!.profileImage == null
                              ? Text(
                                  _customer!.customerName[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 24),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _customer!.customerName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _customer!.phoneNumber ??
                                  _customer!.email ??
                                  'No contact info',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _customer!.isBlacklisted
                                ? Colors.red[50]
                                : Colors.green[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _customer!.isBlacklisted
                                  ? Colors.red[200]!
                                  : Colors.green[200]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _customer!.isBlacklisted
                                    ? Icons.block
                                    : Icons.check_circle,
                                size: 16,
                                color: _customer!.isBlacklisted
                                    ? Colors.red
                                    : Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _customer!.isBlacklisted
                                    ? 'Blacklisted'
                                    : 'Active Customer',
                                style: TextStyle(
                                  color: _customer!.isBlacklisted
                                      ? Colors.red[700]
                                      : Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Body
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Panel: Stats & Info
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            color: Colors.grey[50],
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(
                                  'Total Spent',
                                  '₹${_customer!.totalSpent.toStringAsFixed(0)}',
                                  Icons.payments,
                                ),
                                _buildDetailRow(
                                  'Total Orders',
                                  '${_customer!.totalOrders}',
                                  Icons.shopping_bag,
                                ),
                                _buildDetailRow(
                                  'Points Balance',
                                  '${_customer!.points.toStringAsFixed(2)}',
                                  Icons.loyalty,
                                ),
                                _buildDetailRow(
                                  'Avg Rating',
                                  _customer!.averageRating.toStringAsFixed(1),
                                  Icons.star,
                                ),
                                _buildDetailRow(
                                  'Joined',
                                  _customer!.joinedDate != null
                                      ? DateFormat(
                                          'MMM yyyy',
                                        ).format(_customer!.joinedDate!)
                                      : '-',
                                  Icons.calendar_today,
                                ),

                                const Spacer(),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _toggleBlacklist,
                                    icon: Icon(
                                      _customer!.isBlacklisted
                                          ? Icons.check
                                          : Icons.block,
                                    ),
                                    label: Text(
                                      _customer!.isBlacklisted
                                          ? 'Unblacklist Customer'
                                          : 'Blacklist Customer',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _customer!.isBlacklisted
                                          ? Colors.green
                                          : Colors.red,
                                      side: BorderSide(
                                        color: _customer!.isBlacklisted
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const VerticalDivider(width: 1),

                        // Right Panel: Recent Orders & Activity
                        Expanded(
                          flex: 2,
                          child: DefaultTabController(
                            length: 2,
                            child: Column(
                              children: [
                                const TabBar(
                                  tabs: [
                                    Tab(text: 'Order History'),
                                    Tab(text: 'Reward History'),
                                  ],
                                ),
                                Expanded(
                                  child: TabBarView(
                                    children: [
                                      // Orders List
                                      _customer!.recentOrders.isEmpty
                                          ? const Center(
                                              child: Text('No orders yet'),
                                            )
                                          : ListView.builder(
                                              padding: const EdgeInsets.all(16),
                                              itemCount: _customer!
                                                  .recentOrders
                                                  .length,
                                              itemBuilder: (context, index) {
                                                final order = _customer!
                                                    .recentOrders[index];
                                                return Card(
                                                  margin: const EdgeInsets.only(
                                                    bottom: 12,
                                                  ),
                                                  elevation: 1,
                                                  child: ListTile(
                                                    title: Text(
                                                      'Order #${order['order_number']}',
                                                    ),
                                                    subtitle: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          DateFormat(
                                                            'MMM dd, yyyy HH:mm',
                                                          ).format(
                                                            DateTime.parse(
                                                              order['created_at'],
                                                            ),
                                                          ),
                                                        ),
                                                        if (order['my_rating'] !=
                                                            null)
                                                          Row(
                                                            children: [
                                                              const Icon(
                                                                Icons.star,
                                                                size: 14,
                                                                color: Colors
                                                                    .amber,
                                                              ),
                                                              Text(
                                                                ' You rated: ${order['my_rating']}',
                                                                style: const TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .grey,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                      ],
                                                    ),
                                                    trailing: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .end,
                                                          children: [
                                                            Text(
                                                              '₹${order['total_amount']}',
                                                              style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            Text(
                                                              order['status'],
                                                              style: TextStyle(
                                                                color: _getStatusColor(
                                                                  order['status'],
                                                                ),
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        if (order['status']
                                                                    .toLowerCase() ==
                                                                'delivered' &&
                                                            order['my_rating'] ==
                                                                null)
                                                          TextButton(
                                                            onPressed: () =>
                                                                _showRatingDialog(
                                                                  order['id'],
                                                                ),
                                                            child: const Text(
                                                              'Rate',
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),

                                      // Rewards List
                                      _customer!.rewardHistory.isEmpty
                                          ? const Center(
                                              child: Text('No reward history'),
                                            )
                                          : ListView.builder(
                                              padding: const EdgeInsets.all(16),
                                              itemCount: _customer!
                                                  .rewardHistory
                                                  .length,
                                              itemBuilder: (context, index) {
                                                final reward = _customer!
                                                    .rewardHistory[index];
                                                return ListTile(
                                                  leading: const Icon(
                                                    Icons.stars,
                                                    color: Colors.orange,
                                                  ),
                                                  title: Text(
                                                    '${reward['type'] == 'earned' ? '+' : '-'}${reward['points']} Points',
                                                  ),
                                                  subtitle: Text(
                                                    'Order: ${reward['order_number'] ?? '-'}',
                                                  ),
                                                  trailing: Text(
                                                    DateFormat('MMM dd').format(
                                                      DateTime.parse(
                                                        reward['date'],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.grey[700]),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showRatingDialog(int orderId) async {
    int rating = 5;
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rate Customer'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star,
                      color: index < rating ? Colors.amber : Colors.grey[300],
                      size: 32,
                    ),
                    onPressed: () => setState(() => rating = index + 1),
                  );
                }),
              ),
              TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'Optional comment'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _submitRating(orderId, rating, controller.text);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRating(int orderId, int rating, String comment) async {
    try {
      final response = await _apiService.rateCustomer(
        orderId,
        rating,
        comment: comment,
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        _fetchDetails();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Rating submitted')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
