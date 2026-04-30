// lib/screens/attendance_report_screen.dart

import 'package:absensi_geo/providers/attendance_update_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:absensi_geo/providers/auth_provider.dart';
import 'package:absensi_geo/services/attendance_service.dart';
import 'package:absensi_geo/theme/app_colors.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  final AttendanceService _attendanceService = AttendanceService();

  // Filter State
  late int _selectedMonth;
  late int _selectedYear;

  // View State
  bool _isListView = true;

  // Data State
  String _totalPresent = '00';
  String _totalLate = '00';
  String _totalAbsent = '00';
  List<dynamic> _attendanceHistory = [];
  int _lastUpdateCount = 0;

  final List<String> _months = [
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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;

    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.user?.token;

    if (token != null) {
      final reportData = await _attendanceService.getMonthlyReport(
        token,
        _selectedMonth,
        _selectedYear,
      );

      if (mounted && reportData != null) {
        setState(() {
          final stats = reportData['stats'];
          if (stats != null) {
            _totalPresent = stats['total_attendance'] ?? '00';
            _totalLate = stats['late_clock_in'] ?? '00';
            _totalAbsent = stats['no_clock_in'] ?? '00';
          }

          if (reportData['history'] != null) {
            _attendanceHistory = reportData['history'];
          }
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Dengarkan provider (tanpa mengubah UI secara paksa)
    final updateCount = Provider.of<AttendanceUpdateProvider>(
      context,
    ).updateCount;

    // Jika jumlah update bertambah (artinya baru saja absen)
    if (updateCount > _lastUpdateCount) {
      _lastUpdateCount = updateCount;
      _fetchReportData(); // Ambil ulang data dari server secara diam-diam!
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light[500],
      appBar: AppBar(
        backgroundColor: AppColors.white[500],
        elevation: 0,
        // 👇 SMART BACK BUTTON 👇
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gray[10],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 16,
                    color: AppColors.dark[500],
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null, // Automatically hides the button if it's a Tab!
        title: Text(
          'Data Presensi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.dark[500],
          ),
        ),
        centerTitle: true,
      ),
      // 👇 Stack removed! Just a clean Column holding the filters and list.
      body: Column(
        children: [
          _buildHeaderFilters(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom:
                    100.0, // Ensures content scrolls ABOVE the floating nav bar
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildHistoryHeader(),
                  const SizedBox(height: 16),
                  _isListView ? _buildListView() : _buildCalendarView(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. Header Dropdown Filters ---
  Widget _buildHeaderFilters() {
    return Container(
      color: AppColors.white[500],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.dark05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedMonth,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, color: AppColors.dark[500]),
                  items: List.generate(12, (index) {
                    return DropdownMenuItem(
                      value: index + 1,
                      child: Text(
                        _months[index],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedMonth = value);
                      _fetchReportData();
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.dark05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedYear,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, color: AppColors.dark[500]),
                  items: [2024, 2025, 2026].map((year) {
                    return DropdownMenuItem(
                      value: year,
                      child: Text(
                        year.toString(),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedYear = value);
                      _fetchReportData();
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Summary Cards ---
  Widget _buildSummaryCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatCard('Hadir', _totalPresent, AppColors.primary[500]!),
        _buildStatCard('Terlambat', _totalLate, Colors.green[500]!),
        _buildStatCard('Tidak Hadir', _totalAbsent, Colors.red[500]!),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color numberColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white[500],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.dark05,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: numberColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.gray[500],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. View Switcher Header ---
  Widget _buildHistoryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Riwayat Presensi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.dark[500],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_attendanceHistory.length} hari tercatat',
              style: TextStyle(color: AppColors.gray[500], fontSize: 12),
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _isListView = true),
              child: Text(
                'List',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _isListView
                      ? AppColors.dark[500]
                      : AppColors.gray[500],
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => setState(() => _isListView = false),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: !_isListView
                      ? AppColors.primary[500]
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Kalender',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: !_isListView
                        ? AppColors.white[500]
                        : AppColors.gray[500],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- 4. The Photo 3 Styled List View ---
  Widget _buildListView() {
    if (_attendanceHistory.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Text(
            "Tidak ada catatan presensi untuk bulan ini.",
            style: TextStyle(color: AppColors.gray[500]),
          ),
        ),
      );
    }

    return Column(
      children: _attendanceHistory.map((record) {
        String status = record['status'] ?? 'Unknown';
        Color statusColor = _getSemanticColor(status);

        // 👇 LOGIKA N/A SEPERTI DI HOME SCREEN 👇
        String rawClockIn = record['check_in']?.toString() ?? '';
        String rawClockOut = record['check_out']?.toString() ?? '';

        // 1. Jika clock-in kosong/null, langsung jadikan 'N/A'
        String clockInDisplay = (rawClockIn.isEmpty || rawClockIn == 'null')
            ? 'N/A'
            : rawClockIn;

        // 2. Jika clock-out kosong/null:
        //    - Kalau clock-in juga 'N/A' (alpha) -> jadikan 'N/A'
        //    - Kalau clock-in ada isinya (sedang bekerja) -> jadikan '-- : -- : --'
        String clockOutDisplay = (rawClockOut.isEmpty || rawClockOut == 'null')
            ? (clockInDisplay == 'N/A' ? 'N/A' : '-- : -- : --')
            : rawClockOut;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white[500],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.dark05,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 6,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record['date'] ?? 'Unknown Date',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.dark[500],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(
                    width: 1,
                    color: Color(0xFFEEEEEE),
                    thickness: 1,
                  ),
                  Expanded(
                    flex: 2,
                    child: _buildTimeDisplay(
                      'Masuk',
                      clockInDisplay,
                    ), // 👈 Gunakan variabel N/A
                  ),
                  const VerticalDivider(
                    width: 1,
                    color: Color(0xFFEEEEEE),
                    thickness: 1,
                  ),
                  Expanded(
                    flex: 2,
                    child: _buildTimeDisplay(
                      'Keluar',
                      clockOutDisplay,
                    ), // 👈 Gunakan variabel N/A
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeDisplay(String label, String time) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 6),
        Text(
          time,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  // --- Placeholder for Calendar View ---
  Widget _buildCalendarView() {
    int daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    int firstWeekday = DateTime(_selectedYear, _selectedMonth, 1).weekday;
    int emptyPrefix = firstWeekday == 7 ? 0 : firstWeekday;

    final List<String> weekdays = [
      'Min',
      'Sen',
      'Sel',
      'Rab',
      'Kam',
      'Jum',
      'Sab',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white[500],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark05,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${_months[_selectedMonth - 1]} $_selectedYear',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.dark[500],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark[500],
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daysInMonth + emptyPrefix,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.75,
              crossAxisSpacing: 4,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              if (index < emptyPrefix) return const SizedBox();

              int day = index - emptyPrefix + 1;
              String? status = _getDayStatus(day);

              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark[500],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (status != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _getSemanticColor(status),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getShortStatusText(status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String? _getDayStatus(int day) {
    String expectedRawDate =
        "$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";

    for (var record in _attendanceHistory) {
      if (record['raw_date'] == expectedRawDate) {
        return record['status'];
      }
    }

    DateTime dateToCheck = DateTime(_selectedYear, _selectedMonth, day);
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    if (dateToCheck.isBefore(today) &&
        dateToCheck.weekday != DateTime.saturday &&
        dateToCheck.weekday != DateTime.sunday) {
      return 'Absen';
    }

    return null;
  }

  String _getShortStatusText(String status) {
    String s = status.toLowerCase();
    if (s.contains('hadir') || s.contains('reguler')) return 'Hadir';
    if (s.contains('telat') || s.contains('late')) return 'Telat';
    return 'Absen';
  }

  Color _getSemanticColor(String? status) {
    if (status == null) return Colors.redAccent;

    String s = status.toLowerCase();
    if (s.contains('hadir') || s.contains('reguler') || s.contains('present')) {
      return AppColors.primary[500]!;
    } else if (s.contains('telat') || s.contains('late')) {
      return Colors.green[500]!;
    } else {
      return Colors.red[500]!;
    }
  }
}
