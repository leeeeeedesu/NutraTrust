import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'realtime_database_service.dart';

/// Review Service - Restricts reviews to delivered orders only
class ReviewService {
  static FirebaseDatabase get _database => FirebaseDatabase.instanceFor(
    app: FirebaseAuth.instance.app,
    databaseURL: RealtimeDatabaseService.databaseUrl,
  );

  static DatabaseReference get reviewsRef => _database.ref('reviews');
  static DatabaseReference get ordersRef => _database.ref('orders');

  /// Create a review only if the order has been delivered
  /// Returns true if review was saved successfully
  static Future<bool> createReviewForDeliveredOrder({
    required String orderId,
    required String productId,
    required int rating,
    String? comment,
    String? productName,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-signed-in',
        message: 'You must be signed in to submit a review.',
      );
    }

    debugPrint(
      'ReviewService.createReviewForDeliveredOrder: '
      'Attempting to review orderId=$orderId productId=$productId for uid=${currentUser.uid}',
    );

    try {
      // Get the specific order
      final orderSnapshot = await ordersRef.child(orderId).get();

      if (!orderSnapshot.exists) {
        debugPrint(
          'ReviewService.createReviewForDeliveredOrder: Order $orderId not found',
        );
        throw Exception('Order not found');
      }

      final orderData = Map<String, dynamic>.from(
        orderSnapshot.value as Map<dynamic, dynamic>,
      );

      final orderUserId = orderData['userId']?.toString() ?? '';
      final orderStatus = orderData['status']?.toString().toLowerCase() ?? '';
      final orderReviewed = orderData['reviewed'] == true;

      debugPrint(
        'ReviewService.createReviewForDeliveredOrder: '
        'Order status=$orderStatus userId=$orderUserId reviewed=$orderReviewed for orderId=$orderId',
      );

      // Verify order belongs to current user
      if (orderUserId != currentUser.uid) {
        debugPrint(
          'ReviewService.createReviewForDeliveredOrder ACCESS DENIED: '
          'auth.uid=${currentUser.uid} != order.userId=$orderUserId',
        );
        throw Exception('This order does not belong to you');
      }

      if (orderReviewed) {
        debugPrint(
          'ReviewService.createReviewForDeliveredOrder RESTRICTION: '
          'Order $orderId has already been reviewed',
        );
        throw Exception('This order has already been reviewed.');
      }

      // Verify order status is "delivered"
      if (orderStatus != 'delivered') {
        debugPrint(
          'ReviewService.createReviewForDeliveredOrder RESTRICTION: '
          'Order status is "$orderStatus", review only allowed for "delivered"',
        );
        throw Exception(
          'You can only review orders that have been delivered. Current status: $orderStatus',
        );
      }

      debugPrint('Submitting review for orderId: $orderId');

      // Create the review entry with required fields plus optional metadata.
      final Map<String, dynamic> reviewData = {
        'userId': currentUser.uid,
        'orderId': orderId,
        'productId': productId,
        'rating': rating,
        'timestamp': ServerValue.timestamp,
      };

      if (comment?.isNotEmpty == true) {
        reviewData['comment'] = comment;
      }
      if (productName?.trim().isNotEmpty == true) {
        reviewData['productName'] = productName!.trim();
      }
      if (currentUser.email?.isNotEmpty == true) {
        reviewData['customerEmail'] = currentUser.email;
      }

      await reviewsRef.push().set(reviewData);
      await ordersRef.child(orderId).update({'reviewed': true});

      debugPrint(
        'ReviewService.createReviewForDeliveredOrder: '
        'Review saved successfully, marked reviewed for orderId=$orderId',
      );

      return true;
    } catch (e) {
      debugPrint('ReviewService.createReviewForDeliveredOrder ERROR: $e');
      rethrow;
    }
  }

  /// Get delivered orders for current user that contain the specified productId
  static Future<List<Map<String, dynamic>>> getDeliveredOrdersForProduct(
    String productId,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return [];
    }

    debugPrint(
      'ReviewService.getDeliveredOrdersForProduct: '
      'Fetching delivered orders for productId=$productId uid=${currentUser.uid}',
    );

    try {
      final ordersSnapshot = await ordersRef
          .orderByChild('userId')
          .equalTo(currentUser.uid)
          .get();

      if (!ordersSnapshot.exists) {
        debugPrint(
          'ReviewService.getDeliveredOrdersForProduct: No orders found for uid=${currentUser.uid}',
        );
        return [];
      }

      final deliveredOrders = <Map<String, dynamic>>[];
      final value = ordersSnapshot.value;

      if (value is Map) {
        value.forEach((key, rawOrder) {
          if (rawOrder is Map) {
            final orderMap = Map<String, dynamic>.from(rawOrder);
            final orderProductId = orderMap['productId']?.toString() ?? '';
            final orderStatus =
                orderMap['status']?.toString().toLowerCase() ?? '';

            if (orderProductId == productId && orderStatus == 'delivered') {
              final orderId = key.toString();
              debugPrint(
                'ReviewService.getDeliveredOrdersForProduct: '
                'Found delivered order orderId=$orderId for productId=$productId',
              );
              deliveredOrders.add({'orderId': orderId, ...orderMap});
            }
          }
        });
      }

      debugPrint(
        'ReviewService.getDeliveredOrdersForProduct: '
        'Found ${deliveredOrders.length} delivered orders for productId=$productId',
      );

      return deliveredOrders;
    } catch (e) {
      debugPrint('ReviewService.getDeliveredOrdersForProduct ERROR: $e');
      return [];
    }
  }

  /// Check if current user has already reviewed a specific order
  static Future<bool> hasAlreadyReviewedOrder(String orderId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return false;
    }

    debugPrint(
      'ReviewService.hasAlreadyReviewedOrder: '
      'Checking if uid=${currentUser.uid} already reviewed orderId=$orderId',
    );

    try {
      final reviewsSnapshot = await reviewsRef
          .orderByChild('orderId')
          .equalTo(orderId)
          .get();

      if (!reviewsSnapshot.exists) {
        return false;
      }

      final value = reviewsSnapshot.value;
      if (value is Map) {
        for (final entry in value.entries) {
          final review = entry.value;
          if (review is Map) {
            final reviewUserId = review['userId']?.toString() ?? '';
            if (reviewUserId == currentUser.uid) {
              debugPrint(
                'ReviewService.hasAlreadyReviewedOrder: '
                'User already reviewed orderId=$orderId',
              );
              return true;
            }
          }
        }
      }

      return false;
    } catch (e) {
      debugPrint('ReviewService.hasAlreadyReviewedOrder ERROR: $e');
      return false;
    }
  }
}
