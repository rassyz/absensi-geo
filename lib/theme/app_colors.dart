// lib/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // --- Primary Palette (Blue) ---
  static const Map<int, Color> primary = {
    100: Color(0xFFD6E4FF),
    200: Color(0xFFA8C7FF),
    300: Color(0xFF7BAAFF),
    400: Color(0xFF5692FF),
    500: Color(0xFF2F80ED), // Base Primary
    600: Color(0xFF2363CD),
    700: Color(0xFF1849AB),
    800: Color(0xFF0F318A),
    900: Color(0xFF081C68),
  };

  static final MaterialColor primarySwatch = MaterialColor(
    0xFF2F80ED, // Base Primary 500
    primary,
  );

  // --- Secondary Palette (Lime Green) ---
  static const Map<int, Color> secondary = {
    100: Color(0xFFE9F5D3),
    200: Color(0xFFD4EAA6),
    300: Color(0xFFBEDF7A),
    400: Color(0xFFAAD557),
    500: Color(0xFF8DC63F), // Base Secondary
    600: Color(0xFF72A630),
    700: Color(0xFF588622),
    800: Color(0xFF3F6615),
    900: Color(0xFF28460A),
  };

  static final MaterialColor secondarySwatch = MaterialColor(
    0xFF8DC63F, // Base Secondary 500
    secondary,
  );

  // --- Tertiary Palette (Coral Red) ---
  static const Map<int, Color> tertiary = {
    100: Color(0xFFFFDFDF),
    200: Color(0xFFFFBDBD),
    300: Color(0xFFFF9B9B),
    400: Color(0xFFFF8080),
    500: Color(0xFFFF6B6B), // Base Tertiary
    600: Color(0xFFE65050),
    700: Color(0xFFCC3838),
    800: Color(0xFFB32424),
    900: Color(0xFF991212),
  };

  // --- Grayscale & Surface Tints ---
  static const Map<int, Color> dark = {
    500: Color(0xFF1A1C1E),
    90: Color(0xE61A1C1E),
    80: Color(0xCC1A1C1E),
    20: Color(0x331A1C1E),
    10: Color(0x1A1A1C1E),
    5: Color(0x0D1A1C1E),
  };

  static const Map<int, Color> gray = {
    500: Color(0xFF9CA3AF),
    90: Color(0xE69CA3AF),
    80: Color(0xCC9CA3AF),
    20: Color(0x339CA3AF),
    10: Color(0x1A9CA3AF),
    5: Color(0x0D9CA3AF),
  };

  static const Map<int, Color> light = {
    500: Color(0xFFF3F4F6),
    90: Color(0xE6F3F4F6),
    80: Color(0xCCF3F4F6),
    20: Color(0x33F3F4F6),
    10: Color(0x1AF3F4F6),
    5: Color(0x0DF3F4F6),
  };

  static const Map<int, Color> white = {
    500: Color(0xFFFFFFFF),
    90: Color(0xE6FFFFFF),
    80: Color(0xCCFFFFFF),
    20: Color(0x33FFFFFF),
    10: Color(0x1AFFFFFF),
    5: Color(0x0DFFFFFF),
  };

  // --- Backward Compatibility Getters ---
  // Mapped directly to the new structured maps to prevent breaking existing code
  static Color get dark05 => dark[5]!;
  static Color get gray20 => gray[20]!;

  // --- Gradients ---
  static const LinearGradient gradient1 = LinearGradient(
    colors: [Color(0xFF8DC63F), Color(0xFF2F80ED)], // Green to Blue
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradient2 = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [
      Color(0xFF16A085), // Start Teal
      Color(0xFF4285F4), // End Clear Blue
    ],
  );
}
