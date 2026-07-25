import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final Color brandColor = const Color(0xFF0F4C5C);

  // Controllers for the Address form
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  // --- UPDATED: Unified Form for both Adding and Editing ---
  void _showAddressForm(BuildContext context, {String? docId, Map<String, dynamic>? existingData}) {
    // If we are editing, pre-fill the form with existing data
    if (existingData != null) {
      _nameController.text = existingData['name'] ?? '';
      _phoneController.text = existingData['phone'] ?? '';
      _streetController.text = existingData['street'] ?? '';
      _cityController.text = existingData['city'] ?? '';
      _stateController.text = existingData['state'] ?? '';
      _pincodeController.text = existingData['pincode'] ?? '';
    } else {
      // If we are adding new, clear the form
      _nameController.clear();
      _phoneController.clear();
      _streetController.clear();
      _cityController.clear();
      _stateController.clear();
      _pincodeController.clear();
    }

    final bool isEditing = docId != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isEditing ? 'Edit Address' : 'Add New Address', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(_nameController, 'Full Name', Icons.person_outline),
                      const SizedBox(height: 12),
                      _buildTextField(_phoneController, 'Phone Number', Icons.phone_outlined, isNumber: true),
                      const SizedBox(height: 12),
                      _buildTextField(_streetController, 'House No. / Building / Street', Icons.home_outlined),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_cityController, 'City', Icons.location_city_outlined)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(_stateController, 'State', Icons.map_outlined)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(_pincodeController, 'Pincode', Icons.pin_drop_outlined, isNumber: true),
                      const SizedBox(height: 24),

                      // --- SAVE / UPDATE TO FIREBASE BUTTON ---
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isSaving ? null : () async {
                            if (_nameController.text.isEmpty || _streetController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
                              return;
                            }

                            setModalState(() => _isSaving = true);

                            final addressData = {
                              'name': _nameController.text.trim(),
                              'phone': _phoneController.text.trim(),
                              'street': _streetController.text.trim(),
                              'city': _cityController.text.trim(),
                              'state': _stateController.text.trim(),
                              'pincode': _pincodeController.text.trim(),
                            };

                            try {
                              if (isEditing) {
                                // Update existing address
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(currentUser!.uid)
                                    .collection('addresses')
                                    .doc(docId)
                                    .update(addressData);
                              } else {
                                // Add new address
                                addressData['createdAt'] = FieldValue.serverTimestamp() as String; // Only set on creation
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(currentUser!.uid)
                                    .collection('addresses')
                                    .add(addressData);
                              }

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(isEditing ? 'Address updated successfully!' : 'Address saved successfully!'),
                                        backgroundColor: Colors.green
                                    )
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('An error occurred while saving.')));
                              }
                            } finally {
                              setModalState(() => _isSaving = false);
                            }
                          },
                          child: _isSaving
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(isEditing ? 'Update Address' : 'Save Address', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          border: InputBorder.none, prefixIcon: Icon(icon, color: Colors.grey.shade600),
          hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: const BackButton(color: Colors.black)),
        body: const Center(child: Text("Please log in to view addresses.", style: TextStyle(fontSize: 18))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: brandColor), onPressed: () => Navigator.pop(context)),
        title: Text('My Delivery Addresses', style: TextStyle(color: brandColor, fontFamily: 'Times New Roman', fontWeight: FontWeight.bold)),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('addresses')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: brandColor));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("No addresses found", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                  const SizedBox(height: 8),
                  Text("Add a delivery address to ensure seamless checkout.", style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              String docId = snapshot.data!.docs[index].id;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: brandColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.home, color: brandColor, size: 16)),
                            const SizedBox(width: 8),
                            Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),

                        // --- NEW: EDIT AND DELETE BUTTONS SIDE BY SIDE ---
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _showAddressForm(context, docId: docId, existingData: data),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).collection('addresses').doc(docId).delete(),
                            ),
                          ],
                        )
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(data['street'] ?? '', style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
                    Text("${data['city'] ?? ''}, ${data['state'] ?? ''} - ${data['pincode'] ?? ''}", style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
                    const SizedBox(height: 8),
                    Text("Phone: ${data['phone'] ?? ''}", style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFFD814),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text("Add New Address", style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showAddressForm(context), // Passed with no arguments means "Add New"
      ),
    );
  }
}