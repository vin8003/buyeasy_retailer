import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/common_image.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';

class ProductSelectionScreen extends StatefulWidget {
  const ProductSelectionScreen({super.key});

  @override
  State<ProductSelectionScreen> createState() => _ProductSelectionScreenState();
}

class _ProductSelectionScreenState extends State<ProductSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProducts();
    });
    // Rebuild on search change to update the filtered list in build
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchProducts() {
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      context.read<ProductProvider>().fetchProducts(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-filter when provider updates (e.g. after fetch)
    // We use Consumer to listen to changes, but we also want to maintain search state.
    // Actually, listening to provider in build and filtering there is cleaner.

    return Scaffold(
      appBar: AppBar(title: const Text('Select Product')),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          List<Product> displayList;
          if (_searchController.text.isEmpty) {
            displayList = provider.products;
          } else {
            // Apply filter again effectively
            final query = _searchController.text.toLowerCase();
            displayList = provider.products.where((product) {
              return product.name.toLowerCase().contains(query);
            }).toList();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search Products',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : displayList.isEmpty
                    ? const Center(child: Text('No products found'))
                    : ListView.builder(
                        itemCount: displayList.length,
                        itemBuilder: (context, index) {
                          final product = displayList[index];
                          // Only show available products?
                          // Retailer might want to add product even if local stock is low?
                          // For now, let's show all but indicate stock.

                          return ProductSelectionItem(
                            product: product,
                            onTap: () {
                              if (product.quantity > 0) {
                                Navigator.pop(context, product);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Product is out of stock'),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ProductSelectionItem extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductSelectionItem({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  State<ProductSelectionItem> createState() => _ProductSelectionItemState();
}

class _ProductSelectionItemState extends State<ProductSelectionItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final product = widget.product;
    return ListTile(
      leading: product.image != null
          ? CommonImage(
              imageUrl: product.image!,
              width: 50,
              height: 50,
              memCacheWidth: 150,
              memCacheHeight: 150,
              fit: BoxFit.cover,
            )
          : const SizedBox(width: 50, height: 50, child: Icon(Icons.image)),
      title: Text(product.name),
      subtitle: Text(
        'Price: ₹${product.price} • Stock: ${product.quantity} ${product.unit}',
        style: TextStyle(color: product.quantity == 0 ? Colors.red : null),
      ),
      onTap: widget.onTap,
    );
  }
}
