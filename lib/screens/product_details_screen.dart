import 'package:flutter/material.dart';
import '../models/product_model.dart';

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

  int _currentImageIndex = 0;
  int _selectedTab = 0; // 0 for Overview, 1 for Details & Features

  // We will generate fake gallery images for the demo if the product only has 1 image
  late List<String> _galleryImages;

  @override
  void initState() {
    super.initState();
    _galleryImages = List.from(widget.product.imageUrls);
    // If there's only 1 image, duplicate it for the gallery demo effect to match your screenshot
    if (_galleryImages.length == 1) {
      _galleryImages.addAll([
        widget.product.imageUrls[0],
        widget.product.imageUrls[0],
        widget.product.imageUrls[0],
        widget.product.imageUrls[0],
      ]);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String safeId = (widget.product.id.toString().isNotEmpty && widget.product.id.toString() != "null") ? widget.product.id.toString() : widget.product.name;
    final bool isFavorite = widget.wishlistIds.contains(safeId);

    // Dynamic fake stats for realism
    final double rating = 4.0 + (widget.product.name.length % 10) / 10.0;
    final int reviews = 100 + ((widget.product.price.toInt() % 50) * 13);
    final int originalPrice = (widget.product.price * 1.66).round(); // Simulates ~40% off
    final int discountPercent = ((originalPrice - widget.product.price) / originalPrice * 100).round();

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
              widget.onToggleWishlist(safeId, widget.product.name);
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
            // --- 1. IMAGE SLIDER & THUMBNAILS ---
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
                          itemCount: _galleryImages.length,
                          onPageChanged: (index) => setState(() => _currentImageIndex = index),
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(_galleryImages[index], fit: BoxFit.cover, width: double.infinity),
                              ),
                            );
                          },
                        ),
                        // Left/Right Arrows
                        Positioned(left: 24, child: _buildArrowButton(Icons.arrow_back, () {
                          if (_currentImageIndex > 0) _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        })),
                        Positioned(right: 24, child: _buildArrowButton(Icons.arrow_forward, () {
                          if (_currentImageIndex < _galleryImages.length - 1) _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        })),
                        // Photo Counter Badge
                        Positioned(
                          bottom: 12, right: 28,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
                            child: Text('${_currentImageIndex + 1} / ${_galleryImages.length} Photos', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Thumbnails Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_galleryImages.length, (index) {
                        bool isSelected = _currentImageIndex == index;
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
                              child: Image.network(_galleryImages[index], fit: BoxFit.cover, opacity: isSelected ? null : const AlwaysStoppedAnimation(0.6)),
                            ),
                          ),
                        );
                      }),
                    ),
                  )
                ],
              ),
            ),

            // --- 2. PRODUCT TITLE & RATING ---
            Container(
              color: Colors.grey.shade50,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Times New Roman')),
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
                      const Text('IN STOCK', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
                    ],
                  ),
                ],
              ),
            ),

            // --- 3. PRICING BOX ---
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
                            Text('₹${widget.product.price}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Text('₹$originalPrice', style: TextStyle(fontSize: 14, color: Colors.grey.shade500, decoration: TextDecoration.lineThrough)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Inclusive of all taxes', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
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

            // --- 4. AVAILABLE OFFERS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AVAILABLE OFFERS', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.credit_card, color: Colors.pinkAccent, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Bank Offer: 10% Instant Discount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text('Get flat 10% off transaction values on leading credit cards (SBI, HDFC, ICICI). Min purchase ₹1,000.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.4)),
                            ],
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- 5. TABS & DETAILS SECTION ---
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
                _selectedTab == 0
                    ? 'High-quality food grade stainless steel base set that cooks foods evenly. Includes three induction-compatible pots and two frying pans. Premium durability with heat-resistant handles for comfortable grip and protection.'
                    : '• Material: Premium Stainless Steel\n• Compatibility: Induction & Gas Safe\n• Dishwasher Safe: Yes\n• Handle Type: Heat-resistant Bakelite\n• Warranty: 1 Year Manufacturer Warranty',
                style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 100), // Spacing for bottom bar
          ],
        ),
      ),

      // --- 6. BOTTOM ACTION BUTTONS ---
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
                  icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black87, size: 20),
                  label: const Text('Add to Cart', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF047857),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.credit_card, color: Colors.white, size: 20),
                  label: const Text('Buy Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  onPressed: () {},
                ),
              ),
            ],
          ),
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