import 'package:flutter/material.dart';
import 'admin_base_page.dart';
import 'admin_dashboard.dart';
import 'admin_user_lists.dart';

class AdminManageProductPage extends StatelessWidget {
  const AdminManageProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminBasePage(
      activePage: AdminPage.manageProduct,
      onDashboardTap: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
          (route) => route.isFirst,
        );
      },
      onManageProductTap: () {},
      onUserListsTap: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminUserListsPage()),
          (route) => route.isFirst,
        );
      },
      body: Column(
        children: const [
          _ManageProductsLabel(),
          SizedBox(height: 14),
          _ActionButtonsRow(),
          SizedBox(height: 18),
          ProductCard(
            title: 'Product Name',
            subtitle: 'Stock: 0',
            price: '₱0.00',
            description: 'This product gives you what you need for your body',
          ),
          SizedBox(height: 18),
          PagePlaceholder(),
        ],
      ),
    );
  }
}

class _ManageProductsLabel extends StatelessWidget {
  const _ManageProductsLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: const Center(
        child: Text(
          'Manage Products',
          style: TextStyle(
            color: Color(0xFF028B22),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ActionButtonsRow extends StatelessWidget {
  const _ActionButtonsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _ActionButton(label: 'Add Product')),
        SizedBox(width: 8),
        Expanded(child: _ActionButton(label: 'Delete Product')),
        SizedBox(width: 8),
        Expanded(child: _ActionButton(label: 'Edit Product')),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFF028B22),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
