class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final double? discountedPrice;
  final int? discountPercentage;
  final int quantity;
  final String unit;
  final String? image;
  final String? imageUrl;
  final String? categoryName;
  final String? brandName;
  final bool isActive;
  final bool isFeatured;
  final bool isAvailable;
  final double averageRating;
  final int reviewCount;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    this.discountedPrice,
    this.discountPercentage,
    required this.quantity,
    required this.unit,
    this.image,
    this.imageUrl,
    this.categoryName,
    this.brandName,
    required this.isActive,
    this.isFeatured = false,
    this.isAvailable = true,
    this.averageRating = 0.0,
    this.reviewCount = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: double.parse(json['price'].toString()),
      originalPrice: json['original_price'] != null
          ? double.parse(json['original_price'].toString())
          : null,
      discountedPrice: json['discounted_price'] != null
          ? double.parse(json['discounted_price'].toString())
          : null,
      discountPercentage: json['discount_percentage'] != null
          ? (double.tryParse(json['discount_percentage'].toString())?.toInt())
          : null,
      quantity: json['quantity'] ?? 0,
      unit: json['unit'] ?? 'piece',
      image: json['image'], // This is the relative path from backend
      imageUrl: json['image_url'], // This might be a full URL if provided
      categoryName: json['category_name'],
      brandName: json['brand_name'],
      isActive: json['is_active'] ?? true,
      isFeatured: json['is_featured'] ?? false,
      isAvailable: json['is_available'] ?? true,
      averageRating: double.parse((json['average_rating'] ?? 0).toString()),
      reviewCount: json['review_count'] ?? 0,
    );
  }
}
