class UploadSessionItem {
  final int? id;
  final String barcode;
  final String? imageUrl;
  Map<String, dynamic> productDetails; // Mutable for draft editing
  bool isProcessed;

  // UI Helpers
  Map<String, dynamic>? uiData; // Pre-filled data from backend merge logic
  Map<String, dynamic>? masterProduct;
  int? existingProductId;

  UploadSessionItem({
    this.id,
    required this.barcode,
    this.imageUrl,
    this.productDetails = const {},
    this.isProcessed = false,
    this.uiData,
    this.masterProduct,
    this.existingProductId,
  });

  factory UploadSessionItem.fromJson(Map<String, dynamic> json) {
    return UploadSessionItem(
      id: json['id'],
      barcode: json['barcode'],
      imageUrl: json['image'],
      productDetails: json['product_details'] ?? {},
      isProcessed: json['is_processed'] ?? false,
      uiData: json['ui_data'],
      masterProduct: json['master_product'],
      existingProductId: json['existing_product_id'],
    );
  }
}

class ProductUploadSession {
  final int id;
  final String status;
  final DateTime createdAt;
  final List<UploadSessionItem> items;

  ProductUploadSession({
    required this.id,
    required this.status,
    required this.createdAt,
    this.items = const [],
  });

  factory ProductUploadSession.fromJson(Map<String, dynamic> json) {
    var itemsList = <UploadSessionItem>[];
    if (json['items'] != null) {
      itemsList = (json['items'] as List)
          .map((i) => UploadSessionItem.fromJson(i))
          .toList();
    }

    return ProductUploadSession(
      id: json['id'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      items: itemsList,
    );
  }
}
