import 'package:flutter/material.dart';

import 'admin_settings.dart';

enum AdminPage { dashboard, manageProduct, userLists }

class AdminBasePage extends StatelessWidget {
  const AdminBasePage({
    super.key,
    required this.activePage,
    required this.onDashboardTap,
    required this.onManageProductTap,
    required this.onUserListsTap,
    required this.body,
  });

  final AdminPage activePage;
  final VoidCallback onDashboardTap;
  final VoidCallback onManageProductTap;
  final VoidCallback onUserListsTap;
  final Widget body;

  @override
  Widget build(BuildContext context) {
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
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Colors.grey),
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: _NavButton(
                      label: 'User Lists',
                      active: activePage == AdminPage.userLists,
                      onTap: onUserListsTap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Expanded(
                    child: _StatusChip(label: 'INVENTORY', active: false),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _StatusChip(label: 'INVENTORY', active: false),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.description,
  });

  final String title;
  final String subtitle;
  final String price;
  final String description;

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
