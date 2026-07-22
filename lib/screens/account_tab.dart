import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AccountTab extends StatefulWidget {
  final VoidCallback onNavigateHome;

  const AccountTab({super.key, required this.onNavigateHome});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;

  // --- NEW: Track password visibility ---
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show Profile if already logged in
    if (FirebaseAuth.instance.currentUser != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text("You are logged in!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(FirebaseAuth.instance.currentUser!.email ?? '', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await _authService.logoutUser();
                setState(() {}); // Refresh the tab
              },
              child: const Text("Log Out"),
            )
          ],
        ),
      );
    }

    // Show Login/Register Form
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

                    const Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      height: 45, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                      child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword, // <-- BOUND TO VARIABLE
                              decoration: const InputDecoration(border: InputBorder.none, hintText: 'At least 6 characters')
                          )
                      ),
                    ),

                    const SizedBox(height: 8),

                    // --- NEW: SHOW PASSWORD CHECKBOX ---
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: !_obscurePassword,
                            activeColor: const Color(0xFF0F4C5C),
                            onChanged: (bool? value) {
                              setState(() {
                                _obscurePassword = !(value ?? false);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Show password', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                    // -----------------------------------

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

                          setState(() => _isLoading = false);

                          if (result == "Success") {
                            _emailController.clear(); _passwordController.clear(); _nameController.clear();
                            widget.onNavigateHome();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isLoginMode ? "Logged in securely!" : "Account created successfully!")));
                          } else {
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