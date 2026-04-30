import 'package:flutter/material.dart';

enum OvertimeStatus { notStarted, inProgress, finished, unfinished }

class OvertimeModel {
  final int id;
  final String title;
  final String dateText;
  final String rawDate;
  final String timeText;
  final OvertimeStatus status;

  OvertimeModel({
    required this.id,
    required this.title,
    required this.dateText,
    required this.rawDate,
    required this.timeText,
    required this.status,
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

    return OvertimeModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Tanpa Judul',
      dateText: json['date'] ?? '',
      rawDate: json['raw_date'] ?? '',
      timeText: '${json['planned_start_time']} - ${json['planned_end_time']}',
      status: parsedStatus,
    );
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
