import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../product.dart';
import '../services/realtime_database_service.dart';
import '../utils/app_theme.dart';
import 'admin_base_page.dart';
import 'admin_delivery.dart';
import 'admin_inventory.dart';
import 'admin_manage_product.dart';
import 'admin_reviews.dart';
import 'admin_user_lists.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  String _getStockStatus(int stock) {
    if (stock == 0) return 'Out of Stock';
    if (stock <= 5) return 'Low Stock';
    return 'In Stock';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AdminBasePage(
        activePage: AdminPage.dashboard,
        onDashboardTap: () {},
        onManageProductTap: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AdminManageProductPage()),
            (route) => route.isFirst,
          );
        },
        onUserListsTap: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AdminUserListsPage()),
            (route) => route.isFirst,
          );
        },
        onReviewsTap: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AdminReviewsPage()),
            (route) => route.isFirst,
          );
        },
        onInventoryTap: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AdminInventoryPage()),
            (route) => route.isFirst,
          );
        },
        onDeliveryTap: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AdminDeliveryPage()),
            (route) => route.isFirst,
          );
        },
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _ManageActionPlaceholder(),
            const SizedBox(height: 18),
            const _CurrentUserInfoCard(),
            const SizedBox(height: 18),
            StreamBuilder<List<Product>>(
              stream: RealtimeDatabaseService.productsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 140,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return SizedBox(
                    height: 120,
                    child: Center(
                      child: Text(
                        'Unable to load products. Please try again.',
                        style: TextStyle(color: Colors.red[700], fontSize: 14),
                      ),
                    ),
                  );
                }

                final products = snapshot.data ?? [];
                if (products.isEmpty) {
                  return SizedBox(height: 120);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Products (${products.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E8B3A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: products.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final stockStatus = _getStockStatus(product.stock);
                        return ProductCard(
                          title: product.name,
                          subtitle: 'Stock: ${product.stock} • $stockStatus',
                          price: '₱${product.price}',
                          description: product.description,
                          imageUrl: product.image,
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ManageActionPlaceholder extends StatelessWidget {
  const _ManageActionPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(14.0),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: const Center(
        child: Text(
          'Products',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF028B22),
          ),
        ),
      ),
    );
  }
}

class _CurrentUserInfoCard extends StatelessWidget {
  const _CurrentUserInfoCard();

  Future<Map<String, dynamic>?> _currentUserAccountProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;
    return RealtimeDatabaseService.getUserAccountProfile(currentUser.uid);
  }

  @override
  Widget build(BuildContext context) {
    final currentEmail =
        FirebaseAuth.instance.currentUser?.email ?? 'No user signed in';

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _currentUserAccountProfile(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 64,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final rawRole = snapshot.data?['role']?.toString() ?? 'unknown';
            final role = rawRole == 'admin' || rawRole == 'mega_admin'
                ? 'Admin'
                : rawRole;
            final isActive = snapshot.data?['isActive'] == true;
            debugPrint('Admin role: $rawRole');
            debugPrint('Active status: $isActive');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Logged-in User',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F5B2A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currentEmail,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  'Role: $role',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
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
      ),
    );
  }
}
