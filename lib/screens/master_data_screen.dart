import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MasterDataScreen extends StatefulWidget {
  const MasterDataScreen({super.key});

  @override
  State<MasterDataScreen> createState() => _MasterDataScreenState();
}

class _MasterDataScreenState extends State<MasterDataScreen> {
  late Future<List<dynamic>> _vehiclesData;
  late Future<List<dynamic>> _employeesData;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  void _refreshAll() {
    setState(() {

      _vehiclesData = ApiService.searchVehicles('');
      _employeesData = ApiService.searchEmployees('');
    });
  }


  // --- DIALOG KONFIRMASI HAPUS DENGAN PIN ADMIN ---
  Future<void> _confirmDeleteWithPin({
    required String itemType,
    required String itemName,
    required Future<bool> Function() onDeleteProcess,
  }) async {
    final pinCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              const SizedBox(width: 8),
              Text('Hapus $itemType?'),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Apakah Anda yakin ingin menghapus "$itemName" secara permanen dari sistem?'),
                const SizedBox(height: 16),
                const Text(
                  'Masukkan PIN Admin untuk konfirmasi:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: pinCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'PIN Admin',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'PIN wajib diisi';
                    if (val != '1234') return 'PIN Admin salah!';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final success = await onDeleteProcess();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$itemName berhasil dihapus!'), backgroundColor: Colors.green),
                    );
                    _refreshAll();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gagal menghapus data!'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Ya, Hapus Data'),
            ),
          ],
        );
      },
    );
  }

  // --- DIALOG TAMBAH KENDARAAN ---
  Future<void> _showAddVehicleDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final plateCtrl = TextEditingController();
    final kmCtrl = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Unit Kendaraan'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Mobil (Misal: Toyota Innova)', border: OutlineInputBorder()),
                  validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: plateCtrl,
                  decoration: const InputDecoration(labelText: 'Plat Nomor (Misal: N 1234 AB)', border: OutlineInputBorder()),
                  validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: kmCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Kilometer Awal (Odometer)', border: OutlineInputBorder()),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Wajib diisi';
                    if (int.tryParse(val) == null) return 'Harus berupa angka';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final success = await ApiService.addVehicle({
                    'name': nameCtrl.text,
                    'license_plate': plateCtrl.text,
                    'current_km': int.parse(kmCtrl.text),
                  });
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kendaraan berhasil ditambahkan!'), backgroundColor: Colors.green),
                    );
                    _refreshAll();
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  // --- DIALOG TAMBAH / EDIT KARYAWAN ---
  Future<void> _showEmployeeFormDialog({Map<String, dynamic>? existingEmp}) async {
    final isEdit = existingEmp != null;
    final formKey = GlobalKey<FormState>();
    final nikCtrl = TextEditingController(text: isEdit ? existingEmp['nik'] : '');
    final nameCtrl = TextEditingController(text: isEdit ? existingEmp['name'] : '');
    final deptCtrl = TextEditingController(text: isEdit ? existingEmp['department'] : '');

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Data Karyawan' : 'Tambah Karyawan Baru'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nikCtrl,
                  decoration: const InputDecoration(labelText: 'NIK Karyawan', border: OutlineInputBorder()),
                  validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder()),
                  validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: deptCtrl,
                  decoration: const InputDecoration(labelText: 'Departemen / Divisi', border: OutlineInputBorder()),
                  validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final payload = {
                    'nik': nikCtrl.text,
                    'name': nameCtrl.text,
                    'department': deptCtrl.text,
                  };

                  final bool success;
                  if (isEdit) {
                    success = await ApiService.updateEmployee(existingEmp['id'], payload);
                  } else {
                    success = await ApiService.addEmployee(payload);
                  }

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit ? 'Data karyawan diperbarui!' : 'Karyawan berhasil ditambahkan!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _refreshAll();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gagal! Pastikan NIK belum digunakan karyawan lain.'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: Text(isEdit ? 'Simpan Perubahan' : 'Simpan'),
            ),
          ],
        );
      },
    );
  }

  // --- FUNGSI UBAH STATUS KENDARAAN ---
  Future<void> _toggleVehicleStatus(String id, String name, String currentStatus) async {
    final newStatus = currentStatus == 'Available' ? 'Maintenance' : 'Available';
    final actionText = newStatus == 'Maintenance' ? 'memasukkan ke bengkel (Maintenance)' : 'mengaktifkan kembali (Available)';

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Ubah Status'),
        content: Text('Apakah Anda yakin ingin $actionText untuk unit "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'Available' ? Colors.green : Colors.orange[800],
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final success = await ApiService.updateVehicleStatus(id, newStatus);
              if (!context.mounted) return;
              Navigator.pop(context);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Status $name diubah menjadi $newStatus!'), backgroundColor: Colors.green),
                );
                _refreshAll();
              }
            },
            child: Text('Ya, Set $newStatus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Kelola Master Data', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 1,
          bottom: const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(icon: Icon(Icons.directions_car), text: 'Data Kendaraan'),
              Tab(icon: Icon(Icons.people), text: 'Data Karyawan'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildVehiclesTab(),
            _buildEmployeesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildVehiclesTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daftar Seluruh Unit Kendaraan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Tips: Klik pada tombol status untuk mengubah antara Available & Maintenance', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                onPressed: _showAddVehicleDialog,
                icon: const Icon(Icons.add),
                label: const Text('Tambah Kendaraan'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: FutureBuilder<List<dynamic>>(
                future: _vehiclesData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Belum ada data kendaraan.'));
                  }
                  final list = snapshot.data!;
                  return SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                      columns: const [
                        DataColumn(label: Text('ID Unit', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Nama Kendaraan', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Plat Nomor', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Odometer (KM)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Status (Klik untuk Ubah)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: list.map((v) {
                        final status = v['status'];
                        final isAvail = status == 'Available';
                        final isInUse = status == 'In Use';

                        Color bgColor = isAvail ? Colors.green[100]! : (isInUse ? Colors.orange[100]! : Colors.red[100]!);
                        Color textColor = isAvail ? Colors.green[800]! : (isInUse ? Colors.orange[800]! : Colors.red[800]!);

                        return DataRow(cells: [
                          DataCell(Text(v['id'])),
                          DataCell(Text(v['name'], style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(Text(v['license_plate'])),
                          DataCell(Text('${v['current_km']} KM')),
                          DataCell(
                            isInUse
                                ? Tooltip(
                                    message: 'Sedang beroperasi. Lakukan Check-In di Dashboard untuk mengubah.',
                                    child: Chip(
                                      avatar: Icon(Icons.lock, size: 14, color: textColor),
                                      label: Text(status, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                      backgroundColor: bgColor,
                                    ),
                                  )
                                : ActionChip(
                                    avatar: Icon(Icons.sync, size: 14, color: textColor),
                                    label: Text(status, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                    backgroundColor: bgColor,
                                    tooltip: 'Klik untuk ubah status servis',
                                    onPressed: () => _toggleVehicleStatus(v['id'], v['name'], status),
                                  ),
                          ),
                          DataCell(
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: isInUse ? Colors.grey : Colors.red),
                              tooltip: isInUse ? 'Tidak bisa dihapus saat sedang beroperasi' : 'Hapus Kendaraan',
                              onPressed: isInUse
                                  ? null
                                  : () => _confirmDeleteWithPin(
                                        itemType: 'Kendaraan',
                                        itemName: '${v['name']} (${v['license_plate']})',
                                        onDeleteProcess: () => ApiService.deleteVehicle(v['id']),
                                      ),
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeesTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Daftar Karyawan Terdaftar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                onPressed: () => _showEmployeeFormDialog(),
                icon: const Icon(Icons.person_add),
                label: const Text('Tambah Karyawan'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: FutureBuilder<List<dynamic>>(
                future: _employeesData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Belum ada data karyawan.'));
                  }
                  final list = snapshot.data!;
                  return SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                      columns: const [
                        DataColumn(label: Text('NIK', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Nama Karyawan', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Departemen / Divisi', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: list.map((e) {
                        return DataRow(cells: [
                          DataCell(Text(e['nik'], style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(e['name'])),
                          DataCell(Text(e['department'])),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                  tooltip: 'Edit Karyawan',
                                  onPressed: () => _showEmployeeFormDialog(existingEmp: e),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  tooltip: 'Hapus Karyawan',
                                  onPressed: () => _confirmDeleteWithPin(
                                    itemType: 'Karyawan',
                                    itemName: '${e['name']} (NIK: ${e['nik']})',
                                    onDeleteProcess: () => ApiService.deleteEmployee(e['id']),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

