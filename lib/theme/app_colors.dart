// lib/theme/app_colors.dart

import 'package:flutter/material.dart';

/// A class defining all colors and palettes for the Mobile Attendance App.
/// Based directly on the '02. Color Setup' design system (image_1.png).
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation.

  // =========================================================================
  // Core Palettes (Tints 100 - 900)
  // =========================================================================

  // --- Primary Palette (Blue) ---
  // A dynamic blue, key for action.
  static const Map<int, Color> primary = {
    100: Color(0xFFE1F5FE),
    200: Color(0xFFB3E5FC),
    300: Color(0xFF81D4FA),
    400: Color(0xFF4FC3F7),
    500: Color(0xFF2979FF), // <- Core Primary Blue
    600: Color(0xFF1E88E5),
    700: Color(0xFF1976D2),
    800: Color(0xFF1565C0),
    900: Color(0xFF0D47A1),
  };
  static final MaterialColor primarySwatch = MaterialColor(primary[500]!.value, primary);

  // =========================================================================
  // Grayscale & Surface Tints
  // =========================================================================

  // --- Dark Swatch (Black/Deep Gray) ---
  static const Map<int, Color> dark = {
    500: Color(0xFF000000), // <- Black
  };
  // Percentage tints based on 500
  static Color get dark20 => dark[500]!.withOpacity(0.2);
  static Color get dark10 => dark[500]!.withOpacity(0.1);
  static Color get dark05 => dark[500]!.withOpacity(0.05);

  // --- Gray Swatch (Mid-Gray) ---
  static const Map<int, Color> gray = {
    500: Color(0xFFA1A1A1), // <- Mid-Gray
  };
  // Percentage tints based on 500
  static Color get gray20 => gray[500]!.withOpacity(0.2);
  static Color get gray10 => gray[500]!.withOpacity(0.1);
  static Color get gray05 => gray[500]!.withOpacity(0.05);

  // --- Light Swatch (Very Light Gray) ---
  static const Map<int, Color> light = {
    500: Color(0xFFF0F0F0), // <- Light Gray
  };

  // --- White Swatch (Pure White with Opacities) ---
  static const Map<int, Color> white = {
    500: Color(0xFFFFFFFF), // <- Pure White
  };

}