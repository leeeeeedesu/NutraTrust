import 'package:flutter/material.dart';
import 'likes_page.dart';
import 'profile_page.dart';
import 'shoppingcart_page.dart';
import 'trackorders_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Map<String, String>> products = [
    {
      "name": "GOLD STANDARD 100% WHEY™",
      "description": "73 Serving GOLD STANDARD 100% WHEY™",
      "image": "assets/wheygold.png",
    },
    {
      "name": "Gold Standard Isolate Whey Protein Powder",
      "description": "44 Serving GOLD STANDARD 100% WHEY™",
      "image": "assets/wheyisolate.png",
    },
    {
      "name": "Micronized Creatine Powder",
      "description": "60 Serving Micronized CREATINE 100%",
      "image": "assets/creatine.png",
    },
    {
      "name": "Opti-Lock™ Shaker Bundle",
      "description": "10 Serving GOLD STANDARD 100% WHEY™",
      "image": "assets/shakerbundle.png",
    },
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: // Home
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              constraints: const BoxConstraints(maxWidth: 700),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF028B22),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white70,
                        ),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Logo
                  Center(
                    child: Image.asset('assets/NutraTrustnobg.png', height: 84),
                  ),

                  const SizedBox(height: 18),

                  // Product grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 18,
                          crossAxisSpacing: 18,
                          childAspectRatio: 0.72,
                        ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE8E8E8),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x11000000),
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset(
                                    product['image']!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFBEE6C9),
                              ),
                              color: const Color(0xFFF7FFFA),
                            ),
                            child: Text(
                              product['name']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF1E8B3A),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
      //bttom navigation bar
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
