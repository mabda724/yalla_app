import 'package:flutter/material.dart';
import 'restaurant_dashboard_screen.dart';
import 'menu_management_screen.dart';
import 'order_management_screen.dart';

class RestaurantNavScreen extends StatefulWidget {
  const RestaurantNavScreen({super.key});

  @override
  State<RestaurantNavScreen> createState() => _RestaurantNavScreenState();
}

class _RestaurantNavScreenState extends State<RestaurantNavScreen> {
  int _currentIndex = 0;
  final screens = const [
    RestaurantDashboardScreen(),
    MenuManagementScreen(),
    OrderManagementScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'قائمتي'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'الطلبات'),
        ],
      ),
    );
  }
}
