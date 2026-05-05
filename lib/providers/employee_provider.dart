// lib/providers/employee_provider.dart

import 'package:flutter/material.dart';
import '../services/employee_service.dart';

class EmployeeProvider with ChangeNotifier {
  final EmployeeService _service = EmployeeService();

  List<Map<String, dynamic>> _teamMembers = [];
  Map<int, List<Map<String, dynamic>>> _memberAttendances = {};
  bool _isLoading = false;

  List<Map<String, dynamic>> get teamMembers => _teamMembers;
  bool get isLoading => _isLoading;

  // Mendapatkan presensi untuk ID tertentu dari cache
  List<Map<String, dynamic>> getAttendances(int employeeId) =>
      _memberAttendances[employeeId] ?? [];

  // Load daftar tim (panggil saat aplikasi pertama terbuka atau saat refresh)
  Future<void> fetchTeams() async {
    _isLoading = true;
    notifyListeners();
    try {
      _teamMembers = await _service.fetchTeamMembers();
    } catch (e) {
      debugPrint("Error Provider Teams: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tambahkan variabel state loading spesifik untuk halaman ini
  bool _isLoadingAttendances = false;
  bool get isLoadingAttendances => _isLoadingAttendances;

  Future<void> fetchAttendances(int employeeId, {int? month, int? year}) async {
    _isLoadingAttendances = true;
    notifyListeners(); // Beri tahu UI bahwa sedang loading

    try {
      final data = await _service.fetchMemberAttendances(
        employeeId: employeeId,
        month: month,
        year: year,
      );
      _memberAttendances[employeeId] = data;
    } catch (e) {
      debugPrint("Error Provider Attendance: $e");
    } finally {
      _isLoadingAttendances = false;
      notifyListeners(); // Matikan loading
    }
  }

  // 👇 Fungsi baru untuk membersihkan SEMUA data dari memori saat Logout
  void reset() {
    _teamMembers = [];
    _memberAttendances = {};
    _isLoading = false;
    notifyListeners();
  }
}
