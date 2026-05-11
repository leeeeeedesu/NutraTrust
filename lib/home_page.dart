import 'package:flutter/material.dart';
import 'shoppingcart_page.dart';
import 'services/like_service.dart';
import 'likes_page.dart';
import 'product.dart';
import 'profile_page.dart';
import 'services/realtime_database_service.dart';
import 'trackorders_page.dart';
import 'search_page.dart';
import 'widgets/product_list.dart';
import 'widgets/app_bottom_nav.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    LikeService.loadLikedProductsFromDatabase().then((_) {
      if (mounted) setState(() {});
    });
  }

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
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchPage()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF028B22),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        enabled:
                            false, // Disable typing, only tap to open search
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
                  ),

                  const SizedBox(height: 18),

                  // Logo
                  Center(
                    child: Image.asset('assets/NutraTrustnobg.png', height: 84),
                  ),

                  const SizedBox(height: 18),

                  // Product grid
                  StreamBuilder<List<Product>>(
                    stream: RealtimeDatabaseService.productsStream(),
                    builder: (context, snapshot) {
                      return ProductList(
                        products: snapshot.data ?? [],
                        isLoading:
                            snapshot.connectionState == ConnectionState.waiting,
                        hasError: snapshot.hasError,
                        errorMessage: snapshot.error?.toString(),
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
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F8F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFCBDCC4)),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF028B22),
            ),
          ),
        ),
      ),
    );
  }
}
