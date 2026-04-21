import 'package:absensi_geo/providers/auth_provider.dart';
import 'package:absensi_geo/theme/app_colors.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: "juned@absen.test");
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    // 1. Get the provider without listening (for triggering the method)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 2. Call the login method and wait for the result
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    // 3. Ensure the widget is still mounted before interacting with the UI
    if (!mounted) return;

    // 4. Handle success or error using native Flutter tools
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful'),
          backgroundColor: Colors.green,
        ),
      );
      // Navigate to Home and clear the stack
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Consume the AuthProvider state for reactive UI (like visibility toggles)
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom App Logo
              Center(
                child: Container(
                  width: 130,
                  height: 130,
                  padding: const EdgeInsets.all(
                    10,
                  ), // Adjust this padding if the logo feels too tight
                  child: Center(
                    child: Image.asset(
                      'assets/img/logo-no-bg.png',
                      fit: BoxFit
                          .contain, // Ensures the logo fits perfectly inside the circle
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Welcome Text with Waving Hand and Blue highlight
              Text.rich(
                TextSpan(
                  text: 'Welcome Back ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                  children: [
                    const TextSpan(
                      text: '👋',
                      style: TextStyle(fontWeight: FontWeight.normal),
                    ),
                    const TextSpan(text: '\nto '),
                    TextSpan(
                      text: 'Attendify',
                      style: TextStyle(color: AppColors.primarySwatch[500]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Hello there, login to continue',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 30),

              // Email Form Field
              _buildAuthTextField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 16),

              // Password Form Field
              _buildAuthTextField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock_outline,
                obscureText: authProvider.obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    authProvider.obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey,
                  ),
                  onPressed: authProvider.togglePasswordVisibility,
                ),
              ),
              const SizedBox(height: 12),

              // Forgot Password Link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Forgot Password ?',
                    style: TextStyle(color: AppColors.primarySwatch[500]),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Solid Blue Login Button (Reactive to loading state)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  // Disable button while loading
                  onPressed: authProvider.isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primarySwatch[500],
                    disabledBackgroundColor: AppColors
                        .primarySwatch[200], // Lighter blue when disabled
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  // Show loading spinner if API is processing
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),

              // Social Account Divider
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.gray20)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Or continue with social account',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.gray20)),
                ],
              ),
              const SizedBox(height: 20),

              // White Google Social Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: AppColors.gray20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.android, color: Colors.green),
                      SizedBox(width: 12),
                      Text(
                        'Google',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Footer Register Link (Native Navigation)
              Center(
                child: Text.rich(
                  TextSpan(
                    text: 'Didn’t have an account? ',
                    style: const TextStyle(color: Colors.grey),
                    children: [
                      TextSpan(
                        text: 'Register',
                        style: TextStyle(
                          color: AppColors.primarySwatch[500],
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Native Flutter Push Replacement
                            Navigator.pushReplacementNamed(
                              context,
                              '/register',
                            );
                          },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Generic helper for creating auth text fields
  Widget _buildAuthTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray20),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.grey),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
