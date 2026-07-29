import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/database_service.dart';
import 'product_details_screen.dart';

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
  final Color brandColor = const Color(0xFF0F4C5C);

  String _selectedSort = 'Bestselling';
  RangeValues _priceRange = const RangeValues(0, 10000);
  final double _maxPriceLimit = 10000;

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Sort By', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildSortOption('Bestselling'),
              _buildSortOption('Price: Low to High'),
              _buildSortOption('Price: High to Low'),
              _buildSortOption('Avg. Customer Review'),
              _buildSortOption('Newest Arrivals'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String title) {
    return ListTile(
      title: Text(title, style: TextStyle(fontWeight: _selectedSort == title ? FontWeight.bold : FontWeight.normal)),
      trailing: _selectedSort == title ? Icon(Icons.check_circle, color: brandColor) : null,
      onTap: () {
        setState(() => _selectedSort = title);
        Navigator.pop(context);
      },
    );
  }

  void _showFilterBottomSheet() {
    RangeValues tempRange = _priceRange;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Price Range', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₹${tempRange.start.toInt()}', style: TextStyle(color: brandColor, fontWeight: FontWeight.bold)),
                      Text(tempRange.end >= _maxPriceLimit ? '₹${_maxPriceLimit.toInt()}+' : '₹${tempRange.end.toInt()}', style: TextStyle(color: brandColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  RangeSlider(
                    values: tempRange,
                    min: 0,
                    max: _maxPriceLimit,
                    divisions: 100,
                    activeColor: brandColor,
                    inactiveColor: Colors.grey.shade300,
                    onChanged: (RangeValues values) {
                      setModalState(() => tempRange = values);
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        setState(() => _priceRange = tempRange);
                        Navigator.pop(context);
                      },
                      child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getShortSortLabel() {
    switch (_selectedSort) {
      case 'Price: Low to High': return 'Low to High';
      case 'Price: High to Low': return 'High to Low';
      case 'Avg. Customer Review': return 'Top Reviews';
      case 'Newest Arrivals': return 'Newest';
      default: return 'Bestselling';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: brandColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryName,
          style: TextStyle(color: brandColor, fontFamily: 'Times New Roman', fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.symmetric(horizontal: BorderSide(color: Colors.grey.shade300, width: 1.5)),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _showSortBottomSheet,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.swap_vert, color: Colors.teal.shade700, size: 20),
                            const SizedBox(width: 8),
                            const Text('Sort: ', style: TextStyle(color: Color(0xFF0F4C5C), fontSize: 14)),
                            Flexible(
                              child: Text(
                                _getShortSortLabel(),
                                style: const TextStyle(color: Color(0xFF0F4C5C), fontSize: 14, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  VerticalDivider(color: Colors.grey.shade300, thickness: 1.5, width: 1),
                  Expanded(
                    child: InkWell(
                      onTap: _showFilterBottomSheet,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.tune, color: brandColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Filter',
                              style: TextStyle(
                                color: brandColor,
                                fontSize: 14,
                                fontWeight: (_priceRange.start > 0 || _priceRange.end < _maxPriceLimit) ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _databaseService.getProductsByCategory(widget.categoryName),
              builder: (context, snapshot) {

                // --- NEW: CATCHES FIREBASE ERRORS AND PRINTS THEM ---
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Firebase Error: ${snapshot.error}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<Product> rawProducts = snapshot.data ?? [];

                if (rawProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text("No products found in this category.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                List<Product> productsToDisplay = rawProducts.where((p) {
                  bool withinHigh = _priceRange.end >= _maxPriceLimit ? true : p.price <= _priceRange.end;
                  bool withinLow = p.price >= _priceRange.start;
                  return withinLow && withinHigh;
                }).toList();

                if (_selectedSort == 'Price: Low to High') {
                  productsToDisplay.sort((a, b) => a.price.compareTo(b.price));
                } else if (_selectedSort == 'Price: High to Low') {
                  productsToDisplay.sort((a, b) => b.price.compareTo(a.price));
                } else if (_selectedSort == 'Avg. Customer Review') {
                  productsToDisplay.sort((a, b) {
                    double ratingA = 4.0 + (a.name.length % 10) / 10.0;
                    double ratingB = 4.0 + (b.name.length % 10) / 10.0;
                    return ratingB.compareTo(ratingA);
                  });
                } else if (_selectedSort == 'Bestselling') {
                  productsToDisplay.sort((a, b) {
                    int reviewsA = 100 + ((a.price.toInt() % 50) * 13);
                    int reviewsB = 100 + ((b.price.toInt() % 50) * 13);
                    return reviewsB.compareTo(reviewsA);
                  });
                } else if (_selectedSort == 'Newest Arrivals') {
                  productsToDisplay = productsToDisplay.reversed.toList();
                }

                if (productsToDisplay.isEmpty) {
                  return const Center(child: Text("No products match your filters."));
                }

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
                    return _buildCategoryProductCard(productsToDisplay[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryProductCard(Product product) {
    final bool isFavorite = widget.wishlistIds.contains(product.id);
    final double rating = 4.0 + (product.name.length % 10) / 10.0;
    final int reviews = 100 + ((product.price.toInt() % 50) * 13);

    final int originalPrice = product.originalPrice != null
        ? product.originalPrice!.round()
        : (product.price * 1.4).round();

    final int discountPercent = originalPrice > 0 ? (((originalPrice - product.price) / originalPrice) * 100).round() : 0;

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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: Colors.grey.shade100),
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
                      color: Colors.grey.shade50,
                      child: Image.network(
                        product.imageUrls.isNotEmpty ? product.imageUrls[0] : '',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: () {
                        widget.onToggleWishlist(product.id, product.name);
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                        child: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.pinkAccent : Colors.white, size: 16),
                      ),
                    ),
                  ),
                  if (discountPercent > 0)
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
                            Text('₹${product.price.toInt()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            if (originalPrice > product.price)
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
      ),
    );
  }
}