import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';
import '../models/product_model.dart';

class ProductService {
  Future<List<Product>> getProducts(String token) async {
    final response = await http.get(
      Uri.parse(ApiConstants.products),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded is Map ? decoded['results'] : decoded;
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<Product> addProduct(
    String token,
    Map<String, dynamic> productData, {
    XFile? imageFile,
  }) async {
    if (imageFile == null) {
      final response = await http.post(
        Uri.parse(ApiConstants.createProduct),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(productData),
      );

      if (response.statusCode == 201) {
        return Product.fromJson(jsonDecode(response.body));
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to add product');
      }
    } else {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.createProduct),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Add fields
      productData.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          await imageFile.readAsBytes(),
          filename: imageFile.name,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return Product.fromJson(jsonDecode(response.body));
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to add product');
      }
    }
  }

  Future<Product> updateProduct(
    String token,
    int productId,
    Map<String, dynamic> productData, {
    XFile? imageFile,
  }) async {
    if (imageFile == null) {
      final response = await http.patch(
        Uri.parse(ApiConstants.updateProduct(productId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(productData),
      );

      if (response.statusCode == 200) {
        return Product.fromJson(jsonDecode(response.body));
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update product');
      }
    } else {
      var request = http.MultipartRequest(
        'PATCH',
        Uri.parse(ApiConstants.updateProduct(productId)),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Add fields
      productData.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Add image
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          await imageFile.readAsBytes(),
          filename: imageFile.name,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return Product.fromJson(jsonDecode(response.body));
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update product');
      }
    }
  }

  Future<void> deleteProduct(String token, int productId) async {
    final response = await http.delete(
      Uri.parse(ApiConstants.deleteProduct(productId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete product');
    }
  }

  Future<List<Map<String, dynamic>>> getCategories(String token) async {
    final response = await http.get(
      Uri.parse(ApiConstants.categories),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<List<Map<String, dynamic>>> getBrands(
    String token, {
    String? query,
  }) async {
    var url = ApiConstants.brands;
    if (query != null && query.isNotEmpty) {
      url += '?search=$query';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load brands');
    }
  }

  Future<Map<String, dynamic>> searchMasterProduct(
    String token,
    String barcode,
  ) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.masterProductSearch}?barcode=$barcode'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('Product not found in master catalog');
    } else {
      throw Exception('Failed to search product');
    }
  }

  Future<Map<String, dynamic>> uploadProducts(String token, XFile file) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.uploadProducts),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        await file.readAsBytes(),
        filename: file.name,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to upload products');
    }
  }

  Future<Uint8List> downloadTemplate(String token) async {
    final response = await http.get(
      Uri.parse(ApiConstants.downloadTemplate),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to download template');
    }
  }
}
