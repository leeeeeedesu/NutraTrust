import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'shoppingcart_page.dart';
import 'home_page.dart';
import 'likes_page.dart';
import 'login_page.dart';
import 'services/realtime_database_service.dart';
import 'reviews_page.dart';
import 'trackorders_page.dart';
import 'account_settings.dart';
import 'shipping_location.dart';
import 'to_pay.dart';
import 'wallet_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 4; // Profile index
  bool _loadingProfile = true;
  bool _isAdmin = false;
  String _profileName = 'Profile Name';
  String _profileBio = 'Bio';
  String? _profileImageUrl;
  String? _bannerImageUrl;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return;
    }

    final profileModel = await RealtimeDatabaseService.getUserProfileModel(
      currentUser.uid,
    );
    final accountData = await RealtimeDatabaseService.getUserAccountProfile(
      currentUser.uid,
    );
    final images = await RealtimeDatabaseService.getUserImages(currentUser.uid);

    // Check if user is admin
    final customerData = await RealtimeDatabaseService.getCustomerOrDefault(
      currentUser.uid,
    );
    final isAdmin = customerData['role']?.toString().toLowerCase() == 'admin';

    final loadedName = profileModel?.fullName.isNotEmpty == true
        ? profileModel!.fullName
        : currentUser.email?.split('@').first ?? 'Profile Name';
    final loadedBio = accountData?['bio']?.toString() ?? 'Bio';
    final loadedProfileImage = images['profileImage'];
    final loadedBannerImage = images['bannerImage'];

    debugPrint('Loaded name: $loadedName');
    debugPrint('Loaded bio: $loadedBio');
    debugPrint('Loaded profileImage: $loadedProfileImage');
    debugPrint('Loaded bannerImage: $loadedBannerImage');
    debugPrint('Is admin: $isAdmin');

    if (!mounted) return;
    setState(() {
      _isAdmin = isAdmin;
      _profileName = loadedName;
      _profileBio = loadedBio;
      _profileImageUrl = loadedProfileImage;
      _bannerImageUrl = loadedBannerImage;
      _nameController.text = _profileName;
      _bioController.text = _profileBio;
      _loadingProfile = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: // Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
        break;
      case 1: // Likes
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LikesPage()),
        );
        break;
      case 2: // Track Orders
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TrackOrdersPage()),
        );
        break;
      case 3: // Shopping Cart
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ShoppingCartPage()),
        );
        break;
      case 4: // Profile

        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Page not yet implemented")),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: const Color(0xFF028B22),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Banner image with edit button - only for non-admin users
            if (!_isAdmin)
              Stack(
                children: [
                  Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: _bannerImageUrl != null
                        ? Image.network(
                            _bannerImageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 150,
                          )
                        : const Center(child: Text("Choose you BG Picture")),
                  ),
                ],
              ),

            const SizedBox(height: 16),
            // Profile image with edit button
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.green[200],
                  backgroundImage: _profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!)
                      : null,
                  child: _profileImageUrl == null
                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loadingProfile)
              const CircularProgressIndicator(color: Color(0xFF028B22))
            else if (_isAdmin) ...[
              // Admin profile - simplified view
              const SizedBox(height: 12),
              const Text(
                'Admin Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF028B22),
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              // Regular user profile
              Column(
                children: [
                  Text(
                    _profileName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),

              const SizedBox(height: 24),
              // Action buttons
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.green),
                title: const Text("Settings"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AccountSettingsPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on, color: Colors.green),
                title: const Text("Set your shipping Location"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ShippingLocationPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.payment, color: Colors.green),
                title: const Text("To pay"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ToPayPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.rate_review, color: Colors.green),
                title: const Text("Reviews"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReviewsPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.green,
                ),
                title: const Text("Wallet"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WalletPage()),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Log Out button
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("Logged out")));
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Log Out"),
              ),
            ],
          ],
        ),
      ),

      // Bottom navigation bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1E8B3A),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          const BottomNavigationBarItem(
            icon: LikeBadgeIcon(child: Icon(Icons.favorite)),
            label: "Likes",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: "Track Orders",
          ),
          const BottomNavigationBarItem(
            icon: CartBadgeIcon(child: Icon(Icons.shopping_cart)),
            label: "Shopping Cart",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
