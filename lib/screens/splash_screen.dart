import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigationHandled = false;

  @override
  void initState() {
    super.initState();

    /*
     * Tidak menggunakan delay buatan.
     * Splash hanya tampil selama pemulihan sesi benar-benar berlangsung.
     */
    _restoreSessionAndContinue();
  }

  Future<void> _restoreSessionAndContinue() async {
    final AuthProvider authProvider = context.read<AuthProvider>();

    final bool isLoggedIn = await authProvider.restoreSession();

    if (!mounted || _navigationHandled) {
      return;
    }

    _navigationHandled = true;

    if (isLoggedIn || authProvider.isSessionExpired) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/main', (Route<dynamic> route) => false);
      return;
    }

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
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
          ],
        ),
      ),
    );
  }
}
