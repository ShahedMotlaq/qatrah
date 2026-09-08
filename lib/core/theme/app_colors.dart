import 'package:flutter/material.dart';

/// Official color palette for the Government Digital Identity.
/// Each group represents a thematic tone for consistent branding.
class AppColors {
  static const Color forest = Color(0xFF054239);
  static const Color goldenWheat = Color(0xFFb9a779);
  static const Color deepUmber = Color(0xFF4a151e);

  // ☀️ Light Theme Palette
  static const Color lightPrimary = forest;
  static const Color lightScaffold = Color(0xFFedebe0); // Golden Wheat Light
  static const Color lightSurface = Color(0xFFF5F5F5);
  static const Color lightTextPrimary = Color(0xFF161616); // Charcoal Dark
  static const Color lightTextSecondary = Color(0xFF3d3a3b);
  static const Color lightBorder = Color(0xFFD0D5DD);

  // 🌑 Dark Theme Palette
  static const Color darkPrimary = Color(
    0xFF428177,
  ); // Forest Light for better contrast
  static const Color darkScaffold = Color(0xFF101828);
  static const Color darkSurface = Color(0xFF1D2939);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF98A2B3);
  static const Color darkBorder = Color(0xFF344054);

  // 🚩--- (Common Colors) ---
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF232522);
  static const Color error = Color(0xffE25839);
  static const Color success = Color(0xff45B733);
  static const Color info = Color(0xFF2E90FA);
  static const Color warning = Color(0xffF5AE42);
  static const Color orange = Color(0xffE8712E);
  static const Color nude = Color(0xFFD4A87A);
  static const Color transparent = Colors.transparent;
}
