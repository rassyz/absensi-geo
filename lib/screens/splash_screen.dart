// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Wait for 3 seconds, then navigate to the login page
    Future.delayed(const Duration(seconds: 3), () {
      // Ensure the widget is still mounted before using context
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Standard background for splash
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your custom logo
            Image.asset(
              'assets/img/logo-no-bg.png',
              width: 120, // You can adjust the size here
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24), // Spacing between logo and text
            
            // App Title
            const Text(
              'Attendify', 
              style: TextStyle(
                fontSize: 28, 
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2, // Adds a nice touch to splash text
                color: Color(0xFF2979FF), // Using your primary blue color
              ),
            ),
          ],
        ),
      ),
    );
  }
}