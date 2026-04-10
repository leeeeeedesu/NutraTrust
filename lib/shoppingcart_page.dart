import 'package:flutter/material.dart';
import 'home_page.dart';
import 'likes_page.dart';
import 'profile_page.dart';
import 'trackorders_page.dart';

class ShoppingCartPage extends StatefulWidget {
  const ShoppingCartPage({super.key});

  @override
  State<ShoppingCartPage> createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends State<ShoppingCartPage> {
  int _selectedIndex = 3;
  //sample lists of items
  final List<Map<String, dynamic>> cartItems = [
    {
      'title': 'GOLD STANDARD 100% WHEY™',
      'flavor': 'Blueberry Lemonade',
      'size': '0.66 LB',
      'quantity': 1,
      'price': 0.00,
      'image': 'assets/wheygold.png',
    },
    {
      'title': 'Gold Standard Isolate Whey Protein',
      'flavor': 'Citrus Mango',
      'size': '0.8 LB',
      'quantity': 2,
      'price': 0.00,
      'image': 'assets/wheyisolate.png',
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

  bool _checkoutAll = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E8B3A)),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          },
        ),
        title: const Text(
          'Shopping Cart',
          style: TextStyle(
            color: Color(0xFF1E8B3A),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Checkbox(
                  value: _checkoutAll,
                  activeColor: const Color(0xFF1E8B3A),
                  onChanged: (v) {
                    setState(() {
                      _checkoutAll = v ?? false;
                    });
                  },
                ),
                const SizedBox(width: 6),
                const Text(
                  'Checkout All',
                  style: TextStyle(
                    color: Color(0xFF1E8B3A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: ListView.separated(
              itemCount: cartItems.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item checkbox
                      Checkbox(
                        value: _checkoutAll ? true : false,
                        activeColor: const Color(0xFF1E8B3A),
                        onChanged: (v) {},
                      ),

                      const SizedBox(width: 6),

                      // Thumbnail
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: item['image'] != null
                            ? Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Image.asset(
                                  item['image'],
                                  fit: BoxFit.contain,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(width: 12),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F1F1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['flavor'],
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item['size'],
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
                      ),

                      // Quantity & price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Quantity: ${item['quantity']}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₱${item['price'].toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBFEFB0),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Checkout'),
                ),
              ],
            ),
          ),
        ],
      ),

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
