import 'package:flutter/material.dart';
import 'product.dart';
import 'checkout_page.dart';
import 'home_page.dart';
import 'likes_page.dart';
import 'profile_page.dart';
import 'shoppingcart_page.dart';
import 'trackorders_page.dart';
import 'services/review_service.dart';
import 'widgets/app_bottom_nav.dart';
import 'utils/app_theme.dart';

class ViewProductPage extends StatefulWidget {
  final Product product;
  const ViewProductPage({super.key, required this.product});

  @override
  _ViewProductPageState createState() => _ViewProductPageState();
}

class _ViewProductPageState extends State<ViewProductPage> {
  String selectedFlavor = '';
  int quantity = 1;
  List<Map<String, dynamic>> paidOrders = [];
  bool isLoadingOrders = false;
  int _selectedIndex = 0; // Add this for bottom navigation

  @override
  void initState() {
    super.initState();
    if (widget.product.flavors.isNotEmpty) {
      selectedFlavor = widget.product.flavors[0];
    }
    _loadPaidOrders();
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
      case 2: // Track Orders
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TrackOrdersPage()),
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

  Future<void> _loadPaidOrders() async {
    setState(() => isLoadingOrders = true);
    try {
      final orders = await ReviewService.getPaidOrdersForProduct(
        widget.product.id,
      );
      setState(() => paidOrders = orders);
      debugPrint(
        'ViewProductPage: Loaded ${orders.length} paid orders for productId=${widget.product.id}',
      );
    } catch (e) {
      debugPrint('ViewProductPage._loadPaidOrders ERROR: $e');
    } finally {
      setState(() => isLoadingOrders = false);
    }
  }

  void _showReviewDialog(String orderId) {
    final commentController = TextEditingController();
    int rating = 5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Write a Review',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Product: ${widget.product.name}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    // Star Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        return IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.star,
                            size: 32,
                            color: rating >= starIndex
                                ? Colors.orange
                                : Colors.grey[300],
                          ),
                          onPressed: () {
                            setState(() {
                              rating = starIndex;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    // Comment Field
                    TextField(
                      controller: commentController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Share your experience with this product',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E8B3A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final comment = commentController.text.trim();
                        if (comment.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter your review comment'),
                            ),
                          );
                          return;
                        }

                        debugPrint(
                          'ViewProductPage._showReviewDialog: '
                          'Submitting review for orderId=$orderId rating=$rating',
                        );

                        Navigator.of(context).pop();

                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await ReviewService.createReviewForDeliveredOrder(
                            orderId: orderId,
                            productId: widget.product.id,
                            rating: rating,
                            comment: comment,
                            productName: widget.product.name,
                          );

                          debugPrint(
                            'ViewProductPage: Review submitted successfully for orderId=$orderId',
                          );

                          if (mounted) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Review submitted successfully!'),
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint(
                            'ViewProductPage: Review submission error: $e',
                          );
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Submit Review'),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showProductActionPanel() {
    String panelFlavor = selectedFlavor;
    int panelQuantity = quantity;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.product.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₱${widget.product.price}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.product.image != null &&
                            widget.product.image!.isNotEmpty)
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Image.network(
                              widget.product.image!,
                              fit: BoxFit.contain,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (widget.product.flavors.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Choose flavor',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[800],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: panelFlavor.isNotEmpty
                                ? panelFlavor
                                : widget.product.flavors.first,
                            isExpanded: true,
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  panelFlavor = newValue;
                                });
                              }
                            },
                            items: widget.product.flavors.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Quantity',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[800],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (panelQuantity > 1) {
                              setState(() {
                                panelQuantity--;
                              });
                            }
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$panelQuantity',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            if (panelQuantity >= widget.product.stock) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Only ${widget.product.stock} items available',
                                  ),
                                ),
                              );
                            } else {
                              setState(() {
                                panelQuantity++;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: widget.product.stock == 0
                                    ? Colors.grey
                                    : Colors.green,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: widget.product.stock == 0
                                ? null
                                : () async {
                                    if (panelQuantity > widget.product.stock) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Only ${widget.product.stock} items available',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    setState(() {
                                      selectedFlavor = panelFlavor;
                                      quantity = panelQuantity;
                                    });
                                    await CartService.addItem(
                                      product: widget.product,
                                      size: 'standard',
                                      flavor: panelFlavor.isNotEmpty
                                          ? panelFlavor
                                          : 'default',
                                      quantity: panelQuantity,
                                    );
                                    if (!mounted) return;
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(
                                      this.context,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text('Added to cart'),
                                      ),
                                    );
                                  },
                            child: Text(
                              widget.product.stock == 0
                                  ? 'Out of Stock'
                                  : 'Add to cart',
                              style: TextStyle(
                                color: widget.product.stock == 0
                                    ? Colors.grey
                                    : Colors.green,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.product.stock == 0
                                  ? Colors.grey
                                  : const Color(0xFF1B5E20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: widget.product.stock == 0
                                ? null
                                : () {
                                    if (panelQuantity > widget.product.stock) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Only ${widget.product.stock} items available',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    setState(() {
                                      selectedFlavor = panelFlavor;
                                      quantity = panelQuantity;
                                    });
                                    final previewItem = CartItem(
                                      product: widget.product,
                                      size: 'standard',
                                      flavor: panelFlavor.isNotEmpty
                                          ? panelFlavor
                                          : 'default',
                                      quantity: panelQuantity,
                                    );
                                    Navigator.of(context).pop();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CheckoutPage(
                                          previewItems: [previewItem],
                                        ),
                                      ),
                                    );
                                  },
                            child: Text(
                              widget.product.stock == 0
                                  ? 'Out of Stock'
                                  : 'Buy now',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Product Image Section
                  _buildProductImage(),

                  // Product Info Section
                  _buildProductInfo(),

                  // Benefits Section
                  _buildBenefitsSection(),

                  // Trust Badges
                  _buildTrustBadges(),

                  // Description Section
                  _buildDescriptionSection(),

                  // Reviews Section
                  _buildReviewsSection(),

                  // Recommended Products
                  _buildRecommendedProducts(),

                  const SizedBox(height: 100), // Space for sticky buttons
                ],
              ),
            ),

            // Sticky Action Buttons
            _buildStickyActionButtons(),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          Center(
            child:
                widget.product.image != null && widget.product.image!.isNotEmpty
                ? Image.network(
                    widget.product.image!,
                    fit: BoxFit.contain,
                    height: 250,
                  )
                : Icon(
                    Icons.image,
                    size: 100,
                    color: AppColors.text.withAlpha(128),
                  ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: AppColors.primary),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.product.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '₱${widget.product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.product.stock == 0
                      ? Colors.red
                      : AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.product.stock == 0
                      ? 'Out of Stock'
                      : '${widget.product.stock} in stock',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.product.stock == 0
                        ? Colors.white
                        : AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection() {
    final benefits = [
      'Premium Quality Ingredients',
      'Scientifically Formulated',
      'Third-Party Tested',
      'Natural & Safe',
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Benefits',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          ...benefits.map(
            (benefit) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    benefit,
                    style: const TextStyle(fontSize: 14, color: AppColors.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadges() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTrustBadge(Icons.verified, 'Authentic Product'),
          _buildTrustBadge(Icons.local_shipping, 'Fast Shipping'),
          _buildTrustBadge(Icons.security, 'Trusted Seller'),
        ],
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.text,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.product.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.text,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    if (isLoadingOrders) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (paidOrders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accent.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You have ${paidOrders.length} paid order(s)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Share your experience with this product',
            style: TextStyle(fontSize: 14, color: AppColors.text),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () =>
                _showReviewDialog(paidOrders.first['orderId'].toString()),
            icon: const Icon(Icons.rate_review),
            label: const Text('Write a Review'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedProducts() {
    // For now, just show a placeholder. In a real app, you'd fetch similar products
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You might also like',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Recommended products will appear here',
                style: TextStyle(color: AppColors.text, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyActionButtons() {
    final isOutOfStock = widget.product.stock == 0;
    return Positioned(
      bottom: 80, // Above bottom navigation
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: isOutOfStock ? null : _showProductActionPanel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOutOfStock
                      ? Colors.grey
                      : AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  isOutOfStock ? 'Out of Stock' : 'Add to Cart',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: isOutOfStock ? null : _showProductActionPanel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOutOfStock
                      ? Colors.grey
                      : AppColors.accent,
                  foregroundColor: isOutOfStock
                      ? Colors.white
                      : AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  isOutOfStock ? 'Out of Stock' : 'Buy Now',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
