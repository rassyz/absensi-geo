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
    // SafeArea ensures the margin doesn't get pushed off-screen by the phone's physical bezel
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF24A49C), // Teal
              Color(0xFF3B82F6), // Blue
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(
            30,
          ), // Guarantees the capsule shape
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: const Color(0xFF3B82F6).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.home_outlined, 0),
            _buildNavItem(Icons.access_time, 1),
            _buildNavItem(Icons.calendar_today, 2),
            _buildNavItem(Icons.notifications_none, 3),
            _buildNavItem(Icons.person_outline, 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isActive = selectedIndex == index;

    return GestureDetector(
      onTap: () => onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? Colors.white : Colors.white70,
            size: isActive ? 28 : 24,
          ),
          if (isActive)
            Positioned(
              bottom: -10,
              child: Container(
                width: 4,
                height: 4,
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
