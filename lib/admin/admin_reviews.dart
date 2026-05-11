import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../services/realtime_database_service.dart';
import 'admin_base_page.dart';
import 'admin_dashboard.dart';
import 'admin_delivery.dart';
import 'admin_inventory.dart';
import 'admin_manage_product.dart';
import 'admin_user_lists.dart';

class AdminReviewsPage extends StatelessWidget {
  const AdminReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminBasePage(
      activePage: AdminPage.reviews,
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
      onReviewsTap: () {},
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
        children: const [
          SizedBox(height: 8),
          Text(
            'Product Reviews',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E8B3A),
            ),
          ),
          SizedBox(height: 12),
          ReviewsListView(),
        ],
      ),
    );
  }
}

class ReviewsListView extends StatelessWidget {
  const ReviewsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Review>>(
      stream: RealtimeDatabaseService.reviewsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 140,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          final errorMessage =
              snapshot.error is FirebaseException &&
                  (snapshot.error as FirebaseException).code ==
                      'permission-denied'
              ? 'Access denied: you do not have permission to view reviews.'
              : 'Unable to load reviews. ${snapshot.error}';

          return SizedBox(
            height: 120,
            child: Center(
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final reviews = snapshot.data ?? [];
        if (reviews.isEmpty) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: Text(
                'No customer reviews yet.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final review = reviews[index];
            final timestampText = review.timestamp != null
                ? DateTime.fromMillisecondsSinceEpoch(
                    review.timestamp!,
                  ).toLocal().toString().split('.').first
                : 'Unknown date';

            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            review.productName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text('${review.rating}/5'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      review.comment,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'User ID: ${review.userId}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          review.customerEmail,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          timestampText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
