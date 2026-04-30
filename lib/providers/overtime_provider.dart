import 'package:flutter/material.dart';
import '../models/overtime_model.dart';
import '../services/overtime_service.dart';

class OvertimeProvider extends ChangeNotifier {
  final OvertimeService _service = OvertimeService();

  OvertimeModel? currentOvertime;
  List<OvertimeModel> upcomingOvertimes = [];

  bool isLoaded = false; // Menandakan apakah data sudah pernah diambil
  bool isFetching = false; // Menandakan sedang proses ambil data (background)

  Future<void> fetchOvertimes(String token, {bool forceRefresh = false}) async {
    if (isLoaded && !forceRefresh) return;

    isFetching = true;

    try {
      List<OvertimeModel>? data = await _service.fetchOvertimes(token);

      if (data != null) {
        if (data.isNotEmpty) {
          // 👇 1. Ambil tanggal HP hari ini dengan format Y-m-d
          final String todayStr = DateTime.now().toIso8601String().substring(
            0,
            10,
          );

          // 👇 2. Filter Ketat: Harus HARI INI dan statusnya AKTIF
          try {
            currentOvertime = data.firstWhere(
              (item) =>
                  item.rawDate == todayStr &&
                  (item.status == OvertimeStatus.notStarted ||
                      item.status == OvertimeStatus.inProgress),
            );
          } catch (e) {
            currentOvertime = null; // Kosongkan jika tidak ada lembur hari ini
          }

          // 👇 3. Sisanya masuk ke Riwayat (Jadwal kemarin, jadwal besok, atau jadwal hari ini yang SUDAH SELESAI)
          if (currentOvertime != null) {
            upcomingOvertimes = data
                .where((item) => item.id != currentOvertime!.id)
                .toList();
          } else {
            upcomingOvertimes = data;
          }
        } else {
          currentOvertime = null;
          upcomingOvertimes = [];
        }
        isLoaded = true;
      }
    } catch (e) {
      debugPrint('Error fetching overtime in provider: $e');
    } finally {
      isFetching = false;
      notifyListeners();
    }
  }

  // 👇 ADD THIS FUNCTION TO RESET MEMORY ON LOGOUT
  void reset() {
    currentOvertime = null;
    upcomingOvertimes = [];
    isLoaded = false;
    isFetching = false;
    notifyListeners();
  }
}
