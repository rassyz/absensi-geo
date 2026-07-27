// lib/screens/main_screen.dart

import 'package:absensi_geo/providers/auth_provider.dart';
import 'package:absensi_geo/screens/attendance_report_screen.dart';
import 'package:absensi_geo/screens/attendance_screen.dart';
import 'package:absensi_geo/screens/home_screen.dart';
import 'package:absensi_geo/screens/leave_request_screen.dart';
import 'package:absensi_geo/screens/profile_screen.dart';
import 'package:absensi_geo/theme/app_colors.dart';
import 'package:absensi_geo/widgets/custom_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _isCheckingSession = false;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AttendanceScreen(),
    const LeaveRequestScreen(),
    const AttendanceReportScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _validateSessionAfterResume();
    }
  }

  Future<void> _validateSessionAfterResume() async {
    if (_isCheckingSession || !mounted) {
      return;
    }

    _isCheckingSession = true;

    try {
      await context.read<AuthProvider>().validateCurrentSession();
    } finally {
      _isCheckingSession = false;
    }
  }

  void _onItemTapped(int index) {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.isSessionExpired) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  void _goToLogin(AuthProvider authProvider) {
    authProvider.clearSessionExpiredNotice();

    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final bool isSessionExpired = authProvider.isSessionExpired;

    /*
     * Ketika sesi kedaluwarsa:
     * - Home tetap terlihat.
     * - Halaman lain tidak dapat dibuka.
     * - Bottom navigation dan FAB disembunyikan.
     * - Tombol Back diblokir.
     */
    final int visibleIndex = isSessionExpired ? 0 : _selectedIndex;

    return PopScope(
      canPop: !isSessionExpired,
      child: Scaffold(
        backgroundColor: AppColors.light[500],
        extendBody: !isSessionExpired,
        body: Stack(
          children: [
            IndexedStack(index: visibleIndex, children: _screens),
            if (isSessionExpired)
              Positioned.fill(child: _buildSessionExpiredOverlay(authProvider)),
          ],
        ),
        floatingActionButton: isSessionExpired
            ? null
            : FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AttendanceScreen(),
                    ),
                  );
                },
                backgroundColor: const Color(0xFF2F80ED),
                elevation: 0,
                highlightElevation: 0,
                hoverElevation: 0,
                focusElevation: 0,
                shape: const CircleBorder(),
                child: const Icon(
                  Icons.fingerprint,
                  color: Colors.white,
                  size: 33,
                ),
              ),
        floatingActionButtonLocation: isSessionExpired
            ? null
            : const LoweredCenterDockedFabLocation(15.0),
        bottomNavigationBar: isSessionExpired
            ? null
            : CustomBottomNav(
                selectedIndex: _selectedIndex,
                onItemTapped: _onItemTapped,
              ),
      ),
    );
  }

  Widget _buildSessionExpiredOverlay(AuthProvider authProvider) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white[500],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary[500]!.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_clock_outlined,
                      color: AppColors.primary[500],
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Sesi Berakhir',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.dark[500],
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    authProvider.sessionExpiredMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.gray[500],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _goToLogin(authProvider),
                      icon: const Icon(Icons.login),
                      label: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary[500],
                        foregroundColor: AppColors.white[500],
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
