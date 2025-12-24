import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'product_list_screen.dart';
import 'order_list_screen.dart';
import 'profile_screen.dart';
import '../providers/dashboard_provider.dart';
import '../providers/order_provider.dart';
import '../services/notification_service.dart';
import 'dart:async';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
    _listenForNotifications();
  }

  void _listenForNotifications() {
    _notificationSubscription = NotificationService().updateStream.listen((
      data,
    ) {
      if (data['type'] == 'new_order' || data['event'] == 'order_refresh') {
        _refreshData();
      }
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _refreshData() {
    final auth = context.read<AuthProvider>();
    if (auth.token != null) {
      context.read<DashboardProvider>().fetchStats(auth.token!);
      context.read<OrderProvider>().fetchOrders(auth.token!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dash = context.watch<DashboardProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Retailer Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (idx) {
              setState(() {
                _selectedIndex = idx;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Overview'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.shopping_bag),
                label: Text('Products'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.list_alt),
                label: Text('Orders'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person),
                label: Text('Profile'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main Content
          Expanded(child: _buildBody(_selectedIndex, auth, dash)),
        ],
      ),
    );
  }

  Widget _buildBody(int index, AuthProvider auth, DashboardProvider dash) {
    switch (index) {
      case 0:
        return _buildOverview(auth, dash);
      case 1:
        return const ProductListScreen();
      case 2:
        return const OrderListScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const Center(child: Text('Under Implementation'));
    }
  }

  Widget _buildOverview(AuthProvider auth, DashboardProvider dash) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${auth.user?.shopName ?? 'Retailer'}!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 900
                  ? 4
                  : (constraints.maxWidth > 600 ? 2 : 1);
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(
                    'Total Orders',
                    '${dash.stats?.totalOrders ?? 0}',
                    Icons.shopping_cart,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Revenue',
                    '₹${dash.stats?.totalRevenue.toStringAsFixed(0) ?? 0}',
                    Icons.currency_rupee,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Total Products',
                    '${dash.stats?.totalProducts ?? 0}',
                    Icons.inventory_2,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    'Average Rating',
                    '${dash.stats?.averageRating.toStringAsFixed(1) ?? 0}',
                    Icons.star,
                    Colors.purple,
                  ),
                  _buildStatCard(
                    'Avg Order Value',
                    '₹${dash.stats?.averageOrderValue.toStringAsFixed(0) ?? 0}',
                    Icons.payments,
                    Colors.teal,
                  ),
                ],
              );
            },
          ),
          if (dash.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (dash.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Error: ${dash.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          const SizedBox(height: 32),
          Text(
            'Recent Sales Performance',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              child: const Center(
                child: Text('Chart Placeholder (using fl_chart)'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey)),
                Icon(icon, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
