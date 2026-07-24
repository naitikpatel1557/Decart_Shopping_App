import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/database_service.dart';

class SearchScreen extends StatefulWidget {
  final String searchQuery;
  final Set<String> wishlistIds;
  final Function(String, String) onToggleWishlist;

  const SearchScreen({
    super.key,
    required this.searchQuery,
    required this.wishlistIds,
    required this.onToggleWishlist,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final DatabaseService _databaseService = DatabaseService();
  late TextEditingController _searchController;
  late String _currentQuery;

  // --- FULL LIST OF PRODUCTS FOR SEARCH ---
  final List<Product> _fallbackProducts = [
    Product(id: '1', name: 'Stainless Steel Cookware Set (5 Pieces)', price: 1499, imageUrls: ['https://images.unsplash.com/photo-1584992236310-6edddc08acff?w=400&q=80'], productId: '1', category: 'Home & Kitchen'),
    Product(id: '2', name: 'Mixer Grinder (750W Powertron)', price: 2199, imageUrls: ['https://images.unsplash.com/photo-1570222094114-d054a817e56b?w=400&q=80'], productId: '2', category: 'Home & Kitchen'),
    Product(id: '3', name: 'Electric Kettle (1.8L Premium Auto-Cutoff)', price: 899, imageUrls: ['https://images.unsplash.com/photo-1574269909862-7e1d70bb8078?w=400&q=80'], productId: '3', category: 'Home & Kitchen'),
    Product(id: '4', name: 'Non-Stick Frying Pan (24cm with Lid)', price: 799, imageUrls: ['https://images.unsplash.com/photo-1583778176476-4a8b02a64c01?w=400&q=80'], productId: '4', category: 'Home & Kitchen'),

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
  void initState() {
    super.initState();
    _currentQuery = widget.searchQuery;
    _searchController = TextEditingController(text: _currentQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- NEW: Live search as the user types ---
  void _onSearchChanged(String query) {
    setState(() {
      _currentQuery = query.trim();
    });
  }

  // --- NEW: Close the keyboard when they hit "Enter" ---
  void _onSearchSubmitted(String query) {
    setState(() {
      _currentQuery = query.trim();
    });
    FocusManager.instance.primaryFocus?.unfocus();
  }

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
        title: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onChanged: _onSearchChanged,         // <-- Instantly filters list while typing
          onSubmitted: _onSearchSubmitted,     // <-- Dismisses keyboard on enter
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Search for products...',
            hintStyle: TextStyle(color: Colors.grey.shade400),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: _currentQuery.isEmpty
          ? _buildEmptyState("Enter a product name to search.")
          : _buildSearchResults(),
    );
  }

  Widget _buildSearchResults() {
    return StreamBuilder<List<Product>>(
      stream: _databaseService.getProducts(),
      builder: (context, snapshot) {

        List<Product> allProducts = _fallbackProducts;

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          if (snapshot.data!.length < _fallbackProducts.length) {
            allProducts = _fallbackProducts;
          } else {
            allProducts = snapshot.data!;
          }
        }

        // Filters the products based on the search query instantly
        List<Product> searchResults = allProducts.where((product) {
          return product.name.toLowerCase().contains(_currentQuery.toLowerCase()) ||
              product.category.toLowerCase().contains(_currentQuery.toLowerCase());
        }).toList();

        if (searchResults.isEmpty) {
          return _buildEmptyState("No results found for '$_currentQuery'\nTry checking your spelling or using different keywords.");
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                  "${searchResults.length} results found",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.bold)
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                itemCount: searchResults.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.52,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  return _buildProductCard(searchResults[index], index);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, int index) {
    final String safeId = (product.id.toString().isNotEmpty && product.id.toString() != "null") ? product.id.toString() : product.name;
    final bool isFavorite = widget.wishlistIds.contains(safeId);

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
                      widget.onToggleWishlist(safeId, product.name);
                      setState(() {}); // Instantly updates the heart icon UI
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
            flex: 5,
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