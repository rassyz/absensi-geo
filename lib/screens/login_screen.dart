// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../services/api_service.dart'; // Impor ApiService
import 'register_screen.dart'; // Impor RegisterScreen

class LoginScreen extends StatelessWidget {
  final AuthController authController = Get.put(AuthController(ApiService()));

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            Obx(() {
              return authController.isLoading.value
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () {
                        authController.login(
                          emailController.text,
                          passwordController.text,
                        );
                      },
                      child: Text('Login'),
                    );
            }),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Get.to(RegisterScreen());
              },
              child: Text("Don't have an account? Register here"),
            ),
            SizedBox(height: 20),
            Obx(() {
              if (authController.errorMessage.value.isNotEmpty) {
                return Text(
                  authController.errorMessage.value,
                  style: TextStyle(color: Colors.red),
                );
              }
              return SizedBox.shrink(); // Return an empty widget if there's no error
            }),
          ],
        ),
      ),
    );
  }
}
