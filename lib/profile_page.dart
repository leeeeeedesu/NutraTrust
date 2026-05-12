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
import 'utils/app_theme.dart';

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

    debugPrint('Loaded name: $loadedName');
    debugPrint('Loaded bio: $loadedBio');
    debugPrint('Loaded profileImage: $loadedProfileImage');
    debugPrint('Is admin: $isAdmin');

    if (!mounted) return;
    setState(() {
      _isAdmin = isAdmin;
      _profileName = loadedName;
      _profileBio = loadedBio;
      _profileImageUrl = loadedProfileImage;
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

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.primary, width: 3),
            ),
            child: _profileImageUrl != null
                ? ClipOval(
                    child: Image.network(
                      _profileImageUrl!,
                      fit: BoxFit.cover,
                      width: 100,
                      height: 100,
                    ),
                  )
                : Icon(Icons.person, size: 50, color: AppColors.primary),
          ),

          const SizedBox(height: 16),

          // Profile Info
          if (_isAdmin) ...[
            Text(
              'Admin Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Administrator',
              style: TextStyle(fontSize: 16, color: AppColors.text),
            ),
          ] else ...[
            Text(
              _profileName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _profileBio,
              style: TextStyle(fontSize: 16, color: AppColors.text),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuSections() {
    if (_isAdmin) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Panel',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            _buildMenuItem(
              icon: Icons.admin_panel_settings,
              title: 'Admin Dashboard',
              subtitle: 'Manage products and orders',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Admin dashboard coming soon')),
                );
              },
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Account Settings Section
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 16),
              _buildMenuItem(
                icon: Icons.settings,
                title: 'Settings',
                subtitle: 'Account preferences and privacy',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AccountSettingsPage(),
                  ),
                ),
              ),
              _buildMenuItem(
                icon: Icons.location_on,
                title: 'Shipping Location',
                subtitle: 'Manage delivery addresses',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ShippingLocationPage(),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Shopping Section
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shopping',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 16),
              _buildMenuItem(
                icon: Icons.payment,
                title: 'To Pay',
                subtitle: 'Pending payments',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ToPayPage()),
                ),
              ),
              _buildMenuItem(
                icon: Icons.rate_review,
                title: 'My Reviews',
                subtitle: 'Product reviews and ratings',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReviewsPage()),
                ),
              ),
              _buildMenuItem(
                icon: Icons.account_balance_wallet,
                title: 'Wallet',
                subtitle: 'Payment methods and balance',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletPage()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: AppColors.text),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.text),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Management',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                CartService.clear();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logged out successfully')),
                  );
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isAdmin)
            IconButton(
              onPressed: () {
                // TODO: Implement profile editing
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile editing coming soon')),
                );
              },
              icon: const Icon(Icons.edit),
            ),
        ],
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header
                  _buildProfileHeader(),

                  const SizedBox(height: 24),

                  // Menu Sections
                  _buildMenuSections(),

                  const SizedBox(height: 24),

                  // Account Section
                  _buildAccountSection(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
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
