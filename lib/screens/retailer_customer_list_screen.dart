import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/reward_service.dart';
import '../providers/auth_provider.dart';

class RetailerCustomerListScreen extends StatefulWidget {
  const RetailerCustomerListScreen({super.key});

  @override
  State<RetailerCustomerListScreen> createState() =>
      _RetailerCustomerListScreenState();
}

class _RetailerCustomerListScreenState
    extends State<RetailerCustomerListScreen> {
  final RewardService _rewardService = RewardService();
  List<dynamic> _customers = [];
  bool _isLoading = true;
  String? _error;

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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.token == null) {
        throw Exception('User not authenticated');
      }

      final data = await _rewardService.getRetailerCustomersLoyalty(
        authProvider.token!,
      );
      setState(() {
        _customers = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _fetchCustomers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_customers.isEmpty) {
      return const Center(child: Text('No customers with loyalty points yet.'));
    }

    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _customers.length,
        itemBuilder: (context, index) {
          final customer = _customers[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(customer['customer_name']?[0].toUpperCase() ?? '?'),
              ),
              title: Text(customer['customer_name'] ?? 'Unknown'),
              subtitle: Text('ID: ${customer['customer_id']}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${double.parse(customer['points'].toString()).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                  const Text('Points', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
