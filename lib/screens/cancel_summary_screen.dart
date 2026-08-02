import 'package:flutter/material.dart';

class CancelSummaryScreen extends StatelessWidget {
  final List<dynamic> cancelledItems;
  final VoidCallback onNavigateToOrders;

  const CancelSummaryScreen({
    super.key,
    required this.cancelledItems,
    required this.onNavigateToOrders,
  });

  @override
  Widget build(BuildContext context) {
    final Color brandColor = const Color(0xFF0F4C5C);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false, // Hide back button for a clear success flow
        title: Text('DECÁRT', style: TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontFamily: 'Times New Roman', letterSpacing: 2)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SUCCESS BANNER ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFF059669), width: 1.5), // Green border
                borderRadius: BorderRadius.circular(4),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // Thick green left border
                    Container(width: 8, color: const Color(0xFF059669)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF059669), size: 24),
                          SizedBox(width: 8),
                          Text('Cancellation successful', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // --- HEADERS ---
            const Text('Cancellation Summary', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Selected items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // --- CANCELLED ITEMS LIST ---
            ...cancelledItems.map((item) {
              final String name = item['name'] ?? 'Product';
              final num price = item['price'] ?? 0;
              final String imageUrl = item['imageUrl'] ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cancelled', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: TextStyle(color: Colors.blue.shade700, fontSize: 13, height: 1.4)),
                              const SizedBox(height: 8),
                              Text('₹$price', style: const TextStyle(color: Color(0xFFB12704), fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        )
                      ],
                    )
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),

            // --- VIEW YOUR ORDERS BUTTON ---
            SizedBox(
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD814),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Color(0xFFFCD200)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                onPressed: onNavigateToOrders,
                child: const Text('View your orders', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}