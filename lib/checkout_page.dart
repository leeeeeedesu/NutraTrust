import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'models/user_profile.dart';
import 'services/realtime_database_service.dart';
import 'shoppingcart_page.dart';
import 'done_checkout_page.dart';
import 'utils/app_theme.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItem>? previewItems;

  const CheckoutPage({super.key, this.previewItems});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isProcessing = false;
  bool _useNoVoucher = true;
  UserProfile? _userProfile;
  bool _profileLoaded = false;

  // Form controllers for editing profile
  late TextEditingController _firstNameController;
  late TextEditingController _middleInitialController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _streetController;
  late TextEditingController _barangayController;
  late TextEditingController _municipalityController;
  late TextEditingController _cityController;
  late TextEditingController _countryController;
  late TextEditingController _voucherController;
  late TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _middleInitialController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _streetController = TextEditingController();
    _barangayController = TextEditingController();
    _municipalityController = TextEditingController();
    _cityController = TextEditingController();
    _countryController = TextEditingController();
    _voucherController = TextEditingController();
    _messageController = TextEditingController();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleInitialController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _barangayController.dispose();
    _municipalityController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _voucherController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('CheckoutPage._loadUserProfile: No authenticated user');
        setState(() => _profileLoaded = true);
        return;
      }

      debugPrint(
        'CheckoutPage._loadUserProfile: Fetching profile for uid=${currentUser.uid}',
      );

      final profile = await RealtimeDatabaseService.getUserProfileModel(
        currentUser.uid,
      );
      final location = await RealtimeDatabaseService.getUserLocation(
        currentUser.uid,
      );

      if (!mounted) return;

      setState(() {
        _userProfile = profile;
        _profileLoaded = true;

        if (profile != null) {
          _firstNameController.text = profile.firstName;
          _middleInitialController.text = profile.middleInitial;
          _lastNameController.text = profile.lastName;
          _phoneController.text = profile.phoneNumber;

          debugPrint(
            'CheckoutPage._loadUserProfile: Profile loaded '
            'fullName=${profile.fullName} phone=${profile.phoneNumber}',
          );
          debugPrint('Loaded name: ${profile.fullName}');
        }

        if (location != null) {
          _streetController.text = location['street']?.toString() ?? '';
          _barangayController.text = location['barangay']?.toString() ?? '';
          _municipalityController.text =
              location['municipality']?.toString() ?? '';
          _cityController.text = location['city']?.toString() ?? '';
          _countryController.text =
              location['country']?.toString() ?? 'Philippines';

          if (_userProfile != null) {
            _userProfile = _userProfile!.copyWith(
              street: _streetController.text,
              barangay: _barangayController.text,
              municipality: _municipalityController.text,
              city: _cityController.text,
              country: _countryController.text,
            );
          }

          debugPrint('Loaded location: $location');
        } else {
          debugPrint('Loaded location: No saved location found');
        }
      });
    } catch (e) {
      debugPrint('CheckoutPage._loadUserProfile failed: $e');
      if (!mounted) return;
      setState(() => _profileLoaded = true);
    }
  }

  Future<void> _saveProfile() async {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _streetController.text.isEmpty ||
        _barangayController.text.isEmpty ||
        _municipalityController.text.isEmpty ||
        _cityController.text.isEmpty ||
        _countryController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all profile fields'),
          backgroundColor: AppColors.accent,
        ),
      );
      return;
    }

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final profile = UserProfile(
        uid: currentUser.uid,
        firstName: _firstNameController.text.trim(),
        middleInitial: _middleInitialController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        street: _streetController.text.trim(),
        barangay: _barangayController.text.trim(),
        municipality: _municipalityController.text.trim(),
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
        updatedAt: DateTime.now(),
      );

      debugPrint(
        'CheckoutPage._saveProfile: Saving profile '
        'fullName=${profile.fullName} phone=${profile.phoneNumber}',
      );

      await RealtimeDatabaseService.saveUserProfile(profile);

      if (!mounted) return;

      setState(() {
        _userProfile = profile;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('CheckoutPage._saveProfile failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _processCheckout(
    BuildContext context,
    List<CartItem> items,
    double totalAmount,
    List<CartItem>? previewItems,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to complete your order.')),
      );
      return;
    }

    // Check if profile is complete
    if (_userProfile == null || !_userProfile!.isComplete) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete your profile before checkout'),
          backgroundColor: AppColors.accent,
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    debugPrint(
      'CheckoutPage placing order for uid=${currentUser.uid} items=${items.length} '
      'customerName=${_userProfile!.fullName}',
    );
    debugPrint(
      'Checkout cart total: ₱${totalAmount.toStringAsFixed(2)} for ${items.length} product(s)',
    );

    setState(() => _isProcessing = true);

    try {
      // Check stock for all items before proceeding
      for (final item in items) {
        final currentStock = await RealtimeDatabaseService.getProductStock(
          item.product.id,
        );
        if (currentStock == 0) {
          if (!mounted) return;
          setState(() => _isProcessing = false);
          messenger.showSnackBar(
            SnackBar(
              content: Text('${item.product.name} is out of stock'),
              backgroundColor: AppColors.accent,
            ),
          );
          return;
        }
        if (item.quantity > currentStock) {
          if (!mounted) return;
          setState(() => _isProcessing = false);
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Only $currentStock ${item.product.name} available',
              ),
              backgroundColor: AppColors.accent,
            ),
          );
          return;
        }
      }

      // Create order for each cart item and decrement stock.
      for (final item in items) {
        final currentStock = await RealtimeDatabaseService.getProductStock(
          item.product.id,
        );

        // If quantity equals current stock, decrement immediately to 0
        if (item.quantity == currentStock) {
          final decrementSuccess =
              await RealtimeDatabaseService.decrementProductStock(
                item.product.id,
                item.quantity,
              );
          if (!decrementSuccess) {
            throw Exception('Failed to update stock for ${item.product.id}');
          }
        }

        final success = await RealtimeDatabaseService.createOrder(
          productId: item.product.id,
          productName: item.product.name,
          quantity: item.quantity,
          totalPrice: item.total,
          customerName: _userProfile!.fullName,
          phoneNumber: _userProfile!.phoneNumber,
          address: _userProfile!.address,
          messageForSeller: _messageController.text.trim(),
          voucherCode: _useNoVoucher || _voucherController.text.trim().isEmpty
              ? 'none'
              : _voucherController.text.trim(),
        );
        if (!success) {
          throw Exception('Failed to create order for ${item.product.id}');
        }

        // Decrement stock after order creation
        if (item.quantity != currentStock) {
          final decrementSuccess =
              await RealtimeDatabaseService.decrementProductStock(
                item.product.id,
                item.quantity,
              );
          if (!decrementSuccess) {
            throw Exception('Failed to update stock for ${item.product.id}');
          }
        }
      }

      debugPrint('Order placed, stock updated');

      if (_messageController.text.trim().isNotEmpty) {
        debugPrint('Message for seller: ${_messageController.text.trim()}');
      }

      if (_useNoVoucher || _voucherController.text.trim().isEmpty) {
        debugPrint('No voucher used');
      } else {
        debugPrint('Voucher applied: ${_voucherController.text.trim()}');
      }

      // Remove only checked items
      if (previewItems == null) {
        CartService.clear();
      } else {
        await CartService.removeItems(previewItems);
      }

      // Navigate to done page
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DoneCheckoutPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      debugPrint('CheckoutPage._processCheckout error: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Text('Order creation failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.previewItems != null
        ? widget.previewItems!
        : CartService.items;
    final totalAmount = widget.previewItems != null
        ? widget.previewItems!.fold(0.0, (sum, item) => sum + item.total)
        : CartService.cartTotal;

    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.cardBackground),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: !_profileLoaded
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? _buildEmptyCheckout()
          : Column(
              children: [
                // Order Summary Header
                _buildOrderSummaryHeader(items, totalAmount),

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product List
                        _buildProductList(items),

                        const SizedBox(height: 24),

                        // Delivery Information
                        _buildDeliverySection(),

                        const SizedBox(height: 24),

                        // Payment Method
                        _buildPaymentSection(),

                        const SizedBox(height: 24),

                        // Voucher Section
                        _buildVoucherSection(),

                        const SizedBox(height: 24),

                        // Message Section
                        _buildMessageSection(),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Checkout Button
                _buildCheckoutButton(items, totalAmount),
              ],
            ),
    );
  }

  Widget _buildEmptyCheckout() {
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
            'No items to checkout',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some products to your cart first',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.text.withOpacity(0.502),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Back to Cart'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryHeader(List<CartItem> items, double totalAmount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.098),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.receipt_long, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${items.length} item${items.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  'Total: ₱${totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(List<CartItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Items',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 16),
        ...items.map(
          (item) => Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        item.product.image != null &&
                            item.product.image!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item.product.image!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.image,
                            color: AppColors.text.withOpacity(0.502),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        const SizedBox(height: 4),
                        Text(
                          '${item.flavor} • ${item.size}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Qty: ${item.quantity}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.text.withOpacity(0.502),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
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
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliverySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_userProfile == null || !_userProfile!.isComplete) ...[
                  // Profile Form
                  TextField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      hintText: 'Enter your first name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _middleInitialController,
                    maxLength: 1,
                    decoration: InputDecoration(
                      labelText: 'Middle Initial',
                      hintText: 'M.I. (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      hintText: 'Enter your last name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '09123456789',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _streetController,
                    decoration: InputDecoration(
                      labelText: 'Street Address',
                      hintText: 'Enter your street address',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _barangayController,
                    decoration: InputDecoration(
                      labelText: 'Barangay',
                      hintText: 'Enter your barangay',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _municipalityController,
                    decoration: InputDecoration(
                      labelText: 'Municipality',
                      hintText: 'Enter your municipality',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      labelText: 'City',
                      hintText: 'Enter your city',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _countryController,
                    decoration: InputDecoration(
                      labelText: 'Country',
                      hintText: 'Enter your country',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Save Delivery Information'),
                    ),
                  ),
                ] else ...[
                  // Profile Summary
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userProfile!.fullName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _userProfile!.phoneNumber,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.text.withOpacity(0.502),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _userProfile!.address,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.text.withOpacity(0.502),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _userProfile = null; // Force show form
                          });
                        },
                        icon: Icon(Icons.edit, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.098),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.payment,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cash on Delivery',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pay when you receive your order',
                        style: TextStyle(fontSize: 14, color: AppColors.text),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.check_circle, color: AppColors.primary, size: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVoucherSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Promo Code',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _voucherController,
                  enabled: !_useNoVoucher,
                  decoration: InputDecoration(
                    labelText: 'Enter promo code',
                    hintText: 'e.g., SAVE10',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: _voucherController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _voucherController.clear();
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty && _useNoVoucher) {
                      setState(() => _useNoVoucher = false);
                    }
                  },
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: _useNoVoucher,
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  title: const Text("No promo code"),
                  subtitle: const Text('Continue without discount'),
                  onChanged: (checked) {
                    setState(() {
                      _useNoVoucher = checked ?? true;
                      if (_useNoVoucher) {
                        _voucherController.clear();
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Special Instructions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Any special delivery instructions...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutButton(List<CartItem> items, double totalAmount) {
    final isProfileComplete = _userProfile != null && _userProfile!.isComplete;

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
          // Order Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subtotal',
                      style: TextStyle(fontSize: 14, color: AppColors.text),
                    ),
                    Text(
                      '₱${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Shipping',
                      style: TextStyle(fontSize: 14, color: AppColors.text),
                    ),
                    const Text(
                      '₱50.00',
                      style: TextStyle(fontSize: 14, color: AppColors.text),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      '₱${(totalAmount + 50).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Checkout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (items.isEmpty || _isProcessing || !isProfileComplete)
                  ? null
                  : () => _processCheckout(
                      context,
                      items,
                      totalAmount,
                      widget.previewItems,
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: AppColors.secondary,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      !isProfileComplete
                          ? 'Complete Delivery Info'
                          : 'Place Order',
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
}
