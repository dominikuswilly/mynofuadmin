import 'package:flutter/material.dart';
import 'theme.dart';
import 'product_management_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ProductManagementScreenState> _productKey = GlobalKey<ProductManagementScreenState>();

  final List<String> _titles = [
    'Beranda',
    'Manajemen Produk',
    'Manajemen Rider',
    'Inventaris Stok',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey,
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('access_token');
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardTab(),
          ProductManagementScreen(key: _productKey),
          _buildPlaceholder('Rider'),
          _buildPlaceholder('Stock'),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.black,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              activeIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.coffee_rounded),
              activeIcon: Icon(Icons.coffee_rounded, color: AppColors.primary),
              label: 'Produk',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.delivery_dining_rounded),
              activeIcon: Icon(Icons.delivery_dining_rounded, color: AppColors.primary),
              label: 'Rider',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_rounded),
              activeIcon: Icon(Icons.inventory_2_rounded, color: AppColors.primary),
              label: 'Stock',
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                _productKey.currentState?.toggleAddSection();
                setState(() {}); // Refresh to update FAB icon
              },
              backgroundColor: AppColors.black,
              child: Icon(
                (_productKey.currentState?.isAddingProduct ?? false) ? Icons.close : Icons.add,
                color: AppColors.primary,
              ),
            )
          : null,
    );
  }

  Widget _buildPlaceholder(String name) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            name == 'Produk'
                ? Icons.coffee_rounded
                : name == 'Rider'
                    ? Icons.delivery_dining_rounded
                    : Icons.inventory_2_rounded,
            size: 64,
            color: AppColors.black.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'Manajemen $name segera hadir',
            style: TextStyle(
              color: AppColors.black.withOpacity(0.4),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selamat Datang, Admin',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kelola operasional kedai kopi Anda di sini.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.black.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),
          _buildStatsGrid(),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transaksi Terbaru',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecentTransactions(),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.0, // Changed from 1.1 to 1.0 to ensure no overflow
      children: [
        _buildStatCard('Total Penjualan', 'Rp 3.240.000', Icons.monetization_on, Colors.green),
        _buildStatCard('Pesanan', '42', Icons.shopping_basket, Colors.blue),
        _buildStatCard('Produk', '12', Icons.coffee, Colors.orange),
        _buildStatCard('Pelanggan', '85', Icons.people, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16), // Reduced from 20 for more space
      decoration: BoxDecoration(
        color: Colors.white,
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withOpacity(0.4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey.withOpacity(0.1),
          indent: 20,
          endIndent: 20,
        ),
        itemBuilder: (context, index) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.coffee, color: AppColors.black, size: 20),
            ),
            title: Text(
              'Order #${1024 - index}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Text(
              '2 mins ago • Espresso x2',
              style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 13),
            ),
            trailing: const Text(
              'Rp 12.000',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          );
        },
      ),
    );
  }
}
