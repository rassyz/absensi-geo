// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
// Important: This assumes you have the AppColors and AppTheme classes from the previous setup image.
// If you don't have them yet, you can inline the colors or place the class definitions at the top of this file for testing.
// import 'package:mobile_attendance_app/theme/app_colors.dart';
// import 'package:mobile_attendance_app/theme/app_theme.dart';

// --- Inline Color/Theme Definitions from Previous Setup (image_0.png) for easy testing ---
// --- Remove this block if you already have lib/theme/app_colors.dart ---
class AppColors {
  AppColors._();
  // Primary (Blue)
  static const Map<int, Color> primary = {
    500: Color(0xFF2979FF),
    700: Color(0xFF1976D2),
  };
  static final MaterialColor primarySwatch = MaterialColor(
    primary[500]!.value,
    primary,
  );

  // Secondary (Lime Green) - for accents
  static const Map<int, Color> secondary = {500: Color(0xFFA4CD39)};
  static final MaterialColor secondarySwatch = MaterialColor(
    secondary[500]!.value,
    secondary,
  );

  // Grayscale & Surface Tints
  static const Map<int, Color> dark = {500: Color(0xFF000000)};
  static const Map<int, Color> gray = {500: Color(0xFFA1A1A1)};
  static const Map<int, Color> light = {500: Color(0xFFF0F0F0)};
  static const Map<int, Color> white = {500: Color(0xFFFFFFFF)};
  static Color get dark05 => dark[500]!.withOpacity(0.05);

  // Gradients
  static const LinearGradient gradient2 = LinearGradient(
    // Teal to Blue
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
      // Apply the centrally configured light theme here!
      theme: AppTheme.lightTheme(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        children: [
          // Main scrollable content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusGreeting(),
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
                  const SizedBox(
                    height: 100,
                  ), // Extra space for custom bottom nav
                ],
              ),
            ),
          ),
          // Custom Gradient Bottom Navigation
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomBottomNavBar(),
          ),
        ],
      ),
    );
  }

  // 1. Greeting Row and Profile
  Widget _buildStatusGreeting() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '9:41',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ), // Simulating status bar time
            SizedBox(height: 8),
            Text(
              'Good Morning',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            SizedBox(height: 4),
            Text(
              'Hello, Alexander Morales!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        CircleAvatar(
          radius: 26,
          backgroundColor: Colors.grey, // Placeholder for user image
        ),
      ],
    );
  }

  // 2. Search and Filter Bar
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
          child: Icon(
            Icons.tune,
            color: AppColors.primarySwatch[500],
          ), // Custom red filter icon -> Primary Blue
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.dark05),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
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

  // 3. The Big Gradient Card (Red/Orange -> Teal/Blue)
  Widget _buildMainGradientCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient:
            AppColors.gradient2, // Custom red gradient -> Teal/Blue Gradient
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primarySwatch[500]!.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today, 08 December 2024',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
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
                    color: Colors.white.withOpacity(0.7),
                    size: 12,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Clock in/out Cards
          Row(
            children: [
              Expanded(child: _buildClockCard('CLOCK IN', '08 : 45 : 00')),
              const SizedBox(width: 16),
              Expanded(child: _buildClockCard('CLOCK OUT', '17 : 10 : 00')),
            ],
          ),
        ],
      ),
    );
  }

  // Helper widget for Clock in/out cards
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
              Icon(
                Icons.login,
                size: 18,
                color: AppColors.primarySwatch[500],
              ), // Blue icon
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
          ), // Blue time
        ],
      ),
    );
  }

  // 4. Summary Stats Row
  Widget _buildSummaryStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatColumn('Your Absence', '27'),
        _buildStatColumn('Late Clock In', '01'),
        _buildStatColumn('No Clock In', '03'),
      ],
    );
  }

  // Helper widget for stats column
  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 6),
        // Custom red number -> Primary Blue
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

  // 5. Category Section
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
        // Pagination indicator
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
            ), // Red -> Blue indicator
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

  // Helper widget for category card
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
            color: isSelected
                ? AppColors.primarySwatch[500]
                : Colors.white, // Custom red -> Primary Blue for selected
            borderRadius: BorderRadius.circular(16),
            border: !isSelected && !isViewAll
                ? Border.all(color: AppColors.dark05)
                : null,
            boxShadow: [
              BoxShadow(
                color: AppColors.dark[500]!.withOpacity(0.05),
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
          ), // Lime green or gray icon
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

  // 6. Attendance Data Section
  Widget _buildAttendanceDataSection(BuildContext context) {
    return Column(
      children: [
        _buildHeaderRow('Attendance Data'),
        const SizedBox(height: 16),
        _buildAttendanceItem(
          '8 December 2024',
          'Reguler',
          '08 : 45 : 00',
          '17 : 10 : 00',
        ),
        const SizedBox(height: 12),
        _buildAttendanceItem(
          '7 December 2024',
          'Reguler',
          '09 : 00 : 00',
          '17 : 45 : 00',
        ),
      ],
    );
  }

  // Helper widget for attendance item card
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
            color: AppColors.dark[500]!.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Vertical Blue sidebar indicator
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
                    ), // Date Blue
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

  // Helper widget for time display in list item
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

  // General helper for section headers
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
}

// 7. Custom Gradient Bottom Navigation Bar
class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient:
            AppColors.gradient2, // Custom red gradient -> Teal/Blue Gradient
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primarySwatch[500]!.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home_outlined, isSelected: true),
          _buildNavItem(Icons.access_time_outlined),
          _buildNavItem(Icons.calendar_today_outlined),
          _buildNavItem(Icons.notifications_none_outlined),
          _buildNavItem(Icons.person_outline_outlined),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, {bool isSelected = false}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
          size: 26,
        ),
        if (isSelected)
          Positioned(
            bottom: -10,
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
