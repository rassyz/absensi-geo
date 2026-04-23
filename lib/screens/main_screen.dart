// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:absensi_geo/screens/home_screen.dart';
import 'package:absensi_geo/screens/leave_request_screen.dart';
import 'package:absensi_geo/screens/attendance_screen.dart';
import 'package:absensi_geo/screens/attendance_report_screen.dart';

// 👇 Import your newly created nav bar file!
import 'package:absensi_geo/widgets/custom_bottom_nav.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AttendanceScreen(),
    const LeaveRequestScreen(),
    const AttendanceReportScreen(),
    const Center(child: Text("Profile Screen")),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      // 1. We use a Stack so the Nav Bar floats perfectly above the screen content
      body: Stack(
        children: [
          // ✅ Ini menyimpan semua layar di memori, sehingga pergantian tab menjadi INSTAN!
          IndexedStack(index: _selectedIndex, children: _screens),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomBottomNav(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            ),
          ),
        ],
      ),
    );
  }
}
