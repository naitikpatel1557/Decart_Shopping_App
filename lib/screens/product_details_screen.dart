import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import '../models/product_model.dart';
import '../services/database_service.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  final Set<String> wishlistIds;
  final Function(String, String) onToggleWishlist;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.wishlistIds,
    required this.onToggleWishlist,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final Color brandColor = const Color(0xFF0F4C5C);
  final PageController _pageController = PageController();
  final DatabaseService _databaseService = DatabaseService();

  int _currentImageIndex = 0;
  int _selectedTab = 0;
  bool _isAddingToCart = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _addToCart(String liveName, int livePrice, String liveImageUrl) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to add items to your cart.')));
      return;
    }

    setState(() => _isAddingToCart = true);

    try {
      final cartRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('cart').doc(widget.product.id);
      final docSnapshot = await cartRef.get();

      if (docSnapshot.exists) {
        await cartRef.update({'quantity': FieldValue.increment(1)});
      } else {
        await cartRef.set({
          'productId': widget.product.id,
          'name': liveName,
          'price': livePrice,
          'imageUrl': liveImageUrl,
          'quantity': 1,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Cart! 🛒'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add to cart: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isFavorite = widget.wishlistIds.contains(widget.product.id);

    return StreamBuilder<Product>(
      stream: _databaseService.getProductDetails(widget.product.id),
      builder: (context, snapshot) {

        // Render with live Firebase data, or fall back to the passed product if loading
        final Product liveProduct = snapshot.data ?? widget.product;

        List<String> galleryImages = List.from(liveProduct.imageUrls);
        if (galleryImages.length == 1) {
          galleryImages.addAll([liveProduct.imageUrls[0], liveProduct.imageUrls[0], liveProduct.imageUrls[0]]);
        }
        int displayIndex = math.min(_currentImageIndex, galleryImages.isNotEmpty ? galleryImages.length - 1 : 0);

        final double rating = 4.0 + (liveProduct.name.length % 10) / 10.0;
        final int reviews = 100 + ((liveProduct.price.toInt() % 50) * 13);

        final int originalPrice = liveProduct.originalPrice != null
            ? liveProduct.originalPrice!.round()
            : (liveProduct.price * 1.66).round();

        final int discountPercent = originalPrice > 0 ? ((originalPrice - liveProduct.price) / originalPrice * 100).round() : 0;

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(icon: Icon(Icons.arrow_back, color: brandColor), onPressed: () => Navigator.pop(context)),
            actions: [
              IconButton(icon: Icon(Icons.share_outlined, color: brandColor), onPressed: () {}),
              IconButton(
                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.pinkAccent : brandColor),
                onPressed: () {
                  widget.onToggleWishlist(liveProduct.id, liveProduct.name);
                  setState(() {});
                },
              ),
              IconButton(icon: Icon(Icons.shopping_cart_outlined, color: brandColor), onPressed: () {}),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- IMAGE SLIDER ---
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 280,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PageView.builder(
                              controller: _pageController,
                              itemCount: galleryImages.length,
                              onPageChanged: (index) => setState(() => _currentImageIndex = index),
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      galleryImages[index],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                    ),
                                  ),
                                );
                              },
                            ),
                            Positioned(left: 24, child: _buildArrowButton(Icons.arrow_back, () {
                              if (_currentImageIndex > 0) _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                            })),
                            Positioned(right: 24, child: _buildArrowButton(Icons.arrow_forward, () {
                              if (_currentImageIndex < galleryImages.length - 1) _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                            })),
                            Positioned(
                              bottom: 12, right: 28,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
                                child: Text('${displayIndex + 1} / ${galleryImages.length} Photos', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(galleryImages.length, (index) {
                            bool isSelected = displayIndex == index;
                            return GestureDetector(
                              onTap: () => _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                width: 50, height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isSelected ? Colors.pinkAccent : Colors.grey.shade300, width: isSelected ? 2 : 1),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(galleryImages[index], fit: BoxFit.cover, opacity: isSelected ? null : const AlwaysStoppedAnimation(0.6)),
                                ),
                              ),
                            );
                          }),
                        ),
                      )
                    ],
                  ),
                ),

                // --- PRODUCT TITLE & RATING ---
                Container(
                  color: Colors.grey.shade50,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(liveProduct.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Times New Roman')),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFFBBF24), borderRadius: BorderRadius.circular(6)),
                            child: Row(
                              children: [
                                Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                                const SizedBox(width: 4),
                                const Icon(Icons.star, size: 12, color: Colors.black87),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('$reviews verified reviews', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          const SizedBox(width: 16),
                          Text(liveProduct.inStock ? 'IN STOCK' : 'OUT OF STOCK', style: TextStyle(color: liveProduct.inStock ? const Color(0xFF059669) : Colors.red, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
                        ],
                      ),
                    ],
                  ),
                ),

                // --- PRICING BOX ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('₹${liveProduct.price.toInt()}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                if (originalPrice > liveProduct.price)
                                  Text('₹$originalPrice', style: TextStyle(fontSize: 14, color: Colors.grey.shade500, decoration: TextDecoration.lineThrough)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Inclusive of all taxes', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        ),
                        if (discountPercent > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
                            child: Column(
                              children: [
                                Text('$discountPercent% OFF', style: const TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 12)),
                                const Text('SPECIAL SAVE', style: TextStyle(color: Color(0xFF047857), fontSize: 8)),
                              ],
                            ),
                          )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- TABS & DETAILS SECTION ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildTab(0, 'Product Overview'),
                      _buildTab(1, 'Details & Features'),
                    ],
                  ),
                ),
                Container(height: 1, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 16)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _selectedTab == 0 ? liveProduct.description : liveProduct.features,
                    style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 16),

                // --- SUGGESTED PRODUCTS ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Text('SIMILAR PRODUCTS', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 240,
                  child: StreamBuilder<List<Product>>(
                    stream: _databaseService.getProductsByCategory(liveProduct.category),
                    builder: (context, suggestionSnapshot) {
                      List<Product> similarProducts = [];

                      if (suggestionSnapshot.hasData && suggestionSnapshot.data!.isNotEmpty) {
                        similarProducts = suggestionSnapshot.data!.where((p) => p.id != liveProduct.id).toList();
                      }

                      if (similarProducts.isEmpty) {
                        return const Center(child: Text("No similar items found.", style: TextStyle(color: Colors.grey)));
                      }

                      similarProducts.shuffle();
                      similarProducts = similarProducts.take(10).toList();

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: similarProducts.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: SizedBox(
                              width: 150,
                              child: _buildSimilarProductCard(similarProducts[index]),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),

          // --- BOTTOM ACTION BUTTONS ---
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.purple, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isAddingToCart || !liveProduct.inStock ? null : () => _addToCart(liveProduct.name, liveProduct.price.toInt(), galleryImages.isNotEmpty ? galleryImages[0] : ''),
                      icon: _isAddingToCart
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purple))
                          : const Icon(Icons.shopping_bag_outlined, color: Colors.black87, size: 20),
                      label: Text(
                          _isAddingToCart ? 'Adding...' : 'Add to Cart',
                          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: liveProduct.inStock ? const Color(0xFF047857) : Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.credit_card, color: Colors.white, size: 20),
                      label: Text(liveProduct.inStock ? 'Buy Now' : 'Out of Stock', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      onPressed: liveProduct.inStock ? () {} : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- COMPACT CARD WIDGET FOR SUGGESTIONS ---
  Widget _buildSimilarProductCard(Product product) {
    final bool isFavorite = widget.wishlistIds.contains(product.id);
    final double rating = 4.0 + (product.name.length % 10) / 10.0;

    final int originalPrice = product.originalPrice != null
        ? product.originalPrice!.round()
        : (product.price * 1.4).round();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(
              product: product,
              wishlistIds: widget.wishlistIds,
              onToggleWishlist: (id, name) {
                widget.onToggleWishlist(id, name);
                setState(() {});
              },
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 3))],
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
                      child: Container(width: double.infinity, color: Colors.grey.shade50, child: Image.network(product.imageUrls.isNotEmpty ? product.imageUrls[0] : '', fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image, color: Colors.grey)))
                  ),
                  Positioned(
                    top: 6, right: 6,
                    child: GestureDetector(
                      onTap: () {
                        widget.onToggleWishlist(product.id, product.name);
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                        child: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.pinkAccent : Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.2)),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFF59E0B), size: 10),
                        const SizedBox(width: 4),
                        Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${product.price.toInt()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        if (originalPrice > product.price)
                          Text('₹$originalPrice', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, decoration: TextDecoration.lineThrough)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrowButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildTab(int index, String title) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isSelected ? const Color(0xFF047857) : Colors.transparent, width: 3)),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF047857) : Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}