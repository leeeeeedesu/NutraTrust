import 'package:flutter/material.dart';
import '../product.dart';
import '../view_product_page.dart';
import '../services/like_service.dart';

/// Reusable product list widget with null safety and overflow handling
class ProductList extends StatelessWidget {
  final List<Product> products;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;

  const ProductList({
    super.key,
    required this.products,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (hasError) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              errorMessage ?? 'Unable to load products from the database.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[700], fontSize: 14),
            ),
          ),
        ),
      );
    }

    if (products.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'No products available in the database.',
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        childAspectRatio: 0.72,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];

        // Debug logging
        debugPrint(
          'ProductList: Displaying product - ID: ${product.id}, Name: ${product.name}, Price: ${product.price}, Stock: ${product.stock}, Category: ${product.category ?? 'null'}',
        );

        return _ProductCard(product: product);
      },
    );
  }
}

/// Individual product card with null safety
class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    // Get default values for null fields
    final name = product.name.isEmpty ? 'Uncategorized' : product.name;
    final price = product.price > 0 ? product.price : 0;
    final stock = product.stock >= 0 ? product.stock : 0;
    final stockStatus = stock > 0 ? 'Stock: $stock' : 'Out of stock';
    final stockColor = stock > 0 ? const Color(0xFF6F6F6F) : Colors.red;

    return GestureDetector(
      onTap: () {
        debugPrint('Tapping product: ${product.id}');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ViewProductPage(product: product)),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product image
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8E8E8)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x11000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildProductImage(),
                    ),
                  ),
                ),
              ),

              // Product info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBEE6C9)),
                  color: const Color(0xFFF7FFFA),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product name with text wrapping
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Color(0xFF1E8B3A),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Price with Flexible to prevent overflow
                    Flexible(
                      child: Text(
                        '₱${price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Color(0xFF1E8B3A),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Stock status with Flexible
                    Flexible(
                      child: Text(
                        stockStatus,
                        style: TextStyle(color: stockColor, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Like button
          Positioned(
            right: 10,
            top: 10,
            child: ValueListenableBuilder<List<Product>>(
              valueListenable: LikeService.likedProductsNotifier,
              builder: (context, likedProducts, child) {
                final liked = LikeService.isLiked(product.id);
                return GestureDetector(
                  onTap: () async {
                    debugPrint('Toggling like for product: ${product.id}');
                    await LikeService.toggle(product);
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      liked ? Icons.favorite : Icons.favorite_border,
                      color: liked ? const Color(0xFFDD2E44) : Colors.grey,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build product image with null/empty checking
  Widget _buildProductImage() {
    try {
      // Check if image URL is valid
      if (product.image != null && product.image!.isNotEmpty) {
        if (product.image!.startsWith('http')) {
          return Image.network(
            product.image!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              debugPrint(
                'Error loading network image for ${product.id}: $error',
              );
              return _buildPlaceholderIcon();
            },
          );
        } else {
          return Image.asset(
            product.image!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Error loading asset image for ${product.id}: $error');
              return _buildPlaceholderIcon();
            },
          );
        }
      } else {
        debugPrint('Product ${product.id} has no image');
        return _buildPlaceholderIcon();
      }
    } catch (e) {
      debugPrint('Exception loading image for ${product.id}: $e');
      return _buildPlaceholderIcon();
    }
  }

  /// Placeholder icon when image is not available
  Widget _buildPlaceholderIcon() {
    return Center(
      child: Icon(
        Icons.shopping_bag_outlined,
        size: 44,
        color: Colors.green[700],
      ),
    );
  }
}
