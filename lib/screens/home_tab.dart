import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/database_service.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback onNavigateToCategories;

  final Set<String> wishlistIds;
  final Function(String, String) onToggleWishlist;

  const HomeTab({
    super.key,
    required this.onNavigateToCategories,
    required this.wishlistIds,
    required this.onToggleWishlist,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final DatabaseService _databaseService = DatabaseService();
  final PageController _pageController = PageController();
  int _currentBannerIndex = 0;

  final List<Map<String, dynamic>> _banners = [
    {'tag': 'BEAUTY CARE', 'title': 'FLAT 40% OFF', 'subtitle': 'Organic Serums & Creams', 'colors': [const Color(0xFF04483C), const Color(0xFFDCA128)]},
    {'tag': 'MAKER GEAR', 'title': 'IOT SENSORS', 'subtitle': 'Power Sensors & Cameras', 'colors': [const Color(0xFF1E3A8A), const Color(0xFF9333EA)]},
  ];

  final List<Map<String, String>> _categories = [
    {'name': 'Home & Kitchen', 'imageUrl': 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=200&q=80'},
    {'name': 'Health & Personal...', 'imageUrl': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=200&q=80'},
    {'name': 'Office Product', 'imageUrl': 'https://images.unsplash.com/photo-1497215728101-856f4ea42174?w=200&q=80'},
    {'name': 'Toys & Baby Care', 'imageUrl': 'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?w=200&q=80'},
    {'name': 'Home Improvement', 'imageUrl': 'https://images.unsplash.com/photo-1581094794329-c8112a89af12?w=200&q=80'},
    {'name': 'Beauty', 'imageUrl': 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=200&q=80'},
  ];

  final List<Product> _fallbackProducts = [
    Product(id: '1', name: 'Stainless Steel Cookware Set (5 Pieces)', price: 1499, imageUrls: ['https://images.unsplash.com/photo-1584992236310-6edddc08acff?w=400&q=80'], productId: '', category: ''),
    Product(id: '2', name: 'Mixer Grinder (750W Powertron)', price: 2199, imageUrls: ['https://images.unsplash.com/photo-1570222094114-d054a817e56b?w=400&q=80'], productId: '', category: ''),
    Product(id: '3', name: 'Electric Kettle (1.8L Premium Auto-Cutoff)', price: 899, imageUrls: ['https://images.unsplash.com/photo-1574269909862-7e1d70bb8078?w=400&q=80'], productId: '', category: ''),
    Product(id: '4', name: 'Non-Stick Frying Pan (24cm with Lid)', price: 799, imageUrls: ['https://images.unsplash.com/photo-1583778176476-4a8b02a64c01?w=400&q=80'], productId: '', category: ''),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16), _buildBannerSection(), const SizedBox(height: 24),

          // Categories Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [Container(width: 3, height: 16, color: Colors.orangeAccent), const SizedBox(width: 8), const Text('CATEGORIES', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontFamily: 'Times New Roman'))]),
                GestureDetector(onTap: widget.onNavigateToCategories, child: const Row(children: [Text('See All', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)), SizedBox(width: 4), Icon(Icons.arrow_forward, size: 14)])),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- FIXED: Updated aspect ratio to 0.85 to completely prevent vertical overflow ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.85, // Fixed ratio to provide ample vertical room
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 12
              ),
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade100),
                        child: ClipOval(child: Image.network(_categories[index]['imageUrl']!, fit: BoxFit.cover))
                    ),
                    const SizedBox(height: 8),
                    Text(
                        _categories[index]['name']!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.2)
                    )
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 32),
          // Trending Products Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(children: [Container(width: 3, height: 16, color: Colors.orangeAccent), const SizedBox(width: 8), const Text('TRENDING PRODUCTS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontFamily: 'Times New Roman'))]),
          ),
          const SizedBox(height: 16),
          // Products Grid
          StreamBuilder<List<Product>>(
            stream: _databaseService.getProducts(),
            builder: (context, snapshot) {
              List<Product> productsToDisplay = (snapshot.hasData && snapshot.data!.isNotEmpty) ? snapshot.data! : _fallbackProducts;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GridView.builder(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: productsToDisplay.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.58, crossAxisSpacing: 12, mainAxisSpacing: 16),
                  itemBuilder: (context, index) => _buildProductCard(productsToDisplay[index], index),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, int index) {
    final String safeId = (product.id.toString().isNotEmpty && product.id.toString() != "null") ? product.id.toString() : product.name;
    final bool isFavorite = widget.wishlistIds.contains(safeId);
    final double rating = 4.0 + (index % 10) / 10.0;
    final int reviews = 100 + (index * 43);
    final int originalPrice = (product.price * 1.4).round();

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: Container(width: double.infinity, color: Colors.grey.shade100, child: Image.network(product.imageUrls[0], fit: BoxFit.cover))),
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: () => widget.onToggleWishlist(safeId, product.name),
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
                    child: const Text('40% OFF', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
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
                crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('₹${product.price}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('₹$originalPrice', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, decoration: TextDecoration.lineThrough))
                          ]
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFD1FAE5).withOpacity(0.5), borderRadius: BorderRadius.circular(4)),
                        child: const Text('In Stock', style: TextStyle(color: Color(0xFF059669), fontSize: 10, fontWeight: FontWeight.bold)),
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

  Widget _buildBannerSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        height: 180,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentBannerIndex = index;
                  });
                },
                itemCount: _banners.length,
                itemBuilder: (context, index) {
                  final banner = _banners[index];
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: banner['colors'],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(banner['tag'], style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                              ),
                              const SizedBox(height: 8),
                              Text(banner['title'], style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Times New Roman')),
                              const SizedBox(height: 4),
                              Text(banner['subtitle'], style: const TextStyle(color: Colors.white, fontSize: 11, fontStyle: FontStyle.italic)),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.pinkAccent, Colors.redAccent]), borderRadius: BorderRadius.circular(20)),
                                child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [Text('Shop Now', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)), SizedBox(width: 4), Icon(Icons.arrow_forward, color: Colors.white, size: 14)]
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform.rotate(
                                angle: 0.15,
                                child: Container(
                                    width: 80, height: 100,
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.3), width: 1)),
                                    child: const Center(child: Text('DECÁRT', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.5)))
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: 8, top: 0, bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () { if (_currentBannerIndex > 0) _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); },
                  child: CircleAvatar(radius: 0, backgroundColor: Colors.black.withOpacity(0.3), child: const Icon(Icons.keyboard_arrow_left, color: Colors.white, size: 16)),
                ),
              ),
            ),
            Positioned(
              right: 20, top: 0, bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () { if (_currentBannerIndex < _banners.length - 1) _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); },
                  child: CircleAvatar(radius: 0, backgroundColor: Colors.black.withOpacity(0.3), child: const Icon(Icons.keyboard_arrow_right, color: Colors.white, size: 16)),
                ),
              ),
            ),
            Positioned(
              bottom: 12, right: 24,
              child: Row(
                children: List.generate(_banners.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200), margin: const EdgeInsets.only(left: 4), height: 6, width: _currentBannerIndex == index ? 16 : 6,
                    decoration: BoxDecoration(color: _currentBannerIndex == index ? Colors.white : Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(3)),
                  );
                }),
              ),
            )
          ],
        ),
      ),
    );
  }
}