import 'package:flutter/material.dart';
import 'utils/app_theme.dart';
import 'trackorders_page.dart';
import 'widgets/review_form.dart';

class ReviewPage extends StatelessWidget {
  final String orderId;
  final String productId;
  final String productName;

  const ReviewPage({
    super.key,
    required this.orderId,
    required this.productId,
    required this.productName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write a Review'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ReviewForm(
        orderId: orderId,
        productId: productId,
        productName: productName,
        onSuccess: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const TrackOrdersPage()),
            );
          }
        },
      ),
    );
  }
}
