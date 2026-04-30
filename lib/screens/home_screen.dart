// lib/screens/home_screen.dart

import 'package:absensi_geo/providers/attendance_update_provider.dart';
import 'package:absensi_geo/providers/leave_provider.dart';
import 'package:absensi_geo/providers/overtime_provider.dart';
import 'package:absensi_geo/screens/overtime_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:absensi_geo/providers/auth_provider.dart';
import 'package:absensi_geo/services/attendance_service.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:absensi_geo/screens/attendance_report_screen.dart';
import 'package:absensi_geo/screens/leave_request_screen.dart';
import 'package:absensi_geo/screens/profile_screen.dart';

// --- Inline Color/Theme Definitions ---
class AppColors {
  AppColors._();

  static const Map<int, Color> primary = {
    500: Color(0xFF2979FF),
    700: Color(0xFF1976D2),
  };

  static final MaterialColor primarySwatch = MaterialColor(
    primary[500]!.toARGB32(),
    primary,
  );

  static const Map<int, Color> secondary = {500: Color(0xFFA4CD39)};

  static final MaterialColor secondarySwatch = MaterialColor(
    secondary[500]!.toARGB32(),
    secondary,
  );

  static const Map<int, Color> dark = {500: Color(0xFF000000)};
  static const Map<int, Color> gray = {500: Color(0xFFA1A1A1)};
  static const Map<int, Color> light = {500: Color(0xFFF0F0F0)};
  static const Map<int, Color> white = {500: Color(0xFFFFFFFF)};

  static Color get dark05 => dark[500]!.withValues(alpha: 0.05);

  static const LinearGradient gradient2 = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [
      Color(0xFF16A085), // Start Teal
      Color(0xFF4285F4), // End Clear Blue
    ],
  );
}

class AppTheme {
  AppTheme._();
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: AppColors.primarySwatch,
        backgroundColor: AppColors.light[500],
      ).copyWith(surface: AppColors.white[500], onSurface: AppColors.dark[500]),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.dark[500],
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
// --- End of Inline definitions ---

void main() {
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Presensi Mobile',
      theme: AppTheme.lightTheme(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AttendanceService _attendanceService = AttendanceService();

  List<dynamic> _recentAttendances = [];
  String _clockInTime = '-- : -- : --';
  String _clockOutTime = '-- : -- : --';
  String _totalAttendance = '--';
  String _lateClockIn = '--';
  String _noClockIn = '--';
  int _lastUpdateCount = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.user?.token;

      if (token != null) {
        Provider.of<OvertimeProvider>(
          context,
          listen: false,
        ).fetchOvertimes(token);
        Provider.of<LeaveProvider>(
          context,
          listen: false,
        ).fetchLeaveData(token);
      }
    });

    _fetchHomeData();
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
      _fetchHomeData(); // Ambil ulang data dari server secara diam-diam!
    }
  }

  Future<void> _fetchHomeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.user?.token;

    if (token != null) {
      final statusData = await _attendanceService.getTodayAttendanceStatus(
        token,
      );
      final statsData = await _attendanceService.getMonthlyStats(token);
      final historyData = await _attendanceService.getAttendanceHistory(token);

      if (mounted) {
        setState(() {
          if (statusData != null && statusData['success'] == true) {
            // Mengambil key check_in dari API, tapi menyimpannya ke variabel clock_in
            bool hasClockedIn = statusData['has_checked_in'] ?? false;
            bool hasClockedOut = statusData['has_checked_out'] ?? false;

            _clockInTime = hasClockedIn
                ? (statusData['check_in_time'] ?? '-- : -- : --')
                : '-- : -- : --';
            _clockOutTime = hasClockedOut
                ? (statusData['check_out_time'] ?? '-- : -- : --')
                : '-- : -- : --';
          }

          if (statsData != null && statsData['success'] == true) {
            _totalAttendance = statsData['total_attendance'] ?? '--';
            _lateClockIn = statsData['late_clock_in'] ?? '--';
            _noClockIn = statsData['no_clock_in'] ?? '--';
          }

          if (historyData != null) {
            // Plester Darurat: Filter data duplikat berdasarkan tanggal
            var uniqueAttendances = [];
            var seenDates = <String>{};

            for (var record in historyData) {
              String date = record['date']?.toString() ?? '';

              if (!seenDates.contains(date)) {
                seenDates.add(date);
                uniqueAttendances.add(record);
              }
            }

            _recentAttendances = uniqueAttendances;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchHomeData,
          color: AppColors.primary[500],
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 12.0,
              bottom: 100.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusGreeting(
                  context,
                  authProvider,
                  user?.employee?.fullName ?? 'Tamu',
                ),
                const SizedBox(height: 20),
                _buildSearchFilterBar(),
                const SizedBox(height: 24),
                _buildMainGradientCard(context),
                const SizedBox(height: 24),
                _buildSummaryStatsRow(),
                const SizedBox(height: 28),
                _buildCategorySection(context),
                const SizedBox(height: 28),
                _buildAttendanceDataSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusGreeting(
    BuildContext context,
    AuthProvider authProvider,
    String userName,
  ) {
    final String? avatarUrl = authProvider.user?.avatarUrl;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              _getGreeting(),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              '$userName!',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primarySwatch[500]!,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null
                  ? const Icon(Icons.person, color: Colors.white, size: 24)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchFilterBar() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.dark05),
          ),
          child: Icon(Icons.tune, color: AppColors.primarySwatch[500]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.dark05),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Cari...',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainGradientCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.gradient2,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primarySwatch[500]!.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const LiveDateClock(),
              Row(
                children: [
                  const Icon(
                    Icons.history_toggle_off,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '09.00 - 17.00',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 12,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildClockCard('MASUK', _clockInTime)),
              const SizedBox(width: 16),
              Expanded(child: _buildClockCard('KELUAR', _clockOutTime)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClockCard(String title, String time) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 18, color: AppColors.primarySwatch[500]),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            time,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primarySwatch[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatColumn('Hadir', _totalAttendance),
        _buildStatColumn('Terlambat', _lateClockIn),
        _buildStatColumn('Tidak Hadir', _noClockIn),
      ],
    );
  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 6),
        Text(
          count,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.primarySwatch[500],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(BuildContext context) {
    return Column(
      children: [
        _buildHeaderRow('Kategori'),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCategoryCard(
              'Cuti',
              Icons.access_time,
              // isSelected: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LeaveRequestScreen(),
                  ),
                );
              },
            ),
            _buildCategoryCard(
              'Lembur',
              Icons.history,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OvertimeScreen(),
                  ),
                );
              },
            ),
            _buildCategoryCard(
              'Timesheet',
              Icons.account_balance_wallet_outlined,
            ),
            _buildCategoryCard('Kalender', Icons.calendar_today_outlined),
            _buildCategoryCard('Semua', Icons.add, isViewAll: true),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primarySwatch[500],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 30,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    String title,
    IconData icon, {
    bool isSelected = false,
    bool isViewAll = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primarySwatch[500] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: !isSelected && !isViewAll
                  ? Border.all(color: AppColors.dark05)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: AppColors.dark[500]!.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : (isViewAll
                        ? Colors.grey[700]
                        : AppColors.secondarySwatch[500]),
              size: isViewAll ? 20 : 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceDataSection(BuildContext context) {
    return Column(
      children: [
        _buildHeaderRow(
          'Data Presensi',
          onSeeAllTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AttendanceReportScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        if (_recentAttendances.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                "Belum ada data presensi terbaru.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),

        ..._recentAttendances.map((record) {
          String status = record['status'] ?? 'Tidak Diketahui';
          Color statusColor = _getSemanticColor(status);

          // Mengambil dari database key: 'check_in', tapi memakai nama variabel frontend: 'rawClockIn'
          String rawClockIn = record['check_in']?.toString() ?? '';
          String rawClockOut = record['check_out']?.toString() ?? '';

          // 1. Jika clock-in kosong/null, langsung jadikan 'N/A'
          String clockInDisplay = (rawClockIn.isEmpty || rawClockIn == 'null')
              ? 'N/A'
              : rawClockIn;

          // 2. Jika clock-out kosong/null:
          //    - Kalau clock-in juga 'N/A' (alpha) -> jadikan 'N/A'
          //    - Kalau clock-in ada isinya (sedang bekerja) -> jadikan '-- : -- : --'
          String clockOutDisplay =
              (rawClockOut.isEmpty || rawClockOut == 'null')
              ? (clockInDisplay == 'N/A' ? 'N/A' : '-- : -- : --')
              : rawClockOut;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildAttendanceItem(
              record['date'] ?? '--',
              status,
              clockInDisplay,
              clockOutDisplay,
              statusColor,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAttendanceItem(
    String date,
    String status,
    String clockIn,
    String clockOut,
    Color statusColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark[500]!.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  left: Radius.circular(16),
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
                      date,
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
            Expanded(flex: 2, child: _buildTimeDisplay('Clock In', clockIn)),
            const VerticalDivider(
              width: 1,
              color: Color(0xFFEEEEEE),
              thickness: 1,
            ),
            Expanded(flex: 2, child: _buildTimeDisplay('Clock Out', clockOut)),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDisplay(String label, String time) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildHeaderRow(String title, {VoidCallback? onSeeAllTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        GestureDetector(
          onTap: onSeeAllTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: Text(
              'Lihat Semua',
              style: TextStyle(
                color: AppColors.primary[500],
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Selamat Pagi';
    } else if (hour >= 12 && hour < 17) {
      return 'Selamat Siang';
    } else if (hour >= 17 && hour < 21) {
      return 'Selamat Malam';
    } else {
      return 'Selamat Beristirahat';
    }
  }

  Color _getSemanticColor(String? status) {
    if (status == null) return Colors.red[500]!;

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

class LiveDateClock extends StatefulWidget {
  const LiveDateClock({super.key});

  @override
  State<LiveDateClock> createState() => _LiveDateClockState();
}

class _LiveDateClockState extends State<LiveDateClock> {
  late Timer _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      final now = DateTime.now();
      if (now.minute != _currentTime.minute) {
        setState(() {
          _currentTime = now;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      'Hari ini, ${DateFormat('dd MMMM yyyy').format(_currentTime)}',
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }
}
