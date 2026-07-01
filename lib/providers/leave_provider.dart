import 'package:flutter/material.dart';
import '../services/leave_service.dart';
import '../core/utils/app_logger.dart';

class LeaveProvider extends ChangeNotifier {
  final LeaveService _service = LeaveService();

  Map<String, String> summary = {
    'balance': '0',
    'approved': '0',
    'pending': '0',
    'cancelled': '0',
  };

  List<dynamic> allLeaves = [];
  List<dynamic> teamLeaves = [];

  List<Map<String, dynamic>> leaveTypes = [];

  bool isLoaded = false;
  bool isFetching = false;

  bool isTypesLoaded = false;
  bool isFetchingTypes = false;

  // Fungsi untuk mengambil data (bisa dipanggil di background)
  Future<void> fetchLeaveData(String token, {bool forceRefresh = false}) async {
    if (isLoaded && !forceRefresh) return; // Gunakan cache jika sudah ada

    isFetching = true;
    notifyListeners();

    try {
      final data = await _service.getLeaveDashboard(token);

      if (data != null && data['success'] == true) {
        summary = {
          'balance': data['summary']['balance'].toString(),
          'approved': data['summary']['approved'].toString(),
          'pending': data['summary']['pending'].toString(),
          'cancelled': data['summary']['cancelled'].toString(),
        };
        allLeaves = data['leaves'] ?? [];
        teamLeaves = data['team_leaves'] ?? [];
        isLoaded = true;
      }
    } catch (e) {
      AppLogger.error('Error fetching leave data', error: e);
    } finally {
      isFetching = false;
      notifyListeners(); // Update UI
    }
  }

  // 👇 TAMBAHAN BARU: Fungsi untuk mengambil data master tipe cuti
  Future<void> fetchLeaveTypes(
    String token, {
    bool forceRefresh = false,
  }) async {
    if (isTypesLoaded && !forceRefresh) return; // Gunakan cache jika sudah ada

    isFetchingTypes = true;
    notifyListeners();

    try {
      final types = await _service.getLeaveTypes(token);
      if (types != null) {
        leaveTypes = types;
        isTypesLoaded = true;
      }
    } catch (e) {
      AppLogger.error('Error fetching leave types', error: e);
    } finally {
      isFetchingTypes = false;
      notifyListeners();
    }
  }

  // Fungsi pembantu untuk menghapus cuti tim dari daftar setelah di-approve/reject
  void removeTeamLeave(int leaveId) {
    teamLeaves.removeWhere((leave) => leave['id'] == leaveId);
    notifyListeners();
  }

  // 👇 ADD THIS FUNCTION TO RESET MEMORY ON LOGOUT
  void reset() {
    summary = {
      'balance': '0',
      'approved': '0',
      'pending': '0',
      'cancelled': '0',
    };
    allLeaves = [];
    teamLeaves = [];
    leaveTypes = [];
    isTypesLoaded = false;
    isFetchingTypes = false;
    isLoaded = false;
    isFetching = false;
    notifyListeners();
  }
}
