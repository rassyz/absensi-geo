// lib/services/leave_service.dart

import 'dart:convert';
import 'dart:io'; // 👇 Tambahkan import ini untuk menangani File
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:absensi_geo/services/base_api_service.dart';

class LeaveService extends BaseApiService {
  // --- Mengambil Data Dashboard Cuti ---
  Future<Map<String, dynamic>?> getLeaveDashboard(String token) async {
    try {
      final url = Uri.parse('${BaseApiService.baseUrl}/leaves/dashboard');
      final headers = await getHeaders(token);

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Gagal mengambil data cuti: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint("Error API Cuti: $e");
      return null;
    }
  }

  // --- Mengirim Pengajuan Cuti Baru (Dengan Attachment) ---
  Future<bool> submitLeaveRequest({
    required String token,
    required String leaveType,
    required String startDate,
    required String endDate,
    required int applyDays,
    required String reason,
    File? attachment, // File dokumen/foto (Opsional)
  }) async {
    try {
      // 1. Gunakan baseUrl dari BaseApiService
      final url = Uri.parse('${BaseApiService.baseUrl}/leaves/apply');

      // 2. Karena ada file, kita WAJIB menggunakan MultipartRequest (bukan http.post biasa)
      var request = http.MultipartRequest('POST', url);

      // 3. Ambil headers standar (Authorization & Accept) dari BaseApiService
      final headers = await getHeaders(token);
      request.headers.addAll(headers);

      // 4. Masukkan data teks ke dalam request fields
      request.fields['leave_type'] = leaveType;
      request.fields['start_date'] = startDate;
      request.fields['end_date'] = endDate;
      request.fields['apply_days'] = applyDays
          .toString(); // API biasanya butuh string di Multipart
      request.fields['reason'] = reason;

      // 5. Masukkan file attachment JIKA ADA
      if (attachment != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'attachment', // Pastikan nama key ini sama persis dengan yang di Laravel ($request->file('attachment'))
            attachment.path,
          ),
        );
      }

      // 6. Kirim Request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // 7. Cek Hasilnya
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint(
          "Gagal kirim cuti. Status: ${response.statusCode} Body: ${response.body}",
        );
        return false;
      }
    } catch (e) {
      debugPrint("Exception saat kirim cuti: $e");
      return false;
    }
  }

  // --- Proses Persetujuan/Penolakan Cuti oleh Manager ---
  Future<bool> processTeamLeave({
    required String token,
    required int leaveId,
    required String status, // 'Approved' atau 'Rejected'
  }) async {
    try {
      // URL ke backend Laravel Anda
      final url = Uri.parse(
        '${BaseApiService.baseUrl}/leaves/$leaveId/process',
      );

      final headers = await getHeaders(token);
      headers['Content-Type'] = 'application/json'; // Pastikan format JSON

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint("Gagal memproses cuti: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Exception saat memproses cuti: $e");
      return false;
    }
  }
}
