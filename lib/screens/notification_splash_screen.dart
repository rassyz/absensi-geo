import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'attendance_screen.dart';

class NotificationSplashScreen extends StatefulWidget {
  const NotificationSplashScreen({super.key});

  @override
  State<NotificationSplashScreen> createState() =>
      _NotificationSplashScreenState();
}

class _NotificationSplashScreenState extends State<NotificationSplashScreen> {
  bool _navigationHandled = false;

  @override
  void initState() {
    super.initState();
    _continueToAttendance();
  }

  Future<void> _continueToAttendance() async {
    /*
     * Splash cepat hanya untuk aplikasi yang masih hidup di background.
     * Tidak restore session dan tidak memanggil API data awal.
     */
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (!mounted || _navigationHandled) {
      return;
    }

    _navigationHandled = true;

    final AuthProvider authProvider = context.read<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      return;
    }

    /*
     * Quick splash diganti AttendanceScreen.
     * MainScreen tetap ada di bawah route ini sehingga tombol Back
     * kembali ke halaman utama.
     */
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(
        builder: (_) => const AttendanceScreen(),
        settings: const RouteSettings(name: '/attendance-notification'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/img/logo-no-bg.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            const Text(
              'Attendify',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Color(0xFF2979FF),
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
