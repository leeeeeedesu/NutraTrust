import 'package:flutter/material.dart';
import 'shoppingcart_page.dart';
import 'services/like_service.dart';
import 'likes_page.dart';
import 'product.dart';
import 'profile_page.dart';
import 'services/realtime_database_service.dart';
import 'trackorders_page.dart';
import 'search_page.dart';
import 'view_product_page.dart';
import 'widgets/product_list.dart';
import 'widgets/app_bottom_nav.dart';
import 'utils/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String _selectedCategory = 'All';

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

  bool _matchesCategory(String? category, String filter) {
    if (filter == 'All') return true;
    final normalizedCategory = (category ?? '').toLowerCase();
    final normalizedFilter = filter.toLowerCase();
    return normalizedCategory == normalizedFilter ||
        normalizedCategory == normalizedFilter.replaceAll('s', '') ||
        normalizedCategory.contains(normalizedFilter.replaceAll('s', ''));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Banner
              _buildHeroBanner(),

              // Search Bar
              _buildSearchBar(),

              // Categories
              _buildCategories(),

              // Featured Products
              _buildSectionTitle('Featured Products'),
              _buildFeaturedProducts(),

              // Recommended Products
              _buildSectionTitle('Recommended for You'),
              _buildRecommendedProducts(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 20,
            top: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome to',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const Text(
                  'NutraTrust',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Premium Supplements\nfor Your Wellness',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: Image.asset(
              'assets/NutraTrustnobg.png',
              height: 80,
              width: 80,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchPage()),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: AppColors.text.withAlpha(128)),
              const SizedBox(width: 12),
              Text(
                'Search products...',
                style: TextStyle(
                  color: AppColors.text.withAlpha(128),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final categories = [
      'All',
      'Vitamins',
      'Minerals',
      'Herbs',
      'Proteins',
      'Creatine',
    ];

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              child: Chip(
                label: Text(category),
                backgroundColor: isSelected
                    ? AppColors.primary
                    : AppColors.secondary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.text,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.text,
        ),
      ),
    );
  }

  Widget _buildFeaturedProducts() {
    return Container(
      height: 280,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<List<Product>>(
        stream: RealtimeDatabaseService.productsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final products =
              snapshot.data
                  ?.where(
                    (product) =>
                        _matchesCategory(product.category, _selectedCategory),
                  )
                  .take(4)
                  .toList() ??
              [];

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewProductPage(product: product),
                      ),
                    );
                  },
                  child: _buildProductCard(product),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRecommendedProducts() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<List<Product>>(
        stream: RealtimeDatabaseService.productsStream(),
        builder: (context, snapshot) {
          final filteredProducts =
              snapshot.data
                  ?.where(
                    (product) =>
                        _matchesCategory(product.category, _selectedCategory),
                  )
                  .toList() ??
              [];
          return ProductList(
            products: filteredProducts,
            isLoading: snapshot.connectionState == ConnectionState.waiting,
            hasError: snapshot.hasError,
            errorMessage: snapshot.error?.toString(),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final name = product.name.isEmpty ? 'Uncategorized' : product.name;
    final price = product.price > 0 ? product.price : 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                image: product.image != null && product.image!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(product.image!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: product.image == null || product.image!.isEmpty
                  ? const Icon(Icons.image, size: 50, color: Colors.grey)
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '₱${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
