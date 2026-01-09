import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/retailer_customer.dart';
import '../widgets/customer_detail_dialog.dart';

class RetailerCustomerListScreen extends StatefulWidget {
  const RetailerCustomerListScreen({super.key});

  @override
  State<RetailerCustomerListScreen> createState() =>
      _RetailerCustomerListScreenState();
}

class _RetailerCustomerListScreenState
    extends State<RetailerCustomerListScreen> {
  final ApiService _apiService = ApiService();
  List<RetailerCustomer> _customers = [];
  List<RetailerCustomer> _filteredCustomers = [];
  bool _isLoading = true;
  String? _error;

  String _searchQuery = '';
  String _filterBlacklist = 'All'; // All, Active, Blacklisted
  String _sortBy = 'Joined Date';

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getRetailerCustomers();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        setState(() {
          _customers = data
              .map((json) => RetailerCustomer.fromJson(json))
              .toList();
          _filterCustomers();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load customers');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterCustomers() {
    _filteredCustomers = _customers.where((customer) {
      // 1. Search
      final query = _searchQuery.toLowerCase();
      final matchesSearch =
          customer.customerName.toLowerCase().contains(query) ||
          (customer.phoneNumber?.contains(query) ?? false) ||
          customer.customerId.toString().contains(query);

      // 2. Blacklist Filter
      bool matchesFilter = true;
      if (_filterBlacklist == 'Active') {
        matchesFilter = !customer.isBlacklisted;
      } else if (_filterBlacklist == 'Blacklisted') {
        matchesFilter = customer.isBlacklisted;
      }

      return matchesSearch && matchesFilter;
    }).toList();

    // 3. Sort
    _filteredCustomers.sort((a, b) {
      switch (_sortBy) {
        case 'Most Orders':
          return b.totalOrders.compareTo(a.totalOrders);
        case 'Highest Spent':
          return b.totalSpent.compareTo(a.totalSpent);
        case 'Lowest Rating':
          return a.averageRating.compareTo(b.averageRating);
        case 'Recent Activity':
          // Use lastOrderDate or joinedDate as fallback
          final dateA = a.lastOrderDate ?? a.joinedDate ?? DateTime(2000);
          final dateB = b.lastOrderDate ?? b.joinedDate ?? DateTime(2000);
          return dateB.compareTo(dateA);
        case 'Joined Date':
        default:
          final dateA = a.joinedDate ?? DateTime(2000);
          final dateB = b.joinedDate ?? DateTime(2000);
          return dateB.compareTo(dateA);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Analytics
    final totalCustomers = _customers.length;
    final totalBlacklisted = _customers.where((c) => c.isBlacklisted).length;
    final avgRating = _customers.isEmpty
        ? 0.0
        : _customers.map((c) => c.averageRating).reduce((a, b) => a + b) /
              _customers.length;
    final totalRevenue = _customers.isEmpty
        ? 0.0
        : _customers.map((c) => c.totalSpent).reduce((a, b) => a + b);

    // Using LayoutBuilder for responsive (though this is retailer dashboard usually desktop/tablet web)
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: $_error',
                    style: const TextStyle(color: Colors.red),
                  ),
                  ElevatedButton(
                    onPressed: _fetchCustomers,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Customers',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Analytics Cards
                  Row(
                    children: [
                      _buildStatCard(
                        'Total Customers',
                        totalCustomers.toString(),
                        Icons.people_outline,
                        Colors.blue,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Avg Rating',
                        avgRating.toStringAsFixed(1),
                        Icons.star_outline,
                        Colors.amber,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Total Revenue',
                        '₹${NumberFormat.compactCurrency(symbol: '').format(totalRevenue)}',
                        Icons.currency_rupee,
                        Colors.green,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Blacklisted',
                        totalBlacklisted.toString(),
                        Icons.block,
                        Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Filters & Toolbar
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Search
                          Expanded(
                            flex: 2,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search by name, ID, phone...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                  _filterCustomers();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Status Filter
                          DropdownButton<String>(
                            value: _filterBlacklist,
                            underline: Container(),
                            items: ['All', 'Active', 'Blacklisted']
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _filterBlacklist = val;
                                  _filterCustomers();
                                });
                              }
                            },
                          ),
                          const SizedBox(width: 16),

                          // Sort By
                          DropdownButton<String>(
                            value: _sortBy,
                            underline: Container(),
                            items:
                                [
                                      'Joined Date',
                                      'Most Orders',
                                      'Highest Spent',
                                      'Lowest Rating',
                                      'Recent Activity',
                                    ]
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _sortBy = val;
                                  _filterCustomers();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Customer List (Table Header + ListView)
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              border: Border(
                                bottom: BorderSide(color: Colors.grey[200]!),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Customer',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Rating',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Orders',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Spent',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Last Active',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'Status',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // List
                          Expanded(
                            child: _filteredCustomers.isEmpty
                                ? const Center(
                                    child: Text('No customers found'),
                                  )
                                : ListView.separated(
                                    itemCount: _filteredCustomers.length,
                                    separatorBuilder: (ctx, i) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final customer =
                                          _filteredCustomers[index];
                                      return InkWell(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) =>
                                                CustomerDetailDialog(
                                                  customerId:
                                                      customer.customerId,
                                                  onUpdate:
                                                      _fetchCustomers, // Refresh list on change
                                                ),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 16,
                                          ),
                                          child: Row(
                                            children: [
                                              // Customer Info
                                              Expanded(
                                                flex: 3,
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      backgroundImage:
                                                          customer.profileImage !=
                                                              null
                                                          ? NetworkImage(
                                                              _apiService
                                                                  .formatImageUrl(
                                                                    customer
                                                                        .profileImage,
                                                                  ),
                                                            )
                                                          : null,
                                                      child:
                                                          customer.profileImage ==
                                                              null
                                                          ? Text(
                                                              customer
                                                                  .customerName[0]
                                                                  .toUpperCase(),
                                                            )
                                                          : null,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          customer.customerName,
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                        ),
                                                        Text(
                                                          'ID: ${customer.customerId}',
                                                          style: TextStyle(
                                                            color: Colors
                                                                .grey[500],
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Rating
                                              Expanded(
                                                flex: 2,
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.star,
                                                      size: 16,
                                                      color: Colors.amber,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      customer.averageRating
                                                          .toStringAsFixed(1),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Orders
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  customer.totalOrders
                                                      .toString(),
                                                ),
                                              ),
                                              // Spent
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  '₹${customer.totalSpent.toStringAsFixed(0)}',
                                                ),
                                              ),
                                              // Last Active
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  customer.lastOrderDate != null
                                                      ? DateFormat(
                                                          'MMM dd, yyyy',
                                                        ).format(
                                                          customer
                                                              .lastOrderDate!,
                                                        )
                                                      : '-',
                                                ),
                                              ),
                                              // Status
                                              Expanded(
                                                flex: 1,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        customer.isBlacklisted
                                                        ? Colors.red[50]
                                                        : Colors.green[50],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          customer.isBlacklisted
                                                          ? Colors.red[200]!
                                                          : Colors.green[200]!,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    customer.isBlacklisted
                                                        ? 'Blacklisted'
                                                        : 'Active',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          customer.isBlacklisted
                                                          ? Colors.red[700]
                                                          : Colors.green[700],
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  Icon(icon, color: color, size: 24),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
