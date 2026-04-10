import 'package:flutter/material.dart';
import 'admin_base_page.dart';
import 'admin_dashboard.dart';
import 'admin_manage_product.dart';

class AdminUserListsPage extends StatelessWidget {
  const AdminUserListsPage({super.key});

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
      body: Column(
        children: const [
          SizedBox(height: 8),
          _UsersInfoCard(),
          SizedBox(height: 18),
          PagePlaceholder(),
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
            SizedBox(height: 6),
            Text(
              'This page will show the registered user list, active accounts, and roles. Not yet implemented.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
