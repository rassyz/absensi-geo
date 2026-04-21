// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:absensi_geo/providers/auth_provider.dart';
import 'package:absensi_geo/services/api_service.dart'; // Added API Service
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:absensi_geo/screens/attendance_screen.dart';

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
      title: 'Mobile Presensi',
      theme: AppTheme.lightTheme(),
      home: const HomeScreen(),
    );
  }
}

// 1. Converted to StatefulWidget to hold live API data
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService apiService = ApiService();

  // State variable for attendance history
  List<dynamic> _recentAttendances = [];

  // State variables for real-time display
  String _checkInTime = '-- : -- : --';
  String _checkOutTime = '-- : -- : --';

  // NEW: State variables for monthly stats
  String _totalAttendance = '--';
  String _lateClockIn = '--';
  String _noClockIn = '--';

  @override
  void initState() {
    super.initState();
    _fetchHomeData(); // Fetch data when the screen loads
  }

  // 2. Fetch data from Laravel (Renamed to fetch everything at once)
  Future<void> _fetchHomeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.user?.token;

    if (token != null) {
      // 1. Fetch Today's Clock In/Out Status
      final statusData = await apiService.getTodayAttendanceStatus(token);

      // 2. Fetch Monthly Stats
      final statsData = await apiService.getMonthlyStats(token);

      // 3. Fetch Attendance History
      final historyData = await apiService.getAttendanceHistory(token);

      if (mounted) {
        setState(() {
          // Process Today's Data
          if (statusData != null && statusData['success'] == true) {
            bool hasCheckedIn = statusData['has_checked_in'] ?? false;
            bool hasCheckedOut = statusData['has_checked_out'] ?? false;

            _checkInTime = hasCheckedIn
                ? (statusData['check_in_time'] ?? '-- : -- : --')
                : '-- : -- : --';
            _checkOutTime = hasCheckedOut
                ? (statusData['check_out_time'] ?? '-- : -- : --')
                : '-- : -- : --';
          }

          // Process Monthly Data
          if (statsData != null && statsData['success'] == true) {
            _totalAttendance = statsData['total_attendance'] ?? '--';
            _lateClockIn = statsData['late_clock_in'] ?? '--';
            _noClockIn = statsData['no_clock_in'] ?? '--';
          }

          // Process History Data
          if (historyData != null) {
            _recentAttendances = historyData;
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
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusGreeting(
                    context,
                    authProvider,
                    user?.employee?.fullName ?? 'Guest',
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
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            // 3. Pass the refresh function down to the Nav Bar!
            child: CustomBottomNavBar(onReturnFromAttendance: _fetchHomeData),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusGreeting(
    BuildContext context,
    AuthProvider authProvider,
    String userName,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const Text(
            //   '9:41',
            //   style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            // ),
            const SizedBox(height: 8),
            Text(
              _getGreeting(),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'Hello, $userName!',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => _showLogoutDialog(context, authProvider),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primarySwatch[500]!,
                width: 2,
              ),
            ),
            child: const CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey,
              child: Icon(Icons.logout, color: Colors.white, size: 20),
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
                hintText: 'Search...',
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
              // 4. Injected the dynamic state variables here!
              Expanded(child: _buildClockCard('CLOCK IN', _checkInTime)),
              const SizedBox(width: 16),
              Expanded(child: _buildClockCard('CLOCK OUT', _checkOutTime)),
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
        // Note: Changing "Your Absence" to "Total Present" usually makes more sense
        // given the number is high (e.g. 27), but I kept the layout matching your design!
        _buildStatColumn('Your Absence', _totalAttendance),
        _buildStatColumn('Late Clock In', _lateClockIn),
        _buildStatColumn('No Clock In', _noClockIn),
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
        _buildHeaderRow('Category'),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCategoryCard('Leave', Icons.access_time, isSelected: true),
            _buildCategoryCard('Overtime', Icons.history),
            _buildCategoryCard(
              'Timesheet',
              Icons.account_balance_wallet_outlined,
            ),
            _buildCategoryCard('Calendar', Icons.calendar_today_outlined),
            _buildCategoryCard('View All', Icons.add, isViewAll: true),
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
  }) {
    return Column(
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
    );
  }

  Widget _buildAttendanceDataSection(BuildContext context) {
    return Column(
      children: [
        _buildHeaderRow('Attendance Data'),
        const SizedBox(height: 16),

        // Show a message if the database is empty
        if (_recentAttendances.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                "No recent attendance data.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),

        // Dynamically loop through the database records
        ..._recentAttendances.map((record) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildAttendanceItem(
              record['date'] ?? '--',
              record['status'] ?? 'Reguler',
              record['check_in'] ?? '-- : -- : --',
              record['check_out'] ?? '-- : -- : --',
            ),
          );
        }), // .toList() is not required when using the spread operator (...)
      ],
    );
  }

  Widget _buildAttendanceItem(
    String date,
    String status,
    String clockIn,
    String clockOut,
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
                color: AppColors.primarySwatch[500],
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
                        color: AppColors.primarySwatch[500],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const VerticalDivider(width: 1, color: Colors.grey),
            Expanded(flex: 2, child: _buildTimeDisplay('Clock In', clockIn)),
            const VerticalDivider(width: 1, color: Colors.grey),
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

  Widget _buildHeaderRow(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Text(
          'See All',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  Future<void> _showLogoutDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Logout Confirmation'),
          content: const Text(
            'Are you sure you want to log out? Your current session will be ended.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                await authProvider.logout();

                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Logout Successful'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );

                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  final VoidCallback?
  onReturnFromAttendance; // ADDED: Callback for refreshing data!

  const CustomBottomNavBar({super.key, this.onReturnFromAttendance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppColors.gradient2,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primarySwatch[500]!.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home_outlined, isSelected: true),

          // Updated clock icon to await the navigator
          _buildNavItem(
            Icons.access_time_outlined,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AttendanceScreen(),
                ),
              );
              // Once the user pops back to this screen, trigger the API refresh!
              if (onReturnFromAttendance != null) {
                onReturnFromAttendance!();
              }
            },
          ),

          _buildNavItem(Icons.calendar_today_outlined),
          _buildNavItem(Icons.notifications_none_outlined),
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
    // _fetchHomeData();
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
      'Today, ${DateFormat('dd MMMM yyyy').format(_currentTime)}',
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }
}
