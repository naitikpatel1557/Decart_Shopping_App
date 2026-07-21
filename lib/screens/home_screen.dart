import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- ADDED FIRESTORE IMPORT
import '../models/product_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Navigation Index
  int _selectedIndex = 0;

  // Auth Controllers & State
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;

  // Theme Colors
  final Color brandColor = const Color(0xFF0F4C5C);
  final Color drawerBgColor = const Color(0xFF04201E);
  final Color drawerIconColor = const Color(0xFF2DD4BF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _selectedIndex == 4 ? Colors.white : Colors.grey.shade50,

      drawer: _buildCustomDrawer(),
      appBar: _selectedIndex == 4 ? _buildAccountAppBar() : _buildHomeAppBar(),
      body: _buildBodyContent(),

      // --- BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1.0)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: brandColor,
          unselectedItemColor: Colors.grey.shade500,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4.0), child: Icon(Icons.home_outlined)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4.0), child: Icon(Icons.home)),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4.0), child: Icon(Icons.grid_view_outlined)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4.0), child: Icon(Icons.grid_view)),
              label: 'Categories',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4.0), child: Icon(Icons.favorite_border)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4.0), child: Icon(Icons.favorite)),
              label: 'Wishlist',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4.0), child: Icon(Icons.shopping_bag_outlined)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4.0), child: Icon(Icons.shopping_bag)),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4.0), child: Icon(Icons.person_outline)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4.0), child: Icon(Icons.person)),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }

  // --- DYNAMIC BODY ROUTING ---
  Widget _buildBodyContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeBody();
      case 4:
        return _buildAccountBody();
      default:
        return const Center(child: Text("Coming Soon"));
    }
  }

  // ==========================================
  //            ACCOUNT / LOGIN UI
  // ==========================================

  PreferredSizeWidget _buildAccountAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF0F4C5C)),
        onPressed: () {
          setState(() {
            _selectedIndex = 0;
          });
        },
      ),
      title: const Text(
        'DECÁRT.in',
        style: TextStyle(
          color: Colors.black87,
          fontFamily: 'Times New Roman',
          letterSpacing: 2.0,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() { _selectedIndex = 0; });
          },
          child: const Text('Skip', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: Colors.grey.shade200, height: 1.0),
      ),
    );
  }

  Widget _buildAccountBody() {
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
                setState(() {}); // Refresh UI
              },
              child: const Text("Log Out"),
            )
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLoginMode ? 'Sign in' : 'Create account',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),

                    if (!_isLoginMode) ...[
                      const Text('Full Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        height: 45,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(border: InputBorder.none, hintText: 'First and Last name'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    const Text('Email address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      height: 45,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(border: InputBorder.none, hintText: 'Enter your email'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      height: 45,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(border: InputBorder.none, hintText: 'At least 6 characters'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD814),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: const BorderSide(color: Color(0xFFFCD200)),
                          ),
                        ),
                        onPressed: _isLoading ? null : () async {
                          setState(() => _isLoading = true);

                          String? result;
                          if (_isLoginMode) {
                            result = await _authService.loginUser(
                                email: _emailController.text.trim(),
                                password: _passwordController.text.trim()
                            );
                          } else {
                            result = await _authService.registerUser(
                                name: _nameController.text.trim(),
                                email: _emailController.text.trim(),
                                password: _passwordController.text.trim()
                            );
                          }

                          setState(() => _isLoading = false);

                          if (result == "Success") {
                            _emailController.clear();
                            _passwordController.clear();
                            _nameController.clear();
                            setState(() => _selectedIndex = 0);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_isLoginMode ? "Logged in securely!" : "Account created successfully!")),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result ?? "An error occurred")));
                          }
                        },
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : const Text('Continue', style: TextStyle(fontSize: 15)),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_isLoginMode ? "New to Decart? " : "Already have an account? ", style: const TextStyle(fontSize: 13)),
                        GestureDetector(
                          onTap: () {
                            setState(() { _isLoginMode = !_isLoginMode; });
                          },
                          child: Text(
                              _isLoginMode ? "Create an account" : "Sign in",
                              style: TextStyle(color: Colors.blue.shade700, fontSize: 13, fontWeight: FontWeight.bold)
                          ),
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
                        const Expanded(
                          child: Text(
                            'DECÁRT SECURE SOCKETS LAYER ENCRYPTION',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          color: Colors.grey.shade50,
          width: double.infinity,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Conditions of Use', style: TextStyle(color: Colors.blue.shade800, fontSize: 12)),
                  const SizedBox(width: 24),
                  Text('Privacy Notice', style: TextStyle(color: Colors.blue.shade800, fontSize: 12)),
                  const SizedBox(width: 24),
                  Text('Help', style: TextStyle(color: Colors.blue.shade800, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '© 1996-2026, Decart.com, Inc. or its affiliates',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  //            HOME UI (Index 0)
  // ==========================================

  PreferredSizeWidget _buildHomeAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.menu, color: brandColor),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      titleSpacing: 0,
      title: Text(
        'DECÁRT',
        style: TextStyle(
          color: brandColor,
          fontFamily: 'Times New Roman',
          letterSpacing: 3.0,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: const Text(
              'Support FAQs',
              style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(icon: Icon(Icons.notifications_none, color: brandColor), onPressed: () {}),
            Positioned(
              right: 12,
              top: 12,
              child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
            ),
          ],
        ),
        IconButton(icon: Icon(Icons.shopping_cart_outlined, color: brandColor), onPressed: () {}),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(65.0),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(Icons.search, color: Colors.grey.shade600),
                const SizedBox(width: 12),
                Text('Search for products, brands and more...', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeBody() {
    return StreamBuilder<List<Product>>(
      stream: _databaseService.getProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No products found in database."));

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            Product product = snapshot.data![index];
            return ListTile(
              title: Text(product.name),
              subtitle: Text("₹${product.price.toString()}"),
              leading: product.imageUrls.isNotEmpty
                  ? Image.network(product.imageUrls[0], width: 50, errorBuilder: (c, e, s) => const Icon(Icons.broken_image))
                  : const Icon(Icons.image),
            );
          },
        );
      },
    );
  }

  // ==========================================
  //            DRAWER UI
  // ==========================================

  Widget _buildCustomDrawer() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final bool isLoggedIn = currentUser != null;

    return Drawer(
      backgroundColor: drawerBgColor,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          color: drawerBgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orangeAccent, width: 2),
                        ),
                        child: Icon(isLoggedIn ? Icons.person_outline : Icons.login_rounded, color: Colors.orangeAccent, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DECÁRT', style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),

                            // ----- NAME FETCHING LOGIC HERE -----
                            if (isLoggedIn)
                              FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get(),
                                builder: (context, snapshot) {
                                  String displayName = 'Loading...';

                                  if (snapshot.connectionState == ConnectionState.done) {
                                    if (snapshot.hasData && snapshot.data!.exists) {
                                      var data = snapshot.data!.data() as Map<String, dynamic>?;
                                      displayName = data?['name'] ?? 'User';
                                    } else {
                                      displayName = 'User';
                                    }
                                  }

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Text('Premium Active Member', style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 10)),
                                    ],
                                  );
                                },
                              )
                            else
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  setState(() { _selectedIndex = 4; });
                                },
                                behavior: HitTestBehavior.opaque,
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Login / Register', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                    Text('Tap here to sign in', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(color: Colors.white.withOpacity(0.1), height: 1),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _drawerItem(icon: Icons.home_outlined, title: 'Home', isSelected: _selectedIndex == 0, onTap: () { Navigator.pop(context); setState(() { _selectedIndex = 0; }); }),
                  _drawerItem(icon: Icons.grid_view, title: 'Categories'),
                  _drawerItem(icon: Icons.shopping_cart_outlined, title: 'Cart'),
                  _drawerItem(icon: Icons.favorite_border, title: 'Wishlist'),
                  _drawerItem(icon: Icons.inventory_2_outlined, title: 'Orders'),
                  _drawerItem(icon: Icons.local_offer_outlined, title: 'My Coupons', trailing: _buildNewBadge()),
                  _drawerItem(icon: Icons.headset_mic_outlined, title: 'Help & Support'),
                  if (isLoggedIn) ...[
                    _drawerItem(icon: Icons.location_on_outlined, title: 'My Address'),
                    _drawerItem(icon: Icons.info_outline, title: 'Account Settings'),
                  ],
                  _drawerItem(icon: Icons.privacy_tip_outlined, title: 'Privacy Policy'),
                  _drawerItem(icon: Icons.description_outlined, title: 'Terms & Conditions'),
                  const SizedBox(height: 16),
                  if (isLoggedIn) _drawerItem(icon: Icons.logout, title: 'Logout', isLogout: true, onTap: () async {
                    await _authService.logoutUser();
                    Navigator.pop(context);
                    setState(() {}); // Refresh State
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({required IconData icon, required String title, bool isSelected = false, bool isLogout = false, Widget? trailing, VoidCallback? onTap}) {
    Color textColor = isLogout ? Colors.redAccent : (isSelected ? drawerBgColor : Colors.white);
    Color iconColor = isLogout ? Colors.redAccent : (isSelected ? drawerBgColor : drawerIconColor);
    Color tileBgColor = isSelected ? const Color(0xFFE0F2FE) : Colors.transparent;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(color: tileBgColor, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 22),
        title: Text(title, style: TextStyle(color: textColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
        trailing: trailing,
        onTap: onTap ?? () {},
      ),
    );
  }

  Widget _buildNewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.orangeAccent, borderRadius: BorderRadius.circular(12)),
      child: const Text('NEW', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}