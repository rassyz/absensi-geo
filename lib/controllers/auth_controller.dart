// lib/controllers/auth_controller.dart
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthController extends GetxController {
  final ApiService apiService;

  var user = UserModel(token: '', name: '', email: '').obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  AuthController(this.apiService);

  Future<void> login(String email, String password) async {
    isLoading.value = true; // Mulai loading
    errorMessage.value = ''; // Reset error message

    try {
      UserModel? result = await apiService.login(email, password);
      if (result != null) {
        user.value = result; // Simpan user data jika berhasil login
        Get.snackbar('Success', 'Login successful');
        // Navigate to the next screen, e.g., Get.offAll(HomeScreen());
      }
    } catch (e) {
      errorMessage.value = e.toString(); // Set error message
      Get.snackbar('Error', errorMessage.value); // Tampilkan error
    } finally {
      isLoading.value = false; // Stop loading
    }
  }

  Future<void> register(
    String name,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    isLoading.value = true; // Mulai loading
    errorMessage.value = ''; // Reset error message

    try {
      // Ambil pesan dari hasil registrasi
      String resultMessage = await apiService.register(
        name,
        email,
        password,
        passwordConfirmation,
      );
      // Tampilkan pesan sukses
      Get.snackbar('Success', resultMessage);

      // Setelah registrasi berhasil, arahkan ke halaman login
      Get.offNamed(
        '/login',
      ); // Ganti '/login' dengan nama rute yang sesuai, jika Anda menggunakan named routes

      // Jika Anda menggunakan Get.to(), gunakan berikut:
      // Get.to(LoginScreen()); // Ganti LoginScreen dengan widget login yang sesuai
    } catch (e) {
      errorMessage.value = e.toString(); // Set error message
      Get.snackbar('Error', errorMessage.value); // Tampilkan error
    } finally {
      isLoading.value = false; // Stop loading
    }
  }

  Future<void> logout() async {
    await apiService.logout(); // Panggil apiService untuk logout
    user.value = UserModel(token: '', name: '', email: ''); // Reset user data
    Get.snackbar('Success', 'Logout successful');
  }

  Future<void> getUserProfile() async {
    try {
      UserModel? result = await apiService.getUserProfile();
      if (result != null) {
        user.value = result; // Simpan profil user
      }
    } catch (e) {
      errorMessage.value = e.toString(); // Set error message
      Get.snackbar('Error', errorMessage.value); // Tampilkan error
    }
  }
}
