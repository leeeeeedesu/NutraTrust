import 'package:flutter/material.dart';
import '../product.dart';
import '../services/realtime_database_service.dart';
import 'admin_base_page.dart';
import 'admin_dashboard.dart';
import 'admin_delivery.dart';
import 'admin_manage_product.dart';
import 'admin_reviews.dart';
import 'admin_user_lists.dart';

class AdminInventoryPage extends StatelessWidget {
  const AdminInventoryPage({super.key});

  Color _statusBackground(int stock) {
    if (stock == 0) {
      return const Color(0xFFFFEBEE);
    }
    if (stock <= 5) {
      return const Color(0xFFFFF3E0);
    }
    return Colors.white;
  }

  Color _statusTextColor(int stock) {
    if (stock == 0) {
      return const Color(0xFFD32F2F);
    }
    if (stock <= 5) {
      return const Color(0xFFF57C00);
    }
    return const Color(0xFF2E7D32);
  }

  String _stockTag(int stock) {
    if (stock == 0) return 'No stock';
    if (stock <= 5) return 'Low stock';
    return 'In stock';
  }

  @override
  Widget build(BuildContext context) {
    return AdminBasePage(
      activePage: AdminPage.inventory,
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
      body: StreamBuilder<List<Product>>(
        stream: RealtimeDatabaseService.productsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load inventory. Please try again.',
                style: TextStyle(color: Colors.red[700], fontSize: 16),
              ),
            );
          }

          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(
              child: Text(
                'No products in inventory.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                debugPrint('Inventory list rendered successfully');
              });
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Stocks',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E8B3A),
                          ),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: products.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final background = _statusBackground(product.stock);
                      final statusColor = _statusTextColor(product.stock);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 0),
                        decoration: BoxDecoration(
                          color: background,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: product.stock == 0
                                ? const Color(0xFFEF9A9A)
                                : product.stock <= 5
                                ? const Color(0xFFFFCC80)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F6F9),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child:
                                    product.image != null &&
                                        product.image!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(18),
                                        child: product.image!.startsWith('http')
                                            ? Image.network(
                                                product.image!,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.asset(
                                                product.image!,
                                                fit: BoxFit.cover,
                                              ),
                                      )
                                    : const Icon(
                                        Icons.inventory_2,
                                        size: 32,
                                        color: Color(0xFF9CA3AF),
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      product.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(
                                              alpha: 0.14,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          child: Text(
                                            _stockTag(product.stock),
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Stocks: ${product.stock}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF4B5563),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Flexible(
                                fit: FlexFit.loose,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₱${product.price}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E8B3A),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      product.category ?? 'Uncategorized',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
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
          );
        },
      ),
    );
  }
}
