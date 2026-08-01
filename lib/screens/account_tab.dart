import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'address_screen.dart';
import 'orders_tab.dart';

class AccountTab extends StatefulWidget {
  final VoidCallback onNavigateHome;

  const AccountTab({super.key, required this.onNavigateHome});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your email address in the box above first!')));
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password reset link sent to $email!'), backgroundColor: Colors.green));
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'An error occurred.')));
      }
    }
  }

  void _showEditProfileDialog(String currentName) {
    final TextEditingController editNameController = TextEditingController(text: currentName);

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Times New Roman')),
            content: TextField(
              controller: editNameController,
              decoration: InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey))
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C5C)),
                onPressed: () async {
                  if (editNameController.text.trim().isNotEmpty) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .update({'name': editNameController.text.trim(), 'fullName': editNameController.text.trim()});
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: const Text("Save", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser != null) {
      final User user = FirebaseAuth.instance.currentUser!;

      return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF0F4C5C)));
            }

            String displayName = "User";
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              displayName = data['name'] ?? data['fullName'] ?? "User";
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: const Color(0xFF0F4C5C).withOpacity(0.1),
                          child: Text(displayName[0].toUpperCase(), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF0F4C5C))),
                        ),
                        const SizedBox(height: 16),
                        Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Times New Roman')),
                        const SizedBox(height: 4),
                        Text(user.email ?? '', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Profile Menu Options
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle), child: Icon(Icons.person_outline, color: Colors.blue.shade700)),
                          title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.w500)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          onTap: () => _showEditProfileDialog(displayName),
                        ),

                        // --- FIXED: MY ORDERS BUTTON ---
                        const Divider(height: 1, indent: 60),
                        ListTile(
                          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.purple.shade50, shape: BoxShape.circle), child: Icon(Icons.shopping_bag_outlined, color: Colors.purple.shade700)),
                          title: const Text("My Orders", style: TextStyle(fontWeight: FontWeight.w500)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                                builder: (context) => OrdersTab(onNavigateToHome: widget.onNavigateHome) // Fixed parameter!
                            ));
                          },
                        ),

                        const Divider(height: 1, indent: 60),
                        ListTile(
                          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle), child: Icon(Icons.location_on_outlined, color: Colors.orange.shade700)),
                          title: const Text("My Addresses", style: TextStyle(fontWeight: FontWeight.w500)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const AddressScreen()));
                          },
                        ),

                        const Divider(height: 1, indent: 60),
                        ListTile(
                          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle), child: Icon(Icons.logout, color: Colors.red.shade700)),
                          title: Text("Log Out", style: TextStyle(fontWeight: FontWeight.w500, color: Colors.red.shade700)),
                          onTap: () async {
                            await _authService.logoutUser();
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isLoginMode ? 'Sign in' : 'Create account', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 16),
                    if (!_isLoginMode) ...[
                      const Text('Full Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        height: 45, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: TextField(controller: _nameController, decoration: const InputDecoration(border: InputBorder.none, hintText: 'First and Last name'))),
                      ),
                      const SizedBox(height: 16),
                    ],

                    const Text('Email address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      height: 45, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(border: InputBorder.none, hintText: 'Enter your email'))),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        if (_isLoginMode)
                          GestureDetector(
                            onTap: _resetPassword,
                            child: const Text('Forgot password?', style: TextStyle(fontSize: 12, color: Color(0xFF0F4C5C), fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 45, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                      child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: const InputDecoration(border: InputBorder.none, hintText: 'At least 6 characters')
                          )
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        SizedBox(
                          height: 24, width: 24,
                          child: Checkbox(
                            value: !_obscurePassword, activeColor: const Color(0xFF0F4C5C),
                            onChanged: (bool? value) { setState(() { _obscurePassword = !(value ?? false); }); },
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Show password', style: TextStyle(fontSize: 13)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity, height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD814), foregroundColor: Colors.black, elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: const BorderSide(color: Color(0xFFFCD200))),
                        ),
                        onPressed: _isLoading ? null : () async {
                          setState(() => _isLoading = true);

                          String? result = _isLoginMode
                              ? await _authService.loginUser(email: _emailController.text.trim(), password: _passwordController.text.trim())
                              : await _authService.registerUser(name: _nameController.text.trim(), email: _emailController.text.trim(), password: _passwordController.text.trim());

                          if (!mounted) return;

                          if (result == "Success") {
                            _emailController.clear();
                            _passwordController.clear();
                            _nameController.clear();

                            try {
                              final prodCheck = await FirebaseFirestore.instance.collection('products').limit(1).get();
                              if (prodCheck.docs.isEmpty) {
                                await _databaseService.uploadAllDummyData();
                              }
                            } catch (e) {
                              debugPrint("Background upload failed: $e");
                            }

                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isLoginMode ? "Logged in securely!" : "Account created successfully!")));
                            widget.onNavigateHome();
                          } else {
                            setState(() => _isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result ?? "An error occurred")));
                          }
                        },
                        child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('Continue', style: TextStyle(fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_isLoginMode ? "New to Decart? " : "Already have an account? ", style: const TextStyle(fontSize: 13)),
                        GestureDetector(
                          onTap: () { setState(() { _isLoginMode = !_isLoginMode; }); },
                          child: Text(_isLoginMode ? "Create an account" : "Sign in", style: TextStyle(color: Colors.blue.shade700, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Divider(color: Colors.grey.shade200, thickness: 1.5),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.shield_outlined, color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('DECÁRT SECURE SOCKETS LAYER ENCRYPTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}