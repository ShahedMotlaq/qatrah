// lib/core/extensions/datetime_extensions.dart

import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  /// Format to ISO string for API
  String formatToApi() => toIso8601String();

  /// Check if date is today
  bool isToday() {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Add this function
  bool isTomorrow() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Add this function
  bool isYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Get time ago string (Arabic)
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);

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

  /// Format to display date (dd/MM/yyyy)
  String formatDate({String pattern = 'dd/MM/yyyy'}) {
    return DateFormat(pattern).format(this);
  }

  /// Format to display time (HH:mm)
  String formatTime() {
    return DateFormat('HH:mm').format(this);
  }

  /// Format to display date and time
  String formatDateTime() {
    return DateFormat('dd/MM/yyyy HH:mm').format(this);
  }

  /// Format Arabic date with intl locale
  String formatArabicDate() {
    return DateFormat('EEEE، d MMMM | hh:mm a', 'ar').format(this);
  }

  /// Format Arabic date with English locale
  String formatArabicDateEnglish() {
    return DateFormat('EEEE, d MMMM | hh:mm a').format(this);
  }

  /// Check if this datetime is in the past
  bool get isPast => isBefore(DateTime.now());

  /// Check if this datetime is in the future or now
  bool get isFutureOrNow =>
      isAtSameMomentAs(DateTime.now()) || isAfter(DateTime.now());

  /// Check if this datetime is between two others (inclusive start, exclusive end)
  bool isBetween(DateTime start, DateTime end) {
    return (isAtSameMomentAs(start) || isAfter(start)) && isBefore(end);
  }

  /// Add this function for comparing with a specific date
  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Add this function for start of day
  DateTime get startOfDay => DateTime(year, month, day);

  /// Add this function for end of day
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);
}

extension StringToDateTimeExtension on String {
  /// Parse ISO string to DateTime safely
  DateTime? toDateTime() {
    try {
      return DateTime.parse(this);
    } catch (_) {
      return null;
    }
  }

  /// Parse ISO string to DateTime or return null
  DateTime? toDateTimeOrNull() {
    try {
      return DateTime.tryParse(this);
    } catch (_) {
      return null;
    }
  }
}
