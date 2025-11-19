// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../services/api_service.dart'; // Impor ApiService

class RegisterScreen extends StatelessWidget {
  final AuthController authController = Get.put(AuthController(ApiService()));

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmationController =
      TextEditingController();

  RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: passwordConfirmationController,
              decoration: InputDecoration(labelText: 'Confirm Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            Obx(() {
              return authController.isLoading.value
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () {
                        authController.register(
                          nameController.text,
                          emailController.text,
                          passwordController.text,
                          passwordConfirmationController.text,
                        );
                      },
                      child: Text('Register'),
                    );
            }),
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
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Get.back(); // Navigate back to login screen
              },
              child: Text("Already have an account? Login here"),
            ),
          ],
        ),
      ),
    );
  }
}
