import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/product_service.dart';
import '../providers/auth_provider.dart';
import '../models/upload_session.dart';
import '../utils/constants.dart';

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

  // Autocomplete Data
  List<Map<String, dynamic>> _categories = []; // Changed to List of Maps

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadSessionDetails(), _loadCategories()]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final cats = await _productService.getCategories(token);
      // Ensure 'name' exists usually, API might return id/name
      setState(() {
        _categories = cats;
      });
    } catch (e) {
      print("Error loading categories: $e");
    }
  }

  Future<void> _loadSessionDetails() async {
    setState(() => _isLoading = true);
    final token = context.read<AuthProvider>().token!;
    try {
      final data = await _productService.getSessionDetails(
        token,
        widget.sessionId,
      );

      // Backend returns { 'session': {...}, 'matched_items': [...], 'unmatched_items': [...] }
      final sessionData = data['session'];
      final session = ProductUploadSession.fromJson(sessionData);

      final matched = (data['matched_items'] as List)
          .map((i) => UploadSessionItem.fromJson(i))
          .toList();

      final unmatched = (data['unmatched_items'] as List)
          .map((i) => UploadSessionItem.fromJson(i))
          .toList();

      // Hydrate items with uiData defaults
      _hydrateItems(matched);
      _hydrateItems(unmatched);

      setState(() {
        _session = session;
        _matchedItems = matched;
        _unmatchedItems = unmatched;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _hydrateItems(List<UploadSessionItem> items) {
    for (var item in items) {
      bool changed = false;
      if (item.uiData != null) {
        item.uiData!.forEach((key, value) {
          // If productDetails doesn't have it, and uiData has valid value
          if (!item.productDetails.containsKey(key) &&
              value != null &&
              value.toString().isNotEmpty) {
            item.productDetails[key] = value;
            changed = true;

            // Special handling for Category ID resolution
            if (key == 'category' && _categories.isNotEmpty) {
              final catName = value.toString().toLowerCase();
              try {
                final catObj = _categories.firstWhere(
                  (c) => c['name'].toString().toLowerCase() == catName,
                  orElse: () => {},
                );
                if (catObj.isNotEmpty) {
                  item.productDetails['category_id'] = catObj['id'];
                }
              } catch (_) {}
            }
          }
        });
      }
      // If we hydrated data, we must mark it as valid to save,
      // primarily so backend gets the full object on commit.
      if (changed) {
        // We add to modified so _saveDraft picks it up.
        // Implementation detail: JSON mapping needs `id`.
        if (item.id != null) {
          _modifiedItemIds.add(item.id!);
        }
      }
    }
  }

  String _getImageUrl(String? partialUrl) {
    if (partialUrl == null || partialUrl.isEmpty) return '';
    if (partialUrl.startsWith('http')) return partialUrl;
    return '${ApiConstants.serverUrl}$partialUrl';
  }

  void _showImagePopup(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: Image.network(
                imageUrl,
                errorBuilder: (_, __, ___) =>
                    const Center(child: Icon(Icons.broken_image, size: 50)),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.black, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveDraft() async {
    // ... (same as before)
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
    setState(() => _isLoading = true);
    final token = context.read<AuthProvider>().token!;

    // FORCE SAVE ALL ITEMS before committing
    // This ensures backend has the latest data (including hydrated defaults)
    // even if user didn't explicitly edit them.
    final allItems = [..._matchedItems, ..._unmatchedItems];
    final itemsToUpdate = allItems
        .map((i) => {'id': i.id, 'product_details': i.productDetails})
        .toList();

    try {
      // 1. Update all items
      // We ignore _modifiedItemIds and just save everything to be safe.
      if (itemsToUpdate.isNotEmpty) {
        await _productService.updateSessionItems(
          token,
          widget.sessionId,
          itemsToUpdate,
        );
      }

      // 2. Commit
      final result = await _productService.commitSession(
        token,
        widget.sessionId,
      );

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Upload Complete"),
          content: Text(
            "Created: ${result['created_count']}\nUpdated: ${result['updated_count']}",
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        if (isMatched) {
          return _buildMatchedItemCard(item);
        } else {
          return _buildUnmatchedItemCard(item);
        }
      },
    );
  }

  Widget _buildMatchedItemCard(UploadSessionItem item) {
    final masterName =
        item.uiData?['name'] ??
        item.productDetails['name'] ??
        "Unknown Product";
    final brandName =
        item.uiData?['brand'] ??
        item.productDetails['brand'] ??
        "Unknown Brand";
    final catName =
        item.uiData?['category'] ??
        item.productDetails['category'] ??
        "Unknown Category";

    final capturedImageUrl = _getImageUrl(item.imageUrl);

    // Collect all images
    final List<String> allImages = [];
    if (capturedImageUrl.isNotEmpty) allImages.add(capturedImageUrl);

    final masterImages = (item.uiData?['images'] as List?)
        ?.map((e) => e.toString())
        .toList();
    if (masterImages != null && masterImages.isNotEmpty) {
      // Avoid duplicates
      for (var img in masterImages) {
        if (!allImages.contains(img)) allImages.add(img);
      }
    } else {
      // Fallback
      final masterImageUrl =
          item.uiData?['image'] ?? item.uiData?['image_url'] ?? '';
      if (masterImageUrl.isNotEmpty && !allImages.contains(masterImageUrl)) {
        allImages.add(masterImageUrl);
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Images List
                if (allImages.isNotEmpty)
                  SizedBox(
                    height: 60,
                    width: 150, // Fixed width for image area
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: allImages.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _showImagePopup(allImages[index]),
                          child: Image.network(
                            allImages[index],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, size: 15),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  ),

                const SizedBox(width: 12),

                // Read-only Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        masterName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(
                            label: Text(
                              brandName,
                              style: const TextStyle(fontSize: 10),
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                          Chip(
                            label: Text(
                              catName,
                              style: const TextStyle(fontSize: 10),
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            // Inline Inputs: MRP | Rate | Qty
            Row(
              children: [
                Expanded(
                  child: _buildCompactInput(item, 'original_price', 'MRP'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCompactInput(item, 'price', 'Selling Price'),
                ),
                const SizedBox(width: 8),
                Expanded(child: _buildCompactInput(item, 'quantity', 'Stock')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInput(UploadSessionItem item, String key, String label) {
    final val = item.productDetails[key]?.toString() ?? '';
    return TextFormField(
      initialValue: val,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        isDense: true,
      ),
      onChanged: (v) {
        item.productDetails[key] = num.tryParse(v) ?? 0;
        if (item.id != null) _modifiedItemIds.add(item.id!);
      },
    );
  }

  Widget _buildUnmatchedItemCard(UploadSessionItem item) {
    final fullImageUrl = _getImageUrl(item.imageUrl);
    return Card(
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        leading: GestureDetector(
          onTap: fullImageUrl.isNotEmpty
              ? () => _showImagePopup(fullImageUrl)
              : null,
          child: fullImageUrl.isNotEmpty
              ? Image.network(
                  fullImageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                )
              : const Icon(Icons.image_not_supported),
        ),
        title: Text(
          item.productDetails['name'] ??
              item.uiData?['name'] ??
              "Unknown Product",
        ), // Use UI Data name preference
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
                        'original_price',
                        'MRP',
                        isNumber: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        item,
                        'price',
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
                        'quantity',
                        'Stock',
                        isNumber: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _buildBrandAutocomplete(item)),
                  ],
                ),
                _buildCategoryAutocomplete(item),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    UploadSessionItem item,
    String key,
    String label, {
    bool isNumber = false,
  }) {
    // Prefer draft value, then UI data (pre-filled), then empty
    final initialVal = item.productDetails[key] ?? item.uiData?[key] ?? '';

    return TextFormField(
      initialValue: initialVal.toString(),
      decoration: InputDecoration(labelText: label),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      onChanged: (val) {
        // We are mutating the map directly, which is fine for draft state in memory
        // but setState triggers rebuild needed if validation or other UI depends on it.
        // Here it's mainly for saving later.
        if (isNumber) {
          item.productDetails[key] = num.tryParse(val) ?? 0;
        } else {
          item.productDetails[key] = val;
        }
        _modifiedItemIds.add(item.id!);
      },
    );
  }

  Widget _buildBrandAutocomplete(UploadSessionItem item) {
    final token = context.read<AuthProvider>().token;
    final initialName =
        item.productDetails['brand'] ?? item.uiData?['brand'] ?? '';

    return Autocomplete<Map<String, dynamic>>(
      initialValue: TextEditingValue(text: initialName.toString()),
      displayStringForOption: (Map<String, dynamic> option) => option['name'],
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text == '') {
          return const Iterable<Map<String, dynamic>>.empty();
        }
        if (token == null) return const Iterable<Map<String, dynamic>>.empty();

        try {
          final brands = await _productService.getBrands(
            token,
            query: textEditingValue.text,
          );
          return brands;
        } catch (e) {
          return const Iterable<Map<String, dynamic>>.empty();
        }
      },
      onSelected: (Map<String, dynamic> selection) {
        item.productDetails['brand'] = selection['name'];
        item.productDetails['brand_id'] = selection['id'];
        _modifiedItemIds.add(item.id!);
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              onFieldSubmitted: (_) => onFieldSubmitted(),
              onChanged: (val) {
                item.productDetails['brand'] = val;
                if (item.productDetails['brand_id'] != null) {
                  item.productDetails.remove('brand_id');
                }
                _modifiedItemIds.add(item.id!);
              },
              decoration: const InputDecoration(labelText: "Brand"),
            );
          },
    );
  }

  Widget _buildCategoryAutocomplete(UploadSessionItem item) {
    final initialName =
        item.productDetails['category'] ?? item.uiData?['category'] ?? '';

    return Autocomplete<Map<String, dynamic>>(
      initialValue: TextEditingValue(text: initialName.toString()),
      displayStringForOption: (Map<String, dynamic> option) => option['name'],
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return _categories;
        }
        return _categories.where((option) {
          final name = option['name'].toString().toLowerCase();
          return name.contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (Map<String, dynamic> selection) {
        item.productDetails['category'] = selection['name'];
        item.productDetails['category_id'] = selection['id'];
        _modifiedItemIds.add(item.id!);
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              onChanged: (val) {
                item.productDetails['category'] = val;
                if (item.productDetails['category_id'] != null) {
                  item.productDetails.remove('category_id');
                }
                _modifiedItemIds.add(item.id!);
              },
              decoration: const InputDecoration(labelText: "Category"),
            );
          },
    );
  }
}
