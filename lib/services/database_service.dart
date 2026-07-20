import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Retrieve a stream of all products (Updates in real-time)
  Stream<List<Product>> getProducts() {
    return _db.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // Here we use your factory constructor!
        return Product.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }
}