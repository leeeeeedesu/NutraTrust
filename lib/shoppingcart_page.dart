import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'product.dart';
import 'services/like_service.dart';
import 'services/realtime_database_service.dart';
import 'checkout_page.dart';
import 'home_page.dart';
import 'likes_page.dart';
import 'profile_page.dart';
import 'trackorders_page.dart';
import 'utils/app_theme.dart';

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

  static const String cartNode = 'carts';

  static List<CartItem> get items => List.unmodifiable(_items);

  static int get totalQuantity =>
      _items.fold(0, (sum, item) => sum + item.quantity);

  static DatabaseReference get cartsRef => FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: RealtimeDatabaseService.databaseUrl,
  ).ref(cartNode);

  static DatabaseReference userCartRef(String uid) => cartsRef.child(uid);

  static DatabaseReference cartItemRef(String uid, String productId) =>
      userCartRef(uid).child(productId);

  static Map<String, dynamic> _cartItemPayload(CartItem item) {
    return {
      'name': item.product.name,
      'flavor': item.flavor,
      'size': item.size,
      'category': item.product.category ?? '',
      'price': item.price,
      'quantity': item.quantity,
      'productId': item.product.id,
    };
  }

  static Future<void> _persistCartItem(CartItem item) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await cartItemRef(uid, item.product.id).set(_cartItemPayload(item));
  }

  static Future<void> _deleteCartItem(CartItem item) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await cartItemRef(uid, item.product.id).remove();
  }

  static void _updateCount() {
    itemCountNotifier.value = totalQuantity;
  }

  static Future<void> addItem({
    required Product product,
    required String size,
    required String flavor,
    required int quantity,
  }) async {
    final existingIndex = _items.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.size == size &&
          item.flavor == flavor,
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
      await _persistCartItem(_items[existingIndex]);
    } else {
      final newItem = CartItem(
        product: product,
        size: size,
        flavor: flavor,
        quantity: quantity,
      );
      _items.add(newItem);
      await _persistCartItem(newItem);
    }

    _updateCount();
  }

  static Future<void> updateQuantity(CartItem item, int newQuantity) async {
    if (newQuantity < 1) return;

    final existingItem = _items.firstWhere(
      (existing) => existing.id == item.id,
      orElse: () => item,
    );
    existingItem.quantity = newQuantity;
    await _persistCartItem(existingItem);
    _updateCount();
  }

  static double get cartTotal {
    return _items.fold(0.0, (value, item) => value + item.total);
  }

  static void clear() {
    _items.clear();
    _updateCount();
  }

  static Future<void> removeItem(CartItem item) async {
    _items.removeWhere((existing) => existing.id == item.id);
    _updateCount();
    await _deleteCartItem(item);
  }

  static Future<void> removeItems(List<CartItem> items) async {
    final ids = items.map((item) => item.id).toSet();
    _items.removeWhere((existing) => ids.contains(existing.id));
    _updateCount();
    await Future.wait(items.map(_deleteCartItem));
  }

  static Product _fallbackProduct(
    String productId,
    Map<dynamic, dynamic> data,
  ) {
    final name = data['name']?.toString() ?? 'Item';
    final category = data['category']?.toString();
    final priceValue = data['price'];
    final price = double.tryParse(priceValue?.toString() ?? '') ?? 0.0;
    return Product(
      id: productId,
      name: name,
      description: '',
      price: price.round(),
      stock: 0,
      category: category?.isEmpty == true ? null : category,
      image: null,
      brand: null,
      flavors: [],
    );
  }

  static Future<void> loadCartForUser(String uid) async {
    _items.clear();

    final productSnapshot = await RealtimeDatabaseService.productsRef.get();
    final availableProducts = <String, Product>{};
    if (productSnapshot.exists && productSnapshot.value is Map) {
      final value = productSnapshot.value as Map;
      value.forEach((key, rawProduct) {
        if (rawProduct is Map) {
          try {
            final product = Product.fromMap(key.toString(), rawProduct);
            availableProducts[key.toString()] = product;
          } catch (_) {
            // skip invalid product entries
          }
        }
      });
    }

    final cartSnapshot = await userCartRef(uid).get();
    if (!cartSnapshot.exists || cartSnapshot.value == null) {
      _updateCount();
      return;
    }

    final cartData = cartSnapshot.value;
    if (cartData is Map) {
      cartData.forEach((key, rawItem) {
        if (rawItem is Map) {
          final quantity =
              int.tryParse(rawItem['quantity']?.toString() ?? '') ?? 1;
          final flavor = rawItem['flavor']?.toString() ?? '';
          final size = rawItem['size']?.toString() ?? '';
          final product =
              availableProducts[key.toString()] ??
              _fallbackProduct(key.toString(), rawItem);
          _items.add(
            CartItem(
              product: product,
              size: size,
              flavor: flavor,
              quantity: quantity,
            ),
          );
        }
      });
    }

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
                    color: AppColors.error,
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
                      color: AppColors.cardBackground,
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
        title: const Text('Shopping Cart'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: cartItems.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                // Select All Section
                _buildSelectAllSection(),

                // Cart Items List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildCartItemCard(cartItems[index]);
                    },
                  ),
                ),

                // Order Summary & Checkout
                _buildOrderSummary(displayTotal, selectedItems),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.text.withOpacity(0.627),
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

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: AppColors.text.withOpacity(0.502),
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some products to get started',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.text.withOpacity(0.502),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Start Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectAllSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        border: Border(bottom: BorderSide(color: AppColors.shadow)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _checkoutAll,
            activeColor: AppColors.primary,
            onChanged: (v) {
              setState(() {
                _checkoutAll = v ?? false;
                if (_checkoutAll) {
                  _selectedItemIds.clear();
                  _selectedItemIds.addAll(cartItems.map((item) => item.id));
                } else {
                  _selectedItemIds.clear();
                }
              });
            },
          ),
          const SizedBox(width: 12),
          Text(
            'Select All (${cartItems.length} items)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    final isSelected = _checkoutAll || _selectedItemIds.contains(item.id);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Checkbox on left, Delete on right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Checkbox(
                  value: isSelected,
                  activeColor: AppColors.primary,
                  onChanged: (selected) {
                    setState(() {
                      if (selected == true) {
                        _selectedItemIds.add(item.id);
                      } else {
                        _selectedItemIds.remove(item.id);
                      }
                      _checkoutAll =
                          _selectedItemIds.length == cartItems.length;
                    });
                  },
                ),
                IconButton(
                  onPressed: () async {
                    await CartService.removeItem(item);
                    if (mounted) {
                      setState(() {
                        _selectedItemIds.remove(item.id);
                        _checkoutAll =
                            _selectedItemIds.length == CartService.items.length;
                      });
                    }
                  },
                  icon: Icon(Icons.delete_outline, color: AppColors.error),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Center Row: Image + Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      item.product.image != null &&
                          item.product.image!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            item.product.image!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(Icons.image, color: AppColors.text.withOpacity(0.502)),
                ),

                const SizedBox(width: 16),

                // Product Details (Name, Flavor, Price)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.098),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${item.flavor} • ${item.size}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₱${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.text,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Total Price
                Text(
                  '₱${item.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),

            // Bottom Row: Quantity Controls (centered)
            const SizedBox(height: 12),
            Center(child: _buildQuantityControls(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityControls(CartItem item) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.shadow),
        borderRadius: BorderRadius.circular(10),
        color: AppColors.cardBackground,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minus Button
          SizedBox(
            width: 42,
            height: 42,
            child: IconButton(
              onPressed: item.quantity > 1
                  ? () async {
                      final newQuantity = item.quantity - 1;
                      await CartService.updateQuantity(item, newQuantity);
                      if (mounted) {
                        setState(() {});
                      }
                    }
                  : null,
              icon: const Icon(Icons.remove),
              iconSize: 18,
              padding: EdgeInsets.zero,
              splashRadius: 20,
            ),
          ),

          // Quantity Display
          Container(
            width: 50,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: AppColors.shadow),
                right: BorderSide(color: AppColors.shadow),
              ),
            ),
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),

          // Plus Button
          SizedBox(
            width: 42,
            height: 42,
            child: IconButton(
              onPressed: () async {
                final newQuantity = item.quantity + 1;
                await CartService.updateQuantity(item, newQuantity);
                if (mounted) {
                  setState(() {});
                }
              },
              icon: const Icon(Icons.add),
              iconSize: 18,
              padding: EdgeInsets.zero,
              splashRadius: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(double displayTotal, List<CartItem> selectedItems) {
    final shippingFee = selectedItems.isEmpty
        ? 0.0
        : 50.0; // Shipping only when items selected
    const discount = 0.0; // Example discount
    final subtotal = displayTotal;
    final total = subtotal + shippingFee - discount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Order Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow('Subtotal', '₱${subtotal.toStringAsFixed(2)}'),
                if (selectedItems.isNotEmpty)
                  _buildSummaryRow(
                    'Shipping Fee',
                    '₱${shippingFee.toStringAsFixed(2)}',
                  ),
                if (discount > 0)
                  _buildSummaryRow(
                    'Discount',
                    '-₱${discount.toStringAsFixed(2)}',
                    isDiscount: true,
                  ),
                const Divider(height: 16),
                _buildSummaryRow(
                  'Total',
                  '₱${total.toStringAsFixed(2)}',
                  isTotal: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Checkout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedItems.isEmpty
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CheckoutPage(previewItems: selectedItems),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: AppColors.secondary,
              ),
              child: Text(
                selectedItems.isEmpty
                    ? 'Select items to checkout'
                    : 'Checkout (${selectedItems.length} items)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? AppColors.error : AppColors.text,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? AppColors.primary : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
