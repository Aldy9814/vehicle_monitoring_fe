import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../services/api_service.dart';

class PassengerInput {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController nikCtrl = TextEditingController();
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _vehicleController = TextEditingController();
  final TextEditingController _driverController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _startKmController = TextEditingController();

  String? _selectedVehicleId;
  bool _isLoading = false;

  final List<PassengerInput> _passengers = [];

  void _addPassenger() {
    setState(() {
      _passengers.add(PassengerInput());
    });
  }

  void _removePassenger(int index) {
    setState(() {
      _passengers[index].nameCtrl.dispose();
      _passengers[index].nikCtrl.dispose();
      _passengers.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kendaraan dari dropdown suggestion!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final passengerData = _passengers.map((p) => {
        'name': p.nameCtrl.text,
        'nik': p.nikCtrl.text,
      }).toList();

      final requestData = {
        "vehicle_id": _selectedVehicleId,
        "passengers": passengerData,
        "driver_name": _driverController.text,
        "destination": _destinationController.text,
        "start_km": int.parse(_startKmController.text),
      };

      final success = await ApiService.checkoutVehicle(requestData);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check-Out Berhasil!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal Check-Out: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _vehicleController.dispose();
    _driverController.dispose();
    _destinationController.dispose();
    _startKmController.dispose();
    for (var p in _passengers) {
      p.nameCtrl.dispose();
      p.nikCtrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Check-Out Kendaraan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //Input Vehicle
              TypeAheadField<dynamic>(
                builder: (context, controller, focusNode) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Cari Mobil / Plat Nomor',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.directions_car),
                    ),
                    validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                  );
                },
                controller: _vehicleController,
                suggestionsCallback: (pattern) async {
                  if (pattern.isEmpty) return [];
                  final list = await ApiService.searchVehicles(pattern);
                  // Filter vehicle
                  return list.where((v) => v['status'] == 'Available').toList();
                },
                itemBuilder: (context, suggestion) {
                  return ListTile(
                    title: Text('${suggestion['name']} - ${suggestion['license_plate']}'),
                    subtitle: Text('KM Terakhir: ${suggestion['current_km']}'),
                  );
                },
                onSelected: (suggestion) {
                  _vehicleController.text = '${suggestion['name']} (${suggestion['license_plate']})';
                  _selectedVehicleId = suggestion['id'];
                  _startKmController.text = suggestion['current_km'].toString();
                },
              ),
              const SizedBox(height: 16),

              // Input KM
              TextFormField(
                controller: _startKmController,
                decoration: const InputDecoration(
                  labelText: 'Kilometer Awal',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.speed),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // Input Destination
              TextFormField(
                controller: _destinationController,
                decoration: const InputDecoration(
                  labelText: 'Tujuan Keluar',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // Input Driver
              TypeAheadField<dynamic>(
                builder: (context, controller, focusNode) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Nama Supir / Pengemudi',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                  );
                },
                controller: _driverController,
                suggestionsCallback: (pattern) async {
                  if (pattern.isEmpty) return [];
                  return await ApiService.searchEmployees(pattern);
                },
                itemBuilder: (context, suggestion) {
                  return ListTile(
                    title: Text(suggestion['name']),
                    subtitle: Text('NIK: ${suggestion['nik']} | Div: ${suggestion['department']}'),
                  );
                },
                onSelected: (suggestion) {
                  _driverController.text = suggestion['name'];
                },
              ),
              const SizedBox(height: 24),

              //Passenger
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daftar Penumpang',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addPassenger,
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _passengers.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Penumpang ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removePassenger(index),
                              )
                            ],
                          ),
                          // Passenger name
                          TypeAheadField<dynamic>(
                            builder: (context, controller, focusNode) {
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: const InputDecoration(labelText: 'Nama Penumpang'),
                                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                              );
                            },
                            controller: _passengers[index].nameCtrl,
                            suggestionsCallback: (pattern) async {
                              if (pattern.isEmpty) return [];
                              return await ApiService.searchEmployees(pattern);
                            },
                            itemBuilder: (context, suggestion) {
                              return ListTile(
                                title: Text(suggestion['name']),
                                subtitle: Text('NIK: ${suggestion['nik']}'),
                              );
                            },
                            onSelected: (suggestion) {
                              _passengers[index].nameCtrl.text = suggestion['name'];
                              _passengers[index].nikCtrl.text = suggestion['nik'];
                            },
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passengers[index].nikCtrl,
                            decoration: const InputDecoration(labelText: 'NIK Penumpang'),
                            validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('SUBMIT CHECK-OUT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}