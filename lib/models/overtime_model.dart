import 'package:flutter/material.dart';

enum OvertimeStatus { notStarted, inProgress, finished, unfinished }

class OvertimeModel {
  final int id;
  final String title;
  final String dateText;
  final String rawDate;
  final String timeText;
  final OvertimeStatus status;
  final String? actualStartTime;
  final String? actualEndTime;

  OvertimeModel({
    required this.id,
    required this.title,
    required this.dateText,
    required this.rawDate,
    required this.timeText,
    required this.status,
    this.actualStartTime,
    this.actualEndTime,
  });

  // Fungsi konversi dari JSON Laravel ke Object Flutter
  factory OvertimeModel.fromJson(Map<String, dynamic> json) {
    OvertimeStatus parsedStatus = OvertimeStatus.notStarted;

    if (json['status'] == 'Selesai') {
      parsedStatus = OvertimeStatus.finished;
    } else if (json['status'] == 'Sedang Lembur') {
      parsedStatus = OvertimeStatus.inProgress;
    } else if (json['status'] == 'Pending') {
      parsedStatus = OvertimeStatus.notStarted;
    }

    // 👇 2. Ambil waktu aktual dari respons JSON Laravel Anda
    String? startActual = json['actual_check_in'];
    String? endActual = json['actual_check_out'];

    // Jika format dari API adalah datetime penuh (2026-05-05 17:15:00),
    // kita potong agar hanya mengambil jam dan menitnya saja (17:15)
    if (startActual != null && startActual.length > 5) {
      // Jika formatnya sudah "17:15", abaikan pemotongan ini.
      if (startActual.contains(':') && startActual.split(':').length == 3) {
        startActual = startActual.substring(0, 5);
      }
    }
    if (endActual != null && endActual.length > 5) {
      if (endActual.contains(':') && endActual.split(':').length == 3) {
        endActual = endActual.substring(0, 5);
      }
    }

    return OvertimeModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Tanpa Judul',
      dateText: json['date'] ?? '',
      rawDate: json['raw_date'] ?? '',
      timeText: '${json['planned_start_time']} - ${json['planned_end_time']}',
      status: parsedStatus,
      actualStartTime: startActual, // Masukkan ke model
      actualEndTime: endActual, // Masukkan ke model
    );
  }

  // 👇 3. Tambahkan Helper ini agar UI tinggal memanggil entry.actualTimeText
  String get actualTimeText {
    if (actualStartTime != null && actualStartTime!.isNotEmpty) {
      String start = actualStartTime!;
      String end = (actualEndTime != null && actualEndTime!.isNotEmpty)
          ? actualEndTime!
          : 'Berjalan'; // Jika sedang lembur dan belum absen keluar

      return '$start - $end';
    } else if (status == OvertimeStatus.notStarted) {
      return 'Belum dimulai';
    }
    return '--:-- - --:--';
  }

  // Helper untuk UI
  String get statusText {
    switch (status) {
      case OvertimeStatus.notStarted:
        return 'Belum Mulai';
      case OvertimeStatus.inProgress:
        return 'Sedang Lembur';
      case OvertimeStatus.finished:
        return 'Selesai';
      case OvertimeStatus.unfinished:
        return 'Tidak Selesai';
    }
  }

  Color get badgeColor {
    switch (status) {
      case OvertimeStatus.notStarted:
        return Colors.grey[300]!;
      case OvertimeStatus.inProgress:
        return Colors.orange[100]!;
      case OvertimeStatus.finished:
        return const Color(0xFFC8E6C9);
      case OvertimeStatus.unfinished:
        return Colors.red[100]!;
    }
  }

  Color get statusTextColor {
    switch (status) {
      case OvertimeStatus.notStarted:
        return Colors.black87;
      case OvertimeStatus.inProgress:
        return Colors.orange[900]!;
      case OvertimeStatus.finished:
        return const Color(0xFF1B5E20);
      case OvertimeStatus.unfinished:
        return Colors.red[900]!;
    }
  }
}
