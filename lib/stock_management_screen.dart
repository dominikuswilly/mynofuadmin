import 'package:flutter/material.dart';
import 'theme.dart';
import 'models/category.dart';
import 'models/stock_item.dart';
import 'models/rider.dart';
import 'models/product.dart';
import 'dart:convert';
import 'services/api_service.dart';

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  State<StockManagementScreen> createState() => StockManagementScreenState();
}

class StockManagementScreenState extends State<StockManagementScreen> {
  List<Category> _categories = [];
  bool _isLoadingCategories = true;
  String _selectedCategoryId = 'all';

  List<StockItem> _stocksList = [];
  bool _isLoadingStocks = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchStocks();
  }

  Future<void> _fetchStocks() async {
    setState(() {
      _isLoadingStocks = true;
    });

    try {
      // For now, using product endpoint as fallback if stock is not ready,
      // or using a mock if it fails.
      final response = await ApiService.get('/private/admin/product');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> productsJson = data['data'];
          setState(() {
            // Mapping products to stock items for demonstration
            _stocksList = productsJson.map((json) {
              return StockItem(
                productId: json['id'] as String,
                productName: json['name'] as String,
                qtyBase: 50, // Mock base
                qtyCurrent: (json['id'].hashCode % 50), // Mock current
              );
            }).toList();
            _isLoadingStocks = false;
          });
        }
      } else {
        setState(() {
          _isLoadingStocks = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching stocks: $e');
      setState(() {
        _isLoadingStocks = false;
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
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: TabBarView(
              children: [
                _buildInventoryTab(),
                _buildRequestsTab(),
                _buildDamageTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _fetchCategories();
        await _fetchStocks();
      },
      child: _isLoadingStocks
          ? const Center(child: CircularProgressIndicator())
          : _stocksList.isEmpty
              ? const Center(child: Text('Tidak ada data stok'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                  itemCount: _stocksList.length,
                  itemBuilder: (context, index) {
                    final item = _stocksList[index];
                    return _buildStockCard(item);
                  },
                ),
    );
  }

  Widget _buildRequestsTab() {
    // Mock data for requests
    final requests = [
      {'rider': 'Budi', 'product': 'Kopi Gula Aren', 'qty': 20, 'status': 'Pending', 'date': '2026-05-06 09:30'},
      {'rider': 'Siti', 'product': 'Cokelat Klasik', 'qty': 15, 'status': 'Disetujui', 'date': '2026-05-06 08:45'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    req['rider'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (req['status'] == 'Pending' ? Colors.orange : Colors.green).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      req['status'] as String,
                      style: TextStyle(
                        color: req['status'] == 'Pending' ? Colors.orange : Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Permintaan: ${req['product']} (${req['qty']} unit)',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    req['date'] as String,
                    style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.4)),
                  ),
                  if (req['status'] == 'Pending')
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: const Text('Tolak', style: TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.black,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Setujui'),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDamageTab() {
    // Mock data for damage reports
    final reports = [
      {'rider': 'Kevin', 'product': 'Kopi Susu', 'qty': 2, 'note': 'Bocor saat pengiriman', 'date': '2026-05-06 10:15'},
      {'rider': 'Cindy', 'product': 'Snack Roti', 'qty': 1, 'note': 'Kadaluarsa', 'date': '2026-05-05 16:20'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    report['rider'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    report['date'] as String,
                    style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.4)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black, fontSize: 14),
                  children: [
                    const TextSpan(text: 'Produk Rusak: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: '${report['product']} (${report['qty']} unit)'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Catatan: ${report['note']}',
                style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.6), fontStyle: FontStyle.italic),
              ),
            ],
          ),
        );
      },
    );
  }

  void showInitiateStockModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _InitiateStockModal(
        onComplete: () {
          _fetchStocks();
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 0),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TabBar(
            labelColor: AppColors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            indicatorWeight: 4,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(text: 'Stok'),
              Tab(text: 'Permintaan'),
              Tab(text: 'Kerusakan'),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('SEMUA', 'all'),
                  if (_isLoadingCategories)
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    ..._categories.map((category) => _buildCategoryChip(category.name.toUpperCase(), category.id)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
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
          setState(() {
            _selectedCategoryId = id;
          });
          // In a real app, we'd filter stocks by category here
        },
        backgroundColor: AppColors.grey,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          fontSize: 12,
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

  Widget _buildStockCard(StockItem item) {
    double percentage = item.qtyCurrent / item.qtyBase;
    Color progressColor = percentage < 0.2 ? Colors.red : (percentage < 0.5 ? Colors.orange : Colors.green);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.black),
                onPressed: () {
                  // TODO: Implement Restock dialog
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Stok saat ini: ${item.qtyCurrent}',
                style: TextStyle(
                  color: AppColors.black.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(percentage * 100).toInt()}%',
                style: TextStyle(
                  color: progressColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: AppColors.grey,
              color: progressColor,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _InitiateStockModal extends StatefulWidget {
  final VoidCallback onComplete;

  const _InitiateStockModal({required this.onComplete});

  @override
  State<_InitiateStockModal> createState() => _InitiateStockModalState();
}

class _InitiateStockModalState extends State<_InitiateStockModal> {
  int _currentStep = 0;
  Rider? _selectedRider;
  List<Rider> _riders = [];
  List<Product> _products = [];
  bool _isLoading = true;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final riderResponse = await ApiService.get('/private/admin/rider');
      final productResponse = await ApiService.get('/private/admin/product');

      if (riderResponse.statusCode == 200 && productResponse.statusCode == 200) {
        final List<dynamic> ridersJson = jsonDecode(riderResponse.body);
        final Map<String, dynamic> productsData = jsonDecode(productResponse.body);
        
        setState(() {
          _riders = ridersJson.map((json) => Rider.fromJson(json)).toList();
          _products = (productsData['data'] as List).map((json) => Product.fromJson(json)).toList();
          
          for (var product in _products) {
            _controllers[product.id] = TextEditingController(text: '0');
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading initiation data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedRider == null) return;

    setState(() => _isLoading = true);
    try {
      final List<Map<String, dynamic>> items = [];
      for (var product in _products) {
        final qty = int.tryParse(_controllers[product.id]!.text) ?? 0;
        if (qty > 0) {
          items.add({
            'product_id': product.id,
            'quantity': qty,
          });
        }
      }

      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan masukkan setidaknya satu jumlah produk')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final response = await ApiService.post('/private/admin/transaction/stock/init', {
        'rider_id': _selectedRider!.id,
        'items': items,
      });

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          widget.onComplete();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inisialisasi stok pagi berhasil'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw 'Failed with status ${response.statusCode}';
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal inisialisasi: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _currentStep == 0
                    ? _buildRiderSelection()
                    : _currentStep == 1
                        ? _buildQuantityEntry()
                        : _buildReview(),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => setState(() => _currentStep--),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: Text(
              _currentStep == 0 
                  ? 'Pilih Rider' 
                  : _currentStep == 1 
                      ? 'Set Stok Awal' 
                      : 'Review Inisialisasi',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderSelection() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _riders.length,
      itemBuilder: (context, index) {
        final rider = _riders[index];
        final isSelected = _selectedRider?.id == rider.id;
        return GestureDetector(
          onTap: () => setState(() => _selectedRider = rider),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.grey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent, width: 2),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(rider.name[0], style: const TextStyle(color: AppColors.black, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Text(rider.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.primary),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuantityEntry() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(product.category, style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.5))),
                  ],
                ),
              ),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _controllers[product.id],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    fillColor: AppColors.white,
                    filled: true,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReview() {
    final List<Map<String, dynamic>> items = [];
    for (var product in _products) {
      final qty = int.tryParse(_controllers[product.id]!.text) ?? 0;
      if (qty > 0) {
        items.add({
          'name': product.name,
          'qty': qty,
        });
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary,
                child: Text(_selectedRider?.name[0] ?? '?', 
                  style: const TextStyle(color: AppColors.black, fontWeight: FontWeight.bold, fontSize: 24)),
              ),
              const SizedBox(height: 12),
              Text(
                _selectedRider?.name ?? '-',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                'Rider Penerima',
                style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text('Ringkasan Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        ...items.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grey),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${item['qty']} unit',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.black),
                ),
              ),
            ],
          ),
        )).toList(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading 
            ? null 
            : () {
                if (_currentStep == 0) {
                  if (_selectedRider != null) setState(() => _currentStep = 1);
                } else if (_currentStep == 1) {
                  // Validate at least one item has qty > 0
                  bool hasItems = false;
                  for (var controller in _controllers.values) {
                    if ((int.tryParse(controller.text) ?? 0) > 0) {
                      hasItems = true;
                      break;
                    }
                  }
                  if (hasItems) {
                    setState(() => _currentStep = 2);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Silakan masukkan setidaknya satu jumlah produk')),
                    );
                  }
                } else {
                  _submit();
                }
              },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.black,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            _currentStep == 0 
                ? 'Lanjutkan' 
                : _currentStep == 1 
                    ? 'Simpan Inisialisasi' 
                    : 'Konfirmasi & Simpan',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
