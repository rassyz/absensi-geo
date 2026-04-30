import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import 'package:absensi_geo/theme/app_colors.dart';
import 'package:absensi_geo/providers/auth_provider.dart';
import 'package:absensi_geo/providers/overtime_provider.dart';
import '../models/overtime_model.dart';
import '../services/overtime_service.dart';

class OvertimeScreen extends StatelessWidget {
  const OvertimeScreen({super.key});

  // --- FUNGSI MENDAPATKAN LOKASI (GPS) ---
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Uji apakah layanan lokasi diaktifkan.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Layanan lokasi dinonaktifkan. Harap nyalakan GPS.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Izin lokasi ditolak pengguna.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Izin lokasi ditolak secara permanen, kita tidak dapat meminta izin.',
      );
    }

    // Mengambil posisi saat ini dengan akurasi tinggi (Penting untuk validasi PostGIS)
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // --- FUNGSI UNTUK TOMBOL MULAI/AKHIRI LEMBUR ---
  Future<void> _handleOvertimeAction(
    BuildContext context,
    OvertimeModel entry,
  ) async {
    final bool isClockIn = entry.status == OvertimeStatus.notStarted;
    final String actionName = isClockIn ? 'Mulai' : 'Akhiri';

    // 1. Tampilkan Loading Dialog agar user tidak klik tombol berkali-kali
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Row(
            children: [
              CircularProgressIndicator(color: AppColors.primary[500]),
              const SizedBox(width: 20),
              Expanded(child: Text("Memproses $actionName Lembur...")),
            ],
          ),
        );
      },
    );

    try {
      // 2. Ambil Kordinat GPS
      Position position = await _determinePosition();

      // 3. Ambil Token dari Provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.user?.token;

      if (token == null)
        throw Exception("Sesi telah habis, silakan login ulang.");

      // 4. Panggil API melalui OvertimeService
      final overtimeService = OvertimeService();
      bool success = false;

      if (isClockIn) {
        success = await overtimeService.clockInOvertime(
          token: token,
          overtimeId: entry.id,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } else {
        success = await overtimeService.clockOutOvertime(
          token: token,
          overtimeId: entry.id,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }

      // 5. Tutup Dialog Loading
      if (context.mounted) Navigator.pop(context);

      // 6. Tangani Hasilnya
      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Berhasil $actionName Lembur!'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh data Provider agar UI berubah seketika (tombol Mulai jadi Akhiri/Selesai)
          await Provider.of<OvertimeProvider>(
            context,
            listen: false,
          ).fetchOvertimes(token, forceRefresh: true);
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mencatat lembur. Coba lagi.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Tutup Dialog Loading jika terjadi error
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        String cleanMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cleanMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // --- TAMPILAN UTAMA (SCAFFOLD) ---
  @override
  Widget build(BuildContext context) {
    final overtimeProvider = Provider.of<OvertimeProvider>(context);
    final currentOvertime = overtimeProvider.currentOvertime;
    final upcomingOvertimes = overtimeProvider.upcomingOvertimes;

    return Scaffold(
      backgroundColor: AppColors.light[500],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lembur Saya',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary[500],
        onRefresh: () async {
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          final token = authProvider.user?.token;

          if (token != null) {
            await overtimeProvider.fetchOvertimes(token, forceRefresh: true);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // --- BAGIAN LEMBUR HARI INI ---
              if (currentOvertime != null) ...[
                _buildSectionHeader('Lembur Hari Ini'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildTodayOvertimeCard(context, currentOvertime),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildActionButton(context, currentOvertime),
                ),
                const SizedBox(height: 24),
              ] else if (overtimeProvider.isLoaded) ...[
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'Tidak ada jadwal lembur saat ini.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                ),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],

              // --- BAGIAN RIWAYAT / MENDATANG ---
              if (upcomingOvertimes.isNotEmpty) ...[
                _buildSectionHeader('Riwayat Lembur'),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  itemCount: upcomingOvertimes.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildHistoryCard(context, upcomingOvertimes[index]);
                  },
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.black87, size: 22),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // --- KARTU LEMBUR UTAMA ---
  Widget _buildTodayOvertimeCard(BuildContext context, OvertimeModel entry) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment, color: Colors.black87, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.calendar_month, entry.dateText),
            const SizedBox(height: 14),
            _buildInfoRow(Icons.access_time_filled, entry.timeText),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.circle, color: Colors.grey, size: 22),
                const SizedBox(width: 12),
                _buildStatusBadge(
                  entry.statusText,
                  entry.badgeColor,
                  entry.statusTextColor,
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  // --- TOMBOL AKSI UTAMA ---
  Widget _buildActionButton(BuildContext context, OvertimeModel entry) {
    bool isFinished = entry.status == OvertimeStatus.finished;
    bool inProgress = entry.status == OvertimeStatus.inProgress;

    String buttonText = 'Mulai Lembur';
    if (isFinished) buttonText = 'Lembur Selesai';
    if (inProgress) buttonText = 'Akhiri Lembur';

    return InkWell(
      onTap: isFinished ? null : () => _handleOvertimeAction(context, entry),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isFinished ? Colors.grey[400] : AppColors.primary[500],
          borderRadius: BorderRadius.circular(14),
          boxShadow: isFinished
              ? []
              : [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: Text(
            buttonText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  // --- KARTU RIWAYAT ---
  Widget _buildHistoryCard(BuildContext context, OvertimeModel entry) {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.dateText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.timeText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _buildStatusBadge(
              entry.statusText,
              entry.badgeColor,
              entry.statusTextColor,
            ),
          ],
        ),
      ),
    );
  }
}
