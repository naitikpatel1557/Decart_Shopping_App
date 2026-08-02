import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'address_screen.dart';
import 'checkout_screen.dart';

// --- IMPORTS FOR PRODUCT REDIRECTION ---
import '../models/product_model.dart';
import 'product_details_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  final Color brandColor = const Color(0xFF0F4C5C);

  // --- FUNCTION TO UPDATE QUANTITY OR DELETE ---
  Future<void> _updateQuantity(String productId, int currentQty, int change) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cartRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('cart').doc(productId);

    final newQty = currentQty + change;

    if (newQty <= 0) {
      await cartRef.delete();
    } else {
      await cartRef.update({'quantity': newQty});
    }
  }

  // --- FUNCTION TO REMOVE ITEM COMPLETELY ---
  Future<void> _removeItem(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('cart').doc(productId).delete();
  }

  // --- ADDRESS SELECTION BOTTOM SHEET ---
  void _showAddressSelection(BuildContext context, int totalAmount) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (BuildContext sheetContext) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Delivery Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Stream addresses from Firebase
                  StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('addresses').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
                        }

                        final addresses = snapshot.data?.docs ?? [];

                        // SCENARIO 1: NO ADDRESS FOUND
                        if (addresses.isEmpty) {
                          return Column(
                            children: [
                              Icon(Icons.location_off_outlined, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              const Text("No address found", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text("Please add a delivery address to proceed.", style: TextStyle(color: Colors.grey.shade600)),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: brandColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(sheetContext); // Close the bottom sheet
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AddressScreen()));
                                  },
                                  child: const Text("Add New Address", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              )
                            ],
                          );
                        }

                        // SCENARIO 2: USER HAS SAVED ADDRESSES
                        return Column(
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: addresses.length,
                                separatorBuilder: (context, index) => const Divider(),
                                itemBuilder: (context, index) {
                                  final addrData = addresses[index].data() as Map<String, dynamic>;
                                  final String title = addrData['title'] ?? addrData['name'] ?? 'Home';
                                  final String fullAddress = addrData['fullAddress'] ?? addrData['address'] ?? 'Address details...';
                                  final String phone = addrData['phone'] ?? '';

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: brandColor.withOpacity(0.1),
                                      child: Icon(Icons.location_on, color: brandColor),
                                    ),
                                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('$fullAddress\n$phone', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.4)),
                                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                                    onTap: () {
                                      Navigator.pop(sheetContext); // Close sheet
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CheckoutScreen(
                                            deliveryAddress: addrData,
                                            totalAmount: totalAmount,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(sheetContext); // Close sheet
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const AddressScreen()));
                              },
                              icon: Icon(Icons.add, color: brandColor),
                              label: Text("Add Another Address", style: TextStyle(color: brandColor, fontWeight: FontWeight.bold)),
                            )
                          ],
                        );
                      }
                  )
                ],
              ),
            ),
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('My Cart', style: TextStyle(color: brandColor)), backgroundColor: Colors.white, elevation: 0),
        body: const Center(child: Text("Please sign in to view your cart.")),
      );
    }

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
          'My Cart',
          style: TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontFamily: 'Times New Roman', fontSize: 22),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .orderBy('addedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final cartItems = snapshot.data?.docs ?? [];

          if (cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text("Your cart is empty!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Add items to it now.", style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          int totalAmount = 0;
          for (var item in cartItems) {
            final data = item.data() as Map<String, dynamic>;
            final int price = data['price'] ?? 0;
            final int qty = data['quantity'] ?? 1;
            totalAmount += (price * qty);
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final data = cartItems[index].data() as Map<String, dynamic>;
                    final docId = cartItems[index].id;
                    // Pass the context here to allow navigation
                    return _buildCartItem(context, data, docId);
                  },
                ),
              ),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal (${cartItems.length} items)', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                          Text('₹$totalAmount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Delivery', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          Text('FREE', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Text('₹$totalAmount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF0F4C5C))),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD814),
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Color(0xFFFCD200))),
                          ),
                          onPressed: () => _showAddressSelection(context, totalAmount),
                          child: const Text('Proceed to Buy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  // --- UPDATED: ADDED BuildContext & GestureDetector FOR NAVIGATION ---
  Widget _buildCartItem(BuildContext context, Map<String, dynamic> data, String docId) {
    final String name = data['name'] ?? 'Unknown Product';
    final int price = data['price'] ?? 0;
    final int qty = data['quantity'] ?? 1;
    final String imageUrl = data['imageUrl'] ?? '';
    final String productId = data['productId'] ?? docId;
    final String category = data['category'] ?? 'Cart';

    return GestureDetector(
      onTap: () {
        // Construct Product object from the cart data
        final productDetails = Product(
          id: productId,
          name: name,
          price: price.toDouble(),
          imageUrls: [imageUrl],
          productId: productId,
          category: category,
        );

        // Navigate to the Product Details Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(
              product: productDetails,
              wishlistIds: const {}, // Cart doesn't strictly need to manage wishlist state here
              onToggleWishlist: (id, name) {},
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(width: 80, height: 80, color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('₹$price', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F4C5C))),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () => _updateQuantity(docId, qty, -1),
                              child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Icon(Icons.remove, size: 16)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              color: Colors.grey.shade100,
                              child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            InkWell(
                              onTap: () => _updateQuantity(docId, qty, 1),
                              child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Icon(Icons.add, size: 16)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                        onPressed: () => _removeItem(docId),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}