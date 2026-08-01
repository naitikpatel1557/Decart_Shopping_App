import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CancelOrderScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const CancelOrderScreen({super.key, required this.orderData});

  @override
  State<CancelOrderScreen> createState() => _CancelOrderScreenState();
}

class _CancelOrderScreenState extends State<CancelOrderScreen> {
  final Color brandColor = const Color(0xFF0F4C5C);

  late List<dynamic> _items;
  late List<bool> _selectedItems;
  String? _selectedReason;
  bool _isLoading = false;

  final List<String> _cancellationReasons = [
    'Order Created by Mistake',
    'Item(s) Would Not Arrive on Time',
    'Shipping Cost Too High',
    'Item Price Too High',
    'Found Cheaper Somewhere Else',
    'Item Sold by Third Party',
    'Need to Change Shipping Address',
    'Need to Change Shipping Speed',
    'Need to Change Billing Address',
    'Need to Change Payment Method',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _items = widget.orderData['items'] ?? [];
    // Initially, no items are selected
    _selectedItems = List<bool>.filled(_items.length, false);
  }

  bool get _allSelected => _selectedItems.every((element) => element == true);
  bool get _anySelected => _selectedItems.contains(true);

  void _toggleSelectAll() {
    setState(() {
      final bool newValue = !_allSelected;
      for (int i = 0; i < _selectedItems.length; i++) {
        _selectedItems[i] = newValue;
      }
    });
  }

  // --- UPDATED: SAVES REASON TO THE SPECIFIC PRODUCT & MOVES TO CANCELLED DB ---
  Future<void> _requestCancellation() async {
    final user = FirebaseAuth.instance.currentUser;
    final String orderId = widget.orderData['orderId'];

    if (user == null || orderId.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // 1. Update the specific products inside the items array with the reason
      List<dynamic> updatedItems = List.from(widget.orderData['items'] ?? []);

      for (int i = 0; i < updatedItems.length; i++) {
        if (_selectedItems[i]) {
          // Attaches the cancellation reason exactly to the chosen product!
          updatedItems[i]['status'] = 'Cancelled';
          updatedItems[i]['cancellationReason'] = _selectedReason;
          updatedItems[i]['cancelledAt'] = DateTime.now().toIso8601String();
        }
      }

      // 2. Prepare the master document update
      Map<String, dynamic> cancelledData = Map<String, dynamic>.from(widget.orderData);
      cancelledData['items'] = updatedItems; // Save the updated items array
      cancelledData['status'] = 'Cancelled';
      cancelledData['cancellationReason'] = _selectedReason; // Root level reason
      cancelledData['cancelledAt'] = FieldValue.serverTimestamp();

      // 3. Use a WriteBatch for absolute safety
      // This copies it to "cancelled_orders" and deletes it from "orders" at the exact same time
      WriteBatch batch = FirebaseFirestore.instance.batch();

      DocumentReference activeOrderRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .doc(orderId);

      DocumentReference cancelledOrderRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cancelled_orders')
          .doc(orderId);

      batch.set(cancelledOrderRef, cancelledData); // Save to history
      batch.delete(activeOrderRef); // Remove from active Orders Tab

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product cancelled successfully.'), backgroundColor: Colors.green),
        );

        // Pop back twice to return to the main Orders Tab so they see it is gone
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel product: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Button is only active if at least one item is checked AND a reason is selected
    final bool canSubmit = _anySelected && _selectedReason != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: brandColor), onPressed: () => Navigator.pop(context)),
        title: Text('DECART', style: TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontFamily: 'Times New Roman', letterSpacing: 2)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cancel items', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // --- ITEMS CONTAINER ---
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Select All / Clear Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: GestureDetector(
                      onTap: _toggleSelectAll,
                      child: Text(
                        _allSelected ? 'Clear' : 'Select all',
                        style: TextStyle(color: Colors.blue.shade700, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey.shade300),

                  // Item List
                  ...List.generate(_items.length, (index) {
                    final item = _items[index];
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _selectedItems[index],
                                  activeColor: Colors.blue.shade700,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _selectedItems[index] = value ?? false;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  item['imageUrl'] ?? '', width: 50, height: 50, fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(width: 50, height: 50, color: Colors.grey.shade200),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['name'] ?? 'Product', style: TextStyle(color: Colors.blue.shade800, fontSize: 13, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    Text('₹${item['price'] ?? 0}', style: const TextStyle(color: Color(0xFFB12704), fontSize: 13, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (index < _items.length - 1) Divider(height: 1, color: Colors.grey.shade200),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- REASON DROPDOWN ---
            Container(
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(6),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text('Cancellation reason', style: TextStyle(fontSize: 14, color: Colors.black87)),
                  value: _selectedReason,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                  items: _cancellationReasons.map((String reason) {
                    return DropdownMenuItem<String>(
                      value: reason,
                      child: Text(reason, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedReason = newValue;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- SUBMIT BUTTON ---
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 200,
                height: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canSubmit ? const Color(0xFFF0F2F2) : Colors.grey.shade200,
                    foregroundColor: Colors.black,
                    elevation: canSubmit ? 1 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: canSubmit ? Colors.grey.shade400 : Colors.transparent),
                    ),
                  ),
                  onPressed: canSubmit && !_isLoading ? _requestCancellation : null,
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Request cancellation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.normal)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}