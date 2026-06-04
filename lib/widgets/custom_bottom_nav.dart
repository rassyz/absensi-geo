// lib/widgets/custom_bottom_nav.dart

import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,

      elevation: 0,

      clipBehavior: Clip.antiAlias,
      shape: const CircularNotchedRectangle(),
      notchMargin: 7.0,
      child: SizedBox(
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.home, Icons.home_outlined, 'Home', 0),
            _buildNavItem(
              Icons.event_available,
              Icons.event_available_outlined,
              'Cuti',
              2,
            ),
            const SizedBox(width: 40),
            _buildNavItem(
              Icons.fact_check,
              Icons.fact_check_outlined,
              'History',
              3,
            ),
            _buildNavItem(Icons.person, Icons.person_outline, 'Profile', 4),
          ],
        ),
      ),
    );
  }

  // --- Helper untuk membangun Item Navbar ---
  Widget _buildNavItem(
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    int index,
  ) {
    final isActive = selectedIndex == index;
    final color = isActive ? const Color(0xFF2F80ED) : Colors.black87;

    return GestureDetector(
      onTap: () => onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : inactiveIcon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
