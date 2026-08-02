import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  final Color brandColor = const Color(0xFF0F4C5C);

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
          'Privacy Policy',
          style: TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontFamily: 'Times New Roman', fontSize: 22),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // --- LISTENS TO FIREBASE FOR DYNAMIC UPDATES ---
          stream: FirebaseFirestore.instance.collection('legal').doc('privacy_policy').snapshots(),
          builder: (context, snapshot) {

            // 1. Show a loading spinner while fetching data
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: brandColor));
            }

            // 2. Handle errors
            if (snapshot.hasError) {
              return const Center(child: Text("Failed to load Privacy Policy."));
            }

            String effectiveDate = 'Updating...';
            List<dynamic> sections = [];

            // 3. Extract dynamic data from Firebase
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              effectiveDate = data['effective_date'] ?? effectiveDate;
              if (data['sections'] != null) {
                sections = data['sections'];
              }
            }

            // 4. Handle empty database state
            if (sections.isEmpty) {
              return const Center(child: Text("Privacy Policy will be updated soon.", style: TextStyle(color: Colors.grey)));
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

                    // 5. Dynamically build all sections from Firebase
                    ...sections.map((section) {
                      return _buildSection(
                          section['title'] ?? 'Section Title',
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