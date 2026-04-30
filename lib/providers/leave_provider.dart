import 'package:flutter/material.dart';
import '../services/leave_service.dart';

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

  bool isLoaded = false;
  bool isFetching = false;

  // Fungsi untuk mengambil data (bisa dipanggil di background)
  Future<void> fetchLeaveData(String token, {bool forceRefresh = false}) async {
    if (isLoaded && !forceRefresh) return; // Gunakan cache jika sudah ada

    isFetching = true;

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
      debugPrint('Error fetching leave data: $e');
    } finally {
      isFetching = false;
      notifyListeners(); // Update UI
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
    isLoaded = false;
    isFetching = false;
    notifyListeners();
  }
}
