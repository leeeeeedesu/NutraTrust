import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../product.dart';
import '../models/user_profile.dart';

class RealtimeDatabaseService {
  static const String databaseUrl =
      'https://e-commerce-92163-default-rtdb.firebaseio.com';
  static DatabaseReference get productsRef => FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: databaseUrl,
  ).ref('products');

  static Stream<List<Product>> productsStream() {
    return productsRef.onValue.map((event) {
      final snapshot = event.snapshot;
      final products = <Product>[];
      if (!snapshot.exists) {
        debugPrint('ProductsStream: No products data in database');
        return products;
      }

      final value = snapshot.value;
      if (value is Map) {
        debugPrint(
          'ProductsStream: Loading ${value.length} products from database',
        );
        value.forEach((key, rawProduct) {
          if (rawProduct is Map) {
            try {
              final product = Product.fromMap(key.toString(), rawProduct);
              debugPrint(
                'ProductsStream: Loaded product - ID: $key, Name: ${product.name}, Price: ${product.price}, Stock: ${product.stock}, Category: ${product.category ?? "null"}, Image: ${product.image ?? "null"}',
              );
              products.add(product);
            } catch (e) {
              debugPrint('ProductsStream: Error parsing product $key: $e');
            }
          }
        });
        debugPrint(
          'ProductsStream: Successfully loaded ${products.length} products',
        );
      }
      return products;
    });
  }

  /// Search products by name, brand, or category
  static Future<List<Product>> searchProducts(String query) async {
    if (query.isEmpty) {
      debugPrint('SearchProducts: Empty query');
      return [];
    }

    final queryLower = query.toLowerCase().trim();
    debugPrint('SearchProducts: Searching for "$queryLower"');
    final snapshot = await productsRef.get();

    if (!snapshot.exists) {
      debugPrint('SearchProducts: No products data found');
      return [];
    }

    final products = <Product>[];
    final value = snapshot.value;

    if (value is Map) {
      debugPrint('SearchProducts: Searching through ${value.length} products');
      value.forEach((key, rawProduct) {
        if (rawProduct is Map) {
          try {
            final product = Product.fromMap(key.toString(), rawProduct);
            final name = product.name.toLowerCase();
            final category = product.category?.toLowerCase() ?? '';
            final brand = product.brand?.toLowerCase() ?? '';

            // Match by name, brand, or category
            if (name.contains(queryLower) ||
                category.contains(queryLower) ||
                brand.contains(queryLower)) {
              debugPrint(
                'SearchProducts: Found match - ${product.name} (ID: $key)',
              );
              products.add(product);
            }
          } catch (e) {
            debugPrint('SearchProducts: Error parsing product $key: $e');
          }
        }
      });
    }
    debugPrint('SearchProducts: Found ${products.length} matches');
    return products;
  }

  /// Get all products for auto-suggestions
  static Future<List<Product>> getAllProducts() async {
    debugPrint('GetAllProducts: Fetching all products');
    final snapshot = await productsRef.get();

    if (!snapshot.exists) {
      debugPrint('GetAllProducts: No products data found');
      return [];
    }

    final products = <Product>[];
    final value = snapshot.value;

    if (value is Map) {
      debugPrint('GetAllProducts: Loading ${value.length} products');
      value.forEach((key, rawProduct) {
        if (rawProduct is Map) {
          try {
            final product = Product.fromMap(key.toString(), rawProduct);
            debugPrint(
              'GetAllProducts: Loaded - ID: $key, Name: ${product.name}, Price: ${product.price}, Stock: ${product.stock}',
            );
            products.add(product);
          } catch (e) {
            debugPrint('GetAllProducts: Error parsing product $key: $e');
          }
        }
      });
    }
    debugPrint('GetAllProducts: Total products loaded: ${products.length}');
    return products;
  }

  static DatabaseReference get likesRef => FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: databaseUrl,
  ).ref('likes');

  static DatabaseReference userLikesRef(String uid) => likesRef.child(uid);

  static Future<void> likeProduct({
    required String uid,
    required String productId,
  }) async {
    await userLikesRef(uid).child(productId).set(true);
  }

  static Future<void> unlikeProduct({
    required String uid,
    required String productId,
  }) async {
    await userLikesRef(uid).child(productId).remove();
  }

  static Future<List<String>> getLikedProductIds(String uid) async {
    final snapshot = await userLikesRef(uid).get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final value = snapshot.value;
    if (value is Map) {
      return value.keys.map((key) => key.toString()).toList();
    }

    return [];
  }

  static Stream<List<String>> likedProductIdsStream(String uid) {
    return userLikesRef(uid).onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) return <String>[];

      final value = snapshot.value;
      if (value is Map) {
        return value.keys.map((key) => key.toString()).toList();
      }

      return <String>[];
    });
  }

  static Stream<List<Product>> likedProductsStream(String uid) {
    final controller = StreamController<List<Product>>.broadcast();
    final likedIds = <String>{};
    var products = <Product>[];

    void emit() {
      final likedProducts = products
          .where((product) => likedIds.contains(product.id))
          .toList();
      controller.add(likedProducts);
    }

    final likesSub = userLikesRef(uid).onValue.listen((event) {
      likedIds.clear();
      final snapshot = event.snapshot;
      if (snapshot.exists && snapshot.value is Map) {
        final value = snapshot.value as Map;
        likedIds.addAll(value.keys.map((key) => key.toString()));
      }
      emit();
    }, onError: controller.addError);

    final productsSub = productsRef.onValue.listen((event) {
      final snapshot = event.snapshot;
      final latestProducts = <Product>[];
      if (snapshot.exists && snapshot.value is Map) {
        final value = snapshot.value as Map;
        value.forEach((key, rawProduct) {
          if (rawProduct is Map) {
            latestProducts.add(Product.fromMap(key.toString(), rawProduct));
          }
        });
      }
      products = latestProducts;
      emit();
    }, onError: controller.addError);

    controller.onCancel = () async {
      await likesSub.cancel();
      await productsSub.cancel();
    };

    return controller.stream;
  }

  static Future<void> updateProduct(
    String productId,
    Map<String, dynamic> updates,
  ) async {
    await productsRef.child(productId).update(updates);
  }

  //decrement product when bought
  static Future<bool> decrementProductStock(
    String productId,
    int quantity,
  ) async {
    try {
      final ref = productsRef.child(productId);

      debugPrint('Requested quantity: $quantity for productId: $productId');

      final transactionResult = await ref.runTransaction((currentData) {
        if (currentData == null) {
          return Transaction.abort();
        }

        final data = Map<String, dynamic>.from(currentData as Map);

        final currentStock =
            int.tryParse(data['stock']?.toString() ?? '0') ?? 0;

        debugPrint('Available stock: $currentStock for productId: $productId');

        // Prevent negative stock
        if (currentStock < quantity) {
          debugPrint(
            'Insufficient stock: Available $currentStock, Requested $quantity for productId: $productId',
          );
          return Transaction.abort();
        }

        data['stock'] = currentStock - quantity;

        return Transaction.success(data);
      });

      if (transactionResult.committed) {
        debugPrint(
          'Stock decremented successfully for productId: $productId, new stock: ${transactionResult.snapshot.child('stock').value}',
        );
      } else {
        debugPrint(
          'Stock decrement failed (transaction aborted) for productId: $productId',
        );
      }

      return transactionResult.committed;
    } catch (e) {
      debugPrint('Stock update failed for $productId: $e');
      return false;
    }
  }

  static Future<int> getProductStock(String productId) async {
    try {
      final snapshot = await productsRef.child(productId).child('stock').get();
      return int.tryParse(snapshot.value?.toString() ?? '0') ?? 0;
    } catch (e) {
      debugPrint('Failed to get stock for $productId: $e');
      return 0;
    }
  }

  static Future<void> deleteProduct(String productId) async {
    await productsRef.child(productId).remove();
  }

  static Future<void> addProduct(Map<String, dynamic> productData) async {
    await productsRef.push().set(productData);
  }

  static DatabaseReference get reviewsRef => FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: databaseUrl,
  ).ref('reviews');

  static Stream<List<Review>> reviewsStream() {
    return reviewsRef.onValue.map((event) {
      final snapshot = event.snapshot;
      final reviews = <Review>[];
      if (!snapshot.exists) return reviews;

      final value = snapshot.value;
      if (value is Map) {
        value.forEach((key, rawReview) {
          if (rawReview is Map) {
            reviews.add(Review.fromMap(key.toString(), rawReview));
          }
        });
      }

      reviews.sort((a, b) {
        final aTs = a.timestamp ?? 0;
        final bTs = b.timestamp ?? 0;
        return bTs.compareTo(aTs);
      });

      return reviews;
    });
  }

  static Stream<List<Review>> reviewsStreamForUser(String userId) {
    final userQuery = reviewsRef.orderByChild('userId').equalTo(userId);
    return userQuery.onValue.map((event) {
      final snapshot = event.snapshot;
      final reviews = <Review>[];
      if (!snapshot.exists) return reviews;

      final value = snapshot.value;
      if (value is Map) {
        value.forEach((key, rawReview) {
          if (rawReview is Map) {
            reviews.add(Review.fromMap(key.toString(), rawReview));
          }
        });
      }

      reviews.sort((a, b) {
        final aTs = a.timestamp ?? 0;
        final bTs = b.timestamp ?? 0;
        return bTs.compareTo(aTs);
      });

      return reviews;
    });
  }

  //review function
  static Future<void> addReview({
    required String productId,
    required int rating,
    required String comment,
    String? productName,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-signed-in',
        message: 'You must be signed in to submit a review.',
      );
    }

    final reviewData = {
      'userId': currentUser.uid,
      'productId': productId,
      'rating': rating,
      'comment': comment,
      'timestamp': ServerValue.timestamp,
      if (productName != null && productName.isNotEmpty)
        'productName': productName,
      if (currentUser.email != null) 'customerEmail': currentUser.email,
    };

    await reviewsRef.push().set(reviewData);
  }

  // ============ Customer Methods ============
  static DatabaseReference get customersRef => FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: databaseUrl,
  ).ref('customers');

  static DatabaseReference get usersRef => FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: databaseUrl,
  ).ref('users');

  static DatabaseReference get userProfilesRef => FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: databaseUrl,
  ).ref('users');

  /// Register a new user entry in the Realtime Database under users/{uid}
  static Future<void> createUserRecord({
    required String uid,
    required String email,
    required String role,
  }) async {
    await usersRef.child(uid).set({
      'uid': uid,
      'email': email,
      'role': role,
      'isActive': true,
      'profileImage': '',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  /// Ensure the user's account record exists and contains required fields.
  /// This makes it safe to read role/isActive/profileImage from /users/{uid}.
  static Future<Map<String, dynamic>> ensureUserAccountProfile({
    required String uid,
    required String email,
    String role = 'customer',
  }) async {
    final defaultData = <String, dynamic>{
      'uid': uid,
      'email': email,
      'role': role,
      'isActive': true,
      'profileImage': '',
      'createdAt': DateTime.now().toIso8601String(),
    };

    try {
      final snapshot = await usersRef.child(uid).get();
      if (!snapshot.exists || snapshot.value == null) {
        await usersRef.child(uid).set(defaultData);
        return defaultData;
      }

      final existingData = Map<String, dynamic>.from(snapshot.value as Map);
      final updates = <String, dynamic>{};

      if (existingData['uid'] == null) updates['uid'] = uid;
      if (existingData['email'] == null) updates['email'] = email;
      if (existingData['role'] == null) updates['role'] = role;
      if (existingData['isActive'] == null) updates['isActive'] = true;
      if (existingData['profileImage'] == null) updates['profileImage'] = '';
      if (existingData['createdAt'] == null) {
        updates['createdAt'] = DateTime.now().toIso8601String();
      }

      if (updates.isNotEmpty) {
        await usersRef.child(uid).update(updates);
        existingData.addAll(updates);
      }

      return existingData;
    } catch (e) {
      debugPrint('RealtimeDatabaseService.ensureUserAccountProfile failed: $e');
      rethrow;
    }
  }

  /// Register a new customer
  static Future<void> createCustomer({
    required String uid,
    required String name,
    required String email,
    required String birthdate,
  }) async {
    await customersRef.child(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'birthdate': birthdate,
      'role': 'customer',
      'createdAt': DateTime.now().toIso8601String(),
      'isActive': true,
    });
  }

  /// Get customer by UID or return a default customer fallback.
  /// This ensures pages still load even when /customers/{uid} is missing or unreadable.
  static Future<Map<String, dynamic>> getCustomerOrDefault(String uid) async {
    try {
      final snapshot = await customersRef.child(uid).get();
      if (snapshot.exists && snapshot.value != null) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
    } on FirebaseException catch (e) {
      debugPrint('Failed to read customer $uid: $e');
    } catch (e) {
      debugPrint('Failed to read customer $uid: $e');
    }

    return {'uid': uid, 'role': 'customer', 'isActive': true};
  }

  /// Update customer information
  static Future<void> updateCustomer(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    await customersRef.child(uid).update(updates);
  }

  /// Get user profile record from either /users/{uid}/profile or legacy customer/user nodes.
  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final profileSnapshot = await userProfilesRef
          .child(uid)
          .child('profile')
          .get();
      if (profileSnapshot.exists && profileSnapshot.value != null) {
        final profileData = Map<String, dynamic>.from(
          profileSnapshot.value as Map,
        );
        debugPrint(
          'RealtimeDatabaseService.getUserProfile loaded profile: $profileData',
        );
        return profileData;
      }
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      // Ignore permission denied on profile path and fall back to legacy nodes.
    }

    try {
      final customerSnapshot = await customersRef.child(uid).get();
      if (customerSnapshot.exists) {
        final customerData = Map<String, dynamic>.from(
          customerSnapshot.value as Map,
        );
        debugPrint(
          'RealtimeDatabaseService.getUserProfile loaded customer data: $customerData',
        );
        return customerData;
      }
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      // Ignore permission denied on customers path and fall back to users path.
    }

    try {
      final userSnapshot = await usersRef.child(uid).get();
      if (userSnapshot.exists) {
        final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
        debugPrint(
          'RealtimeDatabaseService.getUserProfile loaded user node data: $userData',
        );
        return userData;
      }
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      rethrow;
    }

    debugPrint(
      'RealtimeDatabaseService.getUserProfile: No profile data found for uid=$uid',
    );
    return null;
  }

  /// Get account profile data directly from /users/{uid}.
  static Future<Map<String, dynamic>?> getUserAccountProfile(String uid) async {
    try {
      final snapshot = await usersRef.child(uid).get();
      if (snapshot.exists && snapshot.value != null) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
    } on FirebaseException catch (e) {
      debugPrint('RealtimeDatabaseService.getUserAccountProfile failed: $e');
      rethrow;
    }
    return null;
  }

  /// Get user profile as a typed model for checkout and profile UI.
  static Future<UserProfile?> getUserProfileModel(String uid) async {
    final profileData = await getUserProfile(uid);
    if (profileData == null) {
      return null;
    }

    final profile = UserProfile.fromMap(profileData);
    return profile.copyWith(uid: uid);
  }

  /// Update profile information directly under /users/{uid}.
  /// This method writes only name and bio fields to the users node.
  static Future<void> updateUserProfile(
    String uid, {
    String? name,
    String? bio,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (bio != null) updates['bio'] = bio;
    if (updates.isEmpty) {
      debugPrint(
        'RealtimeDatabaseService.updateUserProfile: No updates to apply.',
      );
      return;
    }

    try {
      await usersRef.child(uid).update(updates);
      if (name != null) {
        debugPrint('Updated name: $name');
      }
      if (bio != null) {
        debugPrint('Updated bio: $bio');
      }
    } catch (e) {
      debugPrint('RealtimeDatabaseService.updateUserProfile failed: $e');
      rethrow;
    }
  }

  /// Get a realtime stream of the user's profile data from /users/{uid}/profile.
  static Stream<Map<String, dynamic>?> userProfileStream(String uid) {
    return userProfilesRef.child(uid).child('profile').onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return null;
      }
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }

  /// Load user shipping location from /users/{uid}/profile/location
  static Stream<Map<String, dynamic>?> userLocationStream(String uid) {
    return userProfilesRef
        .child(uid)
        .child('profile')
        .child('location')
        .onValue
        .map((event) {
          if (!event.snapshot.exists || event.snapshot.value == null) {
            return null;
          }
          return Map<String, dynamic>.from(event.snapshot.value as Map);
        });
  }

  /// Deactivate customer account
  static Future<void> deactivateCustomer(String uid) async {
    await customersRef.child(uid).update({'isActive': false});
  }

  // ============ UserProfile Methods ============
  /// Save user profile data for checkout
  /// Stores name, phoneNumber, and address under /users/{uid}/profile
  static Future<void> saveUserProfile(UserProfile profile) async {
    try {
      final profileData = {
        'uid': profile.uid,
        'firstName': profile.firstName,
        'middleInitial': profile.middleInitial,
        'lastName': profile.lastName,
        'fullName': profile.fullName,
        'phoneNumber': profile.phoneNumber,
        'street': profile.street,
        'barangay': profile.barangay,
        'municipality': profile.municipality,
        'city': profile.city,
        'country': profile.country,
        'address': profile.address,
        'createdAt': profile.createdAt?.toIso8601String(),
        'updatedAt':
            profile.updatedAt?.toIso8601String() ??
            DateTime.now().toIso8601String(),
      };

      debugPrint(
        'RealtimeDatabaseService.saveUserProfile: uid=${profile.uid} '
        'firstName=${profile.firstName} middleInitial=${profile.middleInitial} '
        'lastName=${profile.lastName} phone=${profile.phoneNumber} '
        'address=${profile.address}',
      );

      await userProfilesRef
          .child(profile.uid)
          .child('profile')
          .update(profileData);

      debugPrint('RealtimeDatabaseService.saveUserProfile: Successfully saved');
      debugPrint(
        'Saved name: ${profile.firstName} ${profile.middleInitial} ${profile.lastName}',
      );
    } catch (e) {
      debugPrint('RealtimeDatabaseService.saveUserProfile failed: $e');
      rethrow;
    }
  }

  /// Load user shipping location from /users/{uid}/profile/location
  static Future<Map<String, dynamic>?> getUserLocation(String uid) async {
    try {
      final snapshot = await userProfilesRef
          .child(uid)
          .child('profile')
          .child('location')
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final location = Map<String, dynamic>.from(snapshot.value as Map);
        debugPrint('RealtimeDatabaseService.getUserLocation loaded: $location');
        return location;
      }
    } catch (e) {
      debugPrint('RealtimeDatabaseService.getUserLocation failed: $e');
    }
    return null;
  }

  /// Persist user shipping location under /users/{uid}/profile/location
  static Future<void> updateUserLocation(
    String uid,
    Map<String, dynamic> location,
  ) async {
    try {
      await userProfilesRef
          .child(uid)
          .child('profile')
          .child('location')
          .set(location);
      debugPrint('RealtimeDatabaseService.updateUserLocation saved: $location');
    } catch (e) {
      debugPrint('RealtimeDatabaseService.updateUserLocation failed: $e');
      rethrow;
    }
  }

  /// Update specific fields under /users/{uid}/profile.
  static Future<void> updateUserProfileFields(
    String uid, {
    String? firstName,
    String? middleInitial,
    String? lastName,
    String? fullName,
    String? bio,
  }) async {
    final updates = <String, dynamic>{};
    if (firstName != null) updates['firstName'] = firstName;
    if (middleInitial != null) updates['middleInitial'] = middleInitial;
    if (lastName != null) updates['lastName'] = lastName;
    if (fullName != null) updates['fullName'] = fullName;
    if (bio != null) updates['bio'] = bio;

    if (updates.isEmpty) {
      debugPrint(
        'RealtimeDatabaseService.updateUserProfileFields: No updates to apply.',
      );
      return;
    }

    try {
      await userProfilesRef.child(uid).child('profile').update(updates);
      debugPrint(
        'RealtimeDatabaseService.updateUserProfileFields saved: $updates',
      );
    } catch (e) {
      debugPrint('RealtimeDatabaseService.updateUserProfileFields failed: $e');
      rethrow;
    }
  }

  /// Update user images (profileImage and bannerImage) under /users/{uid}/profile
  static Future<void> updateUserImages(
    String uid, {
    String? profileImageUrl,
    String? bannerImageUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (profileImageUrl != null) updates['profileImage'] = profileImageUrl;
    if (bannerImageUrl != null) updates['bannerImage'] = bannerImageUrl;

    if (updates.isEmpty) {
      debugPrint(
        'RealtimeDatabaseService.updateUserImages: No updates to apply.',
      );
      return;
    }

    try {
      await userProfilesRef.child(uid).child('profile').update(updates);
      if (profileImageUrl != null) {
        await usersRef.child(uid).update({'profileImage': profileImageUrl});
      }
      debugPrint('RealtimeDatabaseService.updateUserImages saved: $updates');
    } catch (e) {
      debugPrint('RealtimeDatabaseService.updateUserImages failed: $e');
      rethrow;
    }
  }

  /// Get user images from /users/{uid}/profile
  static Future<Map<String, String?>> getUserImages(String uid) async {
    try {
      final snapshot = await userProfilesRef.child(uid).child('profile').get();
      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final profileImage = data['profileImage']?.toString();
        final bannerImage = data['bannerImage']?.toString();
        debugPrint(
          'RealtimeDatabaseService.getUserImages loaded: profileImage=$profileImage, bannerImage=$bannerImage',
        );
        return {'profileImage': profileImage, 'bannerImage': bannerImage};
      }
    } catch (e) {
      debugPrint('RealtimeDatabaseService.getUserImages failed: $e');
    }
    return {'profileImage': null, 'bannerImage': null};
  }

  // ============ Orders Methods ============
  static DatabaseReference get ordersRef => FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: databaseUrl,
  ).ref('orders');

  /// Get all orders (for admins)
  static Stream<List<Order>> ordersStream() {
    return ordersRef.onValue.map((event) {
      final snapshot = event.snapshot;
      final orders = <Order>[];
      if (!snapshot.exists) {
        debugPrint('RealtimeDatabaseService.ordersStream: no orders');
        return orders;
      }

      final value = snapshot.value;
      if (value is Map) {
        value.forEach((key, rawOrder) {
          if (rawOrder is Map) {
            orders.add(Order.fromMap(key.toString(), rawOrder));
          }
        });
      }

      // Sort by timestamp descending (latest first)
      orders.sort((a, b) {
        final aTs = a.timestamp ?? 0;
        final bTs = b.timestamp ?? 0;
        return bTs.compareTo(aTs);
      });

      return orders;
    });
  }

  /// Get all orders (for admins)
  static Stream<List<Order>> ordersStreamForAdmin() {
    debugPrint('RealtimeDatabaseService.ordersStreamForAdmin called');
    return ordersStream();
  }

  /// Get orders for a specific customer using a Realtime Database query.
  static Stream<List<Order>> ordersStreamForCustomer(String userId) {
    debugPrint(
      'RealtimeDatabaseService.ordersStreamForCustomer userId=$userId '
      'query=orderByChild("userId").equalTo("$userId")',
    );
    final customerQuery = ordersRef.orderByChild('userId').equalTo(userId);
    return customerQuery.onValue.map((event) {
      final snapshot = event.snapshot;
      final orders = <Order>[];
      if (!snapshot.exists) {
        debugPrint(
          'RealtimeDatabaseService.ordersStreamForCustomer: no orders for userId=$userId',
        );
        return orders;
      }

      final value = snapshot.value;
      if (value is Map) {
        debugPrint(
          'RealtimeDatabaseService.ordersStreamForCustomer: found ${value.length} orders for userId=$userId',
        );
        value.forEach((key, rawOrder) {
          if (rawOrder is Map) {
            final order = Order.fromMap(key.toString(), rawOrder);
            debugPrint(
              'RealtimeDatabaseService.ordersStreamForCustomer: loaded order id=${order.id} userId=${order.userId}',
            );
            orders.add(order);
          }
        });
      }

      // Sort by timestamp descending (latest first)
      orders.sort((a, b) {
        final aTs = a.timestamp ?? 0;
        final bTs = b.timestamp ?? 0;
        return bTs.compareTo(aTs);
      });

      return orders;
    });
  }

  /// Save a new order and decrement product stock.
  /// Returns true if stock was updated successfully.
  static Future<bool> createOrder({
    required String productId,
    required String productName,
    required int quantity,
    required double totalPrice,
    String? status,
    String? customerName,
    String? phoneNumber,
    String? address,
    String? messageForSeller,
    String? voucherCode,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw StateError('No authenticated user available to create an order.');
    }

    debugPrint(
      'RealtimeDatabaseService.createOrder uid=${currentUser.uid} '
      'productId=$productId quantity=$quantity totalPrice=$totalPrice '
      'customerName=$customerName phoneNumber=$phoneNumber address=$address',
    );

    final orderData = {
      'userId': currentUser.uid,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'status': status ?? 'Pending',
      'reviewed': false,
      'messageForSeller': messageForSeller?.trim() ?? '',
      'voucherCode': voucherCode?.trim().isNotEmpty == true
          ? voucherCode!.trim()
          : 'none',
      'timestamp': ServerValue.timestamp,
      if (customerName != null && customerName.isNotEmpty)
        'customerName': customerName,
      if (phoneNumber != null && phoneNumber.isNotEmpty)
        'phoneNumber': phoneNumber,
      if (address != null && address.isNotEmpty) 'address': address,
    };

    await ordersRef.push().set(orderData);
    return await decrementProductStock(productId, quantity);
  }

  /// One-time migration helper to normalize order.userId values.
  ///
  /// This scans /orders and attempts to verify or correct each order.userId
  /// against existing user records in /customers or /users.
  static Future<void> migrateOrdersUserId() async {
    debugPrint('RealtimeDatabaseService.migrateOrdersUserId started');
    try {
      final ordersSnapshot = await ordersRef.get();
      if (!ordersSnapshot.exists || ordersSnapshot.value == null) {
        debugPrint(
          'RealtimeDatabaseService.migrateOrdersUserId: no orders found',
        );
        return;
      }

      final ordersMap = ordersSnapshot.value;
      if (ordersMap is! Map) {
        debugPrint(
          'RealtimeDatabaseService.migrateOrdersUserId: unexpected orders payload',
        );
        return;
      }

      for (final entry in ordersMap.entries) {
        final orderId = entry.key.toString();
        final rawOrder = entry.value;
        if (rawOrder is! Map) {
          debugPrint('Order $orderId has invalid payload, skipping');
          continue;
        }

        final orderMap = Map<String, dynamic>.from(rawOrder);
        final existingUserId = orderMap['userId']?.toString();
        final hasUserId = existingUserId != null && existingUserId.isNotEmpty;
        final existingProfile = hasUserId
            ? await getUserProfile(existingUserId)
            : null;

        if (existingProfile != null) {
          debugPrint('Order $orderId already has valid userId=$existingUserId');
          continue;
        }

        final emailCandidate =
            orderMap['customerEmail']?.toString() ??
            orderMap['email']?.toString();
        String? resolvedUid;
        if (emailCandidate != null && emailCandidate.isNotEmpty) {
          resolvedUid = await _findUserUidByEmail(emailCandidate);
          debugPrint(
            'Order $orderId attempted resolve by email=$emailCandidate resolvedUid=$resolvedUid',
          );
        }

        if (resolvedUid != null && resolvedUid.isNotEmpty) {
          debugPrint(
            'Order $orderId migrating userId from $existingUserId to $resolvedUid',
          );
          await ordersRef.child(orderId).update({'userId': resolvedUid});
          continue;
        }

        if (!hasUserId) {
          debugPrint('Order $orderId has no userId and could not be inferred');
          continue;
        }

        debugPrint(
          'Order $orderId has invalid userId=$existingUserId and no matching user record',
        );
      }
    } catch (e, st) {
      debugPrint('RealtimeDatabaseService.migrateOrdersUserId failed: $e\n$st');
    }
  }

  static Future<String?> _findUserUidByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      final customersSnapshot = await customersRef.get();
      final customerUid = _searchUidByEmail(customersSnapshot, normalizedEmail);
      if (customerUid != null) return customerUid;

      final usersSnapshot = await usersRef.get();
      return _searchUidByEmail(usersSnapshot, normalizedEmail);
    } catch (e) {
      debugPrint('RealtimeDatabaseService._findUserUidByEmail failed: $e');
      return null;
    }
  }

  static String? _searchUidByEmail(
    DataSnapshot snapshot,
    String normalizedEmail,
  ) {
    if (!snapshot.exists || snapshot.value == null) {
      return null;
    }

    final value = snapshot.value;
    if (value is! Map) return null;

    for (final entry in value.entries) {
      final uid = entry.key.toString();
      final record = entry.value;
      if (record is! Map) continue;

      final recordEmail = record['email']?.toString().trim().toLowerCase();
      if (recordEmail == normalizedEmail) {
        return uid;
      }
    }

    return null;
  }

  /// Update order status (admin only)
  static Future<void> updateOrderStatus(
    String orderId,
    String newStatus,
  ) async {
    await ordersRef.child(orderId).update({'status': newStatus});
  }
}

class Review {
  final String id;
  final String userId;
  final String productId;
  final String productName;
  final int rating;
  final String comment;
  final String customerEmail;
  final int? timestamp;

  Review({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.rating,
    required this.comment,
    required this.customerEmail,
    required this.timestamp,
  });

  factory Review.fromMap(String id, Map<dynamic, dynamic> map) {
    final rawTimestamp = map['timestamp'];
    int? parsedTimestamp;
    if (rawTimestamp is int) {
      parsedTimestamp = rawTimestamp;
    } else if (rawTimestamp is String) {
      parsedTimestamp = int.tryParse(rawTimestamp);
    }

    return Review(
      id: id,
      userId: map['userId']?.toString() ?? 'unknown',
      productId: map['productId']?.toString() ?? 'unknown',
      productName: map['productName']?.toString() ?? 'Unknown Product',
      rating: int.tryParse(map['rating']?.toString() ?? '') ?? 0,
      comment: map['comment']?.toString() ?? '',
      customerEmail: map['customerEmail']?.toString() ?? 'Anonymous',
      timestamp: parsedTimestamp,
    );
  }
}

class Order {
  final String id;
  final String userId;
  final String productId;
  final String productName;
  final int quantity;
  final double totalPrice;
  final String status;
  final bool reviewed;
  final String messageForSeller;
  final String voucherCode;
  final int? timestamp;

  Order({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.totalPrice,
    required this.status,
    required this.reviewed,
    required this.messageForSeller,
    required this.voucherCode,
    required this.timestamp,
  });

  factory Order.fromMap(String id, Map<dynamic, dynamic> map) {
    final rawTimestamp = map['timestamp'];
    int? parsedTimestamp;
    if (rawTimestamp is int) {
      parsedTimestamp = rawTimestamp;
    } else if (rawTimestamp is String) {
      parsedTimestamp = int.tryParse(rawTimestamp);
    }

    return Order(
      id: id,
      userId: map['userId']?.toString() ?? 'unknown',
      productId: map['productId']?.toString() ?? 'unknown',
      productName: map['productName']?.toString() ?? 'Unknown Product',
      quantity: int.tryParse(map['quantity']?.toString() ?? '') ?? 0,
      totalPrice: double.tryParse(map['totalPrice']?.toString() ?? '') ?? 0.0,
      status: map['status']?.toString() ?? 'Pending',
      reviewed: map['reviewed'] == true,
      messageForSeller: map['messageForSeller']?.toString() ?? '',
      voucherCode: map['voucherCode']?.toString() ?? 'none',
      timestamp: parsedTimestamp,
    );
  }
}
