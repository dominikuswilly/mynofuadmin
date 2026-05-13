import 'package:flutter/material.dart';
import 'theme.dart';
import 'models/category.dart';
import 'models/stock_item.dart';
import 'models/rider.dart';
import 'models/product.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'services/api_service.dart';

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  State<StockManagementScreen> createState() => StockManagementScreenState();
}

class StockManagementScreenState extends State<StockManagementScreen> {


  List<StockItem> _stocksList = [];
  bool _isLoadingStocks = true;

  // Filter state
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  Rider? _selectedFilterRider;
  String? _selectedStatus;
  List<Rider> _ridersListForFilter = [];

  // Expansion state
  final Set<String> _expandedDates = {};
  final Set<String> _expandedRiders = {}; // Format: "date|riderName"

  @override
  void initState() {
    super.initState();
    _fetchRidersForFilter();
    _fetchStocks();
  }

  Future<void> _fetchRidersForFilter() async {
    try {
      final response = await ApiService.get('/private/admin/rider');
      if (response.statusCode == 200) {
        final List<dynamic> ridersJson = jsonDecode(response.body);
        setState(() {
          _ridersListForFilter = ridersJson.map((json) => Rider.fromJson(json)).toList();
          if (_ridersListForFilter.isNotEmpty) {
            _selectedFilterRider = _ridersListForFilter.first;
            _fetchStocks();
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching riders for filter: $e');
    }
  }

  Future<void> _fetchStocks() async {
    setState(() {
      _isLoadingStocks = true;
    });

    try {
      String startDateStr = _startDate.toIso8601String().split('T')[0];
      String endDateStr = _endDate.toIso8601String().split('T')[0];
      
      String url = '/private/admin/transaction/stock?date_start=$startDateStr&date_end=$endDateStr';
      if (_selectedFilterRider != null) {
        url += '&rider_id=${_selectedFilterRider!.id}';
      }
      if (_selectedStatus != null && _selectedStatus != 'All') {
        url += '&status=${_selectedStatus!.toUpperCase()}';
      }

      final response = await ApiService.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          final dynamic rawData = data['data'];
          List<StockItem> allStocks = [];
          
          if (rawData is List) {
            for (var riderData in rawData) {
              if (riderData is Map<String, dynamic> && riderData['stock_list'] != null) {
                final String riderName = riderData['rider_name']?.toString() ?? 'Unknown Rider';
                final dynamic stockList = riderData['stock_list'];
                if (stockList is List) {
                  for (var dateLog in stockList) {
                    if (dateLog is Map<String, dynamic> && dateLog['item_list'] is List) {
                      final String logDate = dateLog['created_at']?.toString() ?? '';
                      final List<dynamic> itemList = dateLog['item_list'];
                      for (var itemJson in itemList) {
                        try {
                          if (itemJson is Map<String, dynamic>) {
                            allStocks.add(StockItem.fromJson(itemJson, createdAt: logDate, riderName: riderName));
                          }
                        } catch (e) {
                          debugPrint('Error parsing stock item: $e');
                        }
                      }
                    }
                  }
                }
              } else if (riderData is Map<String, dynamic> && riderData.containsKey('product_id')) {
                try {
                  allStocks.add(StockItem.fromJson(riderData));
                } catch (e) {
                  debugPrint('Error parsing flat stock item: $e');
                }
              }
            }
          }

          setState(() {
            _stocksList = allStocks;
            _isLoadingStocks = false;
          });
        } else {
          setState(() {
            _stocksList = [];
            _isLoadingStocks = false;
          });
        }
      } else {
        debugPrint('Failed to fetch stocks: ${response.statusCode} - ${response.body}');
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
    // Group stocks by date
    Map<String, List<StockItem>> groupedStocks = {};
    for (var item in _stocksList) {
      String date = item.createdAt.isEmpty ? 'Tanpa Tanggal' : item.createdAt;
      groupedStocks.putIfAbsent(date, () => []).add(item);
    }

    List<String> sortedDates = groupedStocks.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      children: [
        _buildInventoryFilters(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await _fetchStocks();
            },
            child: _isLoadingStocks
                ? const Center(child: CircularProgressIndicator())
                : _stocksList.isEmpty
                    ? const Center(child: Text('Tidak ada data stok'))
                    : CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          for (var date in sortedDates) ...[
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                              sliver: SliverToBoxAdapter(
                                child: InkWell(
                                  onTap: () => setState(() {
                                    if (_expandedDates.contains(date)) {
                                      _expandedDates.remove(date);
                                    } else {
                                      _expandedDates.add(date);
                                    }
                                  }),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppColors.black,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.primary),
                                        const SizedBox(width: 16),
                                        Text(
                                          date,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${groupedStocks[date]!.length} Item',
                                            style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          _expandedDates.contains(date) ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                          color: AppColors.primary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (_expandedDates.contains(date))
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                sliver: SliverGrid(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    mainAxisExtent: 200, // Fixed height for cards in grid
                                  ),
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final item = groupedStocks[date]![index];
                                      return _buildStockCard(item, isGrid: true);
                                    },
                                    childCount: groupedStocks[date]!.length,
                                  ),
                                ),
                              ),
                          ],
                          const SliverToBoxAdapter(child: SizedBox(height: 32)),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryFilters() {
    String startDateStr = _startDate.toIso8601String().split('T')[0];
    String endDateStr = _endDate.toIso8601String().split('T')[0];

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SizedBox(
              width: 160,
              child: _buildFilterBox(
                label: 'Rider',
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Rider>(
                    isExpanded: true,
                    value: _selectedFilterRider,
                    hint: const Text('Pilih Rider', style: TextStyle(fontSize: 13)),
                    items: _ridersListForFilter.map((rider) => DropdownMenuItem<Rider>(
                      value: rider,
                      child: Text(rider.name, style: const TextStyle(fontSize: 13)),
                    )).toList(),
                    onChanged: (value) {
                      setState(() => _selectedFilterRider = value);
                      _fetchStocks();
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 110,
              child: _buildFilterBox(
                label: 'Dari',
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _startDate = picked);
                    _fetchStocks();
                  }
                },
                child: Text(startDateStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.black)),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 110,
              child: _buildFilterBox(
                label: 'Sampai',
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _endDate = picked);
                    _fetchStocks();
                  }
                },
                child: Text(endDateStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.black)),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 130,
              child: _buildFilterBox(
                label: 'Status',
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedStatus ?? 'All',
                    hint: const Text('Semua Status', style: TextStyle(fontSize: 13)),
                    items: ['All', 'Accepted', 'Rejected', 'Waiting'].map((status) => DropdownMenuItem<String>(
                      value: status,
                      child: Text(status, style: const TextStyle(fontSize: 13)),
                    )).toList(),
                    onChanged: (value) {
                      setState(() => _selectedStatus = value);
                      _fetchStocks();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBox({required String label, required Widget child, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.grey.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: Colors.black.withOpacity(0.4), fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            child,
          ],
        ),
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
        ],
      ),
    );
  }



  Widget _buildStockCard(StockItem item, {bool isGrid = false}) {
    double percentage = item.qtyBase > 0 ? (item.qtyCurrent / item.qtyBase).clamp(0.0, 1.0) : 0.0;
    Color progressColor = percentage < 0.2 ? Colors.red : (percentage < 0.5 ? Colors.orange : Colors.green);

    return Container(
      margin: EdgeInsets.only(bottom: isGrid ? 0 : 16),
      padding: EdgeInsets.all(isGrid ? 12 : 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isGrid ? 16 : 24),
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
          Text(
            item.productName,
            maxLines: isGrid ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isGrid ? 13 : 16,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.productCategory,
            style: TextStyle(
              fontSize: isGrid ? 10 : 12,
              color: AppColors.black.withOpacity(0.4),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Stok',
                style: TextStyle(
                  fontSize: isGrid ? 10 : 12,
                  color: AppColors.black.withOpacity(0.6),
                ),
              ),
              Text(
                '${item.qtyCurrent}/${item.qtyBase}',
                style: TextStyle(
                  fontSize: isGrid ? 11 : 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: AppColors.grey.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: isGrid ? 6 : 8,
            ),
          ),
          if (item.status.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildStatusBadge(item.status),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label = status;
    
    if (status.toUpperCase().contains('WAITING')) {
      color = Colors.orange;
      label = 'Pending';
    } else if (status.toUpperCase().contains('REJECTED')) {
      color = Colors.red;
      label = 'Ditolak';
    } else if (status.toUpperCase().contains('CONFIRMED')) {
      color = Colors.green;
      label = 'Dikonfirmasi';
    } else {
      color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
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
      final riderResponse = await ApiService.get('/private/admin/rider/init-status');
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
        ),
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
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _riders.length,
      itemBuilder: (context, index) {
        final rider = _riders[index];
        final isSelected = _selectedRider?.id == rider.id;
        final canSelect = rider.canInit;

        return GestureDetector(
          onTap: canSelect ? () => setState(() => _selectedRider = rider) : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.primary.withOpacity(0.1) 
                  : canSelect 
                      ? AppColors.grey.withOpacity(0.5)
                      : AppColors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent, 
                width: 2,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: canSelect ? AppColors.primary : Colors.grey,
                  child: Text(
                    rider.name[0], 
                    style: TextStyle(
                      color: canSelect ? AppColors.black : Colors.white, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rider.name, 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 16,
                          color: canSelect ? Colors.black : Colors.black.withOpacity(0.3),
                        ),
                      ),
                      Text(
                        '@${rider.username}', 
                        style: TextStyle(
                          fontSize: 12, 
                          color: Colors.black.withOpacity(canSelect ? 0.5 : 0.2),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!canSelect)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Sudah Inisialisasi',
                      style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
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
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        final controller = _controllers[product.id]!;

        String getEmoji() {
          switch (product.category.toUpperCase()) {
            case 'KOPI': return '☕';
            case 'COKELAT': return '🥛';
            case 'TEH': return '🍵';
            case 'SNACK': return '🥐';
            default: return '📦';
          }
        }

        void updateQty(int delta) {
          int current = int.tryParse(controller.text) ?? 0;
          int next = current + delta;
          if (next < 0) next = 0;
          if (next > 999) next = 999;
          controller.text = next.toString();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.grey),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.grey.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(getEmoji(), style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      product.category,
                      style: TextStyle(fontSize: 11, color: Colors.black.withOpacity(0.4), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _QtyButton(
                      icon: Icons.remove_rounded,
                      onPressed: () => updateQty(-1),
                    ),
                    SizedBox(
                      width: 40,
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            int? val = int.tryParse(value);
                            if (val != null && val > 999) {
                              controller.text = '999';
                              controller.selection = TextSelection.fromPosition(const TextPosition(offset: 3));
                            } else if (value.length > 1 && value.startsWith('0')) {
                              controller.text = value.replaceFirst(RegExp(r'^0+'), '');
                              controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
                            }
                          }
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    _QtyButton(
                      icon: Icons.add_rounded,
                      onPressed: () => updateQty(1),
                    ),
                  ],
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

    items.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

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
              if (_selectedRider != null)
                Text(
                  '@${_selectedRider!.username}',
                  style: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 14, fontWeight: FontWeight.w500),
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

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _QtyButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      icon: Icon(icon, size: 18, color: AppColors.black),
      onPressed: onPressed,
    );
  }
}
