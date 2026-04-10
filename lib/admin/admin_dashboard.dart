import 'package:flutter/material.dart';
import 'admin_base_page.dart';
import 'admin_manage_product.dart';
import 'admin_user_lists.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminBasePage(
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
      body: Column(
        children: const [
          _ManageActionPlaceholder(),
          SizedBox(height: 18),
          ProductCard(
            title: 'Product Name',
            subtitle: 'Stock: 0',
            price: '₱0.00',
            description: '',
          ),
          SizedBox(height: 18),
          PagePlaceholder(),
        ],
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
