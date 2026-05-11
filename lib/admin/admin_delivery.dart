import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/realtime_database_service.dart';
import '../utils/date_formatter.dart';
import 'admin_base_page.dart';
import 'admin_dashboard.dart';
import 'admin_manage_product.dart';
import 'admin_reviews.dart';
import 'admin_user_lists.dart';
import 'admin_inventory.dart';

class AdminDeliveryPage extends StatefulWidget {
  const AdminDeliveryPage({super.key});

  @override
  State<AdminDeliveryPage> createState() => _AdminDeliveryPageState();
}

class _AdminDeliveryPageState extends State<AdminDeliveryPage> {
  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('AdminDeliveryPage currentUid=$currentUid loading admin orders');

    return AdminBasePage(
      activePage: AdminPage.delivery,
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
      onDeliveryTap: () {},
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Delivery Management',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E8B3A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          StreamBuilder<List<Order>>(
            stream: RealtimeDatabaseService.ordersStreamForAdmin(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'Error loading orders. Please try again.',
                      style: TextStyle(color: Colors.red[700], fontSize: 14),
                    ),
                  ),
                );
              }

              final orders = snapshot.data ?? [];
              if (orders.isEmpty) {
                return SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'No orders yet. Orders will appear here once they are placed.',
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: orders.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _DeliveryOrderCard(
                    orderId: order.id,
                    productName: order.productName,
                    customerId: order.userId,
                    currentStatus: order.status,
                    quantity: order.quantity,
                    price: order.totalPrice,
                    timestamp: order.timestamp,
                    onStatusChanged: (newStatus) {
                      _updateDeliveryStatus(order.id, newStatus);
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updateDeliveryStatus(String orderId, String newStatus) async {
    try {
      await RealtimeDatabaseService.updateOrderStatus(orderId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to: $newStatus'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
      }
    }
  }
}

class _DeliveryOrderCard extends StatelessWidget {
  final String orderId;
  final String productName;
  final String customerId;
  final String currentStatus;
  final int quantity;
  final dynamic price;
  final int? timestamp;
  final Function(String) onStatusChanged;

  const _DeliveryOrderCard({
    required this.orderId,
    required this.productName,
    required this.customerId,
    required this.currentStatus,
    required this.quantity,
    required this.price,
    required this.timestamp,
    required this.onStatusChanged,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return const Color(0xFF1E8B3A); // Green
      case 'in transit':
        return Colors.blue; // Blue for shipped/in transit
      case 'cancelled':
        return const Color(0xFFD32F2F); // Red
      default:
        return Colors.grey; // Pending/Unknown
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return 'Delivered';
      case 'in transit':
        return 'In Transit';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order ID: $orderId',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Customer: $customerId',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(currentStatus).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(
                      currentStatus,
                    ).withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  _getStatusLabel(currentStatus),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(currentStatus),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Qty: $quantity',
                style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
              ),
              Text(
                '₱${price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E8B3A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            DateFormatter.formatDateTime(timestamp),
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Update Status:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E2E2E),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatusButton(
                  label: 'Mark as Shipped',
                  isActive: currentStatus.toLowerCase() == 'in transit',
                  onTap: () => onStatusChanged('In Transit'),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusButton(
                  label: 'Mark as Delivered',
                  isActive: currentStatus.toLowerCase() == 'delivered',
                  onTap: () => onStatusChanged('Delivered'),
                  color: const Color(0xFF1E8B3A),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusButton(
                  label: 'Cancel Order',
                  isActive: currentStatus.toLowerCase() == 'cancelled',
                  onTap: () => onStatusChanged('Cancelled'),
                  color: const Color(0xFFD32F2F),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color color;

  const _StatusButton({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: isActive ? 2 : 1),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }
}
