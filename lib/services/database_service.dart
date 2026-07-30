import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream all products
  Stream<List<Product>> getProducts() {
    return _db.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromFirestore(doc.data(), doc.id)).toList();
    });
  }

  // Stream products for a specific category
  Stream<List<Product>> getProductsByCategory(String categoryName) {
    return _db.collection('products').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromFirestore(doc.data(), doc.id))
          .where((p) => p.category.toLowerCase().trim() == categoryName.toLowerCase().trim())
          .toList();
    });
  }

  // Stream a single product's live details
  Stream<Product> getProductDetails(String productId) {
    return _db.collection('products').doc(productId).snapshots().map((doc) {
      if (doc.exists) {
        return Product.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
      throw Exception("Product not found");
    });
  }

  // --- REVIEW SYSTEM METHODS ---

  // Stream all reviews for a specific product
  Stream<QuerySnapshot> getProductReviews(String productId) {
    return _db
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .orderBy('date', descending: true)
        .snapshots();
  }

  // Submit a new review
  Future<void> submitReview({
    required String productId,
    required String userId,
    required String userName,
    required double rating,
    required String title,
    required String description,
  }) async {
    await _db.collection('products').doc(productId).collection('reviews').add({
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'title': title,
      'description': description,
      'date': FieldValue.serverTimestamp(),
      'helpfulCount': 0,
    });
  }

  // --- RESTORED: DUMMY DATA UPLOAD METHOD ---
  Future<void> uploadAllDummyData() async {
    WriteBatch batch = _db.batch();

    List<Map<String, dynamic>> sampleProducts = [
      {
        'category': 'Beauty',
        'name': 'Premium Men\'s Perfume (100ml)',
        'price': 1299,
        'originalPrice': 1999,
        'imageUrls': ['https://images.unsplash.com/photo-1594035910387-fea47794261f?w=400&q=80'],
        'description': 'A long-lasting premium fragrance with woody notes.',
        'features': '• 100ml Bottle\n• Long Lasting\n• Premium Quality\n• Great for daily use',
        'inStock': true,
      }
    ];

    for (var item in sampleProducts) {
      DocumentReference docRef = _db.collection('products').doc();
      batch.set(docRef, item);
    }

    await batch.commit();
  }
}