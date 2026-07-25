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

  // 2. ADMIN SCRIPT TO UPLOAD ALL CATEGORY PRODUCTS TO FIREBASE
  Future<void> uploadAllDummyData() async {
    final CollectionReference productsRef = _firestore.collection('products');

    List<Map<String, dynamic>> allProducts = [
      // --- HOME & KITCHEN ---
      {'name': 'Stainless Steel Cookware Set (5 Pieces)', 'price': 1499, 'imageUrls': ['https://images.unsplash.com/photo-1584992236310-6edddc08acff?w=400&q=80'], 'category': 'Home & Kitchen'},
      {'name': 'Digital Air Fryer (4.2L Rapid Heat)', 'price': 4999, 'imageUrls': ['https://images.unsplash.com/photo-1626806819282-2c1dc01a5e0c?w=400&q=80'], 'category': 'Home & Kitchen'},
      {'name': 'Electric Kettle (1.8L Premium Auto-Cutoff)', 'price': 899, 'imageUrls': ['https://images.unsplash.com/photo-1574269909862-7e1d70bb8078?w=400&q=80'], 'category': 'Home & Kitchen'},

      // --- BEAUTY ---
      {'name': 'Organic Vitamin C Face Serum', 'price': 599, 'imageUrls': ['https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=400&q=80'], 'category': 'Beauty'},
      {'name': 'Matte Finish Liquid Lipstick', 'price': 299, 'imageUrls': ['https://images.unsplash.com/photo-1586495777744-4413f21062fa?w=400&q=80'], 'category': 'Beauty'},
      {'name': 'Premium Men\'s Perfume (100ml)', 'price': 1299, 'imageUrls': ['https://images.unsplash.com/photo-1594035910387-fea47794261f?w=400&q=80'], 'category': 'Beauty'},

      // --- ELECTRONICS ---
      {'name': 'Wireless Noise Cancelling Headphones', 'price': 2999, 'imageUrls': ['https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&q=80'], 'category': 'Electronics'},
      {'name': 'Smartwatch with Heart Rate Monitor', 'price': 1999, 'imageUrls': ['https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=400&q=80'], 'category': 'Electronics'},
      {'name': '10000mAh Fast Charging Power Bank', 'price': 899, 'imageUrls': ['https://images.unsplash.com/photo-1609091839311-d5365f9ff1c5?w=400&q=80'], 'category': 'Electronics'},

      // --- OFFICE PRODUCT ---
      {'name': 'Ergonomic Mesh Office Chair', 'price': 4599, 'imageUrls': ['https://images.unsplash.com/photo-1505843490538-5133c6c7d0e1?w=400&q=80'], 'category': 'Office Product'},
      {'name': 'Leather Bound Professional Notebook', 'price': 349, 'imageUrls': ['https://images.unsplash.com/photo-1531346878377-a5be20888e57?w=400&q=80'], 'category': 'Office Product'},

      // --- TOYS & BABY CARE ---
      {'name': 'Building Blocks Creator Set (500 Pcs)', 'price': 1199, 'imageUrls': ['https://images.unsplash.com/photo-1585366119957-e9730b6d0f60?w=400&q=80'], 'category': 'Toys & Baby Care'},
      {'name': 'Soft Plush Teddy Bear', 'price': 499, 'imageUrls': ['https://images.unsplash.com/photo-1558961314-e6922a9f1437?w=400&q=80'], 'category': 'Toys & Baby Care'},

      // --- FASHION ---
      {'name': 'Men\'s Classic White Sneakers', 'price': 1499, 'imageUrls': ['https://images.unsplash.com/photo-1549298916-b41d501d3772?w=400&q=80'], 'category': 'Fashion'},
      {'name': 'Polarized Aviator Sunglasses', 'price': 799, 'imageUrls': ['https://images.unsplash.com/photo-1511499767150-a48a237f0083?w=400&q=80'], 'category': 'Fashion'},

      // --- HEALTH & PERSONAL... ---
      {'name': 'Non-Slip Yoga Mat with Strap', 'price': 699, 'imageUrls': ['https://images.unsplash.com/photo-1601121841793-1498b04d166b?w=400&q=80'], 'category': 'Health & Personal...'},
      {'name': 'Digital Blood Pressure Monitor', 'price': 1899, 'imageUrls': ['https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=400&q=80'], 'category': 'Health & Personal...'},

      // --- HOME IMPROVEMENT ---
      {'name': 'Cordless Drill Machine Kit', 'price': 2499, 'imageUrls': ['https://images.unsplash.com/photo-1504148455328-c376907d081c?w=400&q=80'], 'category': 'Home Improvement'},
    ];

    for (var prod in allProducts) {
      await productsRef.add(prod);
    }
  }
}