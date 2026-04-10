import 'package:flutter/material.dart';
import 'home_page.dart';
import 'likes_page.dart';
import 'profile_page.dart';
import 'shoppingcart_page.dart';

class TrackOrdersPage extends StatefulWidget {
  const TrackOrdersPage({super.key});

  @override
  State<TrackOrdersPage> createState() => _TrackOrdersPageState();
}

class _TrackOrdersPageState extends State<TrackOrdersPage> {
  int _selectedIndex = 2;

  // sample order data - could later be replaced with real API responses
  final List<Map<String, dynamic>> orders = [
    {
      'name': 'Micronized Creatine Powder',
      'price': 0.00,
      'image': 'assets/creatine.png',
      'status': 'Delivered',
    },
    {
      'name': 'Gold Standard 100% Isolate Whey Protein powder',
      'price': 0.00,
      'image': 'assets/wheyisolate.png',
      'status': 'Delivered',
    },
    {
      'name': 'GOLD STANDARD® Ready To Drink Protein Shake',
      'price': 0.00,
      'image': 'assets/goldshake.jpeg',
      'status': 'In Transit',
    },
  ];

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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return const Color(0xFF1E8B3A); // green
      case 'in transit':
        return const Color(0xFFCED431); // yellowish
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Orders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          },
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = orders[index];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: order['image'] != null
                      ? Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Image.asset(
                            order['image'],
                            fit: BoxFit.contain,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['name'],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₱${order['price'].toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _statusColor(order['status']),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: Text(
                    order['status'],
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        },
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
}
