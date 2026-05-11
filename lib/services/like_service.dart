import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../product.dart';
import 'realtime_database_service.dart';

class LikeService {
  static final List<Product> _likedProducts = [];
  static final ValueNotifier<List<Product>> likedProductsNotifier =
      ValueNotifier<List<Product>>([]);
  static final ValueNotifier<int> likeCountNotifier = ValueNotifier<int>(0);

  static List<Product> get likedProducts => List.unmodifiable(_likedProducts);

  static bool isLiked(String id) {
    return _likedProducts.any((product) => product.id == id);
  }

  static void _updateNotifiers() {
    likedProductsNotifier.value = List.unmodifiable(_likedProducts);
    likeCountNotifier.value = _likedProducts.length;
  }

  static Future<void> loadLikedProductsFromDatabase() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final likedIds = await RealtimeDatabaseService.getLikedProductIds(
        currentUser.uid,
      );
      final allProducts = await RealtimeDatabaseService.getAllProducts();
      _likedProducts
        ..clear()
        ..addAll(allProducts.where((product) => likedIds.contains(product.id)));
      _updateNotifiers();
    } catch (e) {
      debugPrint('Error loading liked products: $e');
    }
  }

  static Future<void> add(Product product) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    if (isLiked(product.id)) return;

    try {
      await RealtimeDatabaseService.likeProduct(
        uid: currentUser.uid,
        productId: product.id,
      );
      _likedProducts.add(product);
      _updateNotifiers();
    } catch (e) {
      debugPrint('Failed to like product ${product.id}: $e');
    }
  }

  static Future<void> remove(String id) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await RealtimeDatabaseService.unlikeProduct(
        uid: currentUser.uid,
        productId: id,
      );
      _likedProducts.removeWhere((product) => product.id == id);
      _updateNotifiers();
    } catch (e) {
      debugPrint('Failed to remove liked product $id: $e');
    }
  }

  static Future<void> toggle(Product product) async {
    if (isLiked(product.id)) {
      await remove(product.id);
    } else {
      await add(product);
    }
  }
}
