import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/database_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final DatabaseService _databaseService = DatabaseService();
  final PageController _pageController = PageController();
  int _currentBannerIndex = 0;

  // Banner Content Data
  final List<Map<String, dynamic>> _banners = [
    {
      'tag': 'BEAUTY CARE SPECTACULAR',
      'title': 'FLAT 40% OFF',
      'subtitle': 'Organic Serums, Creams & Cosmetics Brands',
      'colors': [const Color(0xFF04483C), const Color(0xFFDCA128)],
    },
    {
      'tag': 'MAKER & DEV GEAR',
      'title': 'IOT & SENSORS',
      'subtitle': 'Raspberry Pi, Power Sensors & Camera Modules',
      'colors': [const Color(0xFF1E3A8A), const Color(0xFF9333EA)],
    },
    {
      'tag': 'SMART HOME',
      'title': 'UP TO 50% OFF',
      'subtitle': 'Automated Cleaning & Tracking Systems',
      'colors': [const Color(0xFF7F1D1D), const Color(0xFFEA580C)],
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildBannerSection(),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Container(width: 3, height: 16, color: Colors.orangeAccent),
                const SizedBox(width: 8),
                const Text(
                  'TRENDING PRODUCTS',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontFamily: 'Times New Roman'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Product>>(
            stream: _databaseService.getProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No products found in database."));

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  Product product = snapshot.data![index];
                  return ListTile(
                    title: Text(product.name),
                    subtitle: Text("₹${product.price.toString()}"),
                    leading: product.imageUrls.isNotEmpty
                        ? Image.network(product.imageUrls[0], width: 50, errorBuilder: (c, e, s) => const Icon(Icons.broken_image))
                        : const Icon(Icons.image),
                  );
                },
              );
            },
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
                                child: Text(
                                  banner['tag'],
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                banner['title'],
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Times New Roman'),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                banner['subtitle'],
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontStyle: FontStyle.italic),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Colors.pinkAccent, Colors.redAccent]),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Shop Now', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                                  ],
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
                                  width: 80,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                                  ),
                                  child: const Center(
                                    child: Text('DECÁRT', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.5)),
                                  ),
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
                  onTap: () {
                    if (_currentBannerIndex > 0) {
                      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    }
                  },
                  child: CircleAvatar(
                    radius: 12, backgroundColor: Colors.black.withOpacity(0.3),
                    child: const Icon(Icons.keyboard_arrow_left, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8, top: 0, bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_currentBannerIndex < _banners.length - 1) {
                      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    }
                  },
                  child: CircleAvatar(
                    radius: 12, backgroundColor: Colors.black.withOpacity(0.3),
                    child: const Icon(Icons.keyboard_arrow_right, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12, right: 24,
              child: Row(
                children: List.generate(_banners.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(left: 4),
                    height: 6,
                    width: _currentBannerIndex == index ? 16 : 6,
                    decoration: BoxDecoration(
                      color: _currentBannerIndex == index ? Colors.white : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
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