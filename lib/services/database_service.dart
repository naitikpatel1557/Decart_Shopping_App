import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream all products (used by HomeTab and Suggestions)
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

  // --- NEW: Added missing method to fix the account_tab.dart error ---
  Future<void> uploadAllDummyData() async {
    WriteBatch batch = _db.batch();

    List<Map<String, dynamic>> sampleProducts = [
      // ELECTRONICS
      {
        'category': 'Electronics',
        'name': 'Wireless Noise-Canceling Headphones',
        'price': 4999,
        'originalPrice': 7999,
        'imageUrls': ['https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500&q=80'],
        'description': 'High-fidelity audio with active noise cancellation and 30-hour battery life.',
        'features': '• Active Noise Cancellation\n• 30-Hour Battery Life\n• Bluetooth 5.2\n• Fast Charging via USB-C',
        'inStock': true,
      },
      {
        'category': 'Electronics',
        'name': 'Smart Fitness Watch Series 5',
        'price': 2999,
        'originalPrice': 4999,
        'imageUrls': ['https://images.unsplash.com/photo-1579586337278-3befd40fd17a?w=500&q=80'],
        'description': 'Track heart rate, sleep, workouts, and stay connected with real-time notifications.',
        'features': '• HD AMOLED Display\n• SpO2 & Heart Rate Monitor\n• 50m Water Resistant\n• 7-Day Battery Life',
        'inStock': true,
      },
      // HOME & KITCHEN
      {
        'category': 'Home & Kitchen',
        'name': 'Stainless Steel Cookware Set (5 Pieces)',
        'price': 1499,
        'originalPrice': 2499,
        'imageUrls': ['https://images.unsplash.com/photo-1584992236310-6edddc08acff?w=500&q=80'],
        'description': 'Food-grade stainless steel pots and pans engineered for even heat distribution.',
        'features': '• Induction & Gas Safe\n• Heat-Resistant Handles\n• Dishwasher Friendly\n• 1-Year Warranty',
        'inStock': true,
      },
      {
        'category': 'Home & Kitchen',
        'name': 'Digital Air Fryer (4.2L Rapid Heat)',
        'price': 4999,
        'originalPrice': 8999,
        'imageUrls': ['https://images.unsplash.com/photo-1626806819282-2c1dc01a5e0c?w=500&q=80'],
        'description': 'Crispy healthy meals using up to 85% less oil with 8 preset touch modes.',
        'features': '• 8 Preset Touch Controls\n• Non-stick Dishwasher Safe Basket\n• Overheat Protection\n• 1400W Rapid Heating',
        'inStock': true,
      },
      // BEAUTY
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