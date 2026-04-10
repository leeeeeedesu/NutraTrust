import 'package:flutter/material.dart';
import 'home_page.dart';
import 'shoppingcart_page.dart';
import 'profile_page.dart';
import 'trackorders_page.dart';

class LikesPage extends StatefulWidget {
  const LikesPage({super.key});

  @override
  State<LikesPage> createState() => _LikesPageState();
}

class _LikesPageState extends State<LikesPage> {
  int _selectedIndex = 1;

  final List<Map<String, dynamic>> likedItems = [
    {
      'name': 'GOLD STANDARD® Pre-Workout',
      'image': 'assets/wheygold.png',
      'description': 'Pre-workout formula',
      'liked': true,
    },
    {
      'name': 'Pre-Workout Amped',
      'image': 'assets/wheyisolate.png',
      'description': 'Amped energy boost',
      'liked': true,
    },
  ];

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Page not yet implemented')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Likes'),
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
        padding: const EdgeInsets.all(12),
        itemCount: likedItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = likedItems[index];
          final bool isLiked = item['liked'] as bool? ?? false;
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBEE6C9)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              leading: item['image'] != null
                  ? Image.asset(item['image']!, width: 56, height: 56)
                  : const SizedBox.shrink(),
              title: Text(item['name'] ?? ''),
              subtitle: Text(item['description'] ?? ''),
              trailing: IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    likedItems[index]['liked'] = !isLiked;
                  });
                },
              ),
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
