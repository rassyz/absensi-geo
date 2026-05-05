// lib/screens/member_attendance_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/employee_provider.dart';

class MemberAttendanceScreen extends StatefulWidget {
  final int employeeId;
  final String employeeName;

  const MemberAttendanceScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  State<MemberAttendanceScreen> createState() => _MemberAttendanceScreenState();
}

class _MemberAttendanceScreenState extends State<MemberAttendanceScreen> {
  // Secara default, set ke bulan dan tahun saat ini
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  // Fungsi untuk memunculkan modal filter
  void _showFilterModal() {
    // 👇 Daftar nama bulan dalam bahasa Indonesia
    final List<String> monthNames = [
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

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Presensi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            labelText: 'Bulan',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          initialValue: _selectedMonth,
                          items: List.generate(12, (index) {
                            return DropdownMenuItem(
                              value: index + 1,
                              // 👇 Menggunakan nama bulan dari list di atas
                              child: Text(monthNames[index]),
                            );
                          }),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => _selectedMonth = val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            labelText: 'Tahun',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          initialValue: _selectedYear,
                          items: List.generate(3, (index) {
                            int year = DateTime.now().year - 2 + index;
                            return DropdownMenuItem(
                              value: year,
                              child: Text(year.toString()),
                            );
                          }),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => _selectedYear = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {});
                        context.read<EmployeeProvider>().fetchAttendances(
                          widget.employeeId,
                          month: _selectedMonth,
                          year: _selectedYear,
                        );
                      },
                      child: const Text(
                        'Terapkan Filter',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final employeeProvider = context.watch<EmployeeProvider>();
    final attendances = employeeProvider.getAttendances(widget.employeeId);

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
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        actions: [
          // 👇 Tombol Filter menggunakan icon tune
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.black87),
            onPressed: _showFilterModal,
          ),
        ],
      ),
      // 👇 Gunakan indikator spesifik agar tidak terpengaruh loading halaman lain
      body: employeeProvider.isLoadingAttendances
          ? const Center(child: CircularProgressIndicator())
          : attendances.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.insert_drive_file_outlined,
                    size: 60,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Tidak ada data untuk bulan $_selectedMonth/$_selectedYear.",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: attendances.length,
              itemBuilder: (context, index) {
                final record = attendances[index];
                return _AttendanceCard(record: record);
              },
            ),
    );
  }
}

// ==========================================
// WIDGET BANTUAN TETAP SAMA SEPERTI MILIK ANDA
// ==========================================
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
      return timeString;
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
        Expanded(
          child: Text(
            time,
            style: TextStyle(
              fontSize: 16,
              color: timeColor,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
