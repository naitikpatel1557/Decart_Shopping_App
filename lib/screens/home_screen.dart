import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

// Import our new extracted modular pages
import 'home_tab.dart';
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

  // Theme Colors
  final Color brandColor = const Color(0xFF0F4C5C);
  final Color drawerBgColor = const Color(0xFF04201E);
  final Color drawerIconColor = const Color(0xFF2DD4BF);

  void _switchTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _selectedIndex == 4 ? Colors.white : Colors.grey.shade50,

      drawer: _buildCustomDrawer(),
      appBar: _selectedIndex == 4 ? _buildAccountAppBar() : _buildHomeAppBar(),

      // Look how clean the body router is now!
      body: _buildBodyContent(),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1.0))),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _switchTab,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: brandColor,
          unselectedItemColor: Colors.grey.shade500,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4.0), child: Icon(Icons.home_outlined)), activeIcon: Padding(padding: EdgeInsets.only(bottom: 4.0), child: Icon(Icons.home)), label: 'Home'),
            BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4.0), child: Icon(Icons.grid_view_outlined)), activeIcon: Padding(padding: EdgeInsets.only(bottom: 4.0), child: Icon(Icons.grid_view)), label: 'Categories'),
            BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4.0), child: Icon(Icons.favorite_border)), activeIcon: Padding(padding: EdgeInsets.only(bottom: 4.0), child: Icon(Icons.favorite)), label: 'Wishlist'),
            BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4.0), child: Icon(Icons.shopping_bag_outlined)), activeIcon: Padding(padding: EdgeInsets.only(bottom: 4.0), child: Icon(Icons.shopping_bag)), label: 'Orders'),
            BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4.0), child: Icon(Icons.person_outline)), activeIcon: Padding(padding: EdgeInsets.only(bottom: 4.0), child: Icon(Icons.person)), label: 'Account'),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    switch (_selectedIndex) {
      case 0:
        return const HomeTab(); // Call the extracted Home file
      case 4:
        return AccountTab(onNavigateHome: () => _switchTab(0)); // Call the extracted Account file
      default:
        return const Center(child: Text("Coming Soon... Create more modular tabs!"));
    }
  }

  PreferredSizeWidget _buildHomeAppBar() {
    return AppBar(
      backgroundColor: Colors.white, elevation: 0,
      leading: IconButton(icon: Icon(Icons.menu, color: brandColor), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
      titleSpacing: 0,
      title: Text('DECÁRT', style: TextStyle(color: brandColor, fontFamily: 'Times New Roman', letterSpacing: 3.0, fontSize: 22, fontWeight: FontWeight.w600)),
      actions: [
        Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.red.shade100)), child: const Text('Support FAQs', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)))),
        const SizedBox(width: 4),
        Stack(alignment: Alignment.center, children: [IconButton(icon: Icon(Icons.notifications_none, color: brandColor), onPressed: () {}), Positioned(right: 12, top: 12, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)))]),
        IconButton(icon: Icon(Icons.shopping_cart_outlined, color: brandColor), onPressed: () {}),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(65.0),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
            child: Row(children: [const SizedBox(width: 12), Icon(Icons.search, color: Colors.grey.shade600), const SizedBox(width: 12), Text('Search for products, brands and more...', style: TextStyle(color: Colors.grey.shade500, fontSize: 14))]),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAccountAppBar() {
    return AppBar(
      backgroundColor: Colors.white, elevation: 0, centerTitle: true,
      leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF0F4C5C)), onPressed: () => _switchTab(0)),
      title: const Text('DECÁRT.in', style: TextStyle(color: Colors.black87, fontFamily: 'Times New Roman', letterSpacing: 2.0, fontSize: 20, fontWeight: FontWeight.bold)),
      actions: [TextButton(onPressed: () => _switchTab(0), child: const Text('Skip', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)))],
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1.0), child: Container(color: Colors.grey.shade200, height: 1.0)),
    );
  }

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
                  Align(alignment: Alignment.topRight, child: IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context))),
                  Row(
                    children: [
                      Container(width: 60, height: 60, decoration: BoxDecoration(color: drawerBgColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orangeAccent, width: 2)), child: Icon(isLoggedIn ? Icons.person_outline : Icons.login_rounded, color: Colors.orangeAccent, size: 28)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DECÁRT', style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                            if (isLoggedIn)
                              FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get(),
                                builder: (context, snapshot) {
                                  String displayName = 'Loading...';
                                  if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data!.exists) {
                                    displayName = (snapshot.data!.data() as Map<String, dynamic>?)?['name'] ?? 'User';
                                  }
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const Text('Premium Active Member', style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 10)),
                                    ],
                                  );
                                },
                              )
                            else
                              GestureDetector(
                                onTap: () { Navigator.pop(context); _switchTab(4); },
                                behavior: HitTestBehavior.opaque,
                                child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Login / Register', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), Text('Tap here to sign in', style: TextStyle(color: Colors.grey, fontSize: 10))]),
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
                  _drawerItem(icon: Icons.home_outlined, title: 'Home', isSelected: _selectedIndex == 0, onTap: () { Navigator.pop(context); _switchTab(0); }),
                  _drawerItem(icon: Icons.grid_view, title: 'Categories'),
                  _drawerItem(icon: Icons.shopping_cart_outlined, title: 'Cart'),
                  _drawerItem(icon: Icons.favorite_border, title: 'Wishlist'),
                  _drawerItem(icon: Icons.inventory_2_outlined, title: 'Orders'),
                  _drawerItem(icon: Icons.local_offer_outlined, title: 'My Coupons'),
                  _drawerItem(icon: Icons.headset_mic_outlined, title: 'Help & Support'),
                  if (isLoggedIn) ...[
                    _drawerItem(icon: Icons.location_on_outlined, title: 'My Address'),
                    _drawerItem(icon: Icons.info_outline, title: 'Account Settings'),
                  ],
                  const SizedBox(height: 16),
                  if (isLoggedIn) _drawerItem(icon: Icons.logout, title: 'Logout', isLogout: true, onTap: () async {
                    await _authService.logoutUser();
                    Navigator.pop(context);
                    setState(() {});
                  }),
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
      child: ListTile(leading: Icon(icon, color: iconColor, size: 22), title: Text(title, style: TextStyle(color: textColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 14)), onTap: onTap ?? () {}),
    );
  }
}