import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'order_details_screen.dart';
import 'cancel_order_screen.dart';

class TrackPackageScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final Map<String, dynamic> item;

  const TrackPackageScreen({super.key, required this.orderData, required this.item});

  @override
  State<TrackPackageScreen> createState() => _TrackPackageScreenState();
}

class _TrackPackageScreenState extends State<TrackPackageScreen> {
  final Color brandColor = const Color(0xFF0F4C5C);

  // --- DYNAMIC DIALOG TO UPDATE DELIVERY INSTRUCTIONS ---
  void _showEditInstructionsDialog(BuildContext context, String currentInstructions, String orderId) {
    final TextEditingController instructionsController = TextEditingController(text: currentInstructions);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Delivery Instructions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: instructionsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'e.g., Leave at the front door, call upon arrival...',
              hintStyle: const TextStyle(fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD814), foregroundColor: Colors.black, elevation: 0),
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  // Save dynamically to database
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('orders')
                      .doc(orderId)
                      .update({'deliveryInstructions': instructionsController.text.trim()});
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String orderId = widget.orderData['orderId'] ?? '';

    if (user == null || orderId.isEmpty) {
      return const Scaffold(body: Center(child: Text("Error loading order")));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: brandColor), onPressed: () => Navigator.pop(context)),
        title: Text('DECART', style: TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontFamily: 'Times New Roman', letterSpacing: 2)),
      ),
      // --- STREAM BUILDER FOR LIVE UPDATES ---
      body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('orders')
              .doc(orderId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text("This order has been moved or deleted.", style: TextStyle(color: Colors.grey)));
            }

            final liveOrderData = snapshot.data!.data() as Map<String, dynamic>;

            // --- EXTRACT LIVE DATA ---
            final String status = (liveOrderData['status'] ?? 'Placed').toString().toLowerCase();
            final String deliveryInstructions = liveOrderData['deliveryInstructions'] ?? '';
            final Timestamp? deliveryDateStamp = liveOrderData['deliveryDate'];

            // Status Logic
            bool isDelivered = status == 'delivered';
            bool isCancelled = status == 'cancelled';
            String arrivingText = 'Processing';

            if (isCancelled) {
              arrivingText = 'Order Cancelled';
            } else if (deliveryDateStamp != null) {
              if (isDelivered) {
                arrivingText = 'Delivered ${DateFormat('d MMMM').format(deliveryDateStamp.toDate())}';
              } else {
                arrivingText = 'Arriving ${DateFormat('EEEE').format(deliveryDateStamp.toDate())}';
              }
            }

            // Determine current timeline step
            int currentStep = 1;
            if (status == 'shipped') currentStep = 2;
            if (status == 'out for delivery') currentStep = 3;
            if (status == 'delivered') currentStep = 4;

            // Extract robust address
            final Map<String, dynamic> addressData = liveOrderData['shippingAddress'] ?? {};
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

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- TOP HEADER ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(arrivingText, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isCancelled ? Colors.red : Colors.black)),
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
                          widget.item['imageUrl'] ?? '', width: 100, height: 100, fit: BoxFit.cover,
                          errorBuilder: (c,e,s) => Container(width: 100, height: 100, color: Colors.grey.shade200)
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- LIVE PROGRESS TIMELINE ---
                  if (!isCancelled) ...[
                    Center(child: Text(status.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 24),
                    _buildHorizontalTimeline(currentStep),
                    const SizedBox(height: 40),
                  ] else ...[
                    const Center(child: Text("This order was cancelled", style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 32),
                  ],

                  // --- 3 INFO CARDS ---
                  _buildInfoCard(
                    title: 'Delivery Info',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (deliveryInstructions.isNotEmpty) ...[
                          Text('"$deliveryInstructions"', style: TextStyle(color: Colors.grey.shade800, fontSize: 13, fontStyle: FontStyle.italic)),
                          const SizedBox(height: 12),
                        ],
                        GestureDetector(
                          onTap: () => _showEditInstructionsDialog(context, deliveryInstructions, orderId),
                          child: Row(
                            children: [
                              Icon(Icons.edit_square, color: Colors.blue.shade700, size: 18),
                              const SizedBox(width: 8),
                              Text(deliveryInstructions.isEmpty ? 'Add delivery instructions' : 'Update delivery instructions', style: TextStyle(color: Colors.blue.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
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
                            Navigator.push(context, MaterialPageRoute(builder: (context) => OrderDetailsScreen(orderData: liveOrderData)));
                          },
                          child: Text('View order details', style: TextStyle(color: Colors.blue.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
                        ),
                        if (!isCancelled && !isDelivered) ...[
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => CancelOrderScreen(orderData: liveOrderData)));
                            },
                            child: Text('Cancel order', style: TextStyle(color: Colors.blue.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          }
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