import 'package:absensi_geo/providers/auth_provider.dart';
import 'package:absensi_geo/screens/splash_screen.dart';
import 'package:absensi_geo/screens/home_screen.dart';
import 'package:absensi_geo/screens/login_screen.dart';
import 'package:absensi_geo/screens/register_screen.dart';
import 'package:absensi_geo/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  // 2. Initialize your new AuthService instead of ApiService
  final authService = AuthService();

  runApp(
    MultiProvider(
      providers: [
        // 3. Pass the authService into the AuthProvider
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendify',
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) =>
            const HomeScreen(), // Note: Make sure HomeScreen has const constructor if possible
      },
    );
  }
}
