import 'package:flutter/material.dart';

class AttendanceUpdateProvider extends ChangeNotifier {
  int _updateCount = 0;

  int get updateCount => _updateCount;

  // Fungsi ini dipanggil setelah pengguna berhasil absen
  void notifyUpdate() {
    _updateCount++;
    notifyListeners(); // Memberi sinyal ke semua layar yang mendengarkan
  }
}
