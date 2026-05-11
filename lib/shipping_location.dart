import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_page.dart';
import 'likes_page.dart';
import 'trackorders_page.dart';
import 'shoppingcart_page.dart';
import 'profile_page.dart';
import 'services/realtime_database_service.dart';
import 'models/user_profile.dart';

class ShippingLocationPage extends StatefulWidget {
  const ShippingLocationPage({super.key});

  @override
  State<ShippingLocationPage> createState() => _ShippingLocationPageState();
}

class _ShippingLocationPageState extends State<ShippingLocationPage> {
  int _selectedIndex = 4;
  bool _loading = true;
  bool _saving = false;

  final _firstNameController = TextEditingController();
  final _middleInitialController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _brgyController = TextEditingController();
  final _municipalController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleInitialController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _brgyController.dispose();
    _municipalController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _loadLocation(String uid, {bool reloaded = false}) async {
    try {
      final location = await RealtimeDatabaseService.getUserLocation(uid);
      if (!mounted) return;

      if (location != null) {
        _streetController.text = location['street']?.toString() ?? '';
        _brgyController.text = location['barangay']?.toString() ?? '';
        _municipalController.text = location['municipality']?.toString() ?? '';
        _cityController.text = location['city']?.toString() ?? '';
        _countryController.text =
            location['country']?.toString() ?? 'Philippines';

        debugPrint('${reloaded ? 'Reloaded' : 'Loaded'} location: $location');
      } else if (!reloaded) {
        _countryController.text = 'Philippines';
        debugPrint('Loaded location: No saved location found');
      } else {
        debugPrint('Reloaded location: No saved location found');
      }
    } catch (e) {
      debugPrint('Failed to load location: $e');
    }
  }

  Future<void> _loadProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    try {
      final profile = await RealtimeDatabaseService.getUserProfileModel(
        currentUser.uid,
      );
      if (!mounted) return;

      if (profile != null) {
        _firstNameController.text = profile.firstName;
        _middleInitialController.text = profile.middleInitial;
        _lastNameController.text = profile.lastName;
        _phoneController.text = profile.phoneNumber;

        debugPrint(
          'Loaded profile: ${profile.fullName}, ${profile.phoneNumber}, ${profile.address}',
        );
      }

      await _loadLocation(currentUser.uid);
    } catch (e) {
      debugPrint('Failed to load profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phoneNumber = _phoneController.text.trim();
    final street = _streetController.text.trim();
    final barangay = _brgyController.text.trim();
    final municipality = _municipalController.text.trim();
    final city = _cityController.text.trim();
    final country = _countryController.text.trim();

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        phoneNumber.isEmpty ||
        street.isEmpty ||
        barangay.isEmpty ||
        municipality.isEmpty ||
        city.isEmpty ||
        country.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final profile = UserProfile(
        uid: currentUser.uid,
        firstName: firstName,
        middleInitial: _middleInitialController.text.trim(),
        lastName: lastName,
        phoneNumber: phoneNumber,
        street: street,
        barangay: barangay,
        municipality: municipality,
        city: city,
        country: country,
        updatedAt: DateTime.now(),
      );

      await RealtimeDatabaseService.saveUserProfile(profile);
      await RealtimeDatabaseService.updateUserLocation(currentUser.uid, {
        'street': street,
        'barangay': barangay,
        'municipality': municipality,
        'city': city,
        'country': country,
      });

      debugPrint('Saved location: ${profile.address}');
      await _loadLocation(currentUser.uid, reloaded: true);

      debugPrint(
        'Updated profile: ${profile.fullName}, ${profile.phoneNumber}, ${profile.address}',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Shipping location saved')));
    } catch (e) {
      debugPrint('Failed to save profile: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LikesPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TrackOrdersPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ShoppingCartPage()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location'),
        backgroundColor: const Color(0xFF028B22),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x11000000),
                            blurRadius: 10,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildField(
                            label: 'First Name:',
                            controller: _firstNameController,
                          ),
                          const SizedBox(height: 12),
                          _buildField(
                            label: 'Middle Initial:',
                            controller: _middleInitialController,
                          ),
                          const SizedBox(height: 12),
                          _buildField(
                            label: 'Last Name:',
                            controller: _lastNameController,
                          ),
                          const SizedBox(height: 12),
                          _buildField(
                            label: 'Phone Number:',
                            controller: _phoneController,
                          ),
                          const SizedBox(height: 12),
                          _buildField(
                            label: 'Street:',
                            controller: _streetController,
                          ),
                          const SizedBox(height: 12),
                          _buildField(
                            label: 'Barangay:',
                            controller: _brgyController,
                          ),
                          const SizedBox(height: 12),
                          _buildField(
                            label: 'Municipality:',
                            controller: _municipalController,
                          ),
                          const SizedBox(height: 12),
                          _buildField(
                            label: 'City:',
                            controller: _cityController,
                          ),
                          const SizedBox(height: 12),
                          _buildField(
                            label: 'Country:',
                            controller: _countryController,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _saving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF028B22),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text('Save Location'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1E8B3A),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Likes'),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Track Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Shopping Cart',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7F7F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
