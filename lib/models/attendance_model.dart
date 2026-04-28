class AttendanceModel {
  final int id;
  final String date;
  final String? clockIn; // 👈 Wajib pakai tanda tanya (?)
  final String? clockOut; // 👈 Wajib pakai tanda tanya (?)
  final String status;

  AttendanceModel({
    required this.id,
    required this.date,
    this.clockIn,
    this.clockOut,
    required this.status,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'],
      date: json['date'] ?? '',
      // 👇 Jangan dipaksa jadi String jika nilainya bisa null
      clockIn: json['clock_in'],
      clockOut: json['clock_out'],
      status: json['status'] ?? 'Hadir',
    );
  }
}
