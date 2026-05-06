import 'package:flutter/material.dart';
import 'theme.dart';
import 'models/category.dart';
import 'models/product.dart';
import 'dart:convert';
import 'services/api_service.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => ProductManagementScreenState();
}

class ProductManagementScreenState extends State<ProductManagementScreen> {
  List<Category> _categories = [];
  bool _isLoadingCategories = true;
  String _selectedCategoryId = 'all';

  List<Product> _productsList = [];
  bool _isLoadingProducts = true;

  // New product form state
  final TextEditingController _newNameController = TextEditingController();
  final TextEditingController _newPriceController = TextEditingController();
  String? _selectedNewCategory;
  bool _showAddSection = false;
  bool _isSavingProduct = false;


  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchProducts();
  }

  @override
  void dispose() {
    _newNameController.dispose();
    _newPriceController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      String endpoint = '/private/admin/product';
      if (_selectedCategoryId != 'all') {
        // Find the selected category name
        final selectedCategory = _categories.firstWhere((cat) => cat.id == _selectedCategoryId);
        endpoint += '?category=${selectedCategory.name}';
      }

      final response = await ApiService.get(endpoint);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> productsJson = data['data'];
          setState(() {
            _productsList = productsJson.map((json) => Product.fromJson(json)).toList();
            _isLoadingProducts = false;
          });
        }
      } else {
        setState(() {
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final response = await ApiService.get('/private/inventory/categories');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> categoriesJson = data['data'];
          setState(() {
            _categories = categoriesJson.map((json) => Category.fromJson(json)).toList();
            _isLoadingCategories = false;
          });
        }
      } else if (response.statusCode == 401) {
        // Handle case where even after refresh it's still 401 (e.g. refresh token also expired)
        debugPrint('Unauthorized even after refresh attempt');
        setState(() {
          _isLoadingCategories = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sesi telah berakhir, silakan login kembali')),
          );
          Navigator.of(context).pushReplacementNamed('/');
        }
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _isLoadingProducts
              ? const Center(child: CircularProgressIndicator())
              : (_productsList.isEmpty && !_showAddSection)
                  ? const Center(child: Text('Tidak ada produk'))
                  : ListView.builder(
                      padding: const EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 100),
                      itemCount: _productsList.length + (_showAddSection ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_showAddSection && index == 0) {
                          return _buildAddProductSection();
                        }
                        
                        final productIndex = _showAddSection ? index - 1 : index;
                        final product = _productsList[productIndex];
                        
                        return ProductCard(
                          product: product,
                          onSave: (name, price, active) async {
                            try {
                              final response = await ApiService.patch(
                                '/private/admin/product/${product.id}',
                                {
                                  'name': name,
                                  'amount_sell': price,
                                  'active': active,
                                },
                              );

                              if (response.statusCode == 200) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Produk berhasil diperbarui'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                                _fetchProducts(); // Refresh the list
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Gagal memperbarui produk (${response.statusCode})'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Terjadi kesalahan: $e'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // Add a public method to toggle add section if needed from parent
  void toggleAddSection() {
    setState(() {
      _showAddSection = !_showAddSection;
    });
  }

  bool get isAddingProduct => _showAddSection;

  Widget _buildAddProductSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tambah Produk Baru',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _newNameController,
            decoration: const InputDecoration(
              labelText: 'Nama Produk',
              hintText: 'Masukkan nama produk',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _selectedNewCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                  ),
                  items: _categories.map((Category category) {
                    return DropdownMenuItem<String>(
                      value: category.name,
                      child: Text(
                        category.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedNewCategory = newValue;
                    });
                  },
                  hint: const Text('Pilih'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _newPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga Jual',
                    hintText: '0',
                    prefixText: 'Rp ',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSavingProduct ? null : _addProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSavingProduct
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Text(
                      'Simpan Produk',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addProduct() async {
    final name = _newNameController.text.trim();
    final priceStr = _newPriceController.text.trim();
    final category = _selectedNewCategory;

    if (name.isEmpty || priceStr.isEmpty || category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan lengkapi semua data produk'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final price = int.tryParse(priceStr);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harga harus berupa angka'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSavingProduct = true;
    });

    try {
      final response = await ApiService.post('/private/admin/product', {
        'name': name,
        'category': category,
        'amount_sell': price,
      });

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Produk berhasil ditambahkan'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Clear form
          _newNameController.clear();
          _newPriceController.clear();
          setState(() {
            _selectedNewCategory = null;
            _showAddSection = false; // Optionally hide the section
            _isSavingProduct = false;
          });
          
          // Auto reload
          _fetchProducts();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menambahkan produk (${response.statusCode})'),
              backgroundColor: Colors.redAccent,
            ),
          );
          setState(() {
            _isSavingProduct = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() {
          _isSavingProduct = false;
        });
      }
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('SEMUA', 'all'),
                if (_isLoadingCategories)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  ..._categories.map((category) => _buildCategoryChip(category.name.toUpperCase(), category.id)),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCategoryChip(String label, String id) {
    final bool isSelected = _selectedCategoryId == id;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          if (_selectedCategoryId != id) {
            setState(() {
              _selectedCategoryId = id;
            });
            _fetchProducts();
          }
        },
        backgroundColor: AppColors.grey,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.black : AppColors.black.withOpacity(0.6),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide.none,
        ),
        showCheckmark: false,
      ),
    );
  }
}

class ProductCard extends StatefulWidget {
  final Product product;
  final Function(String name, int price, int active) onSave;


  const ProductCard({
    super.key,
    required this.product,
    required this.onSave,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.amountSell.toString());
    _isActive = widget.product.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String getEmoji() {
      switch (widget.product.category.toUpperCase()) {
        case 'KOPI':
          return '☕';
        case 'COKELAT':
          return '🥛';
        case 'TEH':
          return '🍵';
        case 'SNACK':
          return '🥐';
        default:
          return '📦';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.grey,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  getEmoji(),
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_isEditing)
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: Text(
                            widget.product.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Row(
                        children: [
                          if (!_isEditing)
                            _buildStatusIndicator(widget.product.isActive),
                          if (_isEditing)
                            Transform.scale(
                              scale: 0.7,
                              child: Switch(
                                value: _isActive,
                                onChanged: (val) {
                                  setState(() {
                                    _isActive = val;
                                  });
                                },
                                activeColor: Colors.green,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    widget.product.category,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.black.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_isEditing)
                        Expanded(
                          child: Row(
                            children: [
                              const Text('Rp ', style: TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(
                                child: TextField(
                                  controller: _priceController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          'Rp ${widget.product.amountSell}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          if (_isEditing) ...[
                            IconButton(
                              icon: const Icon(Icons.check_rounded, color: Colors.green, size: 22),
                              onPressed: () {
                                setState(() => _isEditing = false);
                                widget.onSave(
                                  _nameController.text,
                                  int.tryParse(_priceController.text) ?? widget.product.amountSell,
                                  _isActive ? 1 : 0,
                                );
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 22),
                              onPressed: () {
                                setState(() {
                                  _isEditing = false;
                                  _nameController.text = widget.product.name;
                                  _priceController.text = widget.product.amountSell.toString();
                                  _isActive = widget.product.isActive;
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ] else ...[
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => setState(() => _isEditing = true),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isActive ? 'Aktif' : 'Non-aktif',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}
