import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/realtime_database_service.dart';
import 'services/review_service.dart';
import 'shoppingcart_page.dart';
import 'home_page.dart';
import 'likes_page.dart';
import 'profile_page.dart';
import 'review_page.dart';
import 'utils/date_formatter.dart';

class TrackOrdersPage extends StatefulWidget {
  const TrackOrdersPage({super.key});

  @override
  State<TrackOrdersPage> createState() => _TrackOrdersPageState();
}

Future<void> _ensureOrdersMigrated() async {
  try {
    debugPrint('TrackOrdersPage: Starting orders migration...');
    await RealtimeDatabaseService.migrateOrdersUserId();
    debugPrint('TrackOrdersPage: Orders migration completed.');
  } catch (e) {
    debugPrint('TrackOrdersPage: Migration error: $e');
  }
}

class _TrackOrdersPageState extends State<TrackOrdersPage> {
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _ensureOrdersMigrated();
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
      case 3: // Shopping Cart
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ShoppingCartPage()),
        );
        break;
      case 4: // Profile
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Page not yet implemented")),
        );
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return const Color(0xFF1E8B3A); // green
      case 'in transit':
        return const Color(0xFFFFA000); // orange
      case 'cancelled':
        return const Color(0xFFD32F2F); // red
      case 'failed':
        return const Color(0xFFD32F2F); // red
      case 'pending':
        return const Color(0xFF1976D2); // blue
      case 'paid':
        return const Color(0xFF7B1FA2); // purple
      default:
        return Colors.grey;
    }
  }

  static const List<String> _adminOrderStatuses = [
    'pending',
    'paid',
    'in transit',
    'delivered',
    'cancelled',
    'failed',
  ];

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return 'Delivered';
      case 'in transit':
        return 'In Transit';
      case 'cancelled':
        return 'Cancelled';
      case 'failed':
        return 'Failed';
      case 'pending':
        return 'Pending';
      case 'paid':
        return 'Paid';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Orders'),
        backgroundColor: const Color(0xFF1B5E20),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          },
        ),
      ),
      body: _buildOrdersList(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1E8B3A),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(
            icon: LikeBadgeIcon(child: Icon(Icons.favorite)),
            label: 'Likes',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Track Orders',
          ),
          const BottomNavigationBarItem(
            icon: CartBadgeIcon(child: Icon(Icons.shopping_cart)),
            label: 'Shopping Cart',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildOrdersList() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('Please sign in to view your orders.'));
    }

    debugPrint('TrackOrdersPage._buildOrdersList: uid=${currentUser.uid}');

    return FutureBuilder<Map<String, dynamic>>(
      future: RealtimeDatabaseService.getCustomerOrDefault(currentUser.uid),
      builder: (context, customerSnapshot) {
        if (customerSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (customerSnapshot.hasError) {
          debugPrint(
            'TrackOrdersPage: getCustomerOrDefault error: ${customerSnapshot.error}',
          );
        }

        // Determine user role: admin can see all orders, customer sees only theirs
        final role =
            customerSnapshot.data?['role']?.toString().toLowerCase() ??
            'customer';
        final isAdmin = role == 'admin';

        debugPrint('TrackOrdersPage: User role=$role, isAdmin=$isAdmin');

        // Get the appropriate stream
        final currentUid = currentUser.uid;
        final stream = isAdmin
            ? RealtimeDatabaseService.ordersStreamForAdmin()
            : RealtimeDatabaseService.ordersStreamForCustomer(currentUid);

        return StreamBuilder<List<Order>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Handle permission denied or other errors
            if (snapshot.hasError) {
              final errorMsg = snapshot.error.toString().toLowerCase();
              final isPermissionDenied =
                  errorMsg.contains('permission-denied') ||
                  errorMsg.contains('permission');

              debugPrint(
                'TrackOrdersPage: Stream error (permission=$isPermissionDenied): ${snapshot.error}',
              );

              if (isPermissionDenied) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Permission Denied',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Unable to load orders. Please try signing out and signing back in.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error loading orders:\n${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final orders = snapshot.data ?? [];
            debugPrint(
              'TrackOrdersPage: Loaded ${orders.length} orders for uid=$currentUid',
            );

            if (orders.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No orders yet. Once you place an order, it will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              itemCount: orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orders[index];
                final isPending = order.status.toLowerCase() == 'pending';

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
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
                      // Order ID + Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Order ID: ${order.id}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(
                                order.status,
                              ).withAlpha((0.16 * 255).round()),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              _getStatusLabel(order.status),
                              style: TextStyle(
                                fontSize: 12,
                                color: _statusColor(order.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Product details
                      Text(
                        order.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Quantity: ${order.quantity}'),
                          Text(
                            'Total: ₱${order.totalPrice.toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Placed: ${DateFormatter.formatDateTime(order.timestamp)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (isAdmin) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Update status:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value:
                                          _adminOrderStatuses.contains(
                                            order.status.toLowerCase(),
                                          )
                                          ? order.status.toLowerCase()
                                          : 'pending',
                                      items: _adminOrderStatuses.map((status) {
                                        return DropdownMenuItem(
                                          value: status,
                                          child: Text(_getStatusLabel(status)),
                                        );
                                      }).toList(),
                                      onChanged: (newStatus) {
                                        if (newStatus == null ||
                                            newStatus ==
                                                order.status.toLowerCase()) {
                                          return;
                                        }
                                        _updateOrderStatus(order.id, newStatus);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else if (isPending) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _cancelOrder(order.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[400],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancel Order'),
                          ),
                        ),
                      ] else if (order.status.toLowerCase() == 'paid') ...[
                        if (!order.reviewed)
                          FutureBuilder<bool>(
                            future: _canWriteReview(order),
                            builder: (context, reviewSnapshot) {
                              if (reviewSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              if (reviewSnapshot.hasError ||
                                  reviewSnapshot.data != true) {
                                return const SizedBox.shrink();
                              }

                              return SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _navigateToReview(
                                    order.id,
                                    order.productId,
                                    order.productName,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF028B22),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Write a Review'),
                                ),
                              );
                            },
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Review already submitted',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<bool> _canWriteReview(Order order) async {
    if (order.status.toLowerCase() != 'paid') {
      debugPrint(
        'TrackOrdersPage _canWriteReview: order ${order.id} status is not paid',
      );
      return false;
    }

    if (order.reviewed) {
      debugPrint(
        'TrackOrdersPage _canWriteReview: order ${order.id} already marked reviewed',
      );
      return false;
    }

    final alreadyReviewed = await ReviewService.hasAlreadyReviewedOrder(
      order.id,
    );
    debugPrint(
      'TrackOrdersPage _canWriteReview: orderId=${order.id} alreadyReviewed=$alreadyReviewed',
    );
    return !alreadyReviewed;
  }

  Future<void> _cancelOrder(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await RealtimeDatabaseService.updateOrderStatus(orderId, 'cancelled');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to cancel order: $e')));
    }
  }

  void _navigateToReview(String orderId, String productId, String productName) {
    debugPrint(
      'Navigating to ReviewPage for orderId: $orderId, productId: $productId',
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewPage(
          orderId: orderId,
          productId: productId,
          productName: productName,
        ),
      ),
    );
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await RealtimeDatabaseService.updateOrderStatus(orderId, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order status updated to ${_getStatusLabel(newStatus)}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
    }
  }
}
