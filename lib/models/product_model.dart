class Product {
  final String id;
  final String productId;
  final String name;
  final double price;
  final double? originalPrice;
  final List<String> imageUrls;
  final String category;
  final String description;
  final String features;
  final bool inStock;

  Product({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    this.originalPrice,
    required this.imageUrls,
    required this.category,
    this.description = '',
    this.features = '',
    this.inStock = true,
  });

  factory Product.fromFirestore(Map<String, dynamic> data, String docId) {
    // 1. Bulletproof Image Array Parsing
    List<String> images = [];
    try {
      if (data['imageUrls'] != null && data['imageUrls'] is List) {
        images = List<String>.from(data['imageUrls'].map((e) => e.toString()));
      } else if (data['imageUrl'] != null) {
        images = [data['imageUrl'].toString()];
      }
    } catch (e) {
      images = [];
    }

    // 2. Bulletproof Number Parsing (Prevents crashes if price is saved as a String)
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Product(
      id: docId,
      productId: docId,
      name: data['name']?.toString() ?? 'Unnamed Product',
      price: parsePrice(data['price']),
      originalPrice: data['originalPrice'] != null ? parsePrice(data['originalPrice']) : null,
      imageUrls: images.isNotEmpty ? images : ['https://images.unsplash.com/photo-1581622558667-3419a8dc5f83?w=400&q=80'],
      category: data['category']?.toString() ?? 'Uncategorized',
      description: data['description']?.toString() ?? 'High-quality premium product. Excellent performance and durability.',
      features: data['features']?.toString() ?? '• Premium Quality\n• Modern Design\n• 1 Year Warranty',
      inStock: data['inStock'] is bool ? data['inStock'] : true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'originalPrice': originalPrice,
      'imageUrls': imageUrls,
      'category': category,
      'description': description,
      'features': features,
      'inStock': inStock,
    };
  }
}