import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

// Import our tabs
import 'home_tab.dart';
import 'categories_tab.dart';
import 'wishlist_tab.dart';
import 'account_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService();

  int _selectedIndex = 0;

  // --- MASTER WISHLIST STATE ---
  final Set<String> _wishlistIds = {};

  void _toggleWishlist(String productId, String productName) {
    setState(() {
      if (_wishlistIds.contains(productId)) {
        _wishlistIds.remove(productId);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$productName removed'), duration: const Duration(seconds: 1)));
      } else {
        _wishlistIds.add(productId);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$productName added! ❤️'), duration: const Duration(seconds: 1), backgroundColor: Colors.pink));
      }
    });
  }

  final Color brandColor = const Color(0xFF0F4C5C);
  final Color drawerBgColor = const Color(0xFF04201E);
  final Color drawerIconColor = const Color(0xFF2DD4BF);

  void _switchTab(int index) {
    setState(() { _selectedIndex = index; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _selectedIndex == 4 ? Colors.white : Colors.grey.shade50,
      drawer: _buildCustomDrawer(),
      appBar: _selectedIndex == 4 ? _buildAccountAppBar() : _buildHomeAppBar(),
      body: _buildBodyContent(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1.0))),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _switchTab,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white, selectedItemColor: brandColor, unselectedItemColor: Colors.grey.shade500,
          selectedFontSize: 11, unselectedFontSize: 11, elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), activeIcon: Icon(Icons.grid_view), label: 'Categories'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite_border), activeIcon: Icon(Icons.favorite), label: 'Wishlist'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), activeIcon: Icon(Icons.shopping_bag), label: 'Orders'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Account'),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    switch (_selectedIndex) {
      case 0:
        return HomeTab(
          onNavigateToCategories: () => _switchTab(1),
          wishlistIds: _wishlistIds,
          onToggleWishlist: _toggleWishlist,
        );
      case 1:
        return const CategoriesTab();
      case 2:
        return WishlistTab(
          wishlistIds: _wishlistIds,
          onToggleWishlist: _toggleWishlist,
        );
      case 3:
        return const Center(child: Text("Orders Page")); // Orders tab placeholder
      case 4:
        return AccountTab(onNavigateHome: () => _switchTab(0));
      default:
        return const Center(child: Text("Coming Soon..."));
    }
  }

  PreferredSizeWidget _buildHomeAppBar() {
    return AppBar(
      backgroundColor: Colors.white, elevation: 0,
      leading: IconButton(icon: Icon(Icons.menu, color: brandColor), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
      titleSpacing: 0,
      title: Text('DECÁRT', style: TextStyle(color: brandColor, fontFamily: 'Times New Roman', letterSpacing: 3.0, fontSize: 22, fontWeight: FontWeight.w600)),
      actions: [
        Center(
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.red.shade100)),
                child: const Text('Support FAQs', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold))
            )
        ),
        const SizedBox(width: 4),
        Stack(
            alignment: Alignment.center,
            children: [
              IconButton(icon: Icon(Icons.notifications_none, color: brandColor), onPressed: () {}),
              Positioned(right: 12, top: 12, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)))
            ]
        ),
        IconButton(icon: Icon(Icons.shopping_cart_outlined, color: brandColor), onPressed: () {}),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(65.0),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
            child: Row(children: [const SizedBox(width: 12), Icon(Icons.search, color: Colors.grey.shade600), const SizedBox(width: 12), Text('Search for products...', style: TextStyle(color: Colors.grey.shade500, fontSize: 14))]),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAccountAppBar() {
    return AppBar(backgroundColor: Colors.white, elevation: 0, centerTitle: true, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF0F4C5C)), onPressed: () => _switchTab(0)), title: const Text('DECÁRT.in', style: TextStyle(color: Colors.black87, fontFamily: 'Times New Roman', letterSpacing: 2.0, fontSize: 20, fontWeight: FontWeight.bold)));
  }


  Widget _buildCustomDrawer() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final bool isLoggedIn = currentUser != null;

    return Drawer(
      backgroundColor: drawerBgColor,
      child: SafeArea(
        child: Column(
          children: [
            // --- HEADER WITH CLOSE BUTTON & PROFILE INFO ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: drawerBgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orangeAccent, width: 2),
                        ),
                        child: Icon(
                          isLoggedIn ? Icons.person_outline : Icons.login_rounded,
                          color: Colors.orangeAccent,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DECÁRT',
                              style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2),
                            ),
                            const SizedBox(height: 2),
                            if (isLoggedIn)
                              FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get(),
                                builder: (context, snapshot) {
                                  String displayName = 'User Account';
                                  if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data!.exists) {
                                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                                    displayName = data?['name'] ?? data?['fullName'] ?? 'User Account';
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
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Premium Active Member',
                                        style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 10, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  );
                                },
                              )
                            else
                              GestureDetector(
                                onTap: () { Navigator.pop(context); _switchTab(4); },
                                child: const Text('Login / Register', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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

            // --- SCROLLABLE MENU ITEMS ---
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _drawerItem(icon: Icons.home_outlined, title: 'Home', isSelected: _selectedIndex == 0, onTap: () { Navigator.pop(context); _switchTab(0); }),
                  _drawerItem(icon: Icons.grid_view, title: 'Categories', isSelected: _selectedIndex == 1, onTap: () { Navigator.pop(context); _switchTab(1); }),
                  _drawerItem(icon: Icons.shopping_cart_outlined, title: 'Cart', onTap: () { Navigator.pop(context); }),
                  _drawerItem(icon: Icons.favorite_border, title: 'Wishlist', isSelected: _selectedIndex == 2, onTap: () { Navigator.pop(context); _switchTab(2); }),
                  _drawerItem(icon: Icons.shopping_bag_outlined, title: 'Orders', isSelected: _selectedIndex == 3, onTap: () { Navigator.pop(context); _switchTab(3); }),

                  // My Coupons with "NEW" badge container
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.local_offer_outlined, color: Color(0xFF2DD4BF), size: 22),
                      title: Row(
                        children: [
                          const Text('My Coupons', style: TextStyle(color: Colors.white, fontSize: 14)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.orangeAccent, borderRadius: BorderRadius.circular(4)),
                            child: const Text('NEW', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      onTap: () { Navigator.pop(context); },
                    ),
                  ),

                  _drawerItem(icon: Icons.headset_mic_outlined, title: 'Help & Support', onTap: () { Navigator.pop(context); }),
                  _drawerItem(icon: Icons.location_on_outlined, title: 'My Address', onTap: () { Navigator.pop(context); }),
                  _drawerItem(icon: Icons.info_outline, title: 'Account Settings', onTap: () { Navigator.pop(context); }),
                  _drawerItem(icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', onTap: () { Navigator.pop(context); }),
                  _drawerItem(icon: Icons.description_outlined, title: 'Terms & Conditions', onTap: () { Navigator.pop(context); }),

                  const SizedBox(height: 8),
                  if (isLoggedIn)
                    _drawerItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      isLogout: true,
                      onTap: () async {
                        await _authService.logoutUser();
                        Navigator.pop(context);
                        setState(() {});
                      },
                    ),
                ],
              ),
            ),

            // --- FOOTER VERSION TEXT ---
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  const Text(
                    'Decárt Core Platform v1.4',
                    style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Securely Encrypted',
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({required IconData icon, required String title, bool isSelected = false, bool isLogout = false, VoidCallback? onTap}) {
    Color textColor = isLogout ? Colors.redAccent : (isSelected ? drawerBgColor : Colors.white);
    Color iconColor = isLogout ? Colors.redAccent : (isSelected ? drawerBgColor : drawerIconColor);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(color: isSelected ? const Color(0xFFE0F2FE) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
          leading: Icon(icon, color: iconColor, size: 22),
          title: Text(title, style: TextStyle(color: textColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
          onTap: onTap ?? () {}
      ),
    );
  }
}