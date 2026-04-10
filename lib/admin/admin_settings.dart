import 'package:flutter/material.dart';

import '../login_page.dart';

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

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
                const Text(
                  'NutraTrust',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F5B2A),
                  ),
                ),
                const SizedBox(height: 24),
                const CircleAvatar(
                  radius: 52,
                  backgroundColor: Color(0xFFE8E8E8),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: Color(0xFF028B22),
                    child: Icon(Icons.person, size: 46, color: Colors.white),
                  ),
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
                      _AdminSettingButton(label: 'DASHBOARD', onTap: () {}),
                      const SizedBox(height: 12),
                      _AdminSettingButton(
                        label: 'MANAGE PRODUCT',
                        onTap: () {},
                      ),
                      const SizedBox(height: 12),
                      _AdminSettingButton(label: 'USER LISTS', onTap: () {}),
                      const SizedBox(height: 12),
                      _AdminSettingButton(label: 'INVENTORY', onTap: () {}),
                      const SizedBox(height: 12),
                      _AdminSettingButton(label: 'NOTHING', onTap: () {}),
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
