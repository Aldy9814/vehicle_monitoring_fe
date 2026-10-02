import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/history_screen.dart';
import 'screens/master_data_screen.dart';
import 'screens/tv_display_screen.dart';

void main() {
  runApp(const VehicleApp());
}

class VehicleApp extends StatelessWidget {
  const VehicleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vehicle Monitoring',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/dashboard',
      routes: {
        '/dashboard': (context) => const DashboardScreen(),
        '/checkout': (context) => const CheckoutScreen(),
        '/history': (context) => const HistoryScreen(),
        '/master': (context) => const MasterDataScreen(),
        '/tv': (context) => const TvDisplayScreen(),
      },
    );
  }
}
