import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'dart:io';

// --- Providers ---
import 'package:absensi_geo/providers/auth_provider.dart';
import 'package:absensi_geo/providers/attendance_update_provider.dart';
import 'package:absensi_geo/providers/overtime_provider.dart';
import 'package:absensi_geo/providers/leave_provider.dart';
import 'package:absensi_geo/providers/employee_provider.dart';

// --- Screens ---
import 'package:absensi_geo/screens/splash_screen.dart';
import 'package:absensi_geo/screens/login_screen.dart';
import 'package:absensi_geo/screens/register_screen.dart';
import 'package:absensi_geo/screens/home_screen.dart';
import 'package:absensi_geo/screens/main_screen.dart';

// --- Services ---
import 'package:absensi_geo/services/auth_service.dart';

void main() {
  // 1. Initialize your new AuthService instead of ApiService
  final authService = AuthService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(create: (_) => AttendanceUpdateProvider()),
        ChangeNotifierProvider(create: (_) => OvertimeProvider()),
        ChangeNotifierProvider(create: (_) => LeaveProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
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
        '/home': (context) => const HomeScreen(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}
