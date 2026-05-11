import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'product.dart';
import 'services/like_service.dart';
import 'checkout_page.dart';
import 'home_page.dart';
import 'likes_page.dart';
import 'profile_page.dart';
import 'trackorders_page.dart';

// ============ Cart Item Model ============
class CartItem {
  CartItem({
    required this.product,
    required this.size,
    required this.flavor,
    required this.quantity,
  }) : id = [product.id, size, flavor].join('_'),
       price = product.price.toDouble();

  final String id;
  final Product product;
  final String size;
  final String flavor; // Flavor name from product.flavors
  final double price;
  int quantity;

  double get total => price * quantity;
}

// ============ Cart Service ============
class CartService {
  static final List<CartItem> _items = [];
  static final ValueNotifier<int> itemCountNotifier = ValueNotifier<int>(0);

  static List<CartItem> get items => List.unmodifiable(_items);

  static int get totalQuantity =>
      _items.fold(0, (sum, item) => sum + item.quantity);

  static void _updateCount() {
    itemCountNotifier.value = totalQuantity;
  }

  static void addItem({
    required Product product,
    required String size,
    required String flavor,
    required int quantity,
  }) {
    final existingIndex = _items.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.size == size &&
          item.flavor == flavor,
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(
        CartItem(
          product: product,
          size: size,
          flavor: flavor,
          quantity: quantity,
        ),
      );
    }

    _updateCount();
  }

  static double get cartTotal {
    return _items.fold(0.0, (value, item) => value + item.total);
  }

  static void clear() {
    _items.clear();
    _updateCount();
  }

  static void removeItem(CartItem item) {
    _items.removeWhere((existing) => existing.id == item.id);
    _updateCount();
  }

  static void removeItems(List<CartItem> items) {
    final ids = items.map((item) => item.id).toSet();
    _items.removeWhere((existing) => ids.contains(existing.id));
    _updateCount();
  }
}

// ============ Badge Widgets ============
class BadgeIcon extends StatelessWidget {
  const BadgeIcon({
    super.key,
    required this.valueListenable,
    required this.child,
  });

  final ValueListenable<int> valueListenable;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: valueListenable,
      builder: (context, count, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child!,
            if (count > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    count.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      child: child,
    );
  }
}

class CartBadgeIcon extends StatelessWidget {
  const CartBadgeIcon({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BadgeIcon(
      valueListenable: CartService.itemCountNotifier,
      child: child,
    );
  }
}

class LikeBadgeIcon extends StatelessWidget {
  const LikeBadgeIcon({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BadgeIcon(
      valueListenable: LikeService.likeCountNotifier,
      child: child,
    );
  }
}

// ============ Shopping Cart Page ============
class ShoppingCartPage extends StatefulWidget {
  const ShoppingCartPage({super.key});

  @override
  State<ShoppingCartPage> createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends State<ShoppingCartPage> {
  int _selectedIndex = 3;
  bool _checkoutAll = false;
  final Set<String> _selectedItemIds = {};

  List<CartItem> get cartItems => CartService.items;

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

  @override
  Widget build(BuildContext context) {
    final selectedItems = _checkoutAll
        ? cartItems
        : cartItems
              .where((item) => _selectedItemIds.contains(item.id))
              .toList();
    final displayTotal = selectedItems.isNotEmpty
        ? selectedItems.fold(0.0, (sum, item) => sum + item.total)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E8B3A)),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          },
        ),
        title: const Text(
          'Shopping Cart',
          style: TextStyle(
            color: Color(0xFF1E8B3A),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Checkbox(
                  value: _checkoutAll,
                  activeColor: const Color(0xFF1E8B3A),
                  onChanged: (v) {
                    setState(() {
                      _checkoutAll = v ?? false;
                      if (_checkoutAll) {
                        _selectedItemIds.clear();
                        _selectedItemIds.addAll(
                          cartItems.map((item) => item.id),
                        );
                      } else {
                        _selectedItemIds.clear();
                      }
                    });
                  },
                ),
                const SizedBox(width: 6),
                const Text(
                  'Checkout All',
                  style: TextStyle(
                    color: Color(0xFF1E8B3A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: ListView.separated(
              itemCount: cartItems.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item checkbox
                      Checkbox(
                        value:
                            _checkoutAll || _selectedItemIds.contains(item.id),
                        activeColor: const Color(0xFF1E8B3A),
                        onChanged: (selected) {
                          setState(() {
                            if (selected == true) {
                              _selectedItemIds.add(item.id);
                              final subtotal =
                                  item.product.price * item.quantity;
                              debugPrint(
                                'Selected product: ${item.product.name}, subtotal: ₱${subtotal.toStringAsFixed(2)}',
                              );
                            } else {
                              _selectedItemIds.remove(item.id);
                              final subtotal =
                                  item.product.price * item.quantity;
                              debugPrint(
                                'Deselected product: ${item.product.name}, subtotal: ₱${subtotal.toStringAsFixed(2)}',
                              );
                            }
                            _checkoutAll =
                                _selectedItemIds.length == cartItems.length;
                            final newTotal = _selectedItemIds.isEmpty
                                ? 0.0
                                : cartItems
                                      .where(
                                        (item) =>
                                            _selectedItemIds.contains(item.id),
                                      )
                                      .fold(
                                        0.0,
                                        (sum, item) => sum + item.total,
                                      );
                            debugPrint(
                              'Cart total updated: ₱${newTotal.toStringAsFixed(2)}',
                            );
                          });
                        },
                      ),

                      const SizedBox(width: 6),

                      // Thumbnail
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child:
                            item.product.image != null &&
                                item.product.image!.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: item.product.image!.startsWith('http')
                                    ? Image.network(
                                        item.product.image!,
                                        fit: BoxFit.contain,
                                      )
                                    : Image.asset(
                                        item.product.image!,
                                        fit: BoxFit.contain,
                                      ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(width: 12),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F1F1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.flavor,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.size,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Quantity & price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Quantity: ${item.quantity}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₱${item.total.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: Column(
              children: [
                if (cartItems.isNotEmpty && selectedItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Please select at least one product.',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: ₱${displayTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    ElevatedButton(
                      onPressed:
                          cartItems.isEmpty ||
                              (_selectedItemIds.isEmpty && !_checkoutAll)
                          ? null
                          : () {
                              final selectedItems = _checkoutAll
                                  ? cartItems
                                  : cartItems
                                        .where(
                                          (item) => _selectedItemIds.contains(
                                            item.id,
                                          ),
                                        )
                                        .toList();

                              if (selectedItems.isEmpty) {
                                debugPrint(
                                  'Checkout disabled, no products selected',
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please select at least one product.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              if (selectedItems.length == 1) {
                                debugPrint(
                                  'Checkout single item: ${selectedItems.first.id}',
                                );
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CheckoutPage(previewItems: selectedItems),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF73B222),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Checkout'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1E8B3A),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          const BottomNavigationBarItem(
            icon: LikeBadgeIcon(child: Icon(Icons.favorite)),
            label: "Likes",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: "Track Orders",
          ),
          const BottomNavigationBarItem(
            icon: CartBadgeIcon(child: Icon(Icons.shopping_cart)),
            label: "Shopping Cart",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
