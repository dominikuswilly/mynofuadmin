import 'package:flutter/material.dart';
import 'theme.dart';
import 'models/rider.dart';
import 'dart:convert';
import 'services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final TextEditingController _newUsernameController = TextEditingController();
  final TextEditingController _newPhoneController = TextEditingController();
  bool _showAddSection = false;
  bool _isSavingRider = false;

  // Validation state
  String? _nameError;
  String? _usernameError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _fetchRiders();
  }

  @override
  void dispose() {
    _newNameController.dispose();
    _newUsernameController.dispose();
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
    final username = _newUsernameController.text.trim();
    final phone = _newPhoneController.text.trim();

    setState(() {
      _nameError = name.isEmpty ? 'Nama lengkap tidak boleh kosong' : null;
      _usernameError = username.isEmpty ? 'Username tidak boleh kosong' : null;
      _phoneError = phone.isEmpty ? 'Nomor WhatsApp tidak boleh kosong' : null;
    });

    if (_nameError != null || _usernameError != null || _phoneError != null) {
      return;
    }

    setState(() {
      _isSavingRider = true;
    });

    try {
      // Format phone: remove leading '0' if user typed it, as prefix +62 is already handled
      String formattedPhone = phone;
      if (formattedPhone.startsWith('0')) {
        formattedPhone = formattedPhone.substring(1);
      }
      
      final response = await ApiService.post('/private/admin/rider', {
        'name': name,
        'username': username,
        'whatsapp_number': '+62$formattedPhone',
      });

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rider berhasil ditambahkan'),
              backgroundColor: Colors.green,
            ),
          );
          
          _newNameController.clear();
          _newUsernameController.clear();
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
          child: RefreshIndicator(
            onRefresh: _fetchRiders,
            color: AppColors.primary,
            backgroundColor: AppColors.white,
            child: _isLoadingRiders && _ridersList.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                      onRefresh: _fetchRiders,
                    );
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
            decoration: InputDecoration(
              labelText: 'Nama Lengkap',
              hintText: 'Masukkan nama rider',
              errorText: _nameError,
            ),
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newUsernameController,
            decoration: InputDecoration(
              labelText: 'Username',
              hintText: 'Masukkan username rider',
              errorText: _usernameError,
            ),
            onChanged: (_) {
              if (_usernameError != null) setState(() => _usernameError = null);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Nomor WhatsApp',
              hintText: '08...',
              prefixText: '+62 ',
              errorText: _phoneError,
            ),
            onChanged: (_) {
              if (_phoneError != null) setState(() => _phoneError = null);
            },
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

class RiderCard extends StatefulWidget {
  final Rider rider;
  final VoidCallback onRefresh;

  const RiderCard({
    super.key,
    required this.rider,
    required this.onRefresh,
  });

  @override
  State<RiderCard> createState() => _RiderCardState();
}

class _RiderCardState extends State<RiderCard> {
  bool _isToggled = false;
  late bool _tempActive;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _tempActive = widget.rider.isActive;
  }

  @override
  void didUpdateWidget(RiderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rider.isActive != widget.rider.isActive && !_isToggled) {
      _tempActive = widget.rider.isActive;
    }
  }

  Future<void> _updateStatus() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final response = await ApiService.patch(
        '/private/admin/rider/${widget.rider.id}',
        {
          'status': _tempActive ? 'active' : 'inactive',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          setState(() {
            _isToggled = false;
            _isUpdating = false;
          });
          widget.onRefresh();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Status berhasil diperbarui')),
          );
        }
      } else {
        throw 'Failed to update status';
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui status: $e')),
        );
      }
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final url = Uri.parse("https://wa.me/$cleanPhone");
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
    }
  }

  Future<void> _launchPhone(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final url = Uri.parse("tel:$cleanPhone");
    try {
      if (!await launchUrl(url)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('Error launching Phone: $e');
    }
  }

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
                    widget.rider.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${widget.rider.username}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.black.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _ActionButton(
                        icon: Icons.message_rounded,
                        label: 'WA',
                        color: const Color(0xFF25D366),
                        onTap: () => _launchWhatsApp(widget.rider.whatsappNumber),
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.phone_forwarded_rounded,
                        label: 'Panggil',
                        color: const Color(0xFF34B7F1),
                        onTap: () => _launchPhone(widget.rider.whatsappNumber),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_isToggled)
              Column(
                children: [
                  IconButton(
                    icon: _isUpdating 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: _isUpdating ? null : _updateStatus,
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: _isUpdating ? null : () {
                      setState(() {
                        _isToggled = false;
                        _tempActive = widget.rider.isActive;
                      });
                    },
                  ),
                ],
              )
            else
              Column(
                children: [
                  Switch(
                    value: _tempActive,
                    onChanged: (val) {
                      setState(() {
                        _isToggled = true;
                        _tempActive = val;
                      });
                    },
                    activeColor: Colors.green,
                  ),
                  Text(
                    _tempActive ? 'Aktif' : 'Non-aktif',
                    style: TextStyle(
                      fontSize: 10,
                      color: _tempActive ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
