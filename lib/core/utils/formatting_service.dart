// lib/core/utils/formatting_service.dart
//
// Single source of truth for all date/time/number/duration formatting.
//
// Design contract:
//   • Context-free — no BuildContext dependency.
//   • l10n is passed explicitly to every method that produces user-visible
//     string labels (today/yesterday/duration/time-ago).  Methods that only
//     produce format patterns (clock digits, date digits) need no l10n.
//   • DateFormat instances are cached as static finals — construction is
//     amortised across the app lifetime.
//
// Usage:
//   FormattingService.formatTime(dt)
//   FormattingService.formatSmartDate(l10n, dt)
//   FormattingService.formatScheduleEntry(l10n, start, end)
//   FormattingService.formatTimeRemaining(l10n, endTime)
//   FormattingService.formatTimeAgo(l10n, pastTime)

import 'package:intl/intl.dart';
import 'package:qatrah/l10n/gen/app_localizations.dart';

class FormattingService {
  const FormattingService._();

  // ── Locale constant ───────────────────────────────────────────────────────
  static const _locale = 'ar';

  // ── Cached DateFormat instances ───────────────────────────────────────────
  // These are created once per app run.  DateFormat is mutable only through
  // its builder pattern; calling .format() on a cached instance is safe.

  static final _timeFmt = DateFormat('hh:mm a', _locale);

  static final _dateFmt = DateFormat('d MMMM yyyy', _locale);

  static final _shortDateFmt = DateFormat('d MMMM', _locale);

  static final _dayDateFmt = DateFormat('EEEE، d MMMM', _locale);

  // ── Pure time formatting (no l10n required) ───────────────────────────────

  static String formatTime(DateTime dateTime) => _timeFmt.format(dateTime);

  static String formatTimeRange(DateTime start, DateTime end) =>
      '${formatTime(start)} - ${formatTime(end)}';

  // ── Pure date formatting (no l10n required) ───────────────────────────────

  static String formatDate(DateTime dateTime) => _dateFmt.format(dateTime);

  static String formatShortDate(DateTime dateTime) =>
      _shortDateFmt.format(dateTime);

  static String formatDayDate(DateTime dateTime) =>
      _dayDateFmt.format(dateTime);

  static String formatDayDateTime(DateTime dateTime) =>
      '${formatDayDate(dateTime)} | ${formatTime(dateTime)}';

  // ── Label-bearing formatting (l10n required) ─────────────────────────────

  static String formatSmartDate(AppLocalizations l10n, DateTime dateTime) {
    if (_isToday(dateTime)) return l10n.todayLabel;
    if (_isTomorrow(dateTime)) return l10n.tomorrowLabel;
    if (_isYesterday(dateTime)) return l10n.yesterday;
    return formatShortDate(dateTime);
  }

  static String formatScheduleEntry(
    AppLocalizations _,
    DateTime start,
    DateTime end,
  ) => '${formatDayDate(start)} | ${formatTimeRange(start, end)}';

  /// Duration string with correct Arabic plural forms.
  ///
  /// Uses l10n ICU plural keys so every form is translatable.
  ///
  /// Returns [l10n.pumpingEndedLabel] for zero/negative durations.
  static String formatDuration(AppLocalizations l10n, Duration duration) {
    if (duration.isNegative || duration.inSeconds <= 0) {
      return l10n.pumpingEndedLabel;
    }
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) {
      return l10n.durationHoursAndMinutes(
        l10n.durationHours(hours),
        l10n.durationMinutes(minutes),
      );
    }
    if (hours > 0) return l10n.durationHours(hours);
    return l10n.durationMinutes(minutes > 0 ? minutes : 1);
  }

  /// Returns [l10n.pumpingEndedLabel] when [endTime] is in the past.
  static String formatTimeRemaining(AppLocalizations l10n, DateTime endTime) {
    final remaining = endTime.difference(DateTime.now());
    if (remaining.isNegative || remaining.inSeconds <= 0) {
      return l10n.pumpingEndedLabel;
    }
    return l10n.pumpingTimeRemaining(formatDuration(l10n, remaining));
  }

  static String formatTimeAgo(AppLocalizations l10n, DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays >= 365) {
      return l10n.timeAgoLabel(l10n.durationYears(diff.inDays ~/ 365));
    }
    if (diff.inDays >= 30) {
      return l10n.timeAgoLabel(l10n.durationMonths(diff.inDays ~/ 30));
    }
    if (diff.inDays >= 7) {
      return l10n.timeAgoLabel(l10n.durationWeeks(diff.inDays ~/ 7));
    }
    if (diff.inDays >= 1) {
      return l10n.timeAgoLabel(l10n.durationDays(diff.inDays));
    }
    if (diff.inHours >= 1) {
      return l10n.timeAgoLabel(l10n.durationHours(diff.inHours));
    }
    if (diff.inMinutes >= 1) {
      return l10n.timeAgoLabel(l10n.durationMinutes(diff.inMinutes));
    }
    return l10n.justNow;
  }

  // ── Number formatting ─────────────────────────────────────────────────────

  /// Formats a number with Arabic locale grouping separators: "1,234"
  static String formatNumber(num value) =>
      NumberFormat.decimalPattern(_locale).format(value);

  // ── Private date helpers ──────────────────────────────────────────────────

  static bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  static bool _isTomorrow(DateTime d) {
    final t = DateTime.now().add(const Duration(days: 1));
    return d.year == t.year && d.month == t.month && d.day == t.day;
  }

  static bool _isYesterday(DateTime d) {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return d.year == y.year && d.month == y.month && d.day == y.day;
  }
}
