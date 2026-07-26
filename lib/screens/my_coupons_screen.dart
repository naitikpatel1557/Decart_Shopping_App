import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyCouponsScreen extends StatelessWidget {
  const MyCouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final Color brandColor = const Color(0xFF0F4C5C);

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: const BackButton(color: Colors.black)),
        body: const Center(child: Text("Please log in to view your coupons.", style: TextStyle(fontSize: 18))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: brandColor), onPressed: () => Navigator.pop(context)),
        title: Text('My Coupons', style: TextStyle(color: brandColor, fontFamily: 'Times New Roman', fontWeight: FontWeight.bold)),
      ),

      // --- FETCH FROM FIREBASE NOTIFICATIONS ---
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: brandColor));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // --- 5 DAY EXPIRATION LOGIC ---
          final DateTime fiveDaysAgo = DateTime.now().subtract(const Duration(days: 5));

          // --- FILTER LOGIC: Keep valid coupons less than 5 days old ---
          final couponDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            // 1. Check if it actually has a coupon code
            if (!data.containsKey('code') || data['code'].toString().trim().isEmpty) {
              return false;
            }

            // 2. Check if it is older than 5 days
            final timestamp = data['createdAt'] as Timestamp?;
            if (timestamp != null) {
              if (timestamp.toDate().isBefore(fiveDaysAgo)) {
                return false; // Hide it (expired)
              }
            }

            return true; // Keep it (valid)
          }).toList();

          if (couponDocs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: couponDocs.length,
            itemBuilder: (context, index) {
              final data = couponDocs[index].data() as Map<String, dynamic>;
              return _buildCouponCard(context, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No valid coupons available", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
          const SizedBox(height: 8),
          Text("Coupons expire 5 days after receiving them.", style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildCouponCard(BuildContext context, Map<String, dynamic> data) {
    final String code = data['code'] ?? '';
    final String title = data['title'] ?? 'Special Reward';
    final String subtitle = data['subtitle'] ?? 'Use this code at checkout.';
    final bool isMystery = data['type'] == 'mystery';

    // Calculate days remaining for the UI
    String daysLeftText = "Expires soon";
    final timestamp = data['createdAt'] as Timestamp?;
    if (timestamp != null) {
      final expirationDate = timestamp.toDate().add(const Duration(days: 5));
      final difference = expirationDate.difference(DateTime.now());
      if (difference.inDays > 0) {
        daysLeftText = "Expires in ${difference.inDays} days";
      } else {
        daysLeftText = "Expires today";
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          // --- LEFT SIDE: TICKET ICON ---
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: isMystery ? Colors.purpleAccent.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              border: Border(right: BorderSide(color: Colors.grey.shade300, width: 1.5)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isMystery ? Icons.auto_awesome : Icons.local_offer,
                    color: isMystery ? Colors.purpleAccent : Colors.orange,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                      daysLeftText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 8, color: Colors.redAccent, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
            ),
          ),

          // --- RIGHT SIDE: TICKET DETAILS ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Dotted border box for code
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300)
                        ),
                        child: Text(code, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 13)),
                      ),

                      // Copy Button
                      GestureDetector(
                        onTap: () async {
                          await Clipboard.setData(ClipboardData(text: code));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied "$code" to clipboard!'), backgroundColor: Colors.green));
                          }
                        },
                        child: const Text('COPY', style: TextStyle(color: Color(0xFF0F4C5C), fontWeight: FontWeight.bold, fontSize: 12)),
                      )
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}