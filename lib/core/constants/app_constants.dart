import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  // --- App Info ---
  static const String appName = 'Qatrah';
  static const String appEmail = 'contact@example.com';
  static const String appPhone = '+963xxx-xxx-xxx';
  static const String facebookUrl = 'https://www.facebook.com/';
  static const String xUrl = 'https://www.x.com/';
  static const String instagramUrl = 'https://www.instagram.com/';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=sy.gov.daraa.qatrah';
  static const String appStoreUrl =
      'https://apps.apple.com/app/qatrah/id0000000000';

  // --- Localization Codes ---
  static const String langAr = 'ar';
  static const Locale localeAr = Locale('ar');

  // --- Durations (Times) ---
  static const int animationDurationInMs = 300;
  static const Duration defaultDuration = Duration(milliseconds: 300);

  static const double designWidth = 375;
  static const double designHeight = 812;

  static const double borderRadius = 8;
  static const double buttonHeight = 52;

  static const Size designSize = Size(designWidth, designHeight);
}
