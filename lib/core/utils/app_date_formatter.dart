// lib/core/utils/app_date_formatter.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Centralized date/time formatter for the entire application.
/// Supports both Arabic and English locales with automatic detection.
///
/// Usage:
/// ```dart
/// // In any widget:
/// AppDateFormatter.formatPumpingDateTime(schedule.startTime, context);
/// ```
///
/// All date formatting should go through this class to ensure consistency.
class AppDateFormatter {
  AppDateFormatter._();

  // ===========================================================================
  // PRIMARY FORMATTERS
  // ===========================================================================

  /// Format pumping schedule date/time.
  /// English: EEEE, MMM d, hh:mm a (Example: Saturday, Apr 7, 04:30 PM)
  static String formatPumpingDateTime(
    DateTime? dateTime,
    BuildContext context,
  ) {
    if (dateTime == null) return '--';

    final locale = Localizations.localeOf(context).languageCode;

    if (locale == 'ar') {
      return DateFormat('EEEE، d MMMM، hh:mm a', 'ar').format(dateTime);
    } else {
      // English format: Saturday, Apr 7, 04:30 PM
      return DateFormat('EEEE, MMM d, hh:mm a').format(dateTime);
    }
  }

  /// Format date only (no time).
  /// English: MMM d, yyyy (Example: Apr 7, 2026)
  static String formatDateOnly(DateTime? dateTime, BuildContext context) {
    if (dateTime == null) return '--';

    final locale = Localizations.localeOf(context).languageCode;

    if (locale == 'ar') {
      return DateFormat('d MMMM yyyy', 'ar').format(dateTime);
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

  /// Format time only.
  /// English: hh:mm a (Example: 04:30 PM)
  static String formatTimeOnly(DateTime? dateTime, BuildContext context) {
    if (dateTime == null) return '--';

    final locale = Localizations.localeOf(context).languageCode;

    if (locale == 'ar') {
      return DateFormat('hh:mm a', 'ar').format(dateTime);
    } else {
      return DateFormat('hh:mm a').format(dateTime);
    }
  }

  /// Format notification date/time (compact).
  /// English: MMM d, hh:mm a (Example: Apr 7, 04:30 PM)
  static String formatNotificationDateTime(
    DateTime? dateTime,
    BuildContext context,
  ) {
    if (dateTime == null) return '--';

    final locale = Localizations.localeOf(context).languageCode;

    if (locale == 'ar') {
      return DateFormat('d MMMM، hh:mm a', 'ar').format(dateTime);
    } else {
      return DateFormat('MMM d, hh:mm a').format(dateTime);
    }
  }

  /// Format complaint/feedback date/time (compact with date).
  /// English: yyyy/MM/dd - hh:mm a (Example: 2026/04/07 - 04:30 PM)
  static String formatComplaintDateTime(
    DateTime? dateTime,
    BuildContext context,
  ) {
    if (dateTime == null) return '--';

    final locale = Localizations.localeOf(context).languageCode;

    if (locale == 'ar') {
      return DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(dateTime);
    } else {
      return DateFormat('yyyy/MM/dd - hh:mm a').format(dateTime);
    }
  }

  /// Format short date for tables/lists.
  /// Arabic: dd/MM/yyyy (Example: 07/04/2026)
  /// English: MM/dd/yyyy (Example: 04/07/2026)
  static String formatShortDate(DateTime? dateTime, BuildContext context) {
    if (dateTime == null) return '--';

    final locale = Localizations.localeOf(context).languageCode;

    if (locale == 'ar') {
      return DateFormat('dd/MM/yyyy', 'ar').format(dateTime);
    } else {
      return DateFormat('MM/dd/yyyy').format(dateTime);
    }
  }

  // ===========================================================================
  // RELATIVE TIME FORMATTERS
  // ===========================================================================

  /// Format relative time (time ago).
  /// English: 5 min ago, 1 hour ago, etc.
  static String formatTimeAgo(DateTime? dateTime, BuildContext context) {
    if (dateTime == null) return '--';

    final locale = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (locale == 'ar') {
      return _formatTimeAgoArabic(difference);
    } else {
      return _formatTimeAgoEnglish(difference);
    }
  }

  static String _formatTimeAgoArabic(Duration difference) {
    if (difference.inDays > 365) {
      return 'منذ ${(difference.inDays / 365).floor()} سنة';
    } else if (difference.inDays > 30) {
      return 'منذ ${(difference.inDays / 30).floor()} شهر';
    } else if (difference.inDays > 7) {
      return 'منذ ${(difference.inDays / 7).floor()} أسبوع';
    } else if (difference.inDays >= 1) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inHours >= 1) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inMinutes >= 1) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }

  static String _formatTimeAgoEnglish(Duration difference) {
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 7) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Check if date is today (for "Today" label).
  static bool isToday(DateTime? dateTime) {
    if (dateTime == null) return false;
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// Check if date is tomorrow.
  static bool isTomorrow(DateTime? dateTime) {
    if (dateTime == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dateTime.year == tomorrow.year &&
        dateTime.month == tomorrow.month &&
        dateTime.day == tomorrow.day;
  }

  /// Check if date is yesterday.
  static bool isYesterday(DateTime? dateTime) {
    if (dateTime == null) return false;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day;
  }

  // ===========================================================================
  // SMART FORMATTER (context-aware)
  // ===========================================================================

  /// Smart formatter that shows "Today" or "Tomorrow" instead of full date.
  /// Example: "Today, 04:30 PM" or "Tomorrow, 09:00 AM"
  static String formatSmartDateTime(DateTime? dateTime, BuildContext context) {
    if (dateTime == null) return '--';

    final locale = Localizations.localeOf(context).languageCode;
    final time = formatTimeOnly(dateTime, context);

    if (isToday(dateTime)) {
      return locale == 'ar' ? 'اليوم، $time' : 'Today, $time';
    } else if (isTomorrow(dateTime)) {
      return locale == 'ar' ? 'غداً، $time' : 'Tomorrow, $time';
    } else if (isYesterday(dateTime)) {
      return locale == 'ar' ? 'أمس، $time' : 'Yesterday, $time';
    }

    // Fall back to full date format
    return formatPumpingDateTime(dateTime, context);
  }

  /// Smart date only formatter with "Today", "Tomorrow", etc.
  static String formatSmartDate(DateTime? dateTime, BuildContext context) {
    if (dateTime == null) return '--';

    final locale = Localizations.localeOf(context).languageCode;

    if (isToday(dateTime)) {
      return locale == 'ar' ? 'اليوم' : 'Today';
    } else if (isTomorrow(dateTime)) {
      return locale == 'ar' ? 'غداً' : 'Tomorrow';
    } else if (isYesterday(dateTime)) {
      return locale == 'ar' ? 'أمس' : 'Yesterday';
    }

    return formatDateOnly(dateTime, context);
  }
}
