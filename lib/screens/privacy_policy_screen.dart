import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  final Color brandColor = const Color(0xFF0F4C5C);

  @override
  Widget build(BuildContext context) {
    // Default fallback data if Firebase is empty or loading
    final List<Map<String, String>> fallbackSections = [
        // {'title': '1. Information We Collect', 'content': 'We collect information you provide directly to us, such as when you create or modify your account, request on-demand services, contact customer support, or otherwise communicate with us. This information may include: name, email, phone number, postal address, payment method, and other information you choose to provide.'},
      // {'title': '2. How We Use Your Information', 'content': 'We may use the information we collect about you to provide, maintain, and improve our Services. This includes facilitating payments, sending receipts, providing products you request, authenticating users, and sending product updates and administrative messages.'},
      // {'title': '3. Sharing of Information', 'content': 'We may share the information we collect about you as described in this Statement, including with vendors, consultants, marketing partners, and other service providers who need access to such information to carry out work on our behalf.'},
      // {'title': '4. Security', 'content': 'We take reasonable measures to help protect information about you from loss, theft, misuse, unauthorized access, disclosure, alteration, and destruction. We use secure socket layer (SSL) technology for encrypted transactions.'},
      // {'title': '5. Contact Us', 'content': 'If you have any questions about this Privacy Statement or your personal data, please contact our support team at care@decart.app.'},
    ];

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
          'Privacy Policy',
          style: TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontFamily: 'Times New Roman', fontSize: 22),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // --- LISTENS TO FIREBASE FOR DYNAMIC UPDATES ---
          stream: FirebaseFirestore.instance.collection('legal').doc('privacy_policy').snapshots(),
          builder: (context, snapshot) {

            String effectiveDate = 'July 2026'; // Fallback date
            List<dynamic> sections = fallbackSections;

            // If Firebase has data, override the defaults!
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              effectiveDate = data['effective_date'] ?? effectiveDate;
              if (data['sections'] != null) {
                sections = data['sections'];
              }
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Decart Privacy Policy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 8),
                    Text('Effective Date: $effectiveDate', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    const SizedBox(height: 24),

                    // Dynamically build all sections from Firebase (or fallback)
                    ...sections.map((section) {
                      return _buildSection(
                          section['title'] ?? 'Section',
                          section['content'] ?? 'Content missing.'
                      );
                    }),

                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        '© ${DateTime.now().year} Decart Technologies. All rights reserved.',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
          const SizedBox(height: 8),
          Text(content, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}
