import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'order_details_screen.dart';
import 'cancel_order_screen.dart';

class TrackPackageScreen extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final Map<String, dynamic> item;

  const TrackPackageScreen({super.key, required this.orderData, required this.item});

  @override
  Widget build(BuildContext context) {
    final Color brandColor = const Color(0xFF0F4C5C);

    // --- EXTRACT DATA ---
    final String status = (orderData['status'] ?? 'Placed').toString().toLowerCase();
    final Timestamp? deliveryDateStamp = orderData['deliveryDate'];

    // Status Logic
    bool isDelivered = status == 'delivered';
    String arrivingText = 'Processing';

    if (deliveryDateStamp != null) {
      if (isDelivered) {
        arrivingText = 'Delivered ${DateFormat('d MMMM').format(deliveryDateStamp.toDate())}';
      } else {
        arrivingText = 'Arriving ${DateFormat('EEEE').format(deliveryDateStamp.toDate())}';
      }
    }

    // Determine current step (1 to 4)
    int currentStep = 1; // Default to Ordered
    if (status == 'shipped') currentStep = 2;
    if (status == 'out for delivery') currentStep = 3;
    if (status == 'delivered') currentStep = 4;

    // Extract robust address
    final Map<String, dynamic> addressData = orderData['shippingAddress'] ?? {};
    final String shipName = addressData['title'] ?? addressData['name'] ?? 'Customer';
    String rawAddress = addressData['fullAddress'] ?? addressData['address'] ?? '';

    if (rawAddress.trim().isEmpty) {
      List<String> parts = [];
      final keysToCheck = ['flat', 'houseNo', 'street', 'area', 'landmark', 'city', 'state', 'pincode', 'zipCode'];
      for (String key in keysToCheck) {
        if (addressData[key] != null && addressData[key].toString().trim().isNotEmpty) {
          parts.add(addressData[key].toString().trim());
        }
      }
      rawAddress = parts.join(', ');
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: brandColor), onPressed: () => Navigator.pop(context)),
        title: Text('DECÁRT', style: TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontFamily: 'Times New Roman', letterSpacing: 2)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TOP HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(arrivingText, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('See all orders', style: TextStyle(color: Colors.blue.shade700, fontSize: 13))
                )
              ],
            ),
            const SizedBox(height: 16),

            // --- PRODUCT IMAGE ---
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                    item['imageUrl'] ?? '', width: 100, height: 100, fit: BoxFit.cover,
                    errorBuilder: (c,e,s) => Container(width: 100, height: 100, color: Colors.grey.shade200)
                ),
              ),
            ),
            const SizedBox(height: 32),

            // --- PROGRESS TIMELINE ---
            Center(child: Text(status.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 24),
            _buildHorizontalTimeline(currentStep),
            const SizedBox(height: 40),

            // --- 3 INFO CARDS (Stacked for Mobile) ---
            _buildInfoCard(
              title: 'Delivery Info',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit_square, color: Colors.blue.shade700, size: 18),
                      const SizedBox(width: 8),
                      Text('Update delivery instructions', style: TextStyle(color: Colors.blue.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildInfoCard(
              title: 'Shipping Address',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shipName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(rawAddress.replaceAll(', ', '\n'), style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildInfoCard(
              title: 'Order Info',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => OrderDetailsScreen(orderData: orderData)));
                    },
                    child: Text('View order details', style: TextStyle(color: Colors.blue.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => CancelOrderScreen(orderData: orderData)));
                    },
                    child: Text('Cancel order', style: TextStyle(color: Colors.blue.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Helper Widget for the 3 Boxes
  Widget _buildInfoCard({required String title, required Widget content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  // Custom Horizontal Timeline Builder
  Widget _buildHorizontalTimeline(int currentStep) {
    return Row(
      children: [
        _buildTimelineNode(title: 'Ordered', isActive: currentStep >= 1, isFirst: true, isLast: false),
        _buildTimelineLine(isActive: currentStep >= 2),
        _buildTimelineNode(title: 'Shipped', isActive: currentStep >= 2, isFirst: false, isLast: false),
        _buildTimelineLine(isActive: currentStep >= 3),
        _buildTimelineNode(title: 'Out for delivery', isActive: currentStep >= 3, isFirst: false, isLast: false),
        _buildTimelineLine(isActive: currentStep >= 4),
        _buildTimelineNode(title: 'Delivered', isActive: currentStep >= 4, isFirst: false, isLast: true),
      ],
    );
  }

  Widget _buildTimelineNode({required String title, required bool isActive, required bool isFirst, required bool isLast}) {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.blue.shade600 : Colors.white,
            border: Border.all(color: isActive ? Colors.blue.shade600 : Colors.grey.shade400, width: 2),
          ),
          child: isActive ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 70, // Fixed width to force text wrapping if needed
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? Colors.black87 : Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineLine({required bool isActive}) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(bottom: 24), // Offset to align with circles, not text
        color: isActive ? Colors.blue.shade600 : Colors.grey.shade300,
      ),
    );
  }
}