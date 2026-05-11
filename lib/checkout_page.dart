import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'models/user_profile.dart';
import 'services/realtime_database_service.dart';
import 'shoppingcart_page.dart';
import 'done_checkout_page.dart';

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
          backgroundColor: Colors.orange,
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
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('CheckoutPage._saveProfile failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile: $e'),
          backgroundColor: Colors.red,
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
          backgroundColor: Colors.orange,
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
      // Check stock availability for each item
      for (final item in items) {
        debugPrint(
          'Requested quantity: ${item.quantity} for productId: ${item.product.id}',
        );
        final currentStock = await RealtimeDatabaseService.getProductStock(
          item.product.id,
        );
        debugPrint(
          'Available stock: $currentStock for productId: ${item.product.id}',
        );
        if (item.quantity > currentStock) {
          debugPrint(
            'Order rejected due to insufficient stock for productId: ${item.product.id}',
          );
          if (!mounted) return;
          setState(() => _isProcessing = false);
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Insufficient stock for one or more items.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Create order(s) for each cart item and decrement stock.
      for (final item in items) {
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
          throw Exception('Failed to decrement stock for ${item.product.id}');
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

      // Remove only checked items or clear full cart if no preview selection
      if (previewItems == null) {
        CartService.clear();
      } else {
        CartService.removeItems(previewItems);
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
          backgroundColor: Colors.red,
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
      backgroundColor: const Color(0xFFF7F9F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E8B3A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Color(0xFF1E8B3A),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: !_profileLoaded
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (items.isEmpty) ...[
                      const SizedBox(height: 40),
                      const Center(
                        child: Text(
                          'Your cart is empty.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ] else ...[
                      // Product Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8E8E8)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child:
                                  items.first.product.image != null &&
                                      items.first.product.image!.isNotEmpty
                                  ? (items.first.product.image!.startsWith(
                                          'http',
                                        )
                                        ? Image.network(
                                            items.first.product.image!,
                                            fit: BoxFit.contain,
                                          )
                                        : Image.asset(
                                            items.first.product.image!,
                                            fit: BoxFit.contain,
                                          ))
                                  : const SizedBox.shrink(),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    items.first.product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Amount: ₱${totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Color(0xFF1E8B3A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Delivery Information Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _userProfile == null
                                ? Colors.red
                                : const Color(0xFFE8E8E8),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Color(0xFF1E8B3A),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _userProfile?.fullName ?? 'Add Profile',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _userProfile?.phoneNumber ??
                                            'Phone required',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _userProfile?.address ??
                                            'Address required',
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
                            if (_userProfile == null ||
                                !_userProfile!.isComplete) ...[
                              const SizedBox(height: 12),
                              Container(
                                color: Colors.orange.withOpacity(0.1),
                                padding: const EdgeInsets.all(8),
                                child: const Text(
                                  'Profile is incomplete. Please add your delivery information.',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Profile Edit Form
                      if (_userProfile == null || !_userProfile!.isComplete)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE8E8E8)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Delivery Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E8B3A),
                                ),
                              ),
                              const SizedBox(height: 12),
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
                                  hintText:
                                      'Enter your middle initial (optional)',
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
                                  hintText: '09123456789 or +639123456789',
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
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E8B3A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Save Profile',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Delivery Address Confirmed',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Ready to be delivered to ${_userProfile?.fullName}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Voucher Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8E8E8)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Voucher',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E8B3A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Use a promo code or voucher at checkout.',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _voucherController,
                              enabled: !_useNoVoucher,
                              decoration: InputDecoration(
                                labelText: 'Voucher code',
                                hintText: 'Enter voucher code',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
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
                            CheckboxListTile(
                              value: _useNoVoucher,
                              activeColor: const Color(0xFF1E8B3A),
                              contentPadding: EdgeInsets.zero,
                              title: const Text("Don't use voucher"),
                              subtitle: const Text(
                                'Select this option to skip voucher discounts.',
                              ),
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
                      const SizedBox(height: 12),
                      // Message for Seller Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8E8E8)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Message for seller',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E8B3A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Add any special instructions for the seller.',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _messageController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Enter here',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
      bottomNavigationBar: !_profileLoaded
          ? null
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        'Please select at least one product.',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ElevatedButton(
                    onPressed:
                        (items.isEmpty ||
                            _isProcessing ||
                            _userProfile == null ||
                            !_userProfile!.isComplete)
                        ? null
                        : () => _processCheckout(
                            context,
                            items,
                            totalAmount,
                            widget.previewItems,
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF73B222),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            items.isEmpty
                                ? 'Checkout'
                                : (_userProfile == null ||
                                          !_userProfile!.isComplete
                                      ? 'Complete Profile'
                                      : 'Checkout'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
