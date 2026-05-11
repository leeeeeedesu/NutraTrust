class Product {
  final String id;
  final String name;
  final String description;
  final int price;
  final int stock;
  final String? category;
  final String? image;
  final String? brand;
  final List<String> flavors;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    this.category,
    this.image,
    this.brand,
    this.flavors = const [],
  });

  factory Product.fromMap(String id, Map<dynamic, dynamic>? map) {
    final data = map ?? <dynamic, dynamic>{};

    // Parse flavors from database
    List<String> flavors = [];
    if (data['flavors'] is Map) {
      final flavorsMap = data['flavors'] as Map<dynamic, dynamic>;
      flavors = flavorsMap.values.map((flavor) => flavor.toString()).toList();
    } else if (data['flavors'] is List) {
      flavors = (data['flavors'] as List<dynamic>)
          .map((flavor) => flavor.toString())
          .toList();
    }

    // Safely parse name with default value
    final name = (data['name']?.toString() ?? '').trim().isEmpty
        ? 'Uncategorized'
        : data['name'].toString();

    // Safely parse description
    final description = (data['description']?.toString() ?? '').trim();

    // Safely parse price - ensure it's a valid positive number
    final priceString = data['price']?.toString() ?? '';
    final price = int.tryParse(priceString) ?? 0;
    if (price < 0) {
      print('Warning: Invalid price for product $id: $priceString. Using 0.');
    }

    // Safely parse stock - ensure it's a valid non-negative number
    final stockString = data['stock']?.toString() ?? '';
    final stock = int.tryParse(stockString) ?? 0;
    if (stock < 0) {
      print('Warning: Invalid stock for product $id: $stockString. Using 0.');
    }

    // Safely parse category
    final category = (data['category']?.toString() ?? '').trim().isEmpty
        ? null
        : data['category'].toString();

    // Safely parse image URL
    final image = (data['imageUrl']?.toString() ?? '').trim().isEmpty
        ? null
        : data['imageUrl'].toString();

    // Safely parse brand
    final brand = (data['brand']?.toString() ?? '').trim().isEmpty
        ? null
        : data['brand'].toString();

    // Log parsed product data for debugging
    print(
      'Product.fromMap - ID: $id, Name: $name, Price: $price, Stock: $stock, Category: $category, Image: $image, Brand: $brand',
    );

    return Product(
      id: id,
      name: name,
      description: description,
      price: price,
      stock: stock,
      category: category,
      image: image,
      brand: brand,
      flavors: flavors,
    );
  }
}
