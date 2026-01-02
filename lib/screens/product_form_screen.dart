import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _originalPriceController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  final TextEditingController _barcodeController =
      TextEditingController(); // NEW
  int? _selectedCategoryId;
  int? _selectedBrandId;
  int? _masterProductId; // NEW
  bool _isFeatured = false;
  bool _isAvailable = true;
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.product?.description ?? '',
    );
    _priceController = TextEditingController(
      text: widget.product?.price.toString() ?? '',
    );
    _originalPriceController = TextEditingController(
      text: widget.product?.originalPrice?.toString() ?? '',
    );
    _quantityController = TextEditingController(
      text: widget.product?.quantity.toString() ?? '',
    );
    _unitController = TextEditingController(
      text: widget.product?.unit ?? 'piece',
    );
    _isFeatured = widget.product?.isFeatured ?? false;
    _isAvailable = widget.product?.isAvailable ?? true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        context.read<ProductProvider>().fetchMetadata(token).then((_) {
          // Attempt to match category/brand names to IDs if editing
          if (widget.product != null) {
            final provider = context.read<ProductProvider>();
            if (widget.product!.categoryName != null) {
              try {
                _selectedCategoryId = provider.categories.firstWhere(
                  (c) => c['name'] == widget.product!.categoryName,
                )['id'];
              } catch (_) {}
            }
            if (widget.product!.brandName != null) {
              try {
                _selectedBrandId = provider.brands.firstWhere(
                  (b) => b['name'] == widget.product!.brandName,
                )['id'];
              } catch (_) {}
            }
            setState(() {});
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _barcodeController.dispose(); // NEW
    super.dispose();
  }

  void _searchBarcode() async {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) return;

    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;

    try {
      final data = await context.read<ProductProvider>().searchMasterProduct(
        auth.token!,
        barcode,
      );

      setState(() {
        _masterProductId = data['id'];
        _nameController.text = data['name'];
        _descriptionController.text = data['description'] ?? '';

        // Handle MRP
        if (data['mrp'] != null) {
          _priceController.text = data['mrp'].toString();
          _originalPriceController.text = data['mrp'].toString();
        }

        // Try to match Category
        final provider = context.read<ProductProvider>();
        if (data['category_name'] != null) {
          try {
            _selectedCategoryId = provider.categories.firstWhere(
              (c) => c['name'] == data['category_name'],
            )['id'];
          } catch (_) {}
        }

        // Try to match Brand
        if (data['brand_name'] != null) {
          try {
            _selectedBrandId = provider.brands.firstWhere(
              (b) => b['name'] == data['brand_name'],
            )['id'];
          } catch (_) {}
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Product found!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  String _getProductImageUrl() {
    if (widget.product?.imageUrl != null &&
        widget.product!.imageUrl!.isNotEmpty) {
      return widget.product!.imageUrl!;
    }
    if (widget.product?.image != null && widget.product!.image!.isNotEmpty) {
      if (widget.product!.image!.startsWith('http')) {
        return widget.product!.image!;
      }
      return '${ApiConstants.serverUrl}${widget.product!.image!}';
    }
    return '';
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ProductProvider>();
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;

    final productData = {
      'name': _nameController.text,
      'description': _descriptionController.text,
      'price': double.parse(_priceController.text),
      'original_price': _originalPriceController.text.isNotEmpty
          ? double.parse(_originalPriceController.text)
          : null,
      'quantity': int.parse(_quantityController.text),
      'unit': _unitController.text,
      'category': _selectedCategoryId,
      'brand': _selectedBrandId,
      'is_featured': _isFeatured,
      'is_available': _isAvailable,
      'is_active': true,
      'barcode': _barcodeController.text.isNotEmpty
          ? _barcodeController.text
          : null, // NEW
      'master_product': _masterProductId, // NEW
    };

    try {
      if (widget.product == null) {
        await provider.addProduct(
          auth.token!,
          productData,
          imageFile: _imageFile,
        );
      } else {
        await provider.updateProduct(
          auth.token!,
          widget.product!.id,
          productData,
          imageFile: _imageFile,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product == null ? 'Product added' : 'Product updated',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final isEditing = widget.product != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Product' : 'Add Product')),
      body: provider.isLoading && provider.products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isEditing) ...[
                      // Only show search for new products
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _barcodeController,
                              decoration: const InputDecoration(
                                labelText: 'Barcode / EAN (Optional)',
                                hintText: 'Scan or enter barcode',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: provider.isLoading
                                ? null
                                : _searchBarcode,
                            icon: const Icon(Icons.search),
                            tooltip: 'Search in Master Catalog',
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Image Picker Widget
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[400]!),
                            image: _imageFile != null
                                ? DecorationImage(
                                    image: kIsWeb
                                        ? NetworkImage(_imageFile!.path)
                                        : FileImage(File(_imageFile!.path))
                                              as ImageProvider,
                                    fit: BoxFit.cover,
                                  )
                                : (widget.product?.image != null ||
                                          widget.product?.imageUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(
                                            _getProductImageUrl(),
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null),
                          ),
                          child:
                              _imageFile == null &&
                                  widget.product?.image == null &&
                                  widget.product?.imageUrl == null
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Add Photo',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name*',
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(
                              labelText: 'Price (₹)*',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _originalPriceController,
                            decoration: const InputDecoration(
                              labelText: 'MRP (₹)',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            decoration: const InputDecoration(
                              labelText: 'Stock Quantity*',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _unitController,
                            decoration: const InputDecoration(
                              labelText: 'Unit (e.g. piece, kg)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: provider.categories.map((c) {
                        return DropdownMenuItem<int>(
                          value: c['id'],
                          child: Text(c['name']),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCategoryId = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedBrandId,
                      decoration: const InputDecoration(labelText: 'Brand'),
                      items: provider.brands.map((b) {
                        return DropdownMenuItem<int>(
                          value: b['id'],
                          child: Text(b['name']),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedBrandId = val),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Featured Product'),
                      value: _isFeatured,
                      onChanged: (val) => setState(() => _isFeatured = val),
                    ),
                    SwitchListTile(
                      title: const Text('Is Available'),
                      value: _isAvailable,
                      onChanged: (val) => setState(() => _isAvailable = val),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: provider.isLoading ? null : _saveForm,
                        child: provider.isLoading
                            ? const CircularProgressIndicator()
                            : Text(
                                isEditing ? 'UPDATE PRODUCT' : 'CREATE PRODUCT',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
