import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedYear = DateTime.now().year.toString(); 
  String _selectedMonth = DateTime.now().month.toString().padLeft(2, '0');

  late Future<List<dynamic>> _historyData;

  final List<Map<String, String>> _months = [
    {'val': '01', 'name': 'Januari'}, {'val': '02', 'name': 'Februari'},
    {'val': '03', 'name': 'Maret'}, {'val': '04', 'name': 'April'},
    {'val': '05', 'name': 'Mei'}, {'val': '06', 'name': 'Juni'},
    {'val': '07', 'name': 'Juli'}, {'val': '08', 'name': 'Agustus'},
    {'val': '09', 'name': 'September'}, {'val': '10', 'name': 'Oktober'},
    {'val': '11', 'name': 'November'}, {'val': '12', 'name': 'Desember'},
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyData = ApiService.getTripHistory('$_selectedYear-$_selectedMonth');
    });
  }

  Future<void> _downloadExcel() async {
    final monthParam = '$_selectedYear-$_selectedMonth';
    final Uri url = Uri.parse(ApiService.getExportUrl(monthParam));
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mendownload file Excel'), backgroundColor: Colors.red,),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Riwayat Perjalanan Bulanan'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // filter & export
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Filter Periode: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 12),
                    // dropdown month
                    DropdownButton<String>(
                      value: _selectedMonth,
                      items: _months.map((m) => DropdownMenuItem(value: m['val'], child: Text(m['name']!))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          _selectedMonth = val;
                          _loadHistory();
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    // Dropdown year
                    DropdownButton<String>(
                      value: _selectedYear,
                      items: ['2025', '2026', '2027'].map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          _selectedYear = val;
                          _loadHistory();
                        }
                      },
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  onPressed: _downloadExcel,
                  icon: const Icon(Icons.download),
                  label: const Text('Download Excel (.xlsx)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // history
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                ),
                child: FutureBuilder<List<dynamic>>(
                  future: _historyData,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('Tidak ada riwayat perjalanan pada bulan ini.'));
                    }

                    final logs = snapshot.data!;

                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
                          columns: const [
                            DataColumn(label: Text('Waktu Keluar', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Waktu Kembali', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Kendaraan', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Driver', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Penumpang', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Tujuan', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('KM Awal', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('KM Akhir', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: logs.map((log) {
                            final isCompleted = log['status'] == 'Completed';
                            return DataRow(cells: [
                              DataCell(Text(log['checkout_time'])),
                              DataCell(Text(log['checkin_time'])),
                              DataCell(Text('${log['vehicle_name']} (${log['license_plate']})', style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(Text(log['driver_name'])),
                              DataCell(Text(log['passengers'])),
                              DataCell(Text(log['destination'])),
                              DataCell(Text('${log['start_km']}')),
                              DataCell(Text('${log['end_km']}')),
                              DataCell(
                                Chip(
                                  label: Text(
                                    log['status'],
                                    style: TextStyle(
                                      color: isCompleted ? Colors.green[800] : Colors.orange[800],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor: isCompleted ? Colors.green[100] : Colors.orange[100],
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}