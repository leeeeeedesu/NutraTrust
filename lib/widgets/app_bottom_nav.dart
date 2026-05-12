import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class AppBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('Bottom nav index: $currentIndex');

    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.text.withOpacity(0.627),
      onTap: (index) {
        debugPrint('Bottom nav switching to index: $index');
        onTap(index);
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(
          icon: LikeBadgeIcon(child: Icon(Icons.favorite)),
          label: "Likes",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.card_giftcard),
          label: "Track Orders",
        ),
        BottomNavigationBarItem(
          icon: CartBadgeIcon(child: Icon(Icons.shopping_cart)),
          label: "Shopping Cart",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
      type: BottomNavigationBarType.fixed,
    );
  }
}

class LikeBadgeIcon extends StatelessWidget {
  final Widget child;

  const LikeBadgeIcon({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child; // Simplified for now - can add badge logic later
  }
}

class CartBadgeIcon extends StatelessWidget {
  final Widget child;

  const CartBadgeIcon({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child; // Simplified for now - can add badge logic later
  }
}
