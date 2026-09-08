import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/constants/app_constants.dart';
import 'package:qatrah/core/theme/app_colors.dart';
import 'package:qatrah/core/theme/app_typography.dart';

class AppTheme {
  static ThemeData createTheme({
    required bool isDark,
    required String languageCode,
  }) {
    final fontFamily = AppTypography.getFontFamily(languageCode);
    final colorScheme = isDark ? _darkScheme : _lightScheme;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      fontFamily: fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,

      // 1. 🧭 AppBar Theme - Government Style
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.secondary),
        centerTitle: true,
        titleTextStyle: AppTypography.headlineMedium.copyWith(
          color: colorScheme.secondary,
          fontFamily: fontFamily,
        ),
      ),

      // 2. 🪟 Card Theme - Dynamic for Dark/Light
      cardTheme: CardThemeData(
        color: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 2,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius.r),
        ),
      ),

      // 3. 📝 Typography - Dynamic colors injected
      textTheme: _buildTextTheme(colorScheme, fontFamily),

      // 4. 🔘 Buttons Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, AppConstants.buttonHeight.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius.r),
          ),
          textStyle: AppTypography.labelLarge.copyWith(fontFamily: fontFamily),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: Size(double.infinity, AppConstants.buttonHeight.h),
          side: BorderSide(
            color: colorScheme.primary,
            width: .75,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius.r),
          ),
        ),
      ),

      // 5. 🧱 Input Decoration (Forms)
      inputDecorationTheme: _buildInputTheme(colorScheme, isDark),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: _buildInputTheme(colorScheme, isDark),
      ),
      // 6. 🎨 Divider & Icons
      dividerTheme: DividerThemeData(color: colorScheme.outline, thickness: .5),
      iconTheme: IconThemeData(color: colorScheme.onSurface),
    );
  }

  // --- Helpers ---

  static ColorScheme get _lightScheme => const ColorScheme.light(
    primary: AppColors.lightPrimary,
    secondary: AppColors.goldenWheat,
    surface: AppColors.lightScaffold,
    onSurface: AppColors.lightTextPrimary,
    onSurfaceVariant: AppColors.lightTextSecondary,
    outline: AppColors.lightBorder,
    shadow: AppColors.black,
  );

  static ColorScheme get _darkScheme => const ColorScheme.dark(
    primary: AppColors.darkPrimary,
    secondary: AppColors.goldenWheat,
    surface: AppColors.darkScaffold,
    onSurface: AppColors.darkTextPrimary,
    onSurfaceVariant: AppColors.darkTextSecondary,
    outline: AppColors.darkBorder,
    shadow: AppColors.black,
  );

  static TextTheme _buildTextTheme(ColorScheme scheme, String? family) {
    return TextTheme(
      headlineLarge: AppTypography.headlineLarge.copyWith(
        color: scheme.onSurface,
        fontFamily: family,
      ),
      headlineMedium: AppTypography.headlineMedium.copyWith(
        color: scheme.onSurface,
        fontFamily: family,
      ),
      headlineSmall: AppTypography.headlineSmall.copyWith(
        color: scheme.onSurface,
        fontFamily: family,
      ),
      bodyLarge: AppTypography.bodyLarge.copyWith(
        color: scheme.onSurface,
        fontFamily: family,
      ),
      titleMedium: AppTypography.bodyMedium.copyWith(
        color: scheme.secondary,
        fontFamily: family,
      ),
      bodyMedium: AppTypography.bodyMedium.copyWith(
        color: scheme.onSurfaceVariant,
        fontFamily: family,
      ),
      bodySmall: AppTypography.bodySmall.copyWith(
        color: scheme.onSurfaceVariant,
        fontFamily: family,
      ),
      labelLarge: AppTypography.labelLarge.copyWith(
        color: Colors.white,
        fontFamily: family,
      ),
      // Used for Primary Buttons
      labelMedium: AppTypography.labelMedium.copyWith(
        color: scheme.onSurfaceVariant,
        fontFamily: family,
      ),
    );
  }

  static InputDecorationTheme _buildInputTheme(
    ColorScheme scheme,
    bool isDark,
  ) {
    return InputDecorationTheme(
      filled: true,
      fillColor: scheme.onPrimary,
      hintStyle: AppTypography.bodyMedium.copyWith(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
        fontSize: 14.sp,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
}
