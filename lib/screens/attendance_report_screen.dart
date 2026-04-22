// lib/screens/attendance_report_screen.dart

import 'package:absensi_geo/screens/attendance_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
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
  // bool _isLoading = true;

  // Data State
  String _totalPresent = '00';
  String _totalLate = '00';
  String _totalAbsent = '00';
  List<dynamic> _attendanceHistory = [];

  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
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
      // Pass the selected dropdown values to the backend!
      final reportData = await _attendanceService.getMonthlyReport(
        token,
        _selectedMonth,
        _selectedYear,
      );

      if (mounted && reportData != null) {
        setState(() {
          // 1. Update the Summary Cards
          final stats = reportData['stats'];
          if (stats != null) {
            _totalPresent = stats['total_attendance'] ?? '00';
            _totalLate = stats['late_clock_in'] ?? '00';
            _totalAbsent = stats['no_clock_in'] ?? '00';
          }

          // 2. Update the List and Calendar View
          if (reportData['history'] != null) {
            _attendanceHistory = reportData['history'];
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.light[500],
      appBar: AppBar(
        backgroundColor: AppColors.white[500],
        elevation: 0,
        leading: IconButton(
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
        ),
        title: Text(
          'Attendance Report',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.dark[500],
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeaderFilters(),
              Expanded(
                child: SingleChildScrollView(
                  // 👇 Added bottom padding (100) so the content scrolls ABOVE the floating nav bar
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 16.0,
                    bottom: 100.0,
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

          // 👇 The Floating Bottom Navigation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNavBar(context),
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
          // Month Dropdown
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
          // Year Dropdown
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
        _buildStatCard(
          'Present',
          _totalPresent,
          AppColors.primary[500]!,
        ), // 🔵 Blue
        _buildStatCard('Late', _totalLate, Colors.green[500]!), // 🟢 Green
        _buildStatCard('Absent', _totalAbsent, Colors.red[500]!), // 🔴 Red
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
                color: numberColor, // Blue numbers as requested from Photo 2
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
              'Attendance History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.dark[500],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_attendanceHistory.length} records',
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
                  'Calendar',
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
            "No attendance records for this month.",
            style: TextStyle(color: AppColors.gray[500]),
          ),
        ),
      );
    }

    return Column(
      children: _attendanceHistory.map((record) {
        // 1. Get the exact color for this specific record
        Color statusColor = _getSemanticColor(record['status']);

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
                  // 2. Dynamic Colored Vertical Bar
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

                  // Date and Status
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
                              color: AppColors
                                  .dark[500], // Kept dark for readability
                            ),
                          ),
                          const SizedBox(height: 4),
                          // 3. Dynamic Colored Status Text
                          Text(
                            record['status'] ?? 'Reguler',
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

                  // Clock In
                  Expanded(
                    flex: 2,
                    child: _buildTimeDisplay(
                      'Clock In',
                      record['check_in'] ?? '-- : -- : --',
                    ),
                  ),
                  const VerticalDivider(
                    width: 1,
                    color: Color(0xFFEEEEEE),
                    thickness: 1,
                  ),

                  // Clock Out
                  Expanded(
                    flex: 2,
                    child: _buildTimeDisplay(
                      'Clock Out',
                      record['check_out'] ?? '-- : -- : --',
                    ),
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
    // Calculate the number of days and the starting weekday for the grid
    int daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    int firstWeekday = DateTime(_selectedYear, _selectedMonth, 1).weekday;
    // Dart's DateTime weekday puts Monday=1, Sunday=7. We want Sunday=0 for the grid offset.
    int emptyPrefix = firstWeekday == 7 ? 0 : firstWeekday;

    final List<String> weekdays = [
      'Sun',
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
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
          // Month & Year Header
          Text(
            '${_months[_selectedMonth - 1]} $_selectedYear',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.dark[500],
            ),
          ),
          const SizedBox(height: 20),

          // Weekday Labels
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

          // Calendar Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daysInMonth + emptyPrefix,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio:
                  0.75, // Adjusts the height of the cells to fit the pill
              crossAxisSpacing: 4,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              if (index < emptyPrefix) {
                return const SizedBox(); // Empty cell before the 1st of the month
              }

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
                        borderRadius: BorderRadius.circular(
                          4,
                        ), // Square pill like Photo 1
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

  // --- Helpers for Calendar Logic ---
  // Matches the specific day with the API history data or marks past weekdays as Absent
  String? _getDayStatus(int day) {
    // 1. Buat format YYYY-MM-DD yang 100% akurat (padLeft memastikan angka 8 menjadi '08')
    String expectedRawDate =
        "$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";

    // 2. Cek apakah user memiliki record absensi pada tanggal tersebut
    for (var record in _attendanceHistory) {
      // Cocokkan dengan raw_date dari database!
      if (record['raw_date'] == expectedRawDate) {
        return record['status'];
      }
    }

    // 3. Jika tidak ada record, cek apakah ini hari kerja di masa lalu (Senin-Jumat)
    DateTime dateToCheck = DateTime(_selectedYear, _selectedMonth, day);
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    // Jika tanggalnya sudah lewat dan BUKAN hari Sabtu/Minggu -> otomatis Absen (Merah)
    if (dateToCheck.isBefore(today) &&
        dateToCheck.weekday != DateTime.saturday &&
        dateToCheck.weekday != DateTime.sunday) {
      return 'Absen';
    }

    return null; // Hari di masa depan atau weekend yang belum terjadi dibiarkan kosong
  }

  /// Truncates the text to fit perfectly in the small calendar pill (Matching Photo 1)
  String _getShortStatusText(String status) {
    String s = status.toLowerCase();
    if (s.contains('hadir') || s.contains('reguler')) return 'Pre'; // Present
    if (s.contains('telat') || s.contains('late')) return 'Late';
    return 'Abse'; // Matches the "Abse" text in the red pills from Photo 1
  }

  // --- Universal Semantic Color Helper ---
  Color _getSemanticColor(String? status) {
    if (status == null) return Colors.redAccent; // Default to absent if null

    String s = status.toLowerCase();
    if (s.contains('hadir') || s.contains('reguler') || s.contains('present')) {
      return AppColors.primary[500]!; // blue for present
    } else if (s.contains('telat') || s.contains('late')) {
      return Colors.green[500]!; // Warning green for late
    } else {
      return Colors.red[500]!; // Danger Red (Absent)
    }
  }

  // --- Floating Bottom Navigation Bar ---
  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppColors.gradient2, // Uses your exact gradient from home
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary[500]!.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. Home -> Pops back to Home Screen
          _buildNavItem(
            Icons.home_outlined,
            onTap: () => Navigator.pop(context),
          ),

          // 2. Clock -> Pushes the Attendance Screen
          _buildNavItem(
            Icons.access_time_outlined,
            onTap: () {
              // Note: Make sure AttendanceScreen is imported at the top of this file!
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AttendanceScreen(),
                ),
              );
            },
          ),

          // 3. Calendar -> Currently Active! (No onTap needed)
          _buildNavItem(Icons.calendar_today_outlined, isSelected: true),

          // 4. Notifications
          _buildNavItem(Icons.notifications_none_outlined),

          // 5. Profile
          _buildNavItem(Icons.person_outline_outlined),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon, {
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            icon,
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.7),
            size: 26,
          ),
          if (isSelected)
            Positioned(
              bottom: -10,
              child: Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
