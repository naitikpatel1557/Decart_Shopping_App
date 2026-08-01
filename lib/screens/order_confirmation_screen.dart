import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- IMPORT YOUR HOME / MAIN SCREEN FILE HERE ---
import 'home_screen.dart'; // <-- Change to 'main_screen.dart' if that's where MainScreen class live

class OrderConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic> deliveryAddress;
  final List<Map<String, dynamic>> orderItems;
  final DateTime deliveryDate;

  const OrderConfirmationScreen({
    super.key,
    required this.deliveryAddress,
    required this.orderItems,
    required this.deliveryDate,
  });

  @override
  Widget build(BuildContext context) {
    final String name = deliveryAddress['title'] ?? deliveryAddress['name'] ?? 'Customer';
    final String fullAddress = deliveryAddress['fullAddress'] ?? deliveryAddress['address'] ?? '';
    final String userEmail = FirebaseAuth.instance.currentUser?.email ?? 'your email';
    final String formattedDate = DateFormat('EEEE, d Aug').format(deliveryDate);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF232F3E),
        automaticallyImplyLeading: false,
        title: const Text(
          'DECÁRT',
          style: TextStyle(color: Colors.white, fontFamily: 'Times New Roman', letterSpacing: 2.0, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Success Header
              Row(
                children: const [
                  Icon(Icons.check_circle, color: Color(0xFF067D62), size: 28),
                  SizedBox(width: 12),
                  Text('Order placed, thank you!', style: TextStyle(color: Color(0xFF067D62), fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Text('Confirmation will be sent to $userEmail.', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 16),

              // Shipping Address
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black, fontSize: 14, height: 1.4),
                  children: [
                    const TextSpan(text: 'Shipping to ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: '${name.toUpperCase()}, ', style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: fullAddress),
                  ],
                ),
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),

              // Product Items & Dates
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: orderItems.length,
                itemBuilder: (context, index) {
                  final item = orderItems[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text('Delivery date', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item['imageUrl'] ?? '',
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.image)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Link to return Home / Orders
              GestureDetector(
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                        (route) => false,
                  );
                },
                child: Text('Review or edit your recent orders >', style: TextStyle(color: Colors.blue.shade700, fontSize: 14, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}