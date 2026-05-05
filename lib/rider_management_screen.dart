import 'package:flutter/material.dart';
import 'theme.dart';
import 'models/rider.dart';
import 'dart:convert';
import 'services/api_service.dart';

class RiderManagementScreen extends StatefulWidget {
  const RiderManagementScreen({super.key});

  @override
  State<RiderManagementScreen> createState() => RiderManagementScreenState();
}

class RiderManagementScreenState extends State<RiderManagementScreen> {
  List<Rider> _ridersList = [];
  bool _isLoadingRiders = true;

  // New rider form state
  final TextEditingController _newNameController = TextEditingController();
  final TextEditingController _newPhoneController = TextEditingController();
  bool _showAddSection = false;
  bool _isSavingRider = false;

  @override
  void initState() {
    super.initState();
    _fetchRiders();
  }

  @override
  void dispose() {
    _newNameController.dispose();
    _newPhoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchRiders() async {
    setState(() {
      _isLoadingRiders = true;
    });

    try {
      final response = await ApiService.get('/private/admin/rider');

      if (response.statusCode == 200) {
        final List<dynamic> ridersJson = jsonDecode(response.body);
        setState(() {
          _ridersList = ridersJson.map((json) => Rider.fromJson(json)).toList();
          _isLoadingRiders = false;
        });
      } else {
        setState(() {
          _isLoadingRiders = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching riders: $e');
      setState(() {
        _isLoadingRiders = false;
      });
    }
  }

  void toggleAddSection() {
    setState(() {
      _showAddSection = !_showAddSection;
    });
  }

  bool get isAddingRider => _showAddSection;

  Future<void> _addRider() async {
    final name = _newNameController.text.trim();
    final phone = _newPhoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan lengkapi semua data rider'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSavingRider = true;
    });

    try {
      final response = await ApiService.post('/private/admin/rider', {
        'name': name,
        'whatsapp_number': '+62$phone',
        'active': 1,
      });

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rider berhasil ditambahkan'),
              backgroundColor: Colors.green,
            ),
          );
          
          _newNameController.clear();
          _newPhoneController.clear();
          setState(() {
            _showAddSection = false;
            _isSavingRider = false;
          });
          
          _fetchRiders();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menambahkan rider (${response.statusCode})'),
              backgroundColor: Colors.redAccent,
            ),
          );
          setState(() {
            _isSavingRider = false;
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
          _isSavingRider = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _isLoadingRiders && _ridersList.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 100),
                  itemCount: _ridersList.length + (_showAddSection ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_showAddSection && index == 0) {
                      return _buildAddRiderSection();
                    }
                    
                    final riderIndex = _showAddSection ? index - 1 : index;
                    final rider = _ridersList[riderIndex];
                    
                    return RiderCard(
                      rider: rider,
                      onToggleStatus: (active) async {
                        // TODO: Implement API toggle status
                        setState(() {
                          // Simple local update for demo
                        });
                      },
                    );
                  },
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
          Text(
            'Total Rider: ${_ridersList.length}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddRiderSection() {
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
            'Tambah Rider Baru',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _newNameController,
            decoration: const InputDecoration(
              labelText: 'Nama Lengkap',
              hintText: 'Masukkan nama rider',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Nomor WhatsApp',
              hintText: '08...',
              prefixText: '+62 ',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSavingRider ? null : _addRider,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSavingRider
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Text(
                      'Simpan Rider',
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
}

class RiderCard extends StatelessWidget {
  final Rider rider;
  final Function(bool) onToggleStatus;

  const RiderCard({
    super.key,
    required this.rider,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
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
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.grey,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.person_rounded, size: 32, color: Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rider.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    rider.whatsappNumber,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.black.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: rider.isActive,
              onChanged: onToggleStatus,
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}
