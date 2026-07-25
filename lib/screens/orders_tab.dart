import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class OrdersTab extends StatelessWidget {
  final VoidCallback? onNavigateToHome;
  final bool isTab; // Tells the widget if it's in the Bottom Nav (true) or Pushed from Account (false)

  const OrdersTab({
    super.key,
    this.onNavigateToHome,
    this.isTab = true,
  });

  // --- NEW: FUNCTION TO CREATE AND STORE AN ORDER IN FIREBASE ---
  Future<void> _placeTestOrder(BuildContext context, String uid) async {
    // Generate a random price and item count for the test order
    final randomAmount = (Random().nextInt(50) + 10) * 100;
    final randomItems = Random().nextInt(4) + 1;

    // Save to Firebase: users -> [UID] -> orders
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('orders')
        .add({
      'totalAmount': randomAmount,
      'itemCount': randomItems,
      'status': 'Order Confirmed',
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test Order Placed Successfully!'), backgroundColor: Colors.green)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final Color brandColor = const Color(0xFF0F4C5C);

    // --- SHARED CONTENT AREA ---
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isTab) // Only show this header if it's a tab (no AppBar)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Row(
              children: [
                Container(width: 3, height: 18, color: Colors.purpleAccent),
                const SizedBox(width: 8),
                const Text('MY ORDERS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontFamily: 'Times New Roman')),
              ],
            ),
          ),

        Expanded(
          child: currentUser == null
              ? _buildLoginState()
              : _buildOrdersList(currentUser.uid, context),
        ),
      ],
    );

    // --- IF OPENED FROM ACCOUNT PAGE (Needs an AppBar) ---
    if (!isTab) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(icon: Icon(Icons.arrow_back, color: brandColor), onPressed: () => Navigator.pop(context)),
          title: Text('My Orders', style: TextStyle(color: brandColor, fontFamily: 'Times New Roman', fontWeight: FontWeight.bold)),
        ),
        body: content,
        floatingActionButton: _buildOrderButton(context, currentUser),
      );
    }

    // --- IF OPENED FROM BOTTOM NAV BAR (No AppBar needed) ---
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: content,
      floatingActionButton: _buildOrderButton(context, currentUser),
    );
  }

  // --- FLOATING BUTTON TO CREATE ORDERS ---
  Widget? _buildOrderButton(BuildContext context, User? currentUser) {
    if (currentUser == null) return null;

    return FloatingActionButton.extended(
      backgroundColor: const Color(0xFFFFD814),
      foregroundColor: Colors.black,
      icon: const Icon(Icons.add_shopping_cart),
      label: const Text("Place Test Order", style: TextStyle(fontWeight: FontWeight.bold)),
      onPressed: () => _placeTestOrder(context, currentUser.uid),
    );
  }

  // --- UI IF USER IS NOT LOGGED IN ---
  Widget _buildLoginState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("Please log in to view your orders", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Your order history is securely saved to your account.", style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  // --- UI FETCHING FIREBASE DATA ---
  Widget _buildOrdersList(String uid, BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0F4C5C)));
        }

        // --- EMPTY STATE: "Not Yet Ordered" ---
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text("You haven't ordered yet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                const SizedBox(height: 8),
                Text("Explore our catalog and find something you love!", style: TextStyle(color: Colors.grey.shade500)),
                const SizedBox(height: 24),
                if (isTab && onNavigateToHome != null)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD814),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: onNavigateToHome,
                    child: const Text("Start Shopping", style: TextStyle(fontWeight: FontWeight.bold)),
                  )
              ],
            ),
          );
        }

        // --- ACTIVE ORDERS LIST ---
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            String orderId = snapshot.data!.docs[index].id;

            return Container(
              margin: EdgeInsets.only(bottom: 16, top: index == 0 ? 8 : 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text("Order ID: $orderId", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                        child: Text(data['status'] ?? 'Processing', style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Text("Total Amount: ₹${data['totalAmount'] ?? '0'}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text("Items: ${data['itemCount'] ?? '1'} products", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}