import 'package:flutter/material.dart';
import 'theme.dart';
import 'models/category.dart';
import 'models/stock_item.dart';
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
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await _fetchCategories();
              await _fetchStocks();
            },
            child: _isLoadingStocks
                ? const Center(child: CircularProgressIndicator())
                : _stocksList.isEmpty
                    ? const Center(child: Text('Tidak ada data stok'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: _stocksList.length,
                        itemBuilder: (context, index) {
                          final item = _stocksList[index];
                          return _buildStockCard(item);
                        },
                      ),
          ),
        ),
      ],
    );
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
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
