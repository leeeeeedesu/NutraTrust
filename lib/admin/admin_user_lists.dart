import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_base_page.dart';
import 'admin_dashboard.dart';
import 'admin_delivery.dart';
import 'admin_inventory.dart';
import 'admin_manage_product.dart';
import 'admin_reviews.dart';

class AdminUserListsPage extends StatelessWidget {
  const AdminUserListsPage({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _userListStream() {
    return FirebaseFirestore.instance.collection('users').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return AdminBasePage(
      activePage: AdminPage.userLists,
      onDashboardTap: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
          (route) => route.isFirst,
        );
      },
      onManageProductTap: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminManageProductPage()),
          (route) => route.isFirst,
        );
      },
      onUserListsTap: () {},
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
          const SizedBox(height: 8),
          const _UsersInfoCard(),
          const SizedBox(height: 18),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _userListStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'Unable to load users. ${snapshot.error}',
                      style: TextStyle(color: Colors.red[700], fontSize: 14),
                    ),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'No registered customers found in users collection.',
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      'Registered Users (${docs.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E8B3A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final user = docs[index].data();
                      final email =
                          user['email']?.toString() ?? 'Unknown email';
                      final role = user['role']?.toString() ?? 'customer';
                      final isActive = user['isActive'] == true;

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFFE8F5E9),
                                child: Text(
                                  email.isNotEmpty
                                      ? email[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Color(0xFF1E8B3A),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      email,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Role: $role',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Chip(
                                backgroundColor: isActive
                                    ? const Color(0xFFDFF0D8)
                                    : const Color(0xFFF6D8D8),
                                label: Text(
                                  isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    color: isActive
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFFB71C1C),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _UsersInfoCard extends StatelessWidget {
  const _UsersInfoCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'User Lists',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F5B2A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
