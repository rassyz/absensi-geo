// lib/screens/member_attendance_screen.dart

import 'package:flutter/material.dart';
import '../services/employee_service.dart';

class MemberAttendanceScreen extends StatefulWidget {
  final int employeeId;
  final String employeeName;

  // 👇 Konstruktor murni tanpa token
  const MemberAttendanceScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  // ignore: library_private_types_in_public_api
  _MemberAttendanceScreenState createState() => _MemberAttendanceScreenState();
}

class _MemberAttendanceScreenState extends State<MemberAttendanceScreen> {
  final EmployeeService _employeeService = EmployeeService();
  late Future<List<Map<String, dynamic>>> _memberAttendances;

  @override
  void initState() {
    super.initState();
    // 👇 Panggil fungsi service secara langsung
    _memberAttendances = _employeeService.fetchMemberAttendances(
      employeeId: widget.employeeId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
        title: Text(
          widget.employeeName,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _memberAttendances,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final errorString = snapshot.error.toString();
            if (errorString.contains("Unauthorized")) {
              return _buildUnauthorizedView();
            } else {
              return Center(
                child: Text("Gagal memuat data: ${snapshot.error}"),
              );
            }
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Tidak ada data presensi."));
          }

          final attendances = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: attendances.length,
            itemBuilder: (context, index) {
              final record = attendances[index];
              return _AttendanceCard(record: record);
            },
          );
        },
      ),
    );
  }

  Widget _buildUnauthorizedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, color: Colors.red[300], size: 80),
            const SizedBox(height: 24),
            const Text(
              'Akses Dibatasi',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Anda hanya dapat melihat data presensi untuk anggota tim Anda sendiri.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final Map<String, dynamic> record;

  const _AttendanceCard({required this.record});

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Tanggal Tidak Diketahui';
    try {
      final dt = DateTime.parse(dateString).toLocal();
      const monthNames = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      return '${dt.day} ${monthNames[dt.month - 1]} ${dt.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(String? timeString) {
    if (timeString == null || timeString == '--:--') return '--:--';
    try {
      final dt = DateTime.parse(timeString).toLocal();
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return timeString; // Tampilkan aslinya jika gagal parsing
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentStatus =
        record['status']?.toString().toLowerCase() ?? '';

    bool isInactive =
        currentStatus == 'future_date' || currentStatus == 'absent';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 8,
                decoration: BoxDecoration(
                  // 👇 Garis kiri berubah jadi abu-abu jika isInactive true
                  color: isInactive ? Colors.grey[300] : Colors.blue[400],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 20.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(record['date']),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _TimeBox(
                              icon: Icons.login,
                              time: _formatTime(record['check_in']),
                              // 👇 Ikon dan teks jam juga ikut jadi abu-abu
                              iconColor: isInactive ? Colors.grey : Colors.blue,
                              timeColor: isInactive
                                  ? Colors.grey[500]
                                  : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _TimeBox(
                              icon: Icons.logout,
                              time: _formatTime(record['check_out']),
                              // 👇 Ikon dan teks jam juga ikut jadi abu-abu
                              iconColor: isInactive ? Colors.grey : Colors.blue,
                              timeColor: isInactive
                                  ? Colors.grey[500]
                                  : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  final IconData icon;
  final String time;
  final Color iconColor;
  final Color? timeColor;

  const _TimeBox({
    required this.icon,
    required this.time,
    required this.iconColor,
    this.timeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 8),
        // 👇 Gunakan Expanded dan TextOverflow
        Expanded(
          child: Text(
            time,
            style: TextStyle(
              fontSize: 16,
              color: timeColor,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow
                .ellipsis, // Mencegah error overflow secara permanen
          ),
        ),
      ],
    );
  }
}
