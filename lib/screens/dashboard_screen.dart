import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _dashboardData;
  final ScrollController _tableScrollCtrl = ScrollController();

  bool _isAddingCheckout = false;
  Map<String, dynamic>? _selectedVehicle;
  String _selectedDriverName = '';
  final List<Map<String, String>> _selectedPassengers = [];

  final TextEditingController _vehicleCtrl = TextEditingController();
  final TextEditingController _driverCtrl = TextEditingController();
  final TextEditingController _passengerCtrl = TextEditingController();
  final TextEditingController _destCtrl = TextEditingController();
  final TextEditingController _startKmCtrl = TextEditingController();
  final TextEditingController _checkoutTimeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  void dispose() {
    _tableScrollCtrl.dispose();
    _vehicleCtrl.dispose();
    _driverCtrl.dispose();
    _passengerCtrl.dispose();
    _destCtrl.dispose();
    _startKmCtrl.dispose();
    _checkoutTimeCtrl.dispose;
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${dt.year}-${twoDigits(dt.month)}-${twoDigits(dt.day)} ${twoDigits(dt.hour)}:${twoDigits(dt.minute)}:${twoDigits(dt.second)}";
  }

  Future<String?> _pickDateTime(BuildContext context, {String? initialTimeStr}) async {
    DateTime initialDate = DateTime.now();
    if (initialTimeStr != null && initialTimeStr.isNotEmpty) {
      try {
        initialDate = DateTime.parse(initialTimeStr);
      } catch (_) {}
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (pickedDate == null || !context.mounted) return null;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (pickedTime == null) return null;

    final finalDt = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
      0,
    );
    return _formatDateTime(finalDt);
  }

    

  void _refreshData() {
    setState(() {
      _dashboardData = ApiService.getDashboardSummary();
    });
  }

  void _resetInlineForm() {
    setState(() {
      _isAddingCheckout = false;
      _selectedVehicle = null;
      _selectedDriverName = '';
      _selectedPassengers.clear();
      _vehicleCtrl.clear();
      _driverCtrl.clear();
      _passengerCtrl.clear();
      _destCtrl.clear();
      _startKmCtrl.clear();
    });
  }

  Future<void> _submitInlineCheckout() async {
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kendaraan dari daftar saran terlebih dahulu!'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_driverCtrl.text.trim().isEmpty || _destCtrl.text.trim().isEmpty || _startKmCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver, Tujuan, dan KM Awal wajib diisi!'), backgroundColor: Colors.red),
      );
      return;
    }

    final startKm = int.tryParse(_startKmCtrl.text.trim());
    final currentKm = _selectedVehicle!['current_km'] as int;
    if (startKm == null || startKm < currentKm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('KM Awal tidak boleh kurang dari odometer saat ini ($currentKm KM)!'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_passengerCtrl.text.trim().isNotEmpty) {
      _selectedPassengers.add({
        'name': _passengerCtrl.text.trim(),
        'nik': '-',
      });
      _passengerCtrl.clear();
    }

    final payload = {
      'vehicle_id': _selectedVehicle!['id'],
      'driver_name': _selectedDriverName.isNotEmpty ? _selectedDriverName : _driverCtrl.text.trim(),
      'passengers': _selectedPassengers,
      'destination': _destCtrl.text.trim(),
      'start_km': startKm,
    };

    try {
      final success = await ApiService.checkoutVehicle(payload);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check-Out Berhasil! Kendaraan mulai beroperasi.'), backgroundColor: Colors.green),
        );
        _resetInlineForm();
        _refreshData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal melakukan Check-Out! Periksa kembali data.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showEditTimeDialog(String logId, String vehicleName, String currentCheckoutTime) async {
    final timeCtrl = TextEditingController(text: currentCheckoutTime);

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Waktu Keluar: $vehicleName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sesuaikan waktu jika kendaraan sudah berangkat lebih awal:', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 12),
              TextField(
                controller: timeCtrl,
                decoration: InputDecoration(
                  labelText: 'Waktu Keluar (YYYY-MM-DD HH:MM:SS)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_month, color: Colors.blue),
                    tooltip: 'Pilih dari Kalender & Jam',
                    onPressed: () async {
                      final picked = await _pickDateTime(context, initialTimeStr: timeCtrl.text);
                      if (picked != null) {
                        timeCtrl.text = picked;
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              onPressed: () async {
                if (timeCtrl.text.trim().isNotEmpty) {
                  final success = await ApiService.updateCheckoutTime(logId, timeCtrl.text.trim());
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Waktu keluar berhasil diperbarui!'), backgroundColor: Colors.green),
                    );
                    _refreshData();
                  }
                }
              },
              child: const Text('Simpan Waktu'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _verifyAdminPin(String targetRoute) async {
    final pinCtrl = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock, color: Colors.blue),
              SizedBox(width: 8),
              Text('Akses Khusus Admin'),
            ],
          ),
          content: TextField(
            controller: pinCtrl,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Masukkan PIN Admin',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                if (pinCtrl.text == '1234') {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, targetRoute).then((_) => _refreshData());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN Salah! Akses ditolak.'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Masuk'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCheckInDialog(String logId, String vehicleName, int startKm) async {
    final TextEditingController endKmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Check-In: $vehicleName'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('KM Awal Berangkat: $startKm KM', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: endKmCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Masukkan KM Akhir (Saat Ini)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Wajib diisi';
                    final km = int.tryParse(val);
                    if (km == null) return 'Harus berupa angka';
                    if (km <= startKm) return 'Harus lebih besar dari KM Awal ($startKm)';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final success = await ApiService.checkinVehicle(logId, int.parse(endKmCtrl.text));
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Check-In Berhasil!'), backgroundColor: Colors.green),
                    );
                    _refreshData();
                  }
                }
              },
              child: const Text('Selesaikan Trip'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCancelDialog(String logId, String vehicleName, String driverName) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('Batalkan Check-Out?'),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin membatalkan keberangkatan unit "$vehicleName" (Driver: $driverName)?\n\n'
            'Data perjalanan ini akan dihapus dan status mobil kembali menjadi Available.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tidak'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                final success = await ApiService.cancelCheckout(logId);
                if (!context.mounted) return;
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Check-Out $vehicleName dibatalkan!'), backgroundColor: Colors.orange[800]),
                  );
                  _refreshData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal membatalkan perjalanan!'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Ya, Batalkan & Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Vehicle Monitoring System', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          TextButton.icon(
            onPressed: () async{
              final currentUri = Uri.base;
              final targetUrl = '${currentUri.scheme}://${currentUri.authority}/#/tv';
              
              final uri = Uri.parse(targetUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, webOnlyWindowName: '_blank');
              }
            },
            icon: const Icon(Icons.tv, color: Colors.blue),
            label: const Text('TV Display', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),

          TextButton.icon(
            onPressed: () => _verifyAdminPin('/master'),
            icon: const Icon(Icons.storage),
            label: const Text('Kelola Data'),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/history'),
            icon: const Icon(Icons.history),
            label: const Text('Riwayat & Laporan'),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh Data',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final available = snapshot.data!['available'] as List;
          final inUse = snapshot.data!['in_use'] as List;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Available Car
                _buildSectionHeader('Unit Tersedia (Available)', Icons.check_circle, Colors.green, available.length),
                const SizedBox(height: 16),
                available.isEmpty
                    ? const Text('Tidak ada kendaraan yang tersedia saat ini.', style: TextStyle(color: Colors.grey))
                    : Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: available.map((v) => _buildAvailableCard(v)).toList(),
                      ),
                
                const SizedBox(height: 36),
                const Divider(),
                const SizedBox(height: 20),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader('Unit Sedang Beroperasi (In Use)', Icons.directions_car, Colors.orange, inUse.length),
                    if (!_isAddingCheckout)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        onPressed: () {
                          if (available.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Semua mobil sedang keluar/maintenance!'), backgroundColor: Colors.orange),
                            );
                            return;
                          }
                          setState(() => _isAddingCheckout = true);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Check-Out Kendaraan', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInUseTable(inUse),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, int count) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(width: 10),
        Chip(
          label: Text('$count Unit', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: color,
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildAvailableCard(Map<String, dynamic> vehicle) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(vehicle['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              const Icon(Icons.verified, color: Colors.green, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
            child: Text(vehicle['license_plate'], style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
          const SizedBox(height: 12),
          Text('Odometer: ${vehicle['current_km']} KM', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
        ],
      ),
    );
  }

  DataRow _buildInlineCheckoutRow() {
    return DataRow(
      color: WidgetStateProperty.all(Colors.blue.shade50.withValues(alpha: 0.5)),
      cells: [
        // Vehicle (Autocomplete)
        DataCell(
          SizedBox(
            width: 200,
            child: TypeAheadField<Map<String, dynamic>>(
              controller: _vehicleCtrl,
              builder: (context, controller, focusNode) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Cari Mobil...',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                );
              },
              suggestionsCallback: (pattern) async {
                final res = await ApiService.searchVehicles(pattern);
                return res.where((v) => v['status'] == 'Available').cast<Map<String, dynamic>>().toList();
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  dense: true,
                  title: Text(suggestion['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${suggestion['license_plate']} • ${suggestion['current_km']} KM'),
                );
              },
              onSelected: (suggestion) {
                setState(() {
                  _selectedVehicle = suggestion;
                  _vehicleCtrl.text = suggestion['name'];
                  _startKmCtrl.text = suggestion['current_km'].toString();
                });
              },
            ),
          ),
        ),

        // Plat
        DataCell(
          Text(
            _selectedVehicle != null ? _selectedVehicle!['license_plate'] : '-',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
          ),
        ),

        // Driver
        DataCell(
          SizedBox(
            width: 180,
            child: TypeAheadField<Map<String, dynamic>>(
              controller: _driverCtrl,
              builder: (context, controller, focusNode) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Cari Driver...',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                );
              },
              suggestionsCallback: (pattern) async {
                final res = await ApiService.searchEmployees(pattern);
                return res.cast<Map<String, dynamic>>();
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  dense: true,
                  title: Text(suggestion['name']),
                  subtitle: Text('NIK: ${suggestion['nik']}'),
                );
              },
              onSelected: (suggestion) {
                setState(() {
                  _selectedDriverName = suggestion['name'];
                  _driverCtrl.text = suggestion['name'];
                });
              },
            ),
          ),
        ),

        // Passenger
        DataCell(
          SizedBox(
            width: 240,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedPassengers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: _selectedPassengers.map((p) {
                        return Chip(
                          label: Text(p['name']!, style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          onDeleted: () {
                            setState(() => _selectedPassengers.remove(p));
                          },
                        );
                      }).toList(),
                    ),
                  ),
                TypeAheadField<Map<String, dynamic>>(
                  controller: _passengerCtrl,
                  builder: (context, controller, focusNode) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: _selectedPassengers.isEmpty ? 'Tambah Penumpang (Opsional)...' : '+ Tambah lagi...',
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    );
                  },
                  suggestionsCallback: (pattern) async {
                    final res = await ApiService.searchEmployees(pattern);
                    return res.cast<Map<String, dynamic>>();
                  },
                  itemBuilder: (context, suggestion) {
                    return ListTile(
                      dense: true,
                      title: Text(suggestion['name']),
                      subtitle: Text('NIK: ${suggestion['nik']}'),
                    );
                  },
                  onSelected: (suggestion) {
                    setState(() {
                      final exists = _selectedPassengers.any((p) => p['nik'] == suggestion['nik']);
                      if (!exists) {
                        _selectedPassengers.add({
                          'name': suggestion['name'].toString(),
                          'nik': suggestion['nik'].toString(),
                        });
                      }
                      _passengerCtrl.clear();
                    });
                  },
                ),
              ],
            ),
          ),
        ),

        // Destination
        DataCell(
          SizedBox(
            width: 160,
            child: TextField(
              controller: _destCtrl,
              decoration: const InputDecoration(
                hintText: 'Ketik Tujuan...',
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
          ),
        ),

        // Checkout time
        const DataCell(
          Text('Otomatis (Saat Ini)', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12)),
        ),

        // odometer
        DataCell(
          SizedBox(
            width: 110,
            child: TextField(
              controller: _startKmCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'KM Awal',
                suffixText: 'KM',
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
          ),
        ),

        // Action button
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: _submitInlineCheckout,
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Simpan'),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                tooltip: 'Batal',
                onPressed: _resetInlineForm,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInUseTable(List inUseVehicles) {
    if (inUseVehicles.isEmpty && !_isAddingCheckout) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: const Center(
          child: Text('Semua kendaraan sedang berada di kantor (Tersedia). Klik "+ Check-Out Kendaraan" di atas untuk mencatat keberangkatan.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Scrollbar(
            controller: _tableScrollCtrl,
            thumbVisibility: true,
            trackVisibility: true,
            child: SingleChildScrollView(
              controller: _tableScrollCtrl,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  dataRowMinHeight: 56,
                  dataRowMaxHeight: 95,
                  headingRowColor: WidgetStateProperty.all(Colors.orange.shade50),
                  columns: const [
                    DataColumn(label: Text('Kendaraan', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Plat Nomor', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Driver', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Penumpang', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Tujuan', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Waktu Keluar', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('KM Awal', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: [
                    if (_isAddingCheckout) _buildInlineCheckoutRow(),
                    ...inUseVehicles.map((v) {
                      final trip = v['trip_details'] ?? {};
                      final checkoutTime = trip['checkout_time'] ?? '-';
                      return DataRow(cells: [
                        DataCell(Text(v['name'], style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(v['license_plate'])),
                        DataCell(Text(trip['driver_name'] ?? '-')),
                        DataCell(Text(trip['passengers_str'] ?? '-')),
                        DataCell(Text(trip['destination'] ?? '-')),
                        
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(checkoutTime),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.edit_calendar_outlined, size: 16, color: Colors.blue),
                                tooltip: 'Ubah Waktu Keluar (Jika Lupa Check-Out)',
                                onPressed: () => _showEditTimeDialog(
                                  trip['log_id'],
                                  v['name'],
                                  checkoutTime,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text('${trip['start_km'] ?? 0} KM')),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onPressed: () => _showCheckInDialog(
                                  trip['log_id'],
                                  v['name'],
                                  trip['start_km'] ?? v['current_km'],
                                ),
                                icon: const Icon(Icons.login, size: 16),
                                label: const Text('Check-In'),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_forever, color: Colors.red),
                                tooltip: 'Batalkan Trip (Jika Salah Input)',
                                onPressed: () => _showCancelDialog(
                                  trip['log_id'],
                                  v['name'],
                                  trip['driver_name'] ?? '-',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]);
                    }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}