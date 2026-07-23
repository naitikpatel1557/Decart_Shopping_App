import 'package:flutter/material.dart';

class CategoriesTab extends StatelessWidget {
  const CategoriesTab({super.key});

  final List<Map<String, String>> _allCategories = const [
    {'name': 'Home & Kitchen', 'imageUrl': 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=300&q=80'},
    {'name': 'Health & Personal...', 'imageUrl': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=300&q=80'},
    {'name': 'Office Product', 'imageUrl': 'https://images.unsplash.com/photo-1497215728101-856f4ea42174?w=300&q=80'},
    {'name': 'Toys & Baby Care', 'imageUrl': 'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?w=300&q=80'},
    {'name': 'Home Improvement', 'imageUrl': 'https://images.unsplash.com/photo-1581094794329-c8112a89af12?w=300&q=80'},
    {'name': 'Beauty', 'imageUrl': 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=300&q=80'},
    {'name': 'Electronics', 'imageUrl': 'https://images.unsplash.com/photo-1498049794561-7780e7231661?w=300&q=80'},
    {'name': 'Fashion', 'imageUrl': 'https://images.unsplash.com/photo-1445205170230-053b83016050?w=300&q=80'},
    {'name': 'Sports & Outdoors', 'imageUrl': 'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=300&q=80'},
    {'name': 'Automotive', 'imageUrl': 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?w=300&q=80'},
    {'name': 'Books', 'imageUrl': 'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=300&q=80'},
    {'name': 'Groceries', 'imageUrl': 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=300&q=80'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Row(
              children: [
                Container(width: 3, height: 18, color: Colors.orangeAccent),
                const SizedBox(width: 8),
                const Text(
                  'ALL CATEGORIES',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontFamily: 'Times New Roman',
                  ),
                ),
              ],
            ),
          ),

          // Full Categories Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _allCategories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.70, // Slightly adjusted to fit the new rounded boxes perfectly
                crossAxisSpacing: 16,
                mainAxisSpacing: 24,
              ),
              itemBuilder: (context, index) {
                final category = _allCategories[index];
                return Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 1, // Keeps the image box a perfect square
                      child: Container(
                        decoration: BoxDecoration(
                          // --- CHANGED: Replaced circle with a rounded rectangle ---
                            borderRadius: BorderRadius.circular(16),
                            color: const Color(0xFFF3F4F6), // A soft light-grey/blue background color
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04), // Softer shadow
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              )
                            ]
                        ),
                        // --- CHANGED: Used ClipRRect instead of ClipOval ---
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            category['imageUrl']!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.category, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      category['name']!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.2),
                    )
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}