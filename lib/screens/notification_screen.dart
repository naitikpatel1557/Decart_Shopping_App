import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final Color bgColor = const Color(0xFFF8F9FA);
  final Color cardColor = const Color(0xFF15112A);
  final Color brandColor = const Color(0xFF0F4C5C);

  // --- STATE VARIABLES FOR FILTERS ---
  bool _showUnreadOnly = false;
  bool _isLast30DaysFilterActive = false;

  void _showMysteryRewardDialog(BuildContext context, String code, String docId) {
    _markAsRead(docId);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return MysteryRewardDialog(rewardCode: code);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  String _timeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inDays > 1) return '${diff.inDays} days ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} mins ago';
    return 'Just now';
  }

  Future<void> _markAsRead(String docId) async {
    if (currentUser == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('notifications')
        .doc(docId)
        .update({'isRead': true});
  }

  Future<void> _markAllAsRead() async {
    if (currentUser == null) return;
    final docs = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('notifications')
        .get();

    for (var doc in docs.docs) {
      doc.reference.update({'isRead': true});
    }
  }

  Future<void> _deleteAllNotifications() async {
    if (currentUser == null) return;

    final bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete All Notifications?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
          ],
        )
    ) ?? false;

    if (confirm) {
      final docs = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('notifications')
          .get();

      for (var doc in docs.docs) {
        doc.reference.delete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: const BackButton(color: Colors.black)),
        body: const Center(child: Text("Please log in to view notifications.", style: TextStyle(fontSize: 18))),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: brandColor), onPressed: () => Navigator.pop(context)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notification Center', style: TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontSize: 18)),
            const Text('Live Updates', style: TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.done_all, color: Color(0xFF059669)), tooltip: 'Mark all as read', onPressed: _markAllAsRead),
          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), tooltip: 'Delete all', onPressed: _deleteAllNotifications),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _showUnreadOnly = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(color: !_showUnreadOnly ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(16), boxShadow: !_showUnreadOnly ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : []),
                          child: Text('All Updates', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: !_showUnreadOnly ? Colors.black : Colors.grey)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _showUnreadOnly = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(color: _showUnreadOnly ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(16), boxShadow: _showUnreadOnly ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : []),
                          child: Text('Unread', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _showUnreadOnly ? Colors.black : Colors.grey)),
                        ),
                      ),
                    ],
                  ),
                ),
                // --- UPDATED: LAST 30 DAYS FILTER TOGGLE ---
                GestureDetector(
                  onTap: () => setState(() => _isLast30DaysFilterActive = !_isLast30DaysFilterActive),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                        color: _isLast30DaysFilterActive ? const Color(0xFF8B5CF6) : const Color(0xFFC4B5FD), // Darker purple when active
                        borderRadius: BorderRadius.circular(20)
                    ),
                    child: const Text('Last 30 Days', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).collection('notifications').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey), SizedBox(height: 16), Text("No notifications yet", style: TextStyle(fontSize: 16, color: Colors.grey))]));
                }
                var docs = snapshot.data!.docs;

                // --- FILTER: UNREAD ONLY ---
                if (_showUnreadOnly) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['isRead'] != true;
                  }).toList();
                }

                // --- FILTER: LAST 30 DAYS ONLY ---
                if (_isLast30DaysFilterActive) {
                  final DateTime thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final timestamp = data['createdAt'] as Timestamp?;

                    // If timestamp is null, it means it was created locally "just now" before syncing with server
                    if (timestamp == null) return true;

                    return timestamp.toDate().isAfter(thirtyDaysAgo);
                  }).toList();
                }

                if (docs.isEmpty) return Center(child: Text(_showUnreadOnly ? "No unread notifications" : "No notifications in the last 30 days", style: const TextStyle(color: Colors.grey)));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    var docId = docs[index].id;
                    bool isRead = data['isRead'] ?? false;

                    return _buildDynamicNotificationCard(
                      docId: docId, type: data['type'] ?? 'alert', title: data['title'] ?? 'Notification',
                      subtitle: data['subtitle'] ?? '', code: data['code'] ?? '', time: _timeAgo(data['createdAt'] as Timestamp?), isRead: isRead,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicNotificationCard({required String docId, required String type, required String title, required String subtitle, required String code, required String time, required bool isRead}) {
    IconData icon; Color iconColor; Color iconBg; Widget actionWidget;

    switch (type) {
      case 'coupon':
        icon = Icons.local_offer_outlined; iconColor = Colors.orange; iconBg = Colors.orange.withOpacity(0.1);
        actionWidget = Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text(code, style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied "$code" to clipboard!'), backgroundColor: Colors.green));
            },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.transparent, border: Border.all(color: Colors.purpleAccent), borderRadius: BorderRadius.circular(8)), child: const Row(children: [Icon(Icons.copy, size: 12, color: Colors.purpleAccent), SizedBox(width: 4), Text('Copy Code', style: TextStyle(color: Colors.purpleAccent, fontSize: 11))])),
          )
        ]);
        break;
      case 'shipping':
        icon = Icons.local_shipping_outlined; iconColor = Colors.tealAccent; iconBg = Colors.tealAccent.withOpacity(0.1);
        actionWidget = Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6), decoration: BoxDecoration(color: Colors.teal.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.tealAccent));
        break;
      case 'security':
        icon = Icons.shield_outlined; iconColor = Colors.blueAccent; iconBg = Colors.blueAccent.withOpacity(0.1);
        actionWidget = Container(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6), decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.help_outline, size: 14, color: Colors.blueAccent));
        break;
      case 'mystery':
        icon = Icons.card_giftcard; iconColor = Colors.purpleAccent; iconBg = Colors.purpleAccent.withOpacity(0.1);
        actionWidget = Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.1), border: Border.all(color: Colors.purpleAccent.withOpacity(0.5)), borderRadius: BorderRadius.circular(8)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Text('Tap to Reveal Mystery', style: TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold)), SizedBox(width: 6), Icon(Icons.card_giftcard, size: 12, color: Colors.purpleAccent)]));
        break;
      default:
        icon = Icons.auto_awesome; iconColor = Colors.pinkAccent; iconBg = Colors.pinkAccent.withOpacity(0.1);
        actionWidget = Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.pinkAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Text('View Details', style: TextStyle(color: Colors.pinkAccent, fontSize: 11, fontWeight: FontWeight.bold)), SizedBox(width: 6), Icon(Icons.arrow_forward, size: 12, color: Colors.pinkAccent)]));
    }

    Widget card = Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isRead ? Colors.transparent : Colors.purpleAccent.withOpacity(0.3), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle, border: Border.all(color: iconColor.withOpacity(0.3))), child: Icon(icon, color: iconColor, size: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: isRead ? Colors.grey.shade300 : Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, height: 1.4)),
                    const SizedBox(height: 12),
                    actionWidget,
                    const SizedBox(height: 12),
                    Text(time, style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          if (!isRead) const Positioned(right: 0, top: 0, child: CircleAvatar(radius: 4, backgroundColor: Colors.redAccent))
        ],
      ),
    );

    return GestureDetector(
        onTap: () {
          if (type == 'mystery') {
            _showMysteryRewardDialog(context, code, docId);
          } else {
            _markAsRead(docId);
          }
        },
        child: card
    );
  }
}

// --- SCRATCH CARD DIALOG WIDGET ---
class MysteryRewardDialog extends StatefulWidget {
  final String rewardCode;
  const MysteryRewardDialog({super.key, required this.rewardCode});

  @override
  State<MysteryRewardDialog> createState() => _MysteryRewardDialogState();
}

class _MysteryRewardDialogState extends State<MysteryRewardDialog> {
  bool _isScratched = false;

  void _revealCard() {
    if (!_isScratched) {
      setState(() => _isScratched = true);
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF2D1B4E), Color(0xFF150A21)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.purpleAccent.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: Colors.orangeAccent, size: 18), SizedBox(width: 8),
                Text('MYSTERY REWARD UNLOCKED', style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                SizedBox(width: 8), Icon(Icons.auto_awesome, color: Colors.orangeAccent, size: 18),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Exclusive Mystery Reward Coupon', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Scratch the card below to reveal your secret discount coupon code!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
            const SizedBox(height: 24),

            // --- SCRATCH AREA ---
            GestureDetector(
              onTap: _revealCard,
              child: AnimatedCrossFade(
                firstChild: _buildCoverState(),
                secondChild: _buildRevealedState(),
                crossFadeState: _isScratched ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 500),
                sizeCurve: Curves.easeInOut,
              ),
            ),
            const SizedBox(height: 24),

            // --- BOTTOM BUTTONS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Close', style: TextStyle(color: Colors.purple.shade200))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD814), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Dismiss Rewards', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCoverState() {
    return Container(
      width: double.infinity, height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFDF00), Color(0xFFFF8C00)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 15, spreadRadius: 2)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.card_giftcard, color: Colors.black87, size: 40), const SizedBox(height: 12),
          const Text('SCRATCH HERE', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          const Text('Click or tap to scratch off coating', style: TextStyle(color: Colors.black54, fontSize: 10)),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: const Text('Scratch Now', style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)))
        ],
      ),
    );
  }

  Widget _buildRevealedState() {
    return Container(
      width: double.infinity, height: 200,
      decoration: BoxDecoration(color: const Color(0xFF1E143A), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.purple.withOpacity(0.3), width: 2)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: const Text('ACTIVE CODE', style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0))),
          const SizedBox(height: 16),
          Text(widget.rewardCode, style: const TextStyle(color: Color(0xFF10B981), fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4.0, shadows: [Shadow(color: Color(0xFF10B981), blurRadius: 10)])),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: widget.rewardCode));
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied "${widget.rewardCode}" to clipboard!'), backgroundColor: Colors.green));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.purpleAccent.withOpacity(0.5))),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.copy, color: Colors.purpleAccent, size: 14), SizedBox(width: 8), Text('Copy Reward Code', style: TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold))]),
            ),
          )
        ],
      ),
    );
  }
}