import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/database_service.dart';

class WishlistTab extends StatefulWidget {
  final Set<String> wishlistIds;
  final Function(String, String) onToggleWishlist;

  const WishlistTab({
    super.key,
    required this.wishlistIds,
    required this.onToggleWishlist,
  });

  @override
  State<WishlistTab> createState() => _WishlistTabState();
}

class _WishlistTabState extends State<WishlistTab> {
  final DatabaseService _databaseService = DatabaseService();

  // Fallback products matching the home tab
  final List<Product> _fallbackProducts = [
    Product(id: '1', name: 'Stainless Steel Cookware Set (5 Pieces)', price: 1499, imageUrls: ['https://images.unsplash.com/photo-1584992236310-6edddc08acff?w=400&q=80'], productId: '', category: ''),
    Product(id: '2', name: 'Mixer Grinder (750W Powertron)', price: 2199, imageUrls: ['https://images.unsplash.com/photo-1570222094114-d054a817e56b?w=400&q=80'], productId: '', category: ''),
    Product(id: '3', name: 'Electric Kettle (1.8L Premium Auto-Cutoff)', price: 899, imageUrls: ['https://images.unsplash.com/photo-1574269909862-7e1d70bb8078?w=400&q=80'], productId: '', category: ''), // Fixed URL
    Product(id: '4', name: 'Non-Stick Frying Pan (24cm with Lid)', price: 799, imageUrls: ['https://images.unsplash.com/photo-1583778176476-4a8b02a64c01?w=400&q=80'], productId: '', category: ''),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HEADER ---
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            children: [
              Container(width: 3, height: 18, color: Colors.pinkAccent),
              const SizedBox(width: 8),
              const Text(
                'MY WISHLIST',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontFamily: 'Times New Roman'),
              ),
            ],
          ),
        ),

        // --- WISHLIST CONTENT ---
        Expanded(
          child: widget.wishlistIds.isEmpty
              ? _buildEmptyState()
              : _buildWishlistGrid(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("Your wishlist is empty", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Save items you love to view them later.", style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildWishlistGrid() {
    return StreamBuilder<List<Product>>(
      stream: _databaseService.getProducts(),
      builder: (context, snapshot) {
        List<Product> allProducts = _fallbackProducts;

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          allProducts = snapshot.data!;
        }

        // --- FIX: Filter products using the Safe ID logic ---
        List<Product> favoritedProducts = allProducts.where((product) {
          final String safeId = (product.id.toString().isNotEmpty && product.id.toString() != "null")
              ? product.id.toString()
              : product.name;

          return widget.wishlistIds.contains(safeId);
        }).toList();

        // If after filtering we have no products, show empty state
        if (favoritedProducts.isEmpty) return _buildEmptyState();

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          itemCount: favoritedProducts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.58,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            return _buildProductCard(favoritedProducts[index], index);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Product product, int index) {
    // --- FIX: Use the Safe ID for the card as well ---
    final String safeId = (product.id.toString().isNotEmpty && product.id.toString() != "null")
        ? product.id.toString()
        : product.name;

    final double rating = 4.0 + (index % 10) / 10.0;
    final int reviews = 100 + (index * 43);
    final int originalPrice = (product.price * 1.4).round();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
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
                  child: Container(
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    child: product.imageUrls.isNotEmpty
                        ? Image.network(product.imageUrls[0], fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey))
                        : const Icon(Icons.image, color: Colors.grey, size: 40),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => widget.onToggleWishlist(safeId, product.name),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                      child: const Icon(Icons.favorite, color: Colors.pinkAccent, size: 16), // Always pink in the wishlist view
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.2)),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Color(0xFFF59E0B), size: 10), const SizedBox(width: 2),
                            Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('($reviews)', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('₹${product.price}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('₹$originalPrice', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, decoration: TextDecoration.lineThrough)),
                        ],
                      ),
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