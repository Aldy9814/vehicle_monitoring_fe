import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TvDisplayScreen extends StatefulWidget{
  const TvDisplayScreen({super.key});

  @override
  State<TvDisplayScreen> createState() => _TvDisplayScreenState();
}

class _TvDisplayScreenState extends State<TvDisplayScreen> {
  Map<String, dynamic>? _dashboardData;
  Timer? _refreshTimer;
  String _lastUpdate = '';

  @override
  void initState() {
    super.initState();
    _fetchData();

    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final data = await ApiService.getDashboardSummary();
      if (mounted) {
        setState(() {
          _dashboardData = data;
          final now = DateTime.now();
          _lastUpdate = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
        });
      }
    } catch (e) {
      debugPrint("Gagal update TV Display: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dashboardData == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    final available = _dashboardData!['available'] as List? ?? [];
    final inUse = _dashboardData!['in_use'] as List? ?? [];
    final maintenance = _dashboardData!['maintenance'] as List? ?? [];

    return Scaffold(
      backgroundColor: Colors.grey[100], 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
        title: const Text(
          'STATUS KENDARAAN OPERASIONAL', 
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.black87)
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: Center(
              child: Text(
                'Terakhir Update: $_lastUpdate', 
                style: const TextStyle(color: Colors.black54, fontSize: 16, fontWeight: FontWeight.bold)
              )
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Expanded(child: _buildColumn('TERSEDIA (${available.length})', Colors.green, available, false)),
            const SizedBox(width: 16),

            Expanded(child: _buildColumn('BEROPERASI (${inUse.length})', Colors.orange, inUse, true)),
            const SizedBox(width: 16),

            Expanded(child: _buildColumn('MAINTENANCE (${maintenance.length})', Colors.red, maintenance, false)),
          ],
        ),
      ),
    );
  }

  Widget _buildColumn(String title, Color headerColor, List items, bool isInUse) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: headerColor.withValues(alpha: 0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: headerColor.withValues(alpha: 0.15), 
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10))
            ),
            child: Text(
              title, 
              textAlign: TextAlign.center, 
              style: TextStyle(color: headerColor, fontSize: 24, fontWeight: FontWeight.bold)
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final v = items[index];
                return _buildTvCard(v, isInUse, headerColor);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTvCard(Map<String, dynamic> vehicle, bool isInUse, Color accentColor) {
    final trip = vehicle['trip_details'] ?? {};
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), 
        side: BorderSide(color: accentColor.withValues(alpha: 0.3))
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    vehicle['name'], 
                    style: const TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold)
                  )
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1), 
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: accentColor.withValues(alpha: 0.5))
                  ),
                  child: Text(
                    vehicle['license_plate'], 
                    style: TextStyle(color: accentColor, fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                ),
              ],
            ),
            if (isInUse) ...[
              const Divider(color: Colors.black12, thickness: 1, height: 24),
              Text('Driver: ${trip['driver_name'] ?? '-'}', style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Tujuan: ${trip['destination'] ?? '-'}', style: const TextStyle(color: Colors.black87, fontSize: 18)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('Keluar: ${trip['checkout_time'] ?? '-'}', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                ]
              )
            ] else ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.speed, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${vehicle['current_km']} KM', style: TextStyle(color: Colors.grey[800], fontSize: 16, fontWeight: FontWeight.w600)),
                ]
              )
            ]
          ],
        ),
      ),
    );
  }

}