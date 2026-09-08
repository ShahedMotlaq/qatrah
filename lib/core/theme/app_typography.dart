import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/constants/app_assets.dart';

/// 🏛️ Official typography system for the Government Digital Identity.
/// This class defines the "shapes" (size, weight, height) of text styles.
/// Colors are injected via ThemeData to ensure Dark/Light mode compatibility.
class AppTypography {
  // Keep Flutter's platform font fallback for Arabic until the bundled font is
  // verified as Unicode-safe. The current font renders Arabic as mojibake.
  static String? getFontFamily(String languageCode) {
    if (languageCode == 'ar') return 'ITF Qomra Arabic';
    return AppAssets.enFontFamily;
  }

  // 📰 Headlines (Previously headline1, headline2, headline3)
  static TextStyle get headlineLarge => TextStyle(
    fontSize: 28.sp,
    fontWeight: FontWeight.w700, // Bold
    height: 1.3,
  );

  static TextStyle get headlineMedium => TextStyle(
    fontSize: 22.sp,
    fontWeight: FontWeight.w600, // Semi-Bold
    height: 1.4,
  );

  static TextStyle get headlineSmall => TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeight.w500, // Medium
    height: 1.4,
  );

  // 📄 Body text (Large, Medium, Small)
  static TextStyle get bodyLarge => TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.w400, // Regular
    height: 1.6,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static TextStyle get bodySmall => TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // 🔘 Button & Labels (labelLarge, labelMedium, labelSmall)
  static TextStyle get labelLarge => TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    height: 1.2,
  );

  static TextStyle get labelMedium => TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static TextStyle get labelSmall => TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w400, // For Captions/Footnotes
    height: 1.3,
  );
}
