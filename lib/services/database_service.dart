import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. GET ALL PRODUCTS FROM FIREBASE LIVE
  Stream<List<Product>> getProducts() {
    return _firestore.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Product(
          id: doc.id,
          productId: doc.id,
          name: data['name'] ?? '',
          price: (data['price'] ?? 0).toDouble(), // Safely handles ints or doubles
          imageUrls: List<String>.from(data['imageUrls'] ?? []),
          category: data['category'] ?? '',
        );
      }).toList();
    });
  }

  // 2. SCRIPT TO UPLOAD ALL PRODUCTS TO FIREBASE
  Future<void> uploadAllDummyData() async {
    final CollectionReference productsRef = _firestore.collection('products');

    List<Map<String, dynamic>> allProducts = [
      {'name': 'Stainless Steel Cookware Set (5 Pieces)', 'price': 1499, 'imageUrls': ['https://images.unsplash.com/photo-1584992236310-6edddc08acff?w=400&q=80'], 'category': 'Home & Kitchen'},
      {'name': 'Mixer Grinder (750W Powertron)', 'price': 2199, 'imageUrls': ['https://images.unsplash.com/photo-1570222094114-d054a817e56b?w=400&q=80'], 'category': 'Home & Kitchen'},
      {'name': 'Electric Kettle (1.8L Premium Auto-Cutoff)', 'price': 899, 'imageUrls': ['https://images.unsplash.com/photo-1574269909862-7e1d70bb8078?w=400&q=80'], 'category': 'Home & Kitchen'},
      {'name': 'Non-Stick Frying Pan (24cm with Lid)', 'price': 799, 'imageUrls': ['https://images.unsplash.com/photo-1583778176476-4a8b02a64c01?w=400&q=80'], 'category': 'Home & Kitchen'},
      {'name': 'Manual Compact High-Velocity Vegetable Chopper', 'price': 349, 'imageUrls': ['https://images.unsplash.com/photo-1581622558667-3419a8dc5f83?w=400&q=80'], 'category': 'Home & Kitchen'},
      {'name': 'Digital Air Fryer (4.2L Rapid Heat)', 'price': 4999, 'imageUrls': ['https://images.unsplash.com/photo-1626806819282-2c1dc01a5e0c?w=400&q=80'], 'category': 'Home & Kitchen'},
      {'name': 'Automatic Drip Espresso Coffee Maker', 'price': 2199, 'imageUrls': ['https://images.unsplash.com/photo-1519681393784-d120267933ba?w=400&q=80'], 'category': 'Home & Kitchen'},
      {'name': 'Premium Teak Wood Cutting Board', 'price': 549, 'imageUrls': ['https://images.unsplash.com/photo-1593010996841-f67f259de4b7?w=400&q=80'], 'category': 'Home & Kitchen'},
      {'name': 'Silicone Cooking Utensils Set (12 Pcs)', 'price': 999, 'imageUrls': ['https://images.unsplash.com/photo-1590794056226-79ef3a8147e1?w=400&q=80'], 'category': 'Home & Kitchen'},
      {'name': 'Microwave Safe Glass Bowls (Set of 3)', 'price': 449, 'imageUrls': ['https://images.unsplash.com/photo-1622484211148-52f1b1c676d0?w=400&q=80'], 'category': 'Home & Kitchen'},
      {'name': 'Heavy Duty Mixer Grinder (750W)', 'price': 2499, 'imageUrls': ['https://images.unsplash.com/photo-1570222094114-d054a817e56b?w=400&q=80'], 'category': 'Home & Kitchen'},
      {'name': 'Stainless Steel Insulated Water Bottle (1L)', 'price': 699, 'imageUrls': ['https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=400&q=80'], 'category': 'Home & Kitchen'},
      {'name': 'Digital Kitchen Weighing Scale', 'price': 299, 'imageUrls': ['https://images.unsplash.com/photo-1586716402203-79219bede43c?w=400&q=80'], 'category': 'Home & Kitchen'},
    ];

    for (var prod in allProducts) {
      await productsRef.add(prod);
    }
  }
}