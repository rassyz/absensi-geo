import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

import 'package:absensi_geo/providers/attendance_update_provider.dart';
import 'package:absensi_geo/providers/auth_provider.dart';
import 'package:absensi_geo/providers/employee_provider.dart';
import 'package:absensi_geo/providers/leave_provider.dart';
import 'package:absensi_geo/providers/overtime_provider.dart';

import 'package:absensi_geo/screens/home_screen.dart';
import 'package:absensi_geo/screens/login_screen.dart';
import 'package:absensi_geo/screens/main_screen.dart';
import 'package:absensi_geo/screens/register_screen.dart';
import 'package:absensi_geo/screens/splash_screen.dart';

import 'package:absensi_geo/services/auth_service.dart';
import 'package:absensi_geo/services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  /*
   * Jangan melakukan navigasi, mengakses BuildContext, atau menampilkan UI
   * dari background isolate. Interaksi pengguna diproses oleh:
   * - getInitialMessage() untuk terminated;
   * - onMessageOpenedApp untuk background.
   */
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  /*
   * Bootstrap notifikasi harus selesai sebelum runApp agar intent yang
   * membuka aplikasi dari kondisi terminated tidak hilang.
   *
   * Service hanya menangkap dan mengantrekan intent. Navigasi baru dilakukan
   * setelah MainScreen dan sesi autentikasi benar-benar siap.
   */
  await NotificationService.instance.initialize();

  final AuthService authService = AuthService();

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

// Di main.dart (dalam class MyApp)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendify',
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const HomeScreen(),
        '/main': (_) => const MainScreen(),
      },
    );
  }
}
