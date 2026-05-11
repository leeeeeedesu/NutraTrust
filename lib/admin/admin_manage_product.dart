import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/cloudinary_service.dart';
import '../product.dart';
import '../services/realtime_database_service.dart';
import 'admin_base_page.dart';
import 'admin_dashboard.dart';
import 'admin_delivery.dart';
import 'admin_inventory.dart';
import 'admin_reviews.dart';
import 'admin_user_lists.dart';

class AdminManageProductPage extends StatefulWidget {
  const AdminManageProductPage({super.key});

  @override
  State<AdminManageProductPage> createState() => _AdminManageProductPageState();
}

class _AdminManageProductPageState extends State<AdminManageProductPage> {
  final CloudinaryService _cloudinaryService = CloudinaryService(
    uploadPreset: 'e-commerce',
  );

  void _showProductForm({Product? initialProduct}) {
    final nameController = TextEditingController(
      text: initialProduct?.name ?? '',
    );
    final flavorsController = TextEditingController(
      text: initialProduct?.flavors.join(', ') ?? '',
    );
    final stockController = TextEditingController(
      text: initialProduct?.stock.toString() ?? '',
    );
    final priceController = TextEditingController(
      text: initialProduct?.price.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: initialProduct?.description ?? '',
    );
    final imageUrlController = TextEditingController(
      text: initialProduct?.image ?? '',
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        initialProduct == null ? 'Add Product' : 'Edit Product',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInputField('Product Name', nameController),
                      const SizedBox(height: 12),
                      _buildInputField(
                        'Flavors (comma separated)',
                        flavorsController,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        'Number of Stocks',
                        stockController,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        'Set Price',
                        priceController,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        'Product Description',
                        descriptionController,
                        minLines: 4,
                        maxLines: 6,
                      ),
                      const SizedBox(height: 12),
                      _buildInputField('Product Image URL', imageUrlController),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter a Cloudinary secure image URL or upload a local image to Cloudinary.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E8B3A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: () async {
                                File? pickedFile;
                                setState(() {});
                                final pickedImage = await ImagePicker()
                                    .pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 80,
                                    );
                                if (pickedImage == null) return;

                                setState(() {
                                  pickedFile = File(pickedImage.path);
                                });

                                try {
                                  final secureUrl = await _cloudinaryService
                                      .uploadImage(
                                        pickedFile?.path != null
                                            ? File(pickedFile!.path)
                                            : File(''),
                                      );
                                  if (!mounted) return;
                                  imageUrlController.text = secureUrl;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Image uploaded to Cloudinary.',
                                      ),
                                    ),
                                  );
                                } catch (error) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Cloudinary upload failed: $error',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                'Upload Local Image to Cloudinary',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text('CANCEL'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E8B3A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: () async {
                                final name = nameController.text.trim();
                                final flavors = flavorsController.text
                                    .split(',')
                                    .map((flavor) => flavor.trim())
                                    .where((flavor) => flavor.isNotEmpty)
                                    .toList();
                                final stock =
                                    int.tryParse(stockController.text.trim()) ??
                                    0;
                                final price =
                                    int.tryParse(priceController.text.trim()) ??
                                    0;
                                final description = descriptionController.text
                                    .trim();
                                final imageUrl = imageUrlController.text.trim();

                                if (name.isEmpty || description.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Product name and description are required.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final productData = {
                                  'name': name,
                                  'description': description,
                                  'stock': stock,
                                  'price': price,
                                  'flavors': flavors,
                                  'imageUrl': imageUrl,
                                };

                                try {
                                  if (initialProduct == null) {
                                    await RealtimeDatabaseService.addProduct(
                                      productData,
                                    );
                                  } else {
                                    await RealtimeDatabaseService.updateProduct(
                                      initialProduct.id,
                                      productData,
                                    );
                                  }
                                  if (mounted) Navigator.pop(context);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error saving product: $e'),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                initialProduct == null
                                    ? 'Add Product'
                                    : 'Save Changes',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showDeleteProductSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Delete Product',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 360,
                  child: StreamBuilder<List<Product>>(
                    stream: RealtimeDatabaseService.productsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading products.',
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        );
                      }
                      final products = snapshot.data ?? [];
                      if (products.isEmpty) {
                        return const Center(
                          child: Text('No products available to delete.'),
                        );
                      }
                      return ListView.separated(
                        itemCount: products.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return ListTile(
                            title: Text(product.name),
                            subtitle: Text(
                              'Stock ${product.stock} • ₱${product.price}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Delete product'),
                                      content: Text('Delete ${product.name}?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                if (confirmed == true) {
                                  await RealtimeDatabaseService.deleteProduct(
                                    product.id,
                                  );
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${product.name} deleted.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditProductSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Edit Product',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 360,
                  child: StreamBuilder<List<Product>>(
                    stream: RealtimeDatabaseService.productsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading products.',
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        );
                      }
                      final products = snapshot.data ?? [];
                      if (products.isEmpty) {
                        return const Center(
                          child: Text('No products available to edit.'),
                        );
                      }
                      return ListView.separated(
                        itemCount: products.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return ListTile(
                            title: Text(product.name),
                            subtitle: Text(
                              '₱${product.price} • Stock ${product.stock}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Color(0xFF1E8B3A),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                _showProductForm(initialProduct: product);
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    int minLines = 1,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF1E8B3A),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7F7F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminBasePage(
      activePage: AdminPage.manageProduct,
      onDashboardTap: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
          (route) => route.isFirst,
        );
      },
      onManageProductTap: () {},
      onUserListsTap: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminUserListsPage()),
          (route) => route.isFirst,
        );
      },
      onReviewsTap: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminReviewsPage()),
          (route) => route.isFirst,
        );
      },
      onInventoryTap: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminInventoryPage()),
          (route) => route.isFirst,
        );
      },
      onDeliveryTap: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminDeliveryPage()),
          (route) => route.isFirst,
        );
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ManageProductsLabel(),
          const SizedBox(height: 14),
          _ActionButtonsRow(
            onAdd: () => _showProductForm(),
            onDelete: _showDeleteProductSheet,
            onEdit: _showEditProductSheet,
          ),
          const SizedBox(height: 18),
          StreamBuilder<List<Product>>(
            stream: RealtimeDatabaseService.productsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 140,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'Unable to load product list.',
                      style: TextStyle(color: Colors.red[700], fontSize: 14),
                    ),
                  ),
                );
              }

              final products = snapshot.data ?? [];
              if (products.isEmpty) {
                return SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'No products found in the database.',
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ProductCard(
                    title: product.name,
                    subtitle: 'Stock: ${product.stock}',
                    price: '₱${product.price}',
                    description: product.description,
                    imageUrl: product.image,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ManageProductsLabel extends StatelessWidget {
  const _ManageProductsLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: const Center(
        child: Text(
          'Manage Products',
          style: TextStyle(
            color: Color(0xFF028B22),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ActionButtonsRow extends StatelessWidget {
  const _ActionButtonsRow({
    required this.onAdd,
    required this.onDelete,
    required this.onEdit,
  });

  final VoidCallback onAdd;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(label: 'Add Product', onTap: onAdd),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(label: 'Delete Product', onTap: onDelete),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(label: 'Edit Product', onTap: onEdit),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF028B22),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
