import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart'; // <-- IMPORTED QR PACKAGE
import '../models/product_model.dart';
import '../services/database_service.dart';
import 'write_review_screen.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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

  final List<Product> _fallbackSimilarProducts = [
    Product(id: 's1', name: 'Premium Copper Water Bottle (1L)', price: 899, imageUrls: ['https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=400&q=80'], productId: 's1', category: 'Home & Kitchen'),
    Product(id: 's2', name: 'Digital Kitchen Weighing Scale', price: 299, imageUrls: ['https://images.unsplash.com/photo-1586716402203-79219bede43c?w=400&q=80'], productId: 's2', category: 'Home & Kitchen'),
    Product(id: 's3', name: 'Silicone Cooking Utensils Set (12 Pcs)', price: 999, imageUrls: ['https://images.unsplash.com/photo-1590794056226-79ef3a8147e1?w=400&q=80'], productId: 's3', category: 'Home & Kitchen'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _shareProduct(Product liveProduct) {
    final String shareText = "Check out this amazing product on Decart!\n\n"
        "${liveProduct.name}\n"
        "Price: ₹${liveProduct.price.toInt()}\n\n"
        "View it here: https://decart.app/product/${liveProduct.id}";
    Share.share(shareText);
  }

  // --- NEW: GENERATES A PNG OF THE QR CODE AND SHARES IT ---
  Future<void> _shareQRCodeImage(Product liveProduct) async {
    try {
      final String productLink = "https://decart.app/product/${liveProduct.id}";

      // 1. Generate the QR Code as an image painter
      final qrPainter = QrPainter(
        data: productLink,
        version: QrVersions.auto,
        gapless: true,
        color: const Color(0xFF000000), // Black QR blocks
        emptyColor: const Color(0xFFFFFFFF), // White background
      );

      // 2. Convert to raw PNG image data (1024x1024 resolution)
      final picData = await qrPainter.toImageData(1024, format: ui.ImageByteFormat.png);
      if (picData == null) return;

      // 3. Save it to a temporary file on the device
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/decart_product_qr.png').create();
      await file.writeAsBytes(picData.buffer.asUint8List());

      // 4. Share the image file natively
      await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Scan this QR to view ${liveProduct.name} on Decart!'
      );
    } catch (e) {
      debugPrint("Error sharing QR: $e");
    }
  }


  void _showQRCode(Product liveProduct) {
    final String productLink = "https://decart.app/product/${liveProduct.id}";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            children: [
              Text("Scan to view", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: brandColor)),
              const SizedBox(height: 4),
              Text(
                  liveProduct.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)
              ),
            ],
          ),
          content: SizedBox(
            width: 250,
            height: 250,
            child: Center(
              child: QrImageView(
                data: productLink,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black87),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black87),
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context); // Close the popup
                _shareQRCodeImage(liveProduct); // <-- CALLS THE NEW IMAGE SHARING LOGIC!
              },
              icon: Icon(Icons.share_outlined, color: brandColor, size: 20),
              label: Text("Share QR", style: TextStyle(color: brandColor, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
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
        final Product liveProduct = snapshot.data ?? widget.product;

        List<String> galleryImages = List.from(liveProduct.imageUrls);
        if (galleryImages.length == 1) {
          galleryImages.addAll([liveProduct.imageUrls[0], liveProduct.imageUrls[0], liveProduct.imageUrls[0]]);
        }
        int displayIndex = math.min(_currentImageIndex, galleryImages.isNotEmpty ? galleryImages.length - 1 : 0);

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
              // --- NEW: QR CODE BUTTON ---
              IconButton(
                icon: Icon(Icons.qr_code_scanner, color: brandColor),
                onPressed: () => _showQRCode(liveProduct),
              ),
              IconButton(
                  icon: Icon(Icons.share_outlined, color: brandColor),
                  onPressed: () => _shareProduct(liveProduct)
              ),
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
                // --- 1. IMAGE SLIDER ---
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

                // --- 2. TITLE, PRICE, AND TABS ---
                Container(
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(liveProduct.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Times New Roman')),
                            const SizedBox(height: 8),
                            Text(liveProduct.inStock ? 'IN STOCK' : 'OUT OF STOCK', style: TextStyle(color: liveProduct.inStock ? const Color(0xFF059669) : Colors.red, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('₹${liveProduct.price.toInt()}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                if (originalPrice > liveProduct.price)
                                  Text('₹$originalPrice', style: TextStyle(fontSize: 16, color: Colors.grey.shade500, decoration: TextDecoration.lineThrough)),
                                const SizedBox(width: 8),
                                if (discountPercent > 0)
                                  Text('($discountPercent% OFF)', style: const TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(height: 8, color: Colors.grey.shade100),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _buildTab(0, 'Overview'),
                            _buildTab(1, 'Features'),
                          ],
                        ),
                      ),
                      Container(height: 1, color: Colors.grey.shade300),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _selectedTab == 0 ? liveProduct.description : liveProduct.features,
                          style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                        ),
                      ),
                      Container(height: 8, color: Colors.grey.shade100),
                    ],
                  ),
                ),

                // --- 3. SIMILAR PRODUCTS ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: const Text('SIMILAR PRODUCTS', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
                ),
                SizedBox(
                  height: 240,
                  child: StreamBuilder<List<Product>>(
                    stream: _databaseService.getProductsByCategory(liveProduct.category),
                    builder: (context, suggestionSnapshot) {
                      List<Product> similarProducts = [];
                      if (suggestionSnapshot.hasData && suggestionSnapshot.data!.isNotEmpty) {
                        similarProducts = suggestionSnapshot.data!.where((p) => p.id != liveProduct.id).toList();
                      }
                      if (similarProducts.isEmpty) similarProducts = List.from(_fallbackSimilarProducts);

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

                Container(height: 8, color: Colors.grey.shade100),

                // --- 4. DYNAMIC REVIEWS SECTION ---
                _buildReviewsSection(liveProduct),

                Container(height: 8, color: Colors.grey.shade100),

                // --- 5. BROWSING HISTORY SECTION ---
                _buildBrowsingHistorySection(),

                const SizedBox(height: 60),
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

  // =========================================================================
  // BROWSING HISTORY WIDGET
  // =========================================================================
  Widget _buildBrowsingHistorySection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Text('Your browsing history', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {},
                  child: Text('View or edit your browsing history', style: TextStyle(color: Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: StreamBuilder<List<Product>>(
              stream: _databaseService.getProducts(),
              builder: (context, snapshot) {
                List<Product> historyProducts = [];
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  historyProducts = snapshot.data!.toList();
                  historyProducts.shuffle();
                } else {
                  historyProducts = List.from(_fallbackSimilarProducts);
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: historyProducts.length,
                  itemBuilder: (context, index) {
                    final historyProduct = historyProducts[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailsScreen(
                              product: historyProduct,
                              wishlistIds: widget.wishlistIds,
                              onToggleWishlist: widget.onToggleWishlist,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 110,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            historyProduct.imageUrls.isNotEmpty ? historyProduct.imageUrls[0] : '',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // REVIEWS SECTION WIDGETS
  // =========================================================================
  Widget _buildReviewsSection(Product product) {
    return StreamBuilder<QuerySnapshot>(
      stream: _databaseService.getProductReviews(product.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
        }

        final docs = snapshot.data?.docs ?? [];
        double avgRating = 0.0;
        List<int> starCounts = [0, 0, 0, 0, 0]; // 1-star to 5-star

        if (docs.isNotEmpty) {
          double totalRating = 0;
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final r = (data['rating'] as num?)?.toDouble() ?? 0.0;
            totalRating += r;
            if (r >= 1 && r <= 5) {
              starCounts[r.floor() - 1]++;
            }
          }
          avgRating = totalRating / docs.length;
        }

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Customer reviews', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // Summary Header
              Row(
                children: [
                  _buildStars(avgRating),
                  const SizedBox(width: 8),
                  Text('${avgRating.toStringAsFixed(1)} out of 5', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text('${docs.length} global ratings', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              const SizedBox(height: 16),

              // Progress Bars
              for (int i = 5; i >= 1; i--)
                _buildRatingBar(i, docs.isEmpty ? 0 : (starCounts[i - 1] / docs.length)),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Write Review Block
              const Text('Review this product', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Share your thoughts with other customers', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => WriteReviewScreen(product: product)));
                  },
                  child: const Text('Write a product review', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),

              // User Reviews List
              if (docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text("No reviews yet. Be the first to review!", style: TextStyle(color: Colors.grey))),
                )
              else ...[
                const SizedBox(height: 16),
                const Text('Top reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (c, i) => const Divider(height: 40),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildSingleReview(data);
                  },
                )
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _buildSingleReview(Map<String, dynamic> data) {
    final String name = data['userName'] ?? 'Amazon Customer';
    final double rating = (data['rating'] as num?)?.toDouble() ?? 5.0;
    final String title = data['title'] ?? '';
    final String desc = data['description'] ?? '';
    final Timestamp? timestamp = data['date'] as Timestamp?;
    final String dateString = timestamp != null ? DateFormat('d MMMM yyyy').format(timestamp.toDate()) : 'Recently';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(radius: 16, backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white, size: 20)),
            const SizedBox(width: 8),
            Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStars(rating, size: 14),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        const SizedBox(height: 4),
        Text('Reviewed in India on $dateString', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 12),
        Text(desc, style: const TextStyle(height: 1.4)),
        const SizedBox(height: 16),
        Row(
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(80, 32),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {},
              child: const Text('Helpful', style: TextStyle(color: Colors.black87, fontSize: 12)),
            ),
            const SizedBox(width: 16),
            const Text('|', style: TextStyle(color: Colors.grey)),
            const SizedBox(width: 16),
            const Text('Report', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildStars(double rating, {double size = 20}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) return Icon(Icons.star, color: Colors.orange, size: size);
        if (index < rating) return Icon(Icons.star_half, color: Colors.orange, size: size);
        return Icon(Icons.star_border, color: Colors.orange, size: size);
      }),
    );
  }

  Widget _buildRatingBar(int star, double percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$star star', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w500, fontSize: 12)),
          const SizedBox(width: 12),
          Expanded(
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.grey.shade200,
              color: Colors.orange,
              minHeight: 12,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: Text('${(percent * 100).toInt()}%', style: TextStyle(color: Colors.teal.shade700, fontSize: 12), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // HELPER WIDGETS
  // =========================================================================

  Widget _buildSimilarProductCard(Product product) {
    final bool isFavorite = widget.wishlistIds.contains(product.id);
    final double rating = 4.0 + (product.name.length % 10) / 10.0;
    final int originalPrice = product.originalPrice != null ? product.originalPrice!.round() : (product.price * 1.4).round();

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailsScreen(product: product, wishlistIds: widget.wishlistIds, onToggleWishlist: widget.onToggleWishlist)));
      },
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 3))], border: Border.all(color: Colors.grey.shade100)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: Container(width: double.infinity, color: Colors.grey.shade50, child: Image.network(product.imageUrls.isNotEmpty ? product.imageUrls[0] : '', fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image, color: Colors.grey)))),
                  Positioned(top: 6, right: 6, child: GestureDetector(onTap: () { widget.onToggleWishlist(product.id, product.name); setState(() {}); }, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle), child: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.pinkAccent : Colors.white, size: 14)))),
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
                    Row(children: [const Icon(Icons.star, color: Color(0xFFF59E0B), size: 10), const SizedBox(width: 4), Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309)))]),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [Text('₹${product.price.toInt()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), const SizedBox(width: 4), if (originalPrice > product.price) Text('₹$originalPrice', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, decoration: TextDecoration.lineThrough))],
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
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 20)));
  }

  Widget _buildTab(int index, String title) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isSelected ? const Color(0xFF047857) : Colors.transparent, width: 3))),
          child: Text(title, textAlign: TextAlign.center, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF047857) : Colors.grey.shade500, fontSize: 14)),
        ),
      ),
    );
  }
}