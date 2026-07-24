import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/database_service.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String categoryName;
  final Set<String> wishlistIds;
  final Function(String, String) onToggleWishlist;

  const CategoryProductsScreen({
    super.key,
    required this.categoryName,
    required this.wishlistIds,
    required this.onToggleWishlist,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final DatabaseService _databaseService = DatabaseService();

  // --- 12 DUMMY PRODUCTS FOR "HOME & KITCHEN" ---
  final List<Product> _categoryProducts = [
    Product(id: 'hk1', name: 'Manual Compact High-Velocity Vegetable Chopper', price: 349, imageUrls: ['https://images.unsplash.com/photo-1581622558667-3419a8dc5f83?w=400&q=80'], productId: 'hk1', category: 'Home & Kitchen'),
    Product(id: 'hk2', name: 'Digital Air Fryer (4.2L Rapid Heat)', price: 4999, imageUrls: ['https://images.unsplash.com/photo-1626806819282-2c1dc01a5e0c?w=400&q=80'], productId: 'hk2', category: 'Home & Kitchen'),
    Product(id: 'hk3', name: 'Stainless Steel Cookware Set (5 Pieces)', price: 1499, imageUrls: ['https://images.unsplash.com/photo-1584992236310-6edddc08acff?w=400&q=80'], productId: 'hk3', category: 'Home & Kitchen'),
    Product(id: 'hk4', name: 'Automatic Drip Espresso Coffee Maker', price: 2199, imageUrls: ['https://images.unsplash.com/photo-1519681393784-d120267933ba?w=400&q=80'], productId: 'hk4', category: 'Home & Kitchen'),
    Product(id: 'hk5', name: 'Non-Stick Frying Pan (24cm with Lid)', price: 799, imageUrls: ['https://images.unsplash.com/photo-1583778176476-4a8b02a64c01?w=400&q=80'], productId: 'hk5', category: 'Home & Kitchen'),
    Product(id: 'hk6', name: 'Electric Kettle (1.8L Premium Auto-Cutoff)', price: 899, imageUrls: ['https://images.unsplash.com/photo-1574269909862-7e1d70bb8078?w=400&q=80'], productId: 'hk6', category: 'Home & Kitchen'),
    Product(id: 'hk7', name: 'Premium Teak Wood Cutting Board', price: 549, imageUrls: ['https://images.unsplash.com/photo-1593010996841-f67f259de4b7?w=400&q=80'], productId: 'hk7', category: 'Home & Kitchen'),
    Product(id: 'hk8', name: 'Silicone Cooking Utensils Set (12 Pcs)', price: 999, imageUrls: ['https://images.unsplash.com/photo-1590794056226-79ef3a8147e1?w=400&q=80'], productId: 'hk8', category: 'Home & Kitchen'),
    Product(id: 'hk9', name: 'Microwave Safe Glass Bowls (Set of 3)', price: 449, imageUrls: ['https://images.unsplash.com/photo-1622484211148-52f1b1c676d0?w=400&q=80'], productId: 'hk9', category: 'Home & Kitchen'),
    Product(id: 'hk10', name: 'Heavy Duty Mixer Grinder (750W)', price: 2499, imageUrls: ['https://images.unsplash.com/photo-1570222094114-d054a817e56b?w=400&q=80'], productId: 'hk10', category: 'Home & Kitchen'),
    Product(id: 'hk11', name: 'Stainless Steel Insulated Water Bottle (1L)', price: 699, imageUrls: ['https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=400&q=80'], productId: 'hk11', category: 'Home & Kitchen'),
    Product(id: 'hk12', name: 'Digital Kitchen Weighing Scale', price: 299, imageUrls: ['https://images.unsplash.com/photo-1586716402203-79219bede43c?w=400&q=80'], productId: 'hk12', category: 'Home & Kitchen'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F4C5C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            color: Color(0xFF0F4C5C),
            fontFamily: 'Times New Roman',
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: Column(
        children: [
          // --- SORT & FILTER BAR ---
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.symmetric(horizontal: BorderSide(color: Colors.grey.shade300, width: 1.5)),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.swap_vert, color: Colors.teal.shade700, size: 20),
                          const SizedBox(width: 8),
                          const Text('Sort: ', style: TextStyle(color: Color(0xFF0F4C5C), fontSize: 14)),
                          const Text('Popular', style: TextStyle(color: Color(0xFF0F4C5C), fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  VerticalDivider(color: Colors.grey.shade300, thickness: 1.5, width: 1),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.tune, color: Colors.grey.shade600, size: 20),
                          const SizedBox(width: 8),
                          Text('Filter', style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- PRODUCTS GRID ---
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _databaseService.getProducts(),
              builder: (context, snapshot) {
                // Use live data if available, otherwise use our 12 items!
                List<Product> productsToDisplay = (snapshot.hasData && snapshot.data!.isNotEmpty)
                    ? snapshot.data!.where((p) => p.category == widget.categoryName).toList()
                    : _categoryProducts;

                // If Firestore is connected but has no Home & Kitchen items, default back to our 12 dummy items.
                if (productsToDisplay.isEmpty) productsToDisplay = _categoryProducts;

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: productsToDisplay.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.52,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                  ),
                  itemBuilder: (context, index) {
                    return _buildCategoryProductCard(productsToDisplay[index], index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- UPDATED PRODUCT CARD FOR CATEGORY SCREEN ---
  Widget _buildCategoryProductCard(Product product, int index) {
    final String safeId = (product.id.toString().isNotEmpty && product.id.toString() != "null") ? product.id.toString() : product.name;
    final bool isFavorite = widget.wishlistIds.contains(safeId);

    // Fake dynamic stats based on index to make UI look realistic
    final double rating = 4.0 + (index % 10) / 10.0;
    final int reviews = 100 + (index * 133);
    final int originalPrice = (product.price * 1.4).round();
    final int discountPercent = ((originalPrice - product.price) / originalPrice * 100).round();

    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: Colors.grey.shade100)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Container(width: double.infinity, color: Colors.grey.shade50, child: Image.network(product.imageUrls[0], fit: BoxFit.cover))
                ),
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: () {
                      // 1. Update the master wishlist data in MainScreen
                      widget.onToggleWishlist(safeId, product.name);

                      // 2. NEW FIX: Tell THIS screen to redraw instantly
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                      child: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.pinkAccent : Colors.white, size: 16),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF047857), borderRadius: BorderRadius.circular(4)),
                    child: Text('$discountPercent% OFF', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 5, // Given slightly more space for the extra text
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.2)),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Color(0xFFF59E0B), size: 10),
                            const SizedBox(width: 2),
                            Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('($reviews)', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹${product.price}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Text('₹$originalPrice', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, decoration: TextDecoration.lineThrough)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text('Inclusive of all taxes', style: TextStyle(color: Color(0xFF047857), fontSize: 9, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}