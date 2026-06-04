// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:absensi_geo/screens/home_screen.dart';
import 'package:absensi_geo/screens/leave_request_screen.dart';
import 'package:absensi_geo/screens/attendance_screen.dart';
import 'package:absensi_geo/screens/attendance_report_screen.dart';
import 'package:absensi_geo/screens/profile_screen.dart';
import 'package:absensi_geo/widgets/custom_bottom_nav.dart';
import 'package:absensi_geo/theme/app_colors.dart';
// import 'package:flutter_svg/flutter_svg.dart';

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
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light[500],

      extendBody: true,

      body: IndexedStack(index: _selectedIndex, children: _screens),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AttendanceScreen()),
          );
        },
        backgroundColor: const Color(0xFF2F80ED),
        elevation: 0,
        highlightElevation: 0,
        hoverElevation: 0,
        focusElevation: 0,
        shape: const CircleBorder(),
        child: const Icon(Icons.fingerprint, color: Colors.white, size: 33),
      ),

      floatingActionButtonLocation: const LoweredCenterDockedFabLocation(15.0),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

// 👇 Tambahkan class ini untuk mengatur offset vertikal
class LoweredCenterDockedFabLocation extends FloatingActionButtonLocation {
  final double offsetY;

  const LoweredCenterDockedFabLocation(this.offsetY);

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX =
        (scaffoldGeometry.scaffoldSize.width -
            scaffoldGeometry.floatingActionButtonSize.width) /
        2.0;

    final double fabY =
        scaffoldGeometry.contentBottom -
        (scaffoldGeometry.floatingActionButtonSize.height / 2.0);

    return Offset(fabX, fabY + offsetY);
  }
}
