import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../login_page.dart';
import 'admin_dashboard.dart';
import 'admin_manage_product.dart';
import 'admin_user_lists.dart';
import 'admin_reviews.dart';
import 'admin_inventory.dart';
import 'admin_delivery.dart';
import '../services/realtime_database_service.dart';
import '../services/cloudinary_service.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  String? _profileImageUrl;
  bool _loadingImages = true;

  final ImagePicker _imagePicker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final images = await RealtimeDatabaseService.getUserImages(
        currentUser.uid,
      );
      setState(() {
        _profileImageUrl = images['profileImage'];

        _loadingImages = false;
      });
    } catch (e) {
      setState(() {
        _loadingImages = false;
      });
    }
  }

  Future<void> _pickAndUploadProfileImage() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile == null) return;

      debugPrint('Selected image path: ${pickedFile.path}');

      final file = File(pickedFile.path);
      final secureUrl = await _cloudinaryService.uploadProfileImage(
        file,
        currentUser.uid,
        true, // isAdmin
      );

      debugPrint('Upload success: secure_url = $secureUrl');

      setState(() {
        _profileImageUrl = secureUrl;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('assets/NutraTrustnobg.png', width: 120),
                const SizedBox(height: 18),
                const SizedBox(height: 24),
                // Profile Image with edit button
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: const Color(0xFFE8E8E8),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: const Color(0xFF028B22),
                        backgroundImage: _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : null,
                        child: _profileImageUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 46,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF028B22),
                        child: IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                          onPressed: _pickAndUploadProfileImage,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F5B2A),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'SETTINGS',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E8E8),
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 20.0,
                    horizontal: 16.0,
                  ),
                  child: Column(
                    children: [
                      _AdminSettingButton(
                        label: 'DASHBOARD',
                        onTap: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminDashboardPage(),
                            ),
                            (route) => route.isFirst,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _AdminSettingButton(
                        label: 'MANAGE PRODUCT',
                        onTap: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminManageProductPage(),
                            ),
                            (route) => route.isFirst,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _AdminSettingButton(
                        label: 'USER LISTS',
                        onTap: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminUserListsPage(),
                            ),
                            (route) => route.isFirst,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _AdminSettingButton(
                        label: 'INVENTORY',
                        onTap: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminInventoryPage(),
                            ),
                            (route) => route.isFirst,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _AdminSettingButton(
                        label: 'REVIEWS',
                        onTap: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminReviewsPage(),
                            ),
                            (route) => route.isFirst,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _AdminSettingButton(
                        label: 'DELIVERY',
                        onTap: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminDeliveryPage(),
                            ),
                            (route) => route.isFirst,
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFCB2020),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                          ),
                          child: const Text(
                            'LOG OUT',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminSettingButton extends StatelessWidget {
  const _AdminSettingButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFF028B22), width: 1.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF028B22),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
