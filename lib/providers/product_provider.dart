import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _brands = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  List<Map<String, dynamic>> get categories => _categories;
  List<Map<String, dynamic>> get brands => _brands;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProducts(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _productService.getProducts(token);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMetadata(String token) async {
    try {
      final results = await Future.wait([
        _productService.getCategories(token),
        _productService.getBrands(token),
      ]);
      _categories = results[0];
      _brands = results[1];
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching metadata: $e');
    }
  }

  Future<Map<String, dynamic>> searchMasterProduct(
    String token,
    String barcode,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _productService.searchMasterProduct(token, barcode);
      return result;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProduct(
    String token,
    Map<String, dynamic> productData,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final newProduct = await _productService.addProduct(token, productData);
      _products.insert(0, newProduct);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProduct(
    String token,
    int productId,
    Map<String, dynamic> productData,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updatedProduct = await _productService.updateProduct(
        token,
        productId,
        productData,
      );
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = updatedProduct;
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String token, int productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _productService.deleteProduct(token, productId);
      _products.removeWhere((p) => p.id == productId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
