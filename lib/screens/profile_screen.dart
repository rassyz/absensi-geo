// lib/screens/profile_screen.dart

import 'package:absensi_geo/providers/leave_provider.dart';
import 'package:absensi_geo/providers/overtime_provider.dart';
import 'package:absensi_geo/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:absensi_geo/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Fungsi Logout yang dipindahkan ke layar Profil
  Future<void> _showLogoutDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Konfirmasi Keluar'),
          content: const Text(
            'Apakah Anda yakin ingin keluar? Sesi Anda saat ini akan diakhiri.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                await authProvider.logout();

                if (context.mounted) {
                  // 👇 RESET MEMORI PROVIDER DI SINI 👇
                  Provider.of<OvertimeProvider>(context, listen: false).reset();
                  Provider.of<LeaveProvider>(context, listen: false).reset();

                  Navigator.pop(context); // Tutup loading
                  Navigator.pop(context); // Tutup dialog

                  // Kembali ke layar login (sesuaikan dengan route Anda)
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF766A),
              ),
              child: const Text(
                'Keluar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data user secara dinamis
    final authProvider = Provider.of<AuthProvider>(context);
    final employee = authProvider.user?.employee;

    // 1. Ekstrak Nama
    final String userName =
        employee?.fullName ?? authProvider.user?.name ?? "Michael Mitc";

    // 👇 2. LOGIKA DEPARTMENT - POSITION 👇
    // Pastikan property 'department' dan 'position' sudah ada di model Employee Anda
    final String dept = employee?.departmentName ?? "";
    final String pos = employee?.position ?? "";

    final String role = (dept.isNotEmpty && pos.isNotEmpty)
        ? "$dept - $pos"
        : (pos.isNotEmpty
              ? pos
              : (dept.isNotEmpty ? dept : "Lead UI/UX Designer"));
    // 👆 SELESAI LOGIKA JABATAN 👆

    final String? avatarUrl = authProvider.user?.avatarUrl;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- 1. FOTO PROFIL & BADGE KAMERA ---
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary[500]!,
                      width: 1.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: AppColors.gray[500],

                    // DYNAMIC IMAGE LOGIC
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl)
                        : null,

                    child: avatarUrl == null
                        ? const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6), // Blue color
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- 2. NAMA & JABATAN ---
            Text(
              userName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              role,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            // --- 3. TOMBOL EDIT PROFIL ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Aksi Edit Profil
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6), // Biru
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Edit Profil',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // --- 4. LIST MENU ---
            _buildMenuItem(
              icon: Icons.person_outline,
              title: 'Profil Saya',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              icon: Icons.settings_outlined,
              title: 'Pengaturan Akun',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              icon: Icons.description_outlined,
              title: 'Syarat & Ketentuan',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              icon: Icons.verified_user_outlined,
              title: 'Kebijakan Privasi',
              onTap: () {},
            ),
            const SizedBox(height: 24),

            // Menu Logout Spesial (Merah)
            _buildMenuItem(
              icon: Icons.logout,
              title: 'Keluar',
              isDestructive: true,
              onTap: () => _showLogoutDialog(context, authProvider),
            ),
          ],
        ),
      ),
    );
  }

  // --- KOMPONEN ITEM MENU ---
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    final Color itemColor = isDestructive
        ? const Color(0xFFFF766A)
        : Colors.black87;
    final Color bgColor = isDestructive
        ? const Color(0xFFFF766A).withValues(alpha: 0.1)
        : Colors.grey.shade100;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: itemColor, size: 22),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: itemColor,
              ),
            ),
            const Spacer(),
            if (!isDestructive)
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 24),
          ],
        ),
      ),
    );
  }
}
