import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'home_page.dart';
import 'likes_page.dart';
import 'login_page.dart';
import 'reset_password.dart';
import 'services/realtime_database_service.dart';
import 'services/cloudinary_service.dart';
import 'shoppingcart_page.dart';
import 'trackorders_page.dart';
import 'profile_page.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  int _selectedIndex = 4;

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
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF028B22),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x11000000),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSettingTile(
                        icon: Icons.person,
                        title: 'Account & Security',
                        subtitle: 'Update name, bio, and login options',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AccountSecurityPage(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _buildSettingTile(
                        icon: Icons.notifications,
                        title: 'Notification Settings',
                        subtitle: 'Manage app alerts and offers',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Notification Settings coming soon',
                              ),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _buildSettingTile(
                        icon: Icons.shield,
                        title: 'Privacy & Security',
                        subtitle: 'View your account protection settings',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Privacy & Security coming soon'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3FFF5),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Helpful tips',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E8B3A),
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

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F2E8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF1E8B3A), size: 24),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
      onTap: onTap,
    );
  }
}

class AccountSecurityPage extends StatefulWidget {
  const AccountSecurityPage({super.key});

  @override
  State<AccountSecurityPage> createState() => _AccountSecurityPageState();
}

class _AccountSecurityPageState extends State<AccountSecurityPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  StreamSubscription<Map<String, dynamic>?>? _profileSubscription;
  String? _profileImageUrl;
  String? _bannerImageUrl;
  final ImagePicker _imagePicker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _subscribeToProfileChanges();
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _nameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to manage account settings.'),
        ),
      );
      Navigator.pop(context);
      return;
    }

    final fetchedEmail = currentUser.email ?? '';
    _emailController.text = fetchedEmail;

    try {
      final profileData = await RealtimeDatabaseService.getUserProfile(
        currentUser.uid,
      );
      final images = await RealtimeDatabaseService.getUserImages(
        currentUser.uid,
      );

      if (profileData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No profile data found for this account.'),
            ),
          );
        }
        _nameController.text = fetchedEmail.split('@').first;
        _bioController.text = '';
        _profileImageUrl = null;
        _bannerImageUrl = null;
        return;
      }

      final firstName = profileData['firstName']?.toString() ?? '';
      final middleInitial = profileData['middleInitial']?.toString() ?? '';
      final lastName = profileData['lastName']?.toString() ?? '';
      final loadedName =
          (firstName.isNotEmpty ||
              middleInitial.isNotEmpty ||
              lastName.isNotEmpty)
          ? '$firstName ${middleInitial.isNotEmpty ? '$middleInitial ' : ''}$lastName'
                .trim()
          : fetchedEmail.split('@').first;
      final loadedBio = profileData['bio']?.toString() ?? '';
      final loadedEmail = profileData['email']?.toString() ?? fetchedEmail;
      final loadedProfileImage = images['profileImage'];
      final loadedBannerImage = images['bannerImage'];
      debugPrint('Loaded name: $loadedName');
      debugPrint('Loaded bio: $loadedBio');
      debugPrint('Loaded profileImage: $loadedProfileImage');
      debugPrint('Loaded bannerImage: $loadedBannerImage');
      _nameController.text = loadedName;
      _bioController.text = loadedBio;
      _emailController.text = loadedEmail;
      _profileImageUrl = loadedProfileImage;
      _bannerImageUrl = loadedBannerImage;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> saveProfileChanges({String? targetUid}) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save profile changes.')),
      );
      return;
    }

    final name = _nameController.text.trim();
    final bio = _bioController.text.trim();
    final email = _emailController.text.trim();
    final profileUid = targetUid?.trim().isNotEmpty == true
        ? targetUid!.trim()
        : currentUser.uid;

    if (name.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name cannot be empty.')));
      return;
    }

    if (email.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email cannot be empty.')));
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await RealtimeDatabaseService.updateUserProfile(
        profileUid,
        name: name,
        bio: bio,
      );
      debugPrint('Updated name: $name');
      debugPrint('Updated bio: $bio');

      final nameParts = _splitFullName(name);
      await RealtimeDatabaseService.updateUserProfileFields(
        profileUid,
        firstName: nameParts['firstName'],
        middleInitial: nameParts['middleInitial'],
        lastName: nameParts['lastName'],
        fullName: name,
        bio: bio,
      );

      await RealtimeDatabaseService.usersRef.child(profileUid).update({
        'email': email,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile changes saved successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile changes: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Map<String, String> _splitFullName(String fullName) {
    final normalized = fullName.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      return {'firstName': '', 'middleInitial': '', 'lastName': ''};
    }

    final parts = normalized.split(' ');
    if (parts.length == 1) {
      return {'firstName': parts[0], 'middleInitial': '', 'lastName': ''};
    }
    if (parts.length == 2) {
      return {'firstName': parts[0], 'middleInitial': '', 'lastName': parts[1]};
    }

    final firstName = parts.first;
    final lastName = parts.last;
    final middleInitial = parts[1].isNotEmpty ? parts[1][0] : '';
    return {
      'firstName': firstName,
      'middleInitial': middleInitial,
      'lastName': lastName,
    };
  }

  void _subscribeToProfileChanges() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _profileSubscription =
        RealtimeDatabaseService.userProfileStream(currentUser.uid).listen(
          (profile) async {
            if (!mounted || profile == null) return;
            final firstName = profile['firstName']?.toString() ?? '';
            final middleInitial = profile['middleInitial']?.toString() ?? '';
            final lastName = profile['lastName']?.toString() ?? '';
            final loadedName =
                (firstName.isNotEmpty ||
                    middleInitial.isNotEmpty ||
                    lastName.isNotEmpty)
                ? '$firstName ${middleInitial.isNotEmpty ? '$middleInitial ' : ''}$lastName'
                      .trim()
                : currentUser.email?.split('@').first ?? '';
            final loadedBio = profile['bio']?.toString() ?? '';
            final loadedEmail =
                profile['email']?.toString() ?? currentUser.email ?? '';
            final images = await RealtimeDatabaseService.getUserImages(
              currentUser.uid,
            );
            final loadedProfileImage = images['profileImage'];
            final loadedBannerImage = images['bannerImage'];
            debugPrint('Loaded name: $loadedName');
            debugPrint('Loaded bio: $loadedBio');
            debugPrint('Loaded profileImage: $loadedProfileImage');
            debugPrint('Loaded bannerImage: $loadedBannerImage');
            setState(() {
              _nameController.text = loadedName;
              _bioController.text = loadedBio;
              _emailController.text = loadedEmail;
              _profileImageUrl = loadedProfileImage;
              _bannerImageUrl = loadedBannerImage;
            });
          },
          onError: (e) {
            debugPrint('AccountSecurityPage profile stream failed: $e');
          },
        );
  }

  Future<void> _pickAndUploadProfileImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile == null) return;

      debugPrint('Selected image path: ${pickedFile.path}');

      final file = File(pickedFile.path);
      final secureUrl = await _cloudinaryService.uploadImage(file);

      debugPrint('Uploaded to Cloudinary: $secureUrl');

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await RealtimeDatabaseService.updateUserImages(
        currentUser.uid,
        profileImageUrl: secureUrl,
      );

      debugPrint('Saved profileImage: $secureUrl');

      if (!mounted) return;
      setState(() {
        _profileImageUrl = secureUrl;
      });

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

  Future<void> _pickAndUploadBannerImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile == null) return;

      debugPrint('Selected image path: ${pickedFile.path}');

      final file = File(pickedFile.path);
      final secureUrl = await _cloudinaryService.uploadImage(file);

      debugPrint('Uploaded to Cloudinary: $secureUrl');

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await RealtimeDatabaseService.updateUserImages(
        currentUser.uid,
        bannerImageUrl: secureUrl,
      );

      debugPrint('Saved bannerImage: $secureUrl');

      if (!mounted) return;
      setState(() {
        _bannerImageUrl = secureUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Banner image updated successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update banner image: $e')),
      );
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No account email available.')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset link sent to $email')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to send reset email: $e')));
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account & Security'),
        backgroundColor: const Color(0xFF028B22),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x11000000),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E8B3A),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              label: 'Name',
                              controller: _nameController,
                              hint: 'Enter your display name',
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              label: 'Bio',
                              controller: _bioController,
                              hint: 'Tell others about yourself',
                              maxLines: 4,
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              label: 'Email',
                              controller: _emailController,
                              hint: 'Enter your account email',
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Profile Images',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E8B3A),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Profile Image Section
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Profile Image',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Colors.green[200],
                                      backgroundImage: _profileImageUrl != null
                                          ? NetworkImage(_profileImageUrl!)
                                          : null,
                                      child: _profileImageUrl == null
                                          ? const Icon(
                                              Icons.person,
                                              size: 30,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    ElevatedButton.icon(
                                      onPressed: _pickAndUploadProfileImage,
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Edit Profile Image'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF028B22,
                                        ),
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Banner Image Section
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Banner Image',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                        image: _bannerImageUrl != null
                                            ? DecorationImage(
                                                image: NetworkImage(
                                                  _bannerImageUrl!,
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: _bannerImageUrl == null
                                          ? const Center(
                                              child: Text(
                                                'Banner',
                                                style: TextStyle(fontSize: 10),
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    ElevatedButton.icon(
                                      onPressed: _pickAndUploadBannerImage,
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Edit Banner'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF028B22,
                                        ),
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _saving
                                  ? null
                                  : () async {
                                      final navigator = Navigator.of(context);
                                      await saveProfileChanges();
                                      if (mounted) {
                                        navigator.pushReplacement(
                                          MaterialPageRoute(
                                            builder: (_) => const ProfilePage(),
                                          ),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF028B22),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.0,
                                      ),
                                    )
                                  : const Text('Save Changes'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSecurityCard(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF5F7F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.lock, color: Color(0xFF1E8B3A)),
            title: const Text('Reset Password'),
            subtitle: const Text('Send a reset link to your email'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 18),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFF1E8B3A)),
            title: const Text('Log Out'),
            subtitle: const Text('Sign out of this account'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 18),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
