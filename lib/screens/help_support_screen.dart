import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; // <-- IMPORT URL LAUNCHER

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;

  final Color brandColor = const Color(0xFF0F4C5C);
  final Color darkGreen = const Color(0xFF04483C);

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // --- NEW: LAUNCH PHONE DIALER ---
  Future<void> _makePhoneCall() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+919876543210');
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication); // Force external
      } else {
        // Fallback if canLaunchUrl fails but launchUrl might still work
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the phone dialer.')));
      }
    }
  }

  // --- NEW: LAUNCH EMAIL APP ---
  Future<void> _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'care@decart.com',
      query: 'subject=Support Inquiry from App',
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication); // Force external
      } else {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the email app.')));
      }
    }
  }

  // --- SAVE SUPPORT TICKET TO FIREBASE ---
  Future<void> _fileTicket() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to submit a support ticket!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both subject and message fields.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance.collection('support_tickets').add({
        'userId': user.uid,
        'userEmail': user.email ?? 'No Email',
        'subject': subject,
        'message': message,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _subjectController.clear();
      _messageController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Support ticket filed successfully! Our team will respond shortly.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit ticket: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

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
          'Help & Support',
          style: TextStyle(
            color: brandColor,
            fontFamily: 'Times New Roman',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TOP CONTACT CARDS ---
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _makePhoneCall, // <-- TRIGGERS DIALER
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.headset_mic_outlined, color: Color(0xFF0F4C5C), size: 24),
                          ),
                          const SizedBox(height: 12),
                          const Text('CALL SUPPORT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                          const SizedBox(height: 6),
                          const Text('+91 98765 43210', style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text('Mon-Sat (9 AM - 6 PM)', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _sendEmail, // <-- TRIGGERS EMAIL
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.mail_outline, color: Color(0xFF0F4C5C), size: 24),
                          ),
                          const SizedBox(height: 12),
                          const Text('EMAIL DESK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                          const SizedBox(height: 6),
                          const Text('care@decart.com', style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text('Responds within 4 hours', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- FREQUENTLY ANSWERED QUERIES ---
            const Text('FREQUENTLY ANSWERED QUERIES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 12),

            _buildFaqItem('How do I track my order?', 'You can track your order directly from the "My Orders" tab in your profile menu or bottom navigation bar to view real-time status updates.'),
            _buildFaqItem('What is the return and refund policy?', 'We offer a 7-day hassle-free return window for eligible products purchased on Decárt. Items must be unused and in original packaging.'),
            _buildFaqItem('Can I pay on delivery (COD)?', 'Yes, Cash on Delivery (COD) is available on eligible items and standard pin codes across supported regions.'),
            _buildFaqItem('How do I add a new address?', 'Go to the Account menu or side drawer, select "My Address", and tap "Add New Address" to save your delivery location securely.'),
            _buildFaqItem('Is online payment secure on Decárt?', 'All online transactions are protected using advanced SSL encryption to ensure total safety and security.'),

            const SizedBox(height: 24),

            // --- RAISE SUPPORT TICKET SECTION ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.chat_bubble_outline, color: Colors.orangeAccent, size: 20),
                      SizedBox(width: 8),
                      Text('RAISE SUPPORT TICKET', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0, fontFamily: 'Times New Roman')),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text('SUBJECT QUERY TOPIC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _subjectController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Delivery status delay, coupon mismatch',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('EXPLAIN CONTEXT MESSAGE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Provide order codes or phone parameters...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      onPressed: _isSubmitting ? null : _fileTicket,
                      child: _isSubmitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('File Support Ticket', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- CORPORATE PROTECTIONS CLAUSES ---
            const Text('CORPORATE PROTECTIONS CLAUSES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildPolicyTile('Return & Refund Policy', '7-Days Window'),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildPolicyTile('Shipping Policy', 'Standard 2-4 Days'),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildPolicyTile('Cancellation Policy', 'Free before dispatch'),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildPolicyTile('Terms of Use & Conditions', 'Revised 2026'),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.pink.shade50, shape: BoxShape.circle),
          child: const Icon(Icons.help_outline, color: Colors.redAccent, size: 16),
        ),
        title: Text(question, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
        iconColor: Colors.black54,
        collapsedIconColor: Colors.black54,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(answer, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyTile(String title, String subtitle) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: () {},
    );
  }
}