import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/product_service.dart';
import '../providers/auth_provider.dart';
import '../models/upload_session.dart';

class SessionReviewScreen extends StatefulWidget {
  final int sessionId;
  const SessionReviewScreen({super.key, required this.sessionId});

  @override
  State<SessionReviewScreen> createState() => _SessionReviewScreenState();
}

class _SessionReviewScreenState extends State<SessionReviewScreen>
    with SingleTickerProviderStateMixin {
  final ProductService _productService = ProductService();
  late TabController _tabController;

  bool _isLoading = true;
  ProductUploadSession? _session;
  List<UploadSessionItem> _matchedItems = [];
  List<UploadSessionItem> _unmatchedItems = [];

  // Track modified items for draft saving
  final Set<int> _modifiedItemIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSessionDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionDetails() async {
    setState(() => _isLoading = true);
    final token = context.read<AuthProvider>().token!;
    try {
      final data = await _productService.getSessionDetails(
        token,
        widget.sessionId,
      );

      // Parse Session Wrapper (though API returns a dict with 'session' key maybe?
      // Checking GetSessionDetailsView: returns serializer.data which matches ProductUploadSession structure

      // Wait, GetSessionDetailsView returns:
      // {
      //    "id": ...,
      //    "items": [ ... with ui_data ... ]
      // }
      // So logic:
      final session = ProductUploadSession.fromJson(data);

      final matched = <UploadSessionItem>[];
      final unmatched = <UploadSessionItem>[];

      for (var item in session.items) {
        // Check ui_data from backend
        // Backend logic: "status": "Matched" or "Unmatched" inside ui_data
        final status = item.uiData?['status'] ?? 'Unmatched';
        if (status == 'Matched') {
          matched.add(item);
        } else {
          unmatched.add(item);
        }
      }

      setState(() {
        _session = session;
        _matchedItems = matched;
        _unmatchedItems = unmatched;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDraft() async {
    if (_modifiedItemIds.isEmpty) return;

    setState(() => _isLoading = true);
    final token = context.read<AuthProvider>().token!;

    // Collect modified items
    final itemsToUpdate = _session!.items
        .where((i) => _modifiedItemIds.contains(i.id))
        .map((i) => {'id': i.id, 'product_details': i.productDetails})
        .toList();

    try {
      await _productService.updateSessionItems(
        token,
        widget.sessionId,
        itemsToUpdate,
      );
      _modifiedItemIds.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Draft Saved")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Save Failed: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _commitSession() async {
    // Save draft first if needed? Better to auto-save.
    if (_modifiedItemIds.isNotEmpty) {
      await _saveDraft();
    }

    setState(() => _isLoading = true);
    final token = context.read<AuthProvider>().token!;

    try {
      final result = await _productService.commitSession(
        token,
        widget.sessionId,
      );
      // Show Result Dialog
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Upload Complete"),
          content: Text(
            "Created: ${result['created_count']}\nUpdated: ${result['updated_count']}\nErrors: ${result['error_count']}",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Dialog
                Navigator.pop(context); // Screen
              },
              child: const Text("Close"),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Commit Failed: $e")));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Review Session #${widget.sessionId}"),
        actions: [
          if (_modifiedItemIds.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.save),
              label: const Text("Save Draft"),
              onPressed: _isLoading ? null : _saveDraft,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: "Unmatched (${_unmatchedItems.length})",
              icon: const Icon(Icons.warning_amber, color: Colors.orange),
            ),
            Tab(
              text: "Matched (${_matchedItems.length})",
              icon: const Icon(Icons.check_circle, color: Colors.green),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildItemsList(_unmatchedItems, isMatched: false),
                _buildItemsList(_matchedItems, isMatched: true),
              ],
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.blue[900],
            foregroundColor: Colors.white,
          ),
          onPressed: _isLoading ? null : _commitSession,
          child: const Text(
            "FINALIZE & UPLOAD",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildItemsList(
    List<UploadSessionItem> items, {
    required bool isMatched,
  }) {
    if (items.isEmpty) return const Center(child: Text("No items here."));

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ExpansionTile(
            leading: item.imageUrl != null
                ? Image.network(
                    item.imageUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image),
                  )
                : const Icon(Icons.image_not_supported),
            title: Text(
              item.productDetails['name'] ??
                  item.uiData?['master_name'] ??
                  "Unknown Product",
            ),
            subtitle: Text("Barcode: ${item.barcode}"),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Form Fields
                    _buildTextField(item, 'name', 'Product Name'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            item,
                            'mrp',
                            'MRP',
                            isNumber: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            item,
                            'selling_price',
                            'Selling Price',
                            isNumber: true,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            item,
                            'stock',
                            'Stock',
                            isNumber: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(item, 'brand', 'Brand'),
                        ), // Should be autocomplete ideally
                      ],
                    ),
                    _buildTextField(
                      item,
                      'category',
                      'Category',
                    ), // Should be dropdown
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField(
    UploadSessionItem item,
    String key,
    String label, {
    bool isNumber = false,
  }) {
    return TextFormField(
      initialValue: item.productDetails[key]?.toString() ?? '',
      decoration: InputDecoration(labelText: label),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      onChanged: (val) {
        setState(() {
          if (isNumber) {
            item.productDetails[key] = num.tryParse(val) ?? val;
          } else {
            item.productDetails[key] = val;
          }
          _modifiedItemIds.add(item.id!);
        });
      },
    );
  }
}
