import 'package:absensi_geo/providers/auth_provider.dart';
import 'package:absensi_geo/theme/app_colors.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Combine First and Last name for the API if needed
    final fullName =
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';

    final success = await authProvider.register(
      fullName,
      _emailController.text.trim(),
      _passwordController.text,
      _confirmPasswordController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Please login.'),
          backgroundColor: Colors.green,
        ),
      );
      // Navigate back to login screen on success
      Navigator.pushReplacementNamed(context, '/login');
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
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '9:41',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  Row(
                    children: const [
                      Icon(Icons.signal_cellular_alt, size: 18),
                      SizedBox(width: 4),
                      Icon(Icons.wifi, size: 18),
                      SizedBox(width: 4),
                      Icon(Icons.battery_std, size: 18),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),

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

              // Register Text
              Text.rich(
                TextSpan(
                  text: 'Register Account ',
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
                'Hello there, register to continue',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 30),

              // Registration Fields
              _buildAuthTextField(
                controller: _firstNameController,
                label: 'First Name',
                hint: 'Enter First Name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildAuthTextField(
                controller: _lastNameController,
                label: 'Last Name',
                hint: 'Enter Last Name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildAuthTextField(
                controller: _emailController,
                label: 'Email Address',
                hint: 'Enter Email Address',
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 16),
              // Password Field
              _buildAuthTextField(
                controller: _passwordController,
                label: 'Password',
                hint: 'Enter Password',
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
              const SizedBox(height: 16),
              // Confirm Password Field
              _buildAuthTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                hint: 'Confirm Password',
                icon: Icons.lock_outline,
                obscureText: authProvider.obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    authProvider.obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey,
                  ),
                  onPressed: authProvider.toggleConfirmPasswordVisibility,
                ),
              ),
              const SizedBox(height: 20),

              // Terms and Conditions Checkbox
              Row(
                children: [
                  Checkbox(
                    value: authProvider.agreeToTerms,
                    onChanged: (value) {
                      authProvider.toggleTermsAgreement();
                    },
                    activeColor: AppColors.primarySwatch[500],
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'I agree to the ',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                        children: [
                          TextSpan(
                            text: 'Terms & Conditions & Privacy Policy',
                            style: TextStyle(
                              color: AppColors.primarySwatch[500],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(text: ' set out by this site.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Primary Blue Register Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  // Disable if not agreed to terms OR currently loading
                  onPressed:
                      (!authProvider.agreeToTerms || authProvider.isLoading)
                      ? null
                      : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primarySwatch[500],
                    disabledBackgroundColor: AppColors.primarySwatch[200],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
                          'Register',
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

              // Footer Login Link
              Center(
                child: Text.rich(
                  TextSpan(
                    text: 'Already have an account? ',
                    style: const TextStyle(color: Colors.grey),
                    children: [
                      TextSpan(
                        text: 'Login',
                        style: TextStyle(
                          color: AppColors.primarySwatch[500],
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Native Flutter Push Replacement
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: Container(
                  width: 134,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Generic helper for creating auth text fields with hints
  Widget _buildAuthTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
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
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.gray20, fontSize: 13),
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
