// lib/models/product_model.dart

class Product {
  final String productId;
  final String name;
  final double price;
  final String category;
  final List<String> imageUrls;

  Product({
    required this.productId,
    required this.name,
    required this.category,
    required this.imageUrls,
    required this.price, required String id,
  });

  // This factory constructor converts Firestore document data into a Product object
  factory Product.fromFirestore(Map<String, dynamic> data, String id) {
    return Product(
      productId: id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      category: data['category'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []), id: '',
    );
  }
}