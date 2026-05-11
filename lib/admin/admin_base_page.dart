import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/realtime_database_service.dart';
import 'admin_settings.dart';
import 'admin_dashboard.dart';
import '../home_page.dart';

//to add pages
enum AdminPage {
  dashboard,
  manageProduct,
  userLists,
  reviews,
  inventory,
  delivery,
}

//Navigation
class AdminBasePage extends StatelessWidget {
  const AdminBasePage({
    super.key,
    required this.activePage,
    required this.onDashboardTap,
    required this.onManageProductTap,
    required this.onUserListsTap,
    required this.onReviewsTap,
    required this.onInventoryTap,
    required this.onDeliveryTap,
    required this.body,
  });
  //functions for navigation
  final AdminPage activePage;
  final VoidCallback onDashboardTap;
  final VoidCallback onManageProductTap;
  final VoidCallback onUserListsTap;
  final VoidCallback onReviewsTap;
  final VoidCallback onInventoryTap;
  final VoidCallback onDeliveryTap;
  final Widget body;

  static Future<void> redirectAfterLogin(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final accountData = await RealtimeDatabaseService.getUserAccountProfile(
      user.uid,
    );
    final role = accountData?['role']?.toString();
    final isActive = accountData?['isActive'] == true;
    debugPrint('Admin role: $role');
    debugPrint('Active status: $isActive');

    if (role == 'mega_admin' || role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E2E2E),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminSettingsPage(),
                        ),
                      );
                    },
                    child: FutureBuilder<Map<String, dynamic>?>(
                      future: currentUser != null
                          ? RealtimeDatabaseService.getUserAccountProfile(
                              currentUser.uid,
                            )
                          : Future.value(null),
                      builder: (context, snapshot) {
                        final profileImage = snapshot.data?['profileImage']
                            ?.toString();
                        return CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white,
                          backgroundImage:
                              profileImage != null && profileImage.isNotEmpty
                              ? NetworkImage(profileImage)
                              : null,
                          child: profileImage == null || profileImage.isEmpty
                              ? const Icon(Icons.person, color: Colors.grey)
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 22.0,
                    horizontal: 20.0,
                  ),
                  child: Column(
                    children: [
                      Image.asset('assets/NutraTrustnobg.png', width: 70),
                      const SizedBox(height: 8),
                      const Text(
                        'NutraTrust',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F5B2A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<Map<String, dynamic>?>(
                        future: currentUser != null
                            ? RealtimeDatabaseService.getUserAccountProfile(
                                currentUser.uid,
                              )
                            : Future.value(null),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text(
                              'Loading admin info...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6F6F6F),
                              ),
                            );
                          }

                          final email =
                              FirebaseAuth.instance.currentUser?.email ??
                              'Signed in as Admin';
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Text(
                              email,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6F6F6F),
                              ),
                              textAlign: TextAlign.center,
                            );
                          }

                          final adminData = snapshot.data!;
                          final rawRole =
                              adminData['role']?.toString() ?? 'unknown';
                          final role =
                              rawRole == 'admin' || rawRole == 'mega_admin'
                              ? 'Admin'
                              : rawRole;
                          final isActive = adminData['isActive'] == true;
                          debugPrint('Admin role: $rawRole');
                          debugPrint('Active status: $isActive');
                          return Column(
                            children: [
                              Text(
                                email,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6F6F6F),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Role: $role',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6F6F6F),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Status: ${isActive ? 'Active' : 'Inactive'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isActive
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFB71C1C),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF5EA),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: const Color(0xFF028B22)),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 20.0,
                        ),
                        child: const Text(
                          'DASHBOARD',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF028B22),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _NavButton(
                      label: 'Dashboard',
                      active: activePage == AdminPage.dashboard,
                      onTap: onDashboardTap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _NavButton(
                      label: 'Manage Product',
                      active: activePage == AdminPage.manageProduct,
                      onTap: onManageProductTap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _NavButton(
                      label: 'User Lists',
                      active: activePage == AdminPage.userLists,
                      onTap: onUserListsTap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _NavButton(
                      label: 'Reviews',
                      active: activePage == AdminPage.reviews,
                      onTap: onReviewsTap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _NavButton(
                      label: 'Inventory',
                      active: activePage == AdminPage.inventory,
                      onTap: onInventoryTap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _NavButton(
                      label: 'Delivery',
                      active: activePage == AdminPage.delivery,
                      onTap: onDeliveryTap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              body,
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF028B22) : Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: const Color(0xFF028B22)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : const Color(0xFF028B22),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

//PRODUCT PLACEHOLDER
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.description,
    this.imageUrl,
    this.flavors,
  });

  final String title;
  final String subtitle;
  final String price;
  final String description;
  final String? imageUrl;
  final List<String>? flavors;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1F1),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: imageUrl != null && imageUrl!.isNotEmpty
                      ? (imageUrl!.startsWith('http')
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12.0),
                                child: Image.network(
                                  imageUrl!,
                                  width: 52,
                                  height: 52,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12.0),
                                child: Image.asset(
                                  imageUrl!,
                                  width: 52,
                                  height: 52,
                                  fit: BoxFit.cover,
                                ),
                              ))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PagePlaceholder extends StatelessWidget {
  const PagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFFE3E3E3),
        borderRadius: BorderRadius.circular(16.0),
      ),
    );
  }
}
