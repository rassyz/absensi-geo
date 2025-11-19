import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simulasi proses pemuatan
    Future.delayed(Duration(seconds: 2), () {
      // Arahkan ke halaman berikutnya
      Get.offNamed('/login'); // Ubah sesuai dengan rute yang ingin Anda arahkan
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF00062A), // Warna latar belakang
      body: Center(
        child: Container(
          width: 300, // Atur lebar container
          height: 300, // Atur tinggi container
          child: Image.asset(
            'assets/img/logo-no-bg.png', // Ganti dengan path logo Anda
            fit: BoxFit.contain, // Atur BoxFit sesuai kebutuhan
          ),
        ),
      ),
    );
  }
}
