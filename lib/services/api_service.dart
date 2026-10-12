
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://vehiclemonitoringbe-production.up.railway.app';

  static Future<bool> addVehicle(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/master/vehicles'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  static Future<bool> addEmployee(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/master/employees'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  static Future<List<dynamic>> searchEmployees(String query) async {
    final response = await http.get(Uri.parse('$baseUrl/master/employees/search?query=$query'));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded['data'];
    }
    throw Exception('Gagal memuat data karyawan');
  }

  static Future<List<dynamic>> searchVehicles(String query) async {
    final response = await http.get(Uri.parse('$baseUrl/master/vehicles/search?query=$query'));
    if (response.statusCode == 200){
      final decoded = jsonDecode(response.body);
      return decoded['data'];
    }
    throw Exception('Gagal memuat data kendaraan');
  }

  static Future<bool> updateVehicleStatus(String vehicleID, String newStatus) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/master/vehicles/$vehicleID/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': newStatus}),
      );
      return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> getDashboardSummary() async {
    final response = await http.get(Uri.parse('$baseUrl/dashboard/summary'));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded['data'];
    }
    throw Exception('Gagal memuat dashboard');
  }

  static Future<bool> checkoutVehicle(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions/checkout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data)
    );
    return response.statusCode == 200;
  }

  static Future<List<dynamic>> getTripHistory(String month) async {
    final response = await http.get(Uri.parse('$baseUrl/transactions/history?month=$month'));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded['data'];
    }
    throw Exception('Gagal memuat trip history');
  }

  static Future<bool> checkinVehicle(String logId, int endKm) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions/checkin/$logId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'end_km': endKm}),
    );
    return response.statusCode == 200;
  }

  static String getExportUrl(String month) {
    return '$baseUrl/transactions/history/export?month=$month';
  }

  static Future<bool> updateEmployee(String empId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/master/employees/$empId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
  return response.statusCode == 200;
  }

  static Future<bool> deleteEmployee(String empId) async{
    final response = await http.delete(Uri.parse('$baseUrl/master/employees/$empId'));
  return response.statusCode == 200;
  }

  static Future<bool> deleteVehicle(String vehicleId) async {
    final response = await http.delete(Uri.parse('$baseUrl/master/vehicles/$vehicleId'));
    return response.statusCode == 200;
  }

  static Future<bool> updateCheckoutTime(String logId, String newTime) async {
    final response = await http.put(
      Uri.parse('$baseUrl/transactions/logs/$logId/time'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'checkout_time': newTime}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> cancelCheckout(String logId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/transactions/checkout/$logId'),
    );
    return response.statusCode == 200;
  }

}