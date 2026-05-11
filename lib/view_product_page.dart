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

class ViewProductPage extends StatefulWidget {
  final Product product;
  const ViewProductPage({super.key, required this.product});

  @override
  _ViewProductPageState createState() => _ViewProductPageState();
}

class _ViewProductPageState extends State<ViewProductPage> {
  String selectedFlavor = '';
  int quantity = 1;
  List<Map<String, dynamic>> deliveredOrders = [];
  bool isLoadingOrders = false;
  int _selectedIndex = 0; // Add this for bottom navigation

  @override
  void initState() {
    super.initState();
    if (widget.product.flavors.isNotEmpty) {
      selectedFlavor = widget.product.flavors[0];
    }
    _loadDeliveredOrders();
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

  Future<void> _loadDeliveredOrders() async {
    setState(() => isLoadingOrders = true);
    try {
      final orders = await ReviewService.getDeliveredOrdersForProduct(
        widget.product.id,
      );
      setState(() => deliveredOrders = orders);
      debugPrint(
        'ViewProductPage: Loaded ${orders.length} delivered orders for productId=${widget.product.id}',
      );
    } catch (e) {
      debugPrint('ViewProductPage._loadDeliveredOrders ERROR: $e');
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
                            ScaffoldMessenger.of(context).showSnackBar(
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
                            ScaffoldMessenger.of(context).showSnackBar(
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
                              side: const BorderSide(color: Colors.green),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              if (panelQuantity > widget.product.stock) {
                                ScaffoldMessenger.of(context).showSnackBar(
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
                              CartService.addItem(
                                product: widget.product,
                                size: 'standard',
                                flavor: panelFlavor.isNotEmpty
                                    ? panelFlavor
                                    : 'default',
                                quantity: panelQuantity,
                              );
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(content: Text('Added to cart')),
                              );
                            },
                            child: const Text(
                              'Add to cart',
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              if (panelQuantity > widget.product.stock) {
                                ScaffoldMessenger.of(context).showSnackBar(
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
                                  builder: (_) =>
                                      CheckoutPage(previewItems: [previewItem]),
                                ),
                              );
                            },
                            child: const Text('Buy now'),
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              SizedBox(width: 8),
              Icon(Icons.search, color: Colors.green),
              SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search',
                    border: InputBorder.none,
                  ),
                  enabled: false,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 16),
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child:
                    widget.product.image != null &&
                        widget.product.image!.isNotEmpty
                    ? Image.network(widget.product.image!, fit: BoxFit.contain)
                    : Icon(Icons.image, size: 100, color: Colors.grey),
              ),
              SizedBox(height: 24),
              Text(
                widget.product.name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                '₱${widget.product.price}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Text(
                  widget.product.description,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _showProductActionPanel,
                      child: const Text('Add to cart'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _showProductActionPanel,
                      child: Text(
                        'Buy now',
                        style: TextStyle(color: Colors.green[900]),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Write Review Section
              if (deliveredOrders.isNotEmpty && !isLoadingOrders) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You have ${deliveredOrders.length} delivered order(s) for this product',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            if (deliveredOrders.isNotEmpty) {
                              debugPrint(
                                'ViewProductPage: User clicking write review for productId=${widget.product.id}',
                              );
                              _showReviewDialog(
                                deliveredOrders.first['orderId'].toString(),
                              );
                            }
                          },
                          icon: const Icon(Icons.rate_review),
                          label: const Text('Write a Review'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ] else if (isLoadingOrders) ...[
                const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                ),
                const SizedBox(height: 24),
              ] else
                ...[],
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
