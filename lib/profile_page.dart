import 'package:flutter/material.dart';
import 'home_page.dart';
import 'likes_page.dart';
import 'login_page.dart';
import 'shoppingcart_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 4; // Profile index

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
      case 3: // Shopping Cart
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ShoppingCartPage()),
        );
        break;
      case 4:
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Page not yet implemented")),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: const Color(0xFF028B22),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Banner placeholder here to insert image later
            Container(
              height: 150,
              color: Colors.grey[300],
              child: const Center(child: Text("Banner Placeholder")),
            ),

            const SizedBox(height: 16),
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.green[200],
              child: const Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              "Profile Name",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text("Lorem ipsum", style: TextStyle(color: Colors.grey)),
            const Text("Bio", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),

            // Action buttons
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.green),
              title: const Text("Settings"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.green),
              title: const Text("Set your shipping Location"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.payment, color: Colors.green),
              title: const Text("To pay"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(
                Icons.account_balance_wallet,
                color: Colors.green,
              ),
              title: const Text("Wallet"),
              onTap: () {},
            ),

            const SizedBox(height: 24),

            // Log Out button
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Logged out")));
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Log Out"),
            ),
          ],
        ),
      ),

      // Bottom navigation bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1E8B3A),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Likes"),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: "Track Orders",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "Shopping Cart",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
